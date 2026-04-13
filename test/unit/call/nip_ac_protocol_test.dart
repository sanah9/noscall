import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/core/call/nip_ac_protocol.dart';
import 'package:nostr_core_dart/nostr.dart';

void main() {
  const senderPrivkey =
      '0000000000000000000000000000000000000000000000000000000000000001';
  const senderPubkey =
      '79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798';
  const receiverPrivkey =
      '0000000000000000000000000000000000000000000000000000000000000002';
  const receiverPubkey =
      'c6047f9441ed7d6d3045406e95c07cd85c778e4b8cef3ca7abac09b95c709ee5';

  group('NipAcProtocol', () {
    test('builds offer tags and decode keeps call metadata', () async {
      final offer = await NipAcProtocol.createOffer(
        toPubkey: receiverPubkey,
        callId: 'call-001',
        callType: 'video',
        sdp: 'v=0\no=alice',
        pubkey: senderPubkey,
        privkey: senderPrivkey,
      );

      final decoded = NipAcProtocol.decodeInner(offer, receiverPubkey);
      expect(decoded.state, SignalingState.offer);
      expect(decoded.callId, 'call-001');
      expect(decoded.callType, 'video');
      expect(decoded.content, 'v=0\no=alice');
    });

    test('wrap/unwrap with 21059 keeps inner event', () async {
      final candidate = await NipAcProtocol.createCandidate(
        toPubkey: receiverPubkey,
        callId: 'call-002',
        candidateJson: jsonEncode({
          'candidate': 'candidate:1 1 udp 2122260223 192.0.2.1 54400 typ host',
          'sdpMid': '0',
          'sdpMLineIndex': 0,
        }),
        pubkey: senderPubkey,
        privkey: senderPrivkey,
      );

      final wrapped = await NipAcProtocol.wrap(candidate, receiverPubkey);
      expect(wrapped.kind, NipAcProtocol.wrapKind);

      final unwrapped = await NipAcProtocol.unwrap(wrapped, receiverPubkey, receiverPrivkey);
      expect(unwrapped.kind, NipAcKind.candidate.value);

      final decoded = NipAcProtocol.decodeInner(unwrapped, receiverPubkey);
      expect(decoded.callId, 'call-002');
      expect(decoded.state, SignalingState.candidate);
    });

    test('unwrap rejects tampered inner event signature', () async {
      final answer = await NipAcProtocol.createAnswer(
        toPubkey: receiverPubkey,
        callId: 'call-005',
        sdp: 'v=0\no=bob',
        pubkey: senderPubkey,
        privkey: senderPrivkey,
      );

      final tamperedMap = Map<String, dynamic>.from(answer.toJson())
        ..['content'] = 'v=0\no=mallory';
      final tamperedInner = await Event.fromJson(tamperedMap, verify: false);
      final wrapped = await NipAcProtocol.wrap(tamperedInner, receiverPubkey);

      expect(
        () => NipAcProtocol.unwrap(wrapped, receiverPubkey, receiverPrivkey),
        throwsA(anything),
      );
    });

    test('reject/hangup map to disconnect signaling state', () async {
      final reject = await NipAcProtocol.createReject(
        toPubkey: receiverPubkey,
        callId: 'call-003',
        reason: 'busy',
        pubkey: senderPubkey,
        privkey: senderPrivkey,
      );
      final hangup = await NipAcProtocol.createHangup(
        toPubkey: receiverPubkey,
        callId: 'call-004',
        reason: 'hangUp',
        pubkey: senderPubkey,
        privkey: senderPrivkey,
      );

      expect(NipAcProtocol.decodeInner(reject, receiverPubkey).state, SignalingState.disconnect);
      expect(NipAcProtocol.decodeInner(hangup, receiverPubkey).state, SignalingState.disconnect);
    });
  });
}
