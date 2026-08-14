import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:nostr_core_dart/nostr.dart';

import 'package:noscall/call/call_connectivity_listener.dart';
import 'package:noscall/call/constant/call_type.dart';
import 'package:noscall/call/web_rtc_handler.dart';
import 'package:noscall/call_history/constants/call_enums.dart';
import 'package:noscall/core/core.dart';

abstract class CallingControllerWebRTCSession {
  RTCVideoRenderer get localRenderer;
  RTCVideoRenderer get remoteRenderer;
  Future<RTCSessionDescription> createOffer();
  Future<RTCSessionDescription> createAnswer();
  Future<void> setRemoteDescription({
    required String? remoteSdp,
    required String? remoteType,
  });
  Future<void> addCandidate({
    required String? candidate,
    required String? sdpMid,
    required int? sdpMLineIndex,
  });
  Future<bool> recordToggle(bool isOpen);
  Future<bool> cameraToggle(bool isOpen);
  Future<bool> switchCamera();
  Future<void> setSpeakerType(AudioOutputType value);
  Future<void> close();
  void dispose();
}

abstract class CallingControllerWebRTCFactory {
  Future<CallingControllerWebRTCSession> create({
    required CallType callType,
    ValueNotifier<CallingState>? state,
    ValueNotifier<AudioOutputType>? speakerType,
    ValueNotifier<bool>? isCameraOn,
    ValueNotifier<bool>? isRecordOn,
    ValueNotifier<bool>? isFrontCamera,
    Function(RTCIceCandidate candidate)? onIceCandidateCallback,
    Function(RTCIceConnectionState state)? onIceConnectionStateCallback,
  });
}

class DefaultCallingControllerWebRTCFactory
    implements CallingControllerWebRTCFactory {
  @override
  Future<CallingControllerWebRTCSession> create({
    required CallType callType,
    ValueNotifier<CallingState>? state,
    ValueNotifier<AudioOutputType>? speakerType,
    ValueNotifier<bool>? isCameraOn,
    ValueNotifier<bool>? isRecordOn,
    ValueNotifier<bool>? isFrontCamera,
    Function(RTCIceCandidate candidate)? onIceCandidateCallback,
    Function(RTCIceConnectionState state)? onIceConnectionStateCallback,
  }) {
    return WebRTCHandler.create(
      callType: callType,
      state: state,
      speakerType: speakerType,
      isCameraOn: isCameraOn,
      isRecordOn: isRecordOn,
      isFrontCamera: isFrontCamera,
      onIceCandidateCallback: onIceCandidateCallback,
      onIceConnectionStateCallback: onIceConnectionStateCallback,
    );
  }
}

abstract class CallingControllerSignalingGateway {
  Future<OKEvent> sendOffer(
    String peerId,
    String callId,
    String callType,
    String sdp,
  );

  Future<OKEvent> sendAnswer(String offerId, String peerId, String sdp);

  Future<OKEvent> sendCandidate(String offerId, String peerId, String meta);

  Future<OKEvent> sendReject(String callId, String peerId, String reason);

  Future<OKEvent> sendHangup(String callId, String peerId, String reason);
}

class DefaultCallingControllerSignalingGateway
    implements CallingControllerSignalingGateway {
  @override
  Future<OKEvent> sendAnswer(String offerId, String peerId, String sdp) {
    return Contacts.sharedInstance.sendAnswer(offerId, peerId, sdp);
  }

  @override
  Future<OKEvent> sendCandidate(String offerId, String peerId, String meta) {
    return Contacts.sharedInstance.sendCandidate(offerId, peerId, meta);
  }

  @override
  Future<OKEvent> sendHangup(String callId, String peerId, String reason) {
    return Contacts.sharedInstance.sendHangup(callId, peerId, reason);
  }

  @override
  Future<OKEvent> sendOffer(
    String peerId,
    String callId,
    String callType,
    String sdp,
  ) {
    return Contacts.sharedInstance.sendOffer(peerId, callId, callType, sdp);
  }

  @override
  Future<OKEvent> sendReject(String callId, String peerId, String reason) {
    return Contacts.sharedInstance.sendReject(callId, peerId, reason);
  }
}

abstract class CallingControllerConnectivityWatcher {
  void start(
    void Function() onNetworkDisconnected, {
    void Function(dynamic)? onError,
  });

  void dispose();
}

typedef CallingControllerConnectivityWatcherFactory =
    CallingControllerConnectivityWatcher Function();

abstract class CallKeepActions {
  Future<void> endCall(String callId);
  Future<void> answerCall(String callId);
  Future<void> rejectCall(String callId);
  Future<void> setMutedCall(String callId, bool shouldMute);
}

abstract class CallHistoryRecorder {
  Future<bool> addCallRecord({
    required String callId,
    required String peerPubkey,
    required CallDirection direction,
    required CallType type,
    required CallStatus status,
    required DateTime startTime,
    Duration? duration,
  });
}

abstract class CallingControllerLifecycleObserver {
  FutureOr<void> onConnected({
    required String callId,
    required String peerPubkey,
    required CallingRole role,
  });

  FutureOr<void> onEnded({
    required String callId,
    required String peerPubkey,
    required CallingRole role,
    required CallEndReason reason,
    required bool hasConnected,
  });
}

class CallingControllerDependencies {
  CallingControllerDependencies({
    CallingControllerWebRTCFactory? webRTCFactory,
    CallingControllerSignalingGateway? signalingGateway,
    CallingControllerConnectivityWatcherFactory? connectivityWatcherFactory,
  }) : webRTCFactory = webRTCFactory ?? DefaultCallingControllerWebRTCFactory(),
       signalingGateway =
           signalingGateway ?? DefaultCallingControllerSignalingGateway(),
       connectivityWatcherFactory =
           connectivityWatcherFactory ?? CallConnectivityListener.new;

  final CallingControllerWebRTCFactory webRTCFactory;
  final CallingControllerSignalingGateway signalingGateway;
  final CallingControllerConnectivityWatcherFactory connectivityWatcherFactory;
}
