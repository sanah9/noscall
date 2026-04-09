import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:flutter_webrtc/flutter_webrtc.dart' show RTCIceCandidate, RTCIceConnectionState;
import 'package:nostr_core_dart/nostr.dart';
import 'package:uuid/uuid.dart';

import 'package:noscall/core/core.dart';
import 'callkeep_manager.dart';
import 'call_connectivity_listener.dart';
import 'call_duration_tracker.dart';
import 'call_invite_timeout.dart';
import 'constant/call_type.dart';
import 'web_rtc_handler.dart';
import 'package:noscall/call_history/controller/call_history_manager.dart';
import 'package:noscall/call_history/constants/call_enums.dart';

///                                   Start
/// ------------------------------------------------------------------------
///               Caller                ｜               Callee
/// ------------------------------------------------------------------------
///    1. createOffer + setLocalDesc    ｜
///       Send Offer                    ｜     setRemoteDesc(offer)
///                                     ｜
///    2. onIceCandidate(caller)        ｜
///       Send Candidate info           ｜     Add Caller candidate info
///                                     ｜
///                                     ｜     3. createAnswer + setLocalDesc
///       setRemoteDesc(answer)         ｜        Send Answer
///                                     ｜
///                                     ｜     4. onIceCandidate(callee)
///       Add Callee candidate info     ｜        Send Candidate info
/// ------------------------------------------------------------------------
///                       5. WebRTC Connection Checking
///                       6. WebRTC Connection Connected
///                       7. Some one send disconnected
/// ------------------------------------------------------------------------
///                                    End

class CallingController {
  CallingController._({
    required this.user,
    required this.role,
    required this.callType,
    String sessionId = '',
    CallingState state = CallingState.ringing,
    AudioOutputType speakerType = AudioOutputType.speaker,
    bool isCameraOn = true,
    bool isRecordOn = true,
    bool isFrontCamera = false,
    this.disposeCallback,
    this.callHistoryManager,
    this.callKeepManager,
  }) :
        state = ValueNotifier(state),
        hasConnected = ValueNotifier(state == CallingState.connected),
        speakerType = ValueNotifier(speakerType),
        isCameraOn = ValueNotifier(isCameraOn),
        isRecordOn = ValueNotifier(isRecordOn),
        isFrontCamera = ValueNotifier(isFrontCamera),
        isAccepting = ValueNotifier(false),
        isHangingUp = ValueNotifier(false),
        sessionId = sessionId.isNotEmpty ? sessionId : user.pubKey;

  UserDBISAR user;
  CallType callType;
  String get peerId => user.pubKey;
  // '${Contacts.sharedInstance.pubkey}-${user.pubKey}'
  String sessionId;

  Set<RTCIceCandidate> localCandidateSet = {};
  Completer<String> offerIdCmp = Completer<String>();
  Future<String> get offerId => offerIdCmp.future;

  Completer<String> callIdCmp = Completer<String>();
  Future<String> get callId => callIdCmp.future;

  CallingRole role;
  ValueNotifier<CallingState> state;
  ValueNotifier<bool> hasConnected;
  ValueNotifier<AudioOutputType> speakerType;
  ValueNotifier<bool> isCameraOn;
  ValueNotifier<bool> isRecordOn;
  ValueNotifier<bool> isFrontCamera;
  ValueNotifier<bool> isAccepting;
  ValueNotifier<bool> isHangingUp;

  late final CallDurationTracker _durationTracker;
  late final CallInviteTimeout _inviteTimeout;
  late final CallConnectivityListener _connectivityListener;

  ValueNotifier<Duration> get connectedDuration => _durationTracker.duration;

  Function(String offerId)? disposeCallback;

  late WebRTCHandler webRTCHandler;

  late DateTime callStartTime;
  final CallHistoryManager? callHistoryManager;
  final CallKeepManager? callKeepManager;

  static Future<CallingController> create({
    required UserDBISAR user,
    required CallingRole role,
    required CallType callType,
    String sessionId = '',
    String offerId = '',
    CallingState state = CallingState.ringing,
    AudioOutputType speakerType = AudioOutputType.speaker,
    bool isCameraOn = true,
    bool isRecordOn = true,
    bool isFrontCamera = false,
    Function(String offerId)? disposeCallback,
    CallHistoryManager? callHistoryManager,
    CallKeepManager? callKeepManager,
  }) async {
    final controller = CallingController._(
      user: user,
      role: role,
      callType: callType,
      sessionId: sessionId,
      state: state,
      speakerType: speakerType,
      isCameraOn: isCameraOn,
      isRecordOn: isRecordOn,
      isFrontCamera: isFrontCamera,
      disposeCallback: disposeCallback,
      callHistoryManager: callHistoryManager,
      callKeepManager: callKeepManager,
    );

    if (offerId.isNotEmpty) {
      controller.offerIdCmp.complete(offerId);
      controller.callIdCmp.complete(const Uuid().v5(Namespace.url.value, offerId));
    }

    controller.webRTCHandler = await WebRTCHandler.create(
      callType: callType,
      state: controller.state,
      speakerType: controller.speakerType,
      isCameraOn: controller.isCameraOn,
      isRecordOn: controller.isRecordOn,
      isFrontCamera: controller.isFrontCamera,
      onIceCandidateCallback: controller.onIceCandidateHandler,
      onIceConnectionStateCallback: controller.onIceConnectionStateHandler,
    );

    controller._durationTracker = CallDurationTracker();
    controller._inviteTimeout = CallInviteTimeout();
    controller._connectivityListener = CallConnectivityListener();

    controller.callStartTime = DateTime.now();

    controller._connectivityListener.start(
      () {
        LogUtils.info(
          className: 'CallingController',
          funcName: 'create',
          message: 'Network disconnected, hanging up call',
        );
        controller.hangup(CallEndReason.networkDisconnected);
      },
      onError: (error) {
        LogUtils.error(
          className: 'CallingController',
          funcName: 'create',
          message: 'Connectivity listener error: $error',
        );
      },
    );

    return controller;
  }

  void _dispose() async {
    _inviteTimeout.dispose();
    _durationTracker.dispose();
    _connectivityListener.dispose();
    webRTCHandler.dispose();
    disposeCallback?.call(await offerId);
  }

  Future<void> _recordCallHistory(String reason) async {
    if (!offerIdCmp.isCompleted) return;

    final callId = await offerId;
    final duration = _durationTracker.elapsed;

    CallDirection direction;
    CallStatus status;

    direction = role == CallingRole.caller
        ? CallDirection.outgoing
        : CallDirection.incoming;

    // Convert string reason to CallEndReason enum for consistent handling
    final callEndReason = CallEndReasonEx.fromValue(reason) ?? CallEndReason.disconnect;
    if (hasConnected.value) {
      status = CallStatus.completed;
    } else {
      switch (callEndReason) {
        case CallEndReason.reject:
          status = CallStatus.declined;
          break;
        case CallEndReason.iceConnectionFailed:
        case CallEndReason.iceDisconnected:
          status = CallStatus.failed;
          break;
        case CallEndReason.timeout:
        case CallEndReason.hangup:
        case CallEndReason.disconnect:
        case CallEndReason.networkDisconnected:
          status = CallStatus.cancelled;
          break;
      }
    }

    callHistoryManager?.addCallRecord(
      callId: callId,
      peerPubkey: peerId,
      direction: direction,
      type: callType,
      status: status,
      startTime: callStartTime,
      duration: duration.inSeconds > 0 ? duration : null,
    );

    LogUtils.info(
      className: 'CallingController',
      funcName: '_recordCallHistory',
      message: 'Call history recorded: $callId, $direction, $status, duration: ${duration.inSeconds}s',
    );
  }
}

extension CallingControllerUserActionEx on CallingController {

  void speakerToggleHandler(AudioOutputType value) async {
    if (speakerType.value == value) return;

    await webRTCHandler.setSpeakerType(value);

    speakerType.value = value;
  }

  void recordToggleHandler(bool value, [bool shouldInvokeCallKeep = true]) async {
    if (isRecordOn.value == value) return;

    final isSuccess = await webRTCHandler.recordToggle(value);
    if (isSuccess) {
      isRecordOn.value = value;
      if (shouldInvokeCallKeep) {
        callKeepManager?.setMutedCall(await callId, !value);
      }
    }
  }

  void cameraToggleHandler(bool value) async {
    if (isCameraOn.value == value) return;

    final isSuccess = await webRTCHandler.cameraToggle(value);
    if (isSuccess) {
      isCameraOn.value = value;
    }
  }

  void cameraSwitchHandler() {
    if (!callType.isVideo) return;

    webRTCHandler.switchCamera();
  }
}

extension CallingControllerSignalingEx on CallingController {
  Future<bool> invitePeer({Function? timeoutHandler}) async {
    _inviteTimeout.cancel();

    _inviteTimeout.start(const Duration(seconds: 60), () {
      if (!hasConnected.value && state.value != CallingState.ended) {
        timeoutHandler?.call();
        _recordCallHistory(CallEndReason.timeout.value);
      }
    });

    final generatedCallId = const Uuid().v4();
    offerIdCmp.complete(generatedCallId);
    callIdCmp.complete(generatedCallId);

    final sent = await _sendOffer(generatedCallId);
    if (!sent) {
      _inviteTimeout.cancel();
      LogUtils.error(
        className: 'CallingController',
        funcName: 'invitePeer',
        message: 'Error sending offer with callId: $generatedCallId',
      );
      return false;
    }
    return true;
  }

  Future hangup(CallEndReason reason, [bool shouldInvokeCallKeep = true]) async {
    if (state.value == CallingState.ended) return;
    if (isHangingUp.value) return;

    isHangingUp.value = true;

    // Determine the appropriate reason based on call state using Dart 3.0 switch
    final finalReason = switch (reason) {
      CallEndReason.hangup => !hasConnected.value
          ? CallEndReason.hangup
          : CallEndReason.disconnect,
      _ => reason,
    };

    _durationTracker.stop();
    await _recordCallHistory(finalReason.value);
    state.value = CallingState.ended;

    if (shouldInvokeCallKeep) {
      switch (reason)  {
        case CallEndReason.reject:
          callKeepManager?.rejectCall(await callId);
          break;
        default:
          callKeepManager?.endCall(await callId);
          break;
      }
    }
    _sendDisconnect(finalReason).catchError((error) {
      LogUtils.error(
        className: 'CallingController',
        funcName: 'hangup',
        message: 'Failed to send disconnect message: $error',
      );
    });

    await webRTCHandler.close();
    _dispose();
  }

  Future accept() async {
    if (state.value != CallingState.ringing) return;
    if (isAccepting.value) return;

    isAccepting.value = true;

    state.value = CallingState.connecting;
    _sendAnswer();
    callKeepManager?.answerCall(await callId);
  }

  Future reject() async {
    await hangup(CallEndReason.reject);
  }
}

extension CallingControllerNostrSignalingEx on CallingController {
  Future<bool> _sendOffer(String callId) async {
    try {
      final description = await webRTCHandler.createOffer();
      LogUtils.info(
          className: 'CallingController',
          funcName: '_sendOffer',
          message: '[send offer] sdp.length: ${description.sdp?.length}, type: ${description.type}'
      );

      OKEvent okEvent = await Contacts.sharedInstance.sendOffer(
        peerId,
        callId,
        callType.value,
        description.sdp ?? '',
      );

      LogUtils.info(
        className: 'CallingController',
        funcName: '_sendOffer',
        message: '[send offer] okEvent id:${okEvent.eventId}, status: ${okEvent.status}, message: ${okEvent.message}',
      );

      return okEvent.status;
    } catch (e, stack) {
      LogUtils.error(
        className: 'CallingController',
        funcName: '_sendOffer',
        message: '$e, $stack',
      );
      return false;
    }
  }

  Future<void> _sendAnswer() async {
    try {
      final description = await webRTCHandler.createAnswer();
      final offerId = await this.offerId;

      LogUtils.info(
        className: 'CallingController',
        funcName: '_sendAnswer',
        message: '[send answer] sessionId: $sessionId, offerId: $offerId, peerId: $peerId, sdp.length: ${description.sdp?.length}, type: ${description.type}',
      );

      final okEvent = await Contacts.sharedInstance.sendAnswer(
        offerId,
        peerId,
        description.sdp ?? '',
      );

      LogUtils.info(
          className: 'CallingController',
          funcName: '_sendAnswer',
          message: '[send answer] offerId: $offerId, okEvent status: ${okEvent.status}, message: ${okEvent.message}'
      );

      await _sendAllCandidate();
    } catch (e, stack) {
      LogUtils.error(
        className: 'CallingController',
        funcName: '_sendAnswer',
        message: '$e, $stack',
      );
    }
  }

  Future _sendAllCandidate() async {
    final candidates = {...localCandidateSet};
    await Future.wait([
      for (var candidate in candidates)
        _sendCandidate(candidate)
    ]);
  }

  Future _sendCandidate(RTCIceCandidate candidate) async {
    final meta = jsonEncode({
      'candidate': candidate.candidate,
      'sdpMid': candidate.sdpMid,
      'sdpMLineIndex': candidate.sdpMLineIndex,
    });

    final offerId = await this.offerId;

    LogUtils.info(
      className: 'CallingController',
      funcName: '_sendCandidate',
      message: '[send candidate] sessionId: $sessionId, offerId: $offerId, peerId: $peerId, candidate: ${candidate.candidate}, sdpMid: ${candidate.sdpMid}, sdpMLineIndex: ${candidate.sdpMLineIndex}',
    );

    final okEvent = await Contacts.sharedInstance.sendCandidate(
      offerId,
      peerId,
      meta,
    );

    LogUtils.info(
      className: 'CallingController',
      funcName: '_sendCandidate',
      message: '[send candidate] okEvent status: ${okEvent.status}, message: ${okEvent.message}',
    );
  }

  Future _sendDisconnect(CallEndReason reason) async {
    CallingControllerNostrSignalingEx.sendDisconnect(
      callId: await offerId,
      peerId: peerId,
      reason: reason,
      reject: reason == CallEndReason.reject,
    );
  }

  static Future sendDisconnect({
    required String callId,
    required String peerId,
    required CallEndReason reason,
    bool reject = false,
  }) async {
    LogUtils.info(
      className: 'CallingController',
      funcName: 'sendDisconnect',
      message: '[send disconnect] callId: $callId, peerId: $peerId, reason: ${reason.value}, reject: $reject',
    );

    final okEvent = reject
        ? await Contacts.sharedInstance.sendReject(callId, peerId, reason.value)
        : await Contacts.sharedInstance.sendHangup(callId, peerId, reason.value);

    LogUtils.info(
      className: 'CallingController',
      funcName: 'sendDisconnect',
      message: '[send disconnect] okEvent status: ${okEvent.status}, message: ${okEvent.message}',
    );
  }

  Future signalingCallbackHandler({
    required SignalingState nostrState,
    required String content,
  }) async {
    switch (nostrState) {
      case SignalingState.offer:
        signalingOfferCallbackHandler(
          remoteSdp: content,
          remoteType: 'offer',
        );
        break;
      case SignalingState.answer:
        signalingAnswerCallbackHandler(
          remoteSdp: content,
          remoteType: 'answer',
        );
        break;
      case SignalingState.candidate:
        Map<String, dynamic> candidateData;
        try {
          candidateData = Map<String, dynamic>.from(jsonDecode(content) as Map);
        } catch (e, stack) {
          _logSignalingError('candidate json decode failed', '$e, $stack');
          return;
        }

        signalingCandidateCallbackHandler(
          candidate: candidateData['candidate'] as String?,
          sdpMid: candidateData['sdpMid'] as String?,
          sdpMLineIndex: candidateData['sdpMLineIndex'] as int?,
        );
        break;
      case SignalingState.disconnect:
        signalingDisconnectCallbackHandler();
        break;
    }
  }

  /// Log signaling error with consistent format
  void _logSignalingError(String field, dynamic value) {
    LogUtils.error(
      className: 'CallingController',
      funcName: 'signalingCallbackHandler',
      message: 'Error $field: $value',
    );
  }

  void signalingOfferCallbackHandler({
    required String? remoteSdp,
    required String? remoteType,
  }) {
    LogUtils.info(
      className: 'CallingController',
      funcName: 'signalingOfferCallbackHandler',
      message: '[receive offer] remoteSdp.length: ${remoteSdp?.length}, remoteType: $remoteType',
    );
    webRTCHandler.setRemoteDescription(
      remoteSdp: remoteSdp,
      remoteType: remoteType,
    );
  }

  void signalingCandidateCallbackHandler({
    required String? candidate,
    required String? sdpMid,
    required int? sdpMLineIndex,
  }) {
    LogUtils.info(
      className: 'CallingController',
      funcName: 'signalingCandidateCallbackHandler',
      message: '[receive candidate] candidate: $candidate, sdpMid: $sdpMid, sdpMLineIndex: $sdpMLineIndex',
    );
    webRTCHandler.addCandidate(
      candidate: candidate,
      sdpMid: sdpMid,
      sdpMLineIndex: sdpMLineIndex,
    );
  }

  void signalingAnswerCallbackHandler({
    required String? remoteSdp,
    required String? remoteType,
  }) {
    LogUtils.info(
      className: 'CallingController',
      funcName: 'signalingAnswerCallbackHandler',
      message: '[receive answer] remoteSdp.length: ${remoteSdp?.length}, remoteType: $remoteType',
    );
    state.value = CallingState.connecting;
    webRTCHandler.setRemoteDescription(
      remoteSdp: remoteSdp,
      remoteType: remoteType,
    );

    _sendAllCandidate();
  }

  void signalingDisconnectCallbackHandler() async {
    LogUtils.info(
      className: 'CallingController',
      funcName: 'signalingDisconnectCallbackHandler',
      message: '[receive disconnect]',
    );
    if (state.value == CallingState.ended) return;

    _durationTracker.stop();
    await _recordCallHistory(CallEndReason.disconnect.value);
    state.value = CallingState.ended;

    callKeepManager?.endCall(await callId);
    await webRTCHandler.close();
    _dispose();
  }
}

extension CallingControllerWebRTCSignalingEx on CallingController {
  void onIceCandidateHandler(RTCIceCandidate candidate) async {
    localCandidateSet.add(candidate);
    LogUtils.info(
      className: 'CallingController',
      funcName: 'onIceCandidateHandler',
      message: 'candidate: ${candidate.candidate}',
    );
  }

  void onIceConnectionStateHandler(RTCIceConnectionState connectionState) async {
    LogUtils.info(
      className: 'CallingController',
      funcName: 'onIceConnectionStateHandler',
      message: '[ice state changed] state: $connectionState',
    );
    switch (connectionState) {
      case RTCIceConnectionState.RTCIceConnectionStateConnected:
        hasConnected.value = true;
        state.value = CallingState.connected;
        _durationTracker.start();
        webRTCHandler.setSpeakerType(speakerType.value);
        break;
      case RTCIceConnectionState.RTCIceConnectionStateFailed:
        hangup(CallEndReason.iceConnectionFailed);
        break;
      case RTCIceConnectionState.RTCIceConnectionStateDisconnected:
        hangup(CallEndReason.iceDisconnected);
        break;
      default:
        break;
    }
  }
}