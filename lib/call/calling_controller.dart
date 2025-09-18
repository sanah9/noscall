import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:flutter_webrtc/flutter_webrtc.dart' show RTCIceCandidate, RTCIceConnectionState;
import 'package:nostr/nostr.dart';

import '../core/core.dart';
import 'constant/call_type.dart';
import 'web_rtc_handler.dart';
import '../call_history/controller/call_history_manager.dart';
import '../call_history/constants/call_enums.dart';

///                          Start
/// ------------------------------------------------------------
///           Caller           ｜            Callee
///    1. Send Offer           ｜
///    2. Send Candidate info  ｜  Add Caller candidate info
///                            ｜      3. Send Answer
/// Add Callee candidate info  ｜      4. Send Candidate info
///             5. WebRTC Connection Checking
///             6. WebRTC Connection Connected
///             7. Some one send disconnected
/// ------------------------------------------------------------
///                           End

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
  }) :
        state = ValueNotifier(state),
        speakerType = ValueNotifier(speakerType),
        isCameraOn = ValueNotifier(isCameraOn),
        isRecordOn = ValueNotifier(isRecordOn),
        isFrontCamera = ValueNotifier(isFrontCamera),
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

  CallingRole role;
  ValueNotifier<CallingState> state;
  ValueNotifier<AudioOutputType> speakerType;
  ValueNotifier<bool> isCameraOn;
  ValueNotifier<bool> isRecordOn;
  ValueNotifier<bool> isFrontCamera;

  ValueNotifier<Duration> connectedDuration;
  final connectedStopwatch = Stopwatch();
  late Timer connectedTimer;

  Function(String offerId)? disposeCallback;

  late WebRTCHandler webRTCHandler;

  late DateTime callStartTime;
  final CallHistoryManager? callHistoryManager;

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
    );

    if (offerId.isNotEmpty) {
      controller.offerIdCmp.complete(offerId);
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

    return controller;
  }

  void _dispose() async {
    connectedTimer.cancel();
    webRTCHandler.dispose();
    disposeCallback?.call(await offerId);
  }

  Future<void> _recordCallHistory(String reason) async {
    final callId = await offerId;
    final duration = connectedStopwatch.isRunning
        ? connectedStopwatch.elapsed
        : connectedDuration.value;

    CallDirection direction;
    CallStatus status;

    direction = role == CallingRole.caller
        ? CallDirection.outgoing
        : CallDirection.incoming;

    switch (reason.toLowerCase()) {
      case 'reject':
        status = CallStatus.declined;
        break;
      case 'ice server connection failed':
      case 'ice server disconnected':
      case 'failed':
        status = CallStatus.failed;
        break;
      case 'timeout':
      case 'hangup':
      case 'disconnect':
        status = state.value == CallingState.connected
            ? CallStatus.completed
            : CallStatus.cancelled;
        break;
      default:
        status = CallStatus.cancelled;
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

  void recordToggleHandler(bool value) async {
    if (isRecordOn.value == value) return;

    final isSuccess = await webRTCHandler.recordToggle(value);
    if (isSuccess) {
      isRecordOn.value = value;
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
        _recordCallHistory('timeout');
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
    return true;
  }

  Future hangup(String reason) async {
    if (reason.toLowerCase() == 'hangup') {
      reason = [CallingState.ringing, CallingState.connecting].contains(state.value) ? 'hangUp': 'disconnect';
    }

    connectedStopwatch.stop();
    await _recordCallHistory(reason);
    state.value = CallingState.ended;

    await _sendDisconnect(reason);
    await webRTCHandler.close();
    _dispose();
  }

  Future accept() async {
    state.value = CallingState.connecting;
    _sendAnswer();
  }

  Future reject() async {
    await hangup('reject');
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
          message: '[send answer] okEvent status: ${okEvent.status}, message: ${okEvent.message}'
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
    connectedStopwatch.stop();
    await _recordCallHistory('disconnect');
    state.value = CallingState.ended;

    await webRTCHandler.close();
    _dispose();
  }
}

extension CallingControllerWebRTCSignalingEx on CallingController {
  void onIceCandidateHandler(RTCIceCandidate candidate) async {
    localCandidateSet.add(candidate);
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
        hangup('ICE Server Connection Failed');
        break;
      case RTCIceConnectionState.RTCIceConnectionStateDisconnected:
        hangup('ICE Server Disconnected');
        break;
      default:
        break;
    }
  }
}