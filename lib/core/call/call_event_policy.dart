import 'package:nostr_core_dart/nostr.dart';

class CallEventPolicy {
  const CallEventPolicy._();

  static bool isStale(Event event, {required int nowSeconds, required int staleAfterSeconds}) {
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
}
