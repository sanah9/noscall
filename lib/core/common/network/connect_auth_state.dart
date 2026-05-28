import 'package:nostr_core_dart/nostr.dart';

import 'connect_types.dart';

class ConnectAuthState {
  final Map<String, AuthData> auths = {};

  void registerChallenge(Auth auth, String relay) {
    final existing = auths[relay];
    if (existing == null) {
      auths[relay] = AuthData(auth.challenge, '', []);
    } else if (existing.challenge != auth.challenge) {
      existing.challenge = auth.challenge;
      existing.eventId = '';
    }
  }

  bool queueResend(String relay, String data) {
    final auth = auths[relay];
    if (auth == null) return false;
    if (auth.resendDatas.contains(data)) return false;
    auth.resendDatas.add(data);
    return true;
  }

  bool isAuthResponse(OKEvent ok, String relay) {
    return auths[relay]?.eventId == ok.eventId;
  }

  List<String> completeAuthResponse(OKEvent ok, String relay) {
    final auth = auths[relay];
    final resendDatas =
        ok.status ? List<String>.from(auth?.resendDatas ?? []) : <String>[];
    auths.remove(relay);
    return resendDatas;
  }

  String? challengeFor(String relay) {
    return auths[relay]?.challenge;
  }

  bool markSending(String relay) {
    final auth = auths[relay];
    if (auth == null) return false;
    if (auth.challenge.isEmpty) return false;
    if (auth.eventId.isNotEmpty) return false;
    auth.eventId = 'sending...';
    return true;
  }

  void markSent(String relay, String eventId) {
    auths[relay]?.eventId = eventId;
  }

  void clear() {
    auths.clear();
  }
}
