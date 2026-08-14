import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/core/call/call_event_policy.dart';
import 'package:nostr_core_dart/nostr.dart';

void main() {
  group('CallEventPolicy', () {
    final baseEvent = Event.partial(
      id: 'id',
      pubkey: 'sender',
      kind: 25050,
      tags: const <List<String>>[],
      content: 'sdp',
      sig: '',
      verify: false,
    )..createdAt = 1000;

    test('isStale returns true when over threshold', () {
      final result = CallEventPolicy.isStale(
        baseEvent,
        nowSeconds: 1061,
        staleAfterSeconds: 60,
      );
      expect(result, isTrue);
    });

    test('isStale returns false within threshold', () {
      final result = CallEventPolicy.isStale(
        baseEvent,
        nowSeconds: 1060,
        staleAfterSeconds: 60,
      );
      expect(result, isFalse);
    });

    test('isFollowedCaller accepts self and followed caller', () {
      expect(
        CallEventPolicy.isFollowedCaller(
          callerPubkey: 'me',
          myPubkey: 'me',
          followedPubkeys: {'friend'},
        ),
        isTrue,
      );
      expect(
        CallEventPolicy.isFollowedCaller(
          callerPubkey: 'friend',
          myPubkey: 'me',
          followedPubkeys: {'friend'},
        ),
        isTrue,
      );
    });

    test('isFollowedCaller rejects unknown caller', () {
      final result = CallEventPolicy.isFollowedCaller(
        callerPubkey: 'stranger',
        myPubkey: 'me',
        followedPubkeys: {'friend'},
      );
      expect(result, isFalse);
    });

    test('classifies NIP-AC signaling and payment inner event kinds', () {
      expect(CallEventPolicy.isNipAcSignalingKind(25050), isTrue);
      expect(CallEventPolicy.isNipAcSignalingKind(25054), isTrue);
      expect(CallEventPolicy.isNipAcSignalingKind(25055), isFalse);

      expect(CallEventPolicy.isCallPaymentKind(25055), isTrue);
      expect(CallEventPolicy.isCallPaymentKind(25058), isTrue);
      expect(CallEventPolicy.isCallPaymentKind(25054), isFalse);

      expect(CallEventPolicy.isNipAcInnerKind(25050), isTrue);
      expect(CallEventPolicy.isNipAcInnerKind(25058), isTrue);
      expect(CallEventPolicy.isNipAcInnerKind(25059), isFalse);
    });
  });
}
