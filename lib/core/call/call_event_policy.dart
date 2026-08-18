import 'package:nostr_core_dart/nostr.dart';

class CallEventPolicy {
  const CallEventPolicy._();

  static bool isStale(
    Event event, {
    required int nowSeconds,
    required int staleAfterSeconds,
  }) {
    return (nowSeconds - event.createdAt) > staleAfterSeconds;
  }

  static bool isFollowedCaller({
    required String callerPubkey,
    required String myPubkey,
    required Set<String> followedPubkeys,
  }) {
    if (callerPubkey == myPubkey) return true;
    return followedPubkeys.contains(callerPubkey);
  }

  static bool isNipAcSignalingKind(int kind) {
    return kind >= 25050 && kind <= 25054;
  }

  static bool isCallPaymentKind(int kind) {
    return kind >= 25055 && kind <= 25060;
  }

  static bool isNipAcInnerKind(int kind) {
    return isNipAcSignalingKind(kind) || isCallPaymentKind(kind);
  }
}
