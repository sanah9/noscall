import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:noscall/call/calling_controller.dart';
import 'package:noscall/call/calling_controller_dependencies.dart';
import 'package:noscall/call/constant/call_type.dart';
import 'package:noscall/call_history/constants/call_enums.dart';

import '../../helpers/test_data.dart';
import '../../helpers/test_helpers.dart';

class FakeCallingControllerWebRTCSession
    implements CallingControllerWebRTCSession {
  @override
  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  @override
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
  int createOfferCalls = 0;
  int createAnswerCalls = 0;
  int closeCalls = 0;
  int disposeCalls = 0;
  int recordToggleCalls = 0;
  int cameraToggleCalls = 0;
  int switchCameraCalls = 0;
  final List<AudioOutputType> speakerTypes = [];
  final List<Map<String, dynamic>> remoteDescriptions = [];
  final List<Map<String, dynamic>> addedCandidates = [];

  @override
  Future<bool> cameraToggle(bool isOpen) async {
    cameraToggleCalls += 1;
    return true;
  }

  @override
  Future<void> close() async {
    closeCalls += 1;
  }

  @override
  Future<RTCSessionDescription> createAnswer() async {
    createAnswerCalls += 1;
    return RTCSessionDescription('answer-sdp', 'answer');
  }

  @override
  Future<RTCSessionDescription> createOffer() async {
    createOfferCalls += 1;
    return RTCSessionDescription('offer-sdp', 'offer');
  }

  @override
  void dispose() {
    disposeCalls += 1;
  }

  @override
  Future<bool> recordToggle(bool isOpen) async {
    recordToggleCalls += 1;
    return true;
  }

  @override
  Future<void> setRemoteDescription({
    required String? remoteSdp,
    required String? remoteType,
  }) async {
    remoteDescriptions.add({'sdp': remoteSdp, 'type': remoteType});
  }

  @override
  Future<void> addCandidate({
    required String? candidate,
    required String? sdpMid,
    required int? sdpMLineIndex,
  }) async {
    addedCandidates.add({
      'candidate': candidate,
      'sdpMid': sdpMid,
      'sdpMLineIndex': sdpMLineIndex,
    });
  }

  @override
  Future<void> setSpeakerType(AudioOutputType value) async {
    speakerTypes.add(value);
  }

  @override
  Future<bool> switchCamera() async {
    switchCameraCalls += 1;
    return true;
  }
}

class FakeCallingControllerWebRTCFactory
    implements CallingControllerWebRTCFactory {
  FakeCallingControllerWebRTCFactory(this.session);

  final FakeCallingControllerWebRTCSession session;

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
  }) async {
    return session;
  }
}

class FakeCallingControllerSignalingGateway
    implements CallingControllerSignalingGateway {
  final List<Map<String, String>> offers = [];
  final List<Map<String, String>> answers = [];
  final List<Map<String, String>> candidates = [];
  final List<Map<String, String>> rejects = [];
  final List<Map<String, String>> hangups = [];

  @override
  Future<OKEvent> sendAnswer(String offerId, String peerId, String sdp) async {
    answers.add({'offerId': offerId, 'peerId': peerId, 'sdp': sdp});
    return OKEvent(offerId, true, '');
  }

  @override
  Future<OKEvent> sendCandidate(
    String offerId,
    String peerId,
    String meta,
  ) async {
    candidates.add({'offerId': offerId, 'peerId': peerId, 'meta': meta});
    return OKEvent(offerId, true, '');
  }

  @override
  Future<OKEvent> sendHangup(
    String callId,
    String peerId,
    String reason,
  ) async {
    hangups.add({'callId': callId, 'peerId': peerId, 'reason': reason});
    return OKEvent(callId, true, '');
  }

  @override
  Future<OKEvent> sendOffer(
    String peerId,
    String callId,
    String callType,
    String sdp,
  ) async {
    offers.add({
      'peerId': peerId,
      'callId': callId,
      'callType': callType,
      'sdp': sdp,
    });
    return OKEvent(callId, true, '');
  }

  @override
  Future<OKEvent> sendReject(
    String callId,
    String peerId,
    String reason,
  ) async {
    rejects.add({'callId': callId, 'peerId': peerId, 'reason': reason});
    return OKEvent(callId, true, '');
  }
}

class FakeCallingControllerConnectivityWatcher
    implements CallingControllerConnectivityWatcher {
  void Function()? onNetworkDisconnected;
  void Function(dynamic)? onError;
  int disposeCalls = 0;

  @override
  void dispose() {
    disposeCalls += 1;
  }

  @override
  void start(
    void Function() onNetworkDisconnected, {
    void Function(dynamic)? onError,
  }) {
    this.onNetworkDisconnected = onNetworkDisconnected;
    this.onError = onError;
  }

  void triggerDisconnected() {
    onNetworkDisconnected?.call();
  }
}

class FakeCallKeepActions implements CallKeepActions {
  final List<String> answeredCallIds = [];
  final List<String> endedCallIds = [];
  final List<String> rejectedCallIds = [];
  final List<Map<String, dynamic>> mutedCalls = [];

  @override
  Future<void> answerCall(String callId) async {
    answeredCallIds.add(callId);
  }

  @override
  Future<void> endCall(String callId) async {
    endedCallIds.add(callId);
  }

  @override
  Future<void> rejectCall(String callId) async {
    rejectedCallIds.add(callId);
  }

  @override
  Future<void> setMutedCall(String callId, bool shouldMute) async {
    mutedCalls.add({'callId': callId, 'shouldMute': shouldMute});
  }
}

class FakeCallHistoryRecorder implements CallHistoryRecorder {
  final List<Map<String, dynamic>> records = [];

  @override
  Future<bool> addCallRecord({
    required String callId,
    required String peerPubkey,
    required CallDirection direction,
    required CallType type,
    required CallStatus status,
    required DateTime startTime,
    Duration? duration,
  }) async {
    records.add({
      'callId': callId,
      'peerPubkey': peerPubkey,
      'direction': direction,
      'type': type,
      'status': status,
      'startTime': startTime,
      'duration': duration,
    });
    return true;
  }
}

class FakeLifecycleObserver implements CallingControllerLifecycleObserver {
  final List<Map<String, dynamic>> connected = [];
  final List<Map<String, dynamic>> ended = [];

  @override
  Future<void> onConnected({
    required String callId,
    required String peerPubkey,
    required CallingRole role,
  }) async {
    connected.add({'callId': callId, 'peerPubkey': peerPubkey, 'role': role});
  }

  @override
  Future<void> onEnded({
    required String callId,
    required String peerPubkey,
    required CallingRole role,
    required CallEndReason reason,
    required bool hasConnected,
  }) async {
    ended.add({
      'callId': callId,
      'peerPubkey': peerPubkey,
      'role': role,
      'reason': reason,
      'hasConnected': hasConnected,
    });
  }
}

Future<void> flushControllerTasks() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  group('CallingController', () {
    late FakeCallingControllerWebRTCSession webRTCSession;
    late FakeCallingControllerSignalingGateway signalingGateway;
    late FakeCallingControllerConnectivityWatcher connectivityWatcher;
    late FakeCallKeepActions callKeepActions;
    late FakeCallHistoryRecorder callHistoryRecorder;
    late FakeLifecycleObserver lifecycleObserver;
    late CallingControllerDependencies dependencies;

    setUp(() {
      webRTCSession = FakeCallingControllerWebRTCSession();
      signalingGateway = FakeCallingControllerSignalingGateway();
      connectivityWatcher = FakeCallingControllerConnectivityWatcher();
      callKeepActions = FakeCallKeepActions();
      callHistoryRecorder = FakeCallHistoryRecorder();
      lifecycleObserver = FakeLifecycleObserver();
      dependencies = CallingControllerDependencies(
        webRTCFactory: FakeCallingControllerWebRTCFactory(webRTCSession),
        signalingGateway: signalingGateway,
        connectivityWatcherFactory: () => connectivityWatcher,
      );
    });

    Future<CallingController> createController({
      required CallingRole role,
      String offerId = 'call-123',
      CallingState state = CallingState.ringing,
      AudioOutputType speakerType = AudioOutputType.speaker,
    }) {
      return CallingController.create(
        user: TestHelpers.createTestUser(pubKey: TestData.validPubkey),
        role: role,
        callType: CallType.audio,
        offerId: offerId,
        state: state,
        speakerType: speakerType,
        callKeepManager: callKeepActions,
        callHistoryManager: callHistoryRecorder,
        lifecycleObserver: lifecycleObserver,
        dependencies: dependencies,
      );
    }

    test('invitePeer sends offer and completes call identifiers', () async {
      final controller = await CallingController.create(
        user: TestHelpers.createTestUser(pubKey: TestData.validPubkey),
        role: CallingRole.caller,
        callType: CallType.audio,
        callKeepManager: callKeepActions,
        callHistoryManager: callHistoryRecorder,
        lifecycleObserver: lifecycleObserver,
        dependencies: dependencies,
      );

      final invited = await controller.invitePeer();
      final generatedOfferId = await controller.offerId;
      final generatedCallId = await controller.callId;

      expect(invited, isTrue);
      expect(generatedOfferId, isNotEmpty);
      expect(generatedCallId, generatedOfferId);
      expect(webRTCSession.createOfferCalls, 1);
      expect(signalingGateway.offers, hasLength(1));
      expect(signalingGateway.offers.single['callId'], generatedOfferId);
    });

    test(
      'invitePeer uses provided call id for paid call preparation',
      () async {
        final controller = await CallingController.create(
          user: TestHelpers.createTestUser(pubKey: TestData.validPubkey),
          role: CallingRole.caller,
          callType: CallType.audio,
          callKeepManager: callKeepActions,
          callHistoryManager: callHistoryRecorder,
          lifecycleObserver: lifecycleObserver,
          dependencies: dependencies,
        );

        final invited = await controller.invitePeer(callId: 'paid-call-1');

        expect(invited, isTrue);
        expect(await controller.offerId, 'paid-call-1');
        expect(await controller.callId, 'paid-call-1');
        expect(signalingGateway.offers.single['callId'], 'paid-call-1');
      },
    );

    test('accept transitions to connecting and sends answer', () async {
      final controller = await createController(role: CallingRole.callee);

      await controller.accept();
      await flushControllerTasks();

      expect(controller.state.value, CallingState.connecting);
      expect(controller.isAccepting.value, isTrue);
      expect(webRTCSession.createAnswerCalls, 1);
      expect(signalingGateway.answers, hasLength(1));
      expect(signalingGateway.answers.single['offerId'], 'call-123');
      expect(callKeepActions.answeredCallIds, ['call-123']);
    });

    test('reject records declined status and sends reject signal', () async {
      final controller = await createController(role: CallingRole.callee);

      await controller.reject();
      await flushControllerTasks();

      expect(controller.state.value, CallingState.ended);
      expect(signalingGateway.rejects, hasLength(1));
      expect(
        signalingGateway.rejects.single['reason'],
        CallEndReason.reject.value,
      );
      expect(callKeepActions.rejectedCallIds, ['call-123']);
      expect(callHistoryRecorder.records, hasLength(1));
      expect(callHistoryRecorder.records.single['status'], CallStatus.declined);
      expect(
        callHistoryRecorder.records.single['direction'],
        CallDirection.incoming,
      );
      expect(webRTCSession.closeCalls, 1);
      expect(webRTCSession.disposeCalls, 1);
      expect(connectivityWatcher.disposeCalls, 1);
    });

    test(
      'connected hangup sends disconnect and records completed call',
      () async {
        final controller = await createController(
          role: CallingRole.caller,
          state: CallingState.connected,
        );

        controller.hasConnected.value = true;
        await controller.hangup(CallEndReason.hangup);
        await flushControllerTasks();

        expect(controller.state.value, CallingState.ended);
        expect(signalingGateway.hangups, hasLength(1));
        expect(
          signalingGateway.hangups.single['reason'],
          CallEndReason.disconnect.value,
        );
        expect(callKeepActions.endedCallIds, ['call-123']);
        expect(
          callHistoryRecorder.records.single['status'],
          CallStatus.completed,
        );
        expect(
          callHistoryRecorder.records.single['direction'],
          CallDirection.outgoing,
        );
      },
    );

    test(
      'signaling disconnect ends call without sending outbound signal',
      () async {
        final controller = await createController(role: CallingRole.callee);

        controller.signalingDisconnectCallbackHandler();
        await flushControllerTasks();

        expect(controller.state.value, CallingState.ended);
        expect(signalingGateway.hangups, isEmpty);
        expect(signalingGateway.rejects, isEmpty);
        expect(callKeepActions.endedCallIds, ['call-123']);
        expect(
          callHistoryRecorder.records.single['status'],
          CallStatus.cancelled,
        );
        expect(webRTCSession.closeCalls, 1);
        expect(webRTCSession.disposeCalls, 1);
      },
    );

    test('payment required disconnect notifies lifecycle reason', () async {
      final controller = await createController(role: CallingRole.caller);

      controller.signalingDisconnectCallbackHandler(
        CallEndReason.paymentRequired.value,
      );
      await flushControllerTasks();

      expect(controller.state.value, CallingState.ended);
      expect(
        lifecycleObserver.ended.single['reason'],
        CallEndReason.paymentRequired,
      );
      expect(
        callHistoryRecorder.records.single['status'],
        CallStatus.cancelled,
      );
    });

    test('network disconnect watcher hangs up active call', () async {
      final controller = await createController(role: CallingRole.caller);

      connectivityWatcher.triggerDisconnected();
      await flushControllerTasks();

      expect(controller.state.value, CallingState.ended);
      expect(signalingGateway.hangups, hasLength(1));
      expect(
        signalingGateway.hangups.single['reason'],
        CallEndReason.networkDisconnected.value,
      );
      expect(
        callHistoryRecorder.records.single['status'],
        CallStatus.cancelled,
      );
    });

    test('ice connected updates controller state and speaker route', () async {
      final controller = await createController(
        role: CallingRole.caller,
        speakerType: AudioOutputType.bluetooth,
      );

      controller.onIceConnectionStateHandler(
        RTCIceConnectionState.RTCIceConnectionStateConnected,
      );
      await flushControllerTasks();

      expect(controller.hasConnected.value, isTrue);
      expect(controller.state.value, CallingState.connected);
      expect(webRTCSession.speakerTypes, [AudioOutputType.bluetooth]);
      expect(lifecycleObserver.connected.single['callId'], 'call-123');
      expect(lifecycleObserver.connected.single['role'], CallingRole.caller);
    });

    test('lifecycle observer is notified when call ends', () async {
      final controller = await createController(
        role: CallingRole.caller,
        state: CallingState.connected,
      );

      controller.hasConnected.value = true;
      await controller.hangup(CallEndReason.hangup);
      await flushControllerTasks();

      expect(lifecycleObserver.ended.single['callId'], 'call-123');
      expect(
        lifecycleObserver.ended.single['reason'],
        CallEndReason.disconnect,
      );
      expect(lifecycleObserver.ended.single['hasConnected'], isTrue);
    });
  });
}
