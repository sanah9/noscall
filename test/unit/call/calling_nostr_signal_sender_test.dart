import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:noscall/call/calling_controller_dependencies.dart';
import 'package:noscall/call/calling_nostr_signal_sender.dart';
import 'package:noscall/call/constant/call_type.dart';

void main() {
  group('CallingNostrSignalSender', () {
    const sender = CallingNostrSignalSender();

    test('sendOffer creates offer and sends it through gateway', () async {
      final webRTC = _FakeWebRTCSession();
      final gateway = _FakeSignalingGateway();

      final sent = await sender.sendOffer(
        webRTCHandler: webRTC,
        signalingGateway: gateway,
        peerId: 'peer-1',
        callId: 'call-1',
        callType: CallType.audio,
      );

      expect(sent, isTrue);
      expect(webRTC.createOfferCalls, 1);
      expect(gateway.offers.single['callId'], 'call-1');
      expect(gateway.offers.single['sdp'], 'offer-sdp');
    });

    test('sendCandidate deduplicates successfully sent candidates', () async {
      final gateway = _FakeSignalingGateway();
      final sentCandidateKeys = <String>{};
      final candidate = RTCIceCandidate('candidate-1', 'audio', 0);

      await sender.sendCandidate(
        candidate: candidate,
        sentCandidateKeys: sentCandidateKeys,
        signalingGateway: gateway,
        sessionId: 'session-1',
        offerId: 'call-1',
        peerId: 'peer-1',
      );
      await sender.sendCandidate(
        candidate: candidate,
        sentCandidateKeys: sentCandidateKeys,
        signalingGateway: gateway,
        sessionId: 'session-1',
        offerId: 'call-1',
        peerId: 'peer-1',
      );

      expect(gateway.candidates, hasLength(1));
      expect(sentCandidateKeys, hasLength(1));
      final meta =
          jsonDecode(gateway.candidates.single['meta']!)
              as Map<String, dynamic>;
      expect(meta['candidate'], 'candidate-1');
      expect(meta['sdpMid'], 'audio');
      expect(meta['sdpMLineIndex'], 0);
    });
  });
}

class _FakeWebRTCSession implements CallingControllerWebRTCSession {
  int createOfferCalls = 0;
  int createAnswerCalls = 0;

  @override
  final RTCVideoRenderer localRenderer = RTCVideoRenderer();

  @override
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  @override
  Future<RTCSessionDescription> createOffer() async {
    createOfferCalls += 1;
    return RTCSessionDescription('offer-sdp', 'offer');
  }

  @override
  Future<RTCSessionDescription> createAnswer() async {
    createAnswerCalls += 1;
    return RTCSessionDescription('answer-sdp', 'answer');
  }

  @override
  Future<void> addCandidate({
    required String? candidate,
    required String? sdpMid,
    required int? sdpMLineIndex,
  }) async {}

  @override
  Future<bool> cameraToggle(bool isOpen) async => true;

  @override
  Future<void> close() async {}

  @override
  void dispose() {}

  @override
  Future<bool> recordToggle(bool isOpen) async => true;

  @override
  Future<void> setRemoteDescription({
    required String? remoteSdp,
    required String? remoteType,
  }) async {}

  @override
  Future<void> setSpeakerType(AudioOutputType value) async {}

  @override
  Future<bool> switchCamera() async => true;
}

class _FakeSignalingGateway implements CallingControllerSignalingGateway {
  final List<Map<String, String>> offers = [];
  final List<Map<String, String>> answers = [];
  final List<Map<String, String>> candidates = [];
  final List<Map<String, String>> rejects = [];
  final List<Map<String, String>> hangups = [];

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
  Future<OKEvent> sendReject(
    String callId,
    String peerId,
    String reason,
  ) async {
    rejects.add({'callId': callId, 'peerId': peerId, 'reason': reason});
    return OKEvent(callId, true, '');
  }
}
