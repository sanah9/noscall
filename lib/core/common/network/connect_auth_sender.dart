import 'package:nostr_core_dart/nostr.dart';

import 'package:noscall/core/account/account.dart';
import 'package:noscall/core/common/utils/log_utils.dart';
import 'connect_auth_state.dart';

typedef ConnectAuthEventEncoder =
    Future<Event> Function(
      String challenge,
      String relay,
      String pubkey,
      String privkey,
    );
typedef ConnectAuthStringBuilder = String Function(Event event);
typedef ConnectAuthSend = void Function(String data, List<String> relays);
typedef ConnectAccountKeyProvider = String Function();

class ConnectAuthSender {
  ConnectAuthSender({
    required ConnectAuthState authState,
    ConnectAccountKeyProvider? pubkey,
    ConnectAccountKeyProvider? privkey,
    ConnectAuthEventEncoder? encodeAuthEvent,
    ConnectAuthStringBuilder? authString,
  }) : _authState = authState,
       _pubkey = pubkey ?? (() => Account.sharedInstance.currentPubkey),
       _privkey = privkey ?? (() => Account.sharedInstance.currentPrivkey),
       _encodeAuthEvent = encodeAuthEvent ?? Nip42.encode,
       _authString = authString ?? Nip42.authString;

  final ConnectAuthState _authState;
  final ConnectAccountKeyProvider _pubkey;
  final ConnectAccountKeyProvider _privkey;
  final ConnectAuthEventEncoder _encodeAuthEvent;
  final ConnectAuthStringBuilder _authString;

  Future<void> sendAuth(String relay, {required ConnectAuthSend send}) async {
    final challenge = _authState.challengeFor(relay);
    if (challenge == null || challenge.isEmpty) return;
    if (!_authState.markSending(relay)) return;

    final event = await _encodeAuthEvent(
      challenge,
      relay,
      _pubkey(),
      _privkey(),
    );
    final authJson = _authString(event);
    _authState.markSent(relay, event.id);
    LogUtils.v(() => 'send auth: $authJson');
    send(authJson, [relay]);
  }
}
