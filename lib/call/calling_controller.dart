import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:flutter_webrtc/flutter_webrtc.dart' show RTCIceCandidate, RTCIceConnectionState;
import 'package:nostr/nostr.dart';
import 'package:uuid/uuid.dart';

import '../core/core.dart';
import 'callkeep_manager.dart';
import 'constant/call_type.dart';
import 'web_rtc_handler.dart';
import '../call_history/controller/call_history_manager.dart';
import '../call_history/constants/call_enums.dart';

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
        speakerType = ValueNotifier(speakerType),
        isCameraOn = ValueNotifier(isCameraOn),
        isRecordOn = ValueNotifier(isRecordOn),
        isFrontCamera = ValueNotifier(isFrontCamera),
        isAccepting = ValueNotifier(false),
        isHangingUp = ValueNotifier(false),
        connectedDuration = ValueNotifier(Duration.zero),
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
  ValueNotifier<AudioOutputType> speakerType;
  ValueNotifier<bool> isCameraOn;
  ValueNotifier<bool> isRecordOn;
  ValueNotifier<bool> isFrontCamera;
  ValueNotifier<bool> isAccepting;
  ValueNotifier<bool> isHangingUp;

  ValueNotifier<Duration> connectedDuration;
  final connectedStopwatch = Stopwatch();
  late Timer connectedTimer;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

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

    controller.connectedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      controller.connectedDuration.value = controller.connectedStopwatch.elapsed;
    });

    controller.callStartTime = DateTime.now();

    controller._startConnectivityListener();

    return controller;
  }

  void _dispose() async {
    connectedTimer.cancel();
    _connectivitySubscription?.cancel();
    webRTCHandler.dispose();
    disposeCallback?.call(await offerId);
  }

  Future<void> _recordCallHistory(String reason) async {
    if (!offerIdCmp.isCompleted) return;

    final callId = await offerId;
    final duration = connectedStopwatch.isRunning
        ? connectedStopwatch.elapsed
        : connectedDuration.value;

    CallDirection direction;
    CallStatus status;

    direction = role == CallingRole.caller
        ? CallDirection.outgoing
        : CallDirection.incoming;

    // Convert string reason to CallEndReason enum for consistent handling
    final callEndReason = CallEndReasonEx.fromValue(reason) ?? CallEndReason.disconnect;

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
        status = state.value == CallingState.connected
            ? CallStatus.completed
            : CallStatus.cancelled;
        break;
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
    Future.delayed(const Duration(seconds: 60), () {
      if (state.value != CallingState.connected && state.value != CallingState.ended) {
        timeoutHandler?.call();
        _recordCallHistory(CallEndReason.timeout.value);
      }
    });

    var offerId = await _sendOffer();
    if (offerId == null || offerId.isEmpty) {
      LogUtils.error(
        className: 'CallingController',
        funcName: 'invitePeer',
        message: 'Error offerId: $offerId',
      );
      return false;
    }

    offerIdCmp.complete(offerId);
    callIdCmp.complete(const Uuid().v5(Namespace.url.value, offerId));
    return true;
  }

  Future hangup(CallEndReason reason, [bool shouldInvokeCallKeep = true]) async {
    if (state.value == CallingState.ended) return;
    if (isHangingUp.value) return;

    isHangingUp.value = true;

    // Determine the appropriate reason based on call state using Dart 3.0 switch
    final finalReason = switch (reason) {
      CallEndReason.hangup => [CallingState.ringing, CallingState.connecting].contains(state.value)
          ? CallEndReason.hangup
          : CallEndReason.disconnect,
      _ => reason,
    };

    connectedStopwatch.stop();
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
    _sendDisconnect(finalReason.value).catchError((error) {
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
  Future<String?> _sendOffer() async {
    try {
      final description = await webRTCHandler.createOffer();
      Map map = {
        'description': {
          'sdp': description.sdp,
          'type': description.type,
        },
        'session_id': sessionId,
        'media': callType.value,
      };
      String jsonOfOfferContent = jsonEncode(map);

      LogUtils.info(
          className: 'CallingController',
          funcName: '_sendOffer',
          message: '[send offer] sdp.length: ${description.sdp?.length}, type: ${description.type}'
      );

      OKEvent okEvent = await Contacts.sharedInstance.sendOffer(peerId, jsonOfOfferContent);

      LogUtils.info(
        className: 'CallingController',
        funcName: '_sendOffer',
        message: '[send offer] okEvent id:${okEvent.eventId}, status: ${okEvent.status}, message: ${okEvent.message}',
      );

      return okEvent.eventId;
    } catch (e, stack) {
      LogUtils.error(
        className: 'CallingController',
        funcName: '_sendOffer',
        message: '$e, $stack',
      );
      return null;
    }
  }

  Future<void> _sendAnswer() async {
    try {
      final description = await webRTCHandler.createAnswer();
      Map map = {
        'description': {
          'sdp': description.sdp,
          'type': description.type,
        },
        'session_id': sessionId,
      };

      final offerId = await this.offerId;

      LogUtils.info(
        className: 'CallingController',
        funcName: '_sendAnswer',
        message: '[send answer] sessionId: $sessionId, offerId: $offerId, peerId: $peerId, sdp.length: ${description.sdp?.length}, type: ${description.type}',
      );

      final okEvent = await Contacts.sharedInstance.sendAnswer(offerId, peerId, jsonEncode(map));

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
      'candidate': {
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      },
      'session_id': sessionId
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

  Future _sendDisconnect(String reason) async {
    CallingControllerNostrSignalingEx.sendDisconnect(
      sessionId: sessionId,
      offerId: await offerId,
      peerId: peerId,
      reason: reason,
    );
  }

  static Future sendDisconnect({
    required String sessionId,
    required String offerId,
    required String peerId,
    required String reason,
  }) async {
    Map map = {
      'session_id': sessionId,
      'reason': reason,
    };

    LogUtils.info(
      className: 'CallingController',
      funcName: 'sendDisconnect',
      message: '[send disconnect] sessionId: $sessionId, offerId: $offerId, peerId: $peerId, reason: $reason',
    );

    final okEvent = await Contacts.sharedInstance.sendDisconnect(offerId, peerId, jsonEncode(map));

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
    Map meta = {};
    try {
      meta = jsonDecode(content);
    } catch (e, stack) {
      LogUtils.error(
        className: 'CallingController',
        funcName: 'signalingCallbackHandler',
        message: '$e, $stack',
      );
    }

    if (meta.isEmpty) return;

    switch (nostrState) {
      case SignalingState.offer:
        final sessionId = meta['session_id'];
        if (sessionId is! String || sessionId.isEmpty) {
          LogUtils.error(
            className: 'CallingController',
            funcName: 'signalingCallbackHandler',
            message: 'Error sessionId: $sessionId',
          );
          return;
        }

        final description = meta['description'];
        if (description is! Map) {
          LogUtils.error(
            className: 'CallingController',
            funcName: 'signalingCallbackHandler',
            message: 'Error description: $description',
          );
          return;
        }
        final remoteSdp = description['sdp'];
        final remoteType = description['type'];
        if (remoteSdp is! String? || remoteType is! String?) {
          LogUtils.error(
            className: 'CallingController',
            funcName: 'signalingCallbackHandler',
            message: 'Error remoteSdp: $sessionId, remoteType: $remoteType',
          );
          return;
        }

        signalingOfferCallbackHandler(
          sessionId: sessionId,
          remoteSdp: remoteSdp,
          remoteType: remoteType,
        );
        break;
      case SignalingState.answer:
        final description = meta['description'];
        if (description is! Map) {
          LogUtils.error(
            className: 'CallingController',
            funcName: 'signalingCallbackHandler',
            message: 'Error description: $description',
          );
          return;
        }

        final remoteSdp = description['sdp'];
        final remoteType = description['type'];
        if (remoteSdp is! String? || remoteType is! String?) {
          LogUtils.error(
            className: 'CallingController',
            funcName: 'signalingCallbackHandler',
            message: 'Error remoteSdp: $remoteSdp, remoteType: $remoteType',
          );
          return;
        }

        signalingAnswerCallbackHandler(
          remoteSdp: remoteSdp,
          remoteType: remoteType,
        );
        break;
      case SignalingState.candidate:
        final data = meta['candidate'];
        if (data is! Map) {
          LogUtils.error(
            className: 'CallingController',
            funcName: 'signalingCallbackHandler',
            message: 'Error data: $data',
          );
          return;
        }

        final candidate = data['candidate'];
        final sdpMid = data['sdpMid'];
        final sdpMLineIndex = data['sdpMLineIndex'];
        if (candidate is! String? || sdpMid is! String? || sdpMLineIndex is! int?) {
          LogUtils.error(
            className: 'CallingController',
            funcName: 'signalingCallbackHandler',
            message: 'Error candidate: $candidate, sdpMid: $sdpMid, sdpMLineIndex: $sdpMLineIndex',
          );
          return;
        }

        signalingCandidateCallbackHandler(
          candidate: candidate,
          sdpMid: sdpMid,
          sdpMLineIndex: sdpMLineIndex,
        );
        break;
      case SignalingState.disconnect:
        signalingDisconnectCallbackHandler();
        break;
    }
  }

  void signalingOfferCallbackHandler({
    required String sessionId,
    required String? remoteSdp,
    required String? remoteType,
  }) {
    LogUtils.info(
      className: 'CallingController',
      funcName: 'signalingOfferCallbackHandler',
      message: '[receive offer] sessionId: $sessionId, remoteSdp.length: ${remoteSdp?.length}, remoteType: $remoteType',
    );
    this.sessionId = sessionId;
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
      funcName: 'signalingAnswerCallbackHandler',
      message: '[receive disconnect]',
    );
    if (state.value == CallingState.ended) return;

    connectedStopwatch.stop();
    await _recordCallHistory(CallEndReason.disconnect.value);
    state.value = CallingState.ended;

    callKeepManager?.endCall(await callId);
    await webRTCHandler.close();
    _dispose();
  }

  void _startConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
          (List<ConnectivityResult> results) {
        if (results.every((result) => result == ConnectivityResult.none)) {
          LogUtils.info(
            className: 'CallingController',
            funcName: '_startConnectivityListener',
            message: 'Network disconnected, hanging up call',
          );
          hangup(CallEndReason.networkDisconnected);
        }
      },
      onError: (error) {
        LogUtils.error(
          className: 'CallingController',
          funcName: '_startConnectivityListener',
          message: 'Connectivity listener error: $error',
        );
      },
    );
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
        state.value = CallingState.connected;
        connectedStopwatch.start();
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