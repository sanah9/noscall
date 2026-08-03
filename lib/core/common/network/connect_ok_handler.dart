import 'dart:async';

import 'package:nostr_core_dart/nostr.dart';

import 'package:noscall/core/common/utils/log_utils.dart';
import 'connect_auth_state.dart';
import 'connect_send_tracker.dart';

typedef ConnectOkSend =
    FutureOr<void> Function(String data, List<String> relays);
typedef ConnectOkSendAuth = FutureOr<void> Function(String relay);
typedef ConnectOkCompleteRelayRequests = FutureOr<void> Function(String relay);

class ConnectOkHandler {
  ConnectOkHandler({
    required ConnectAuthState authState,
    required ConnectSendTracker sendTracker,
  }) : _authState = authState,
       _sendTracker = sendTracker;

  final ConnectAuthState _authState;
  final ConnectSendTracker _sendTracker;

  Future<void> handle(
    OKEvent ok,
    String relay, {
    required ConnectOkSend send,
    required ConnectOkSendAuth sendAuth,
    required ConnectOkCompleteRelayRequests completeRelayRequests,
  }) async {
    LogUtils.v(() => 'receive ok: ${ok.serialize()}, $relay');

    if (_authState.isAuthResponse(ok, relay)) {
      for (final data in _authState.completeAuthResponse(ok, relay)) {
        LogUtils.v(() => 're-send: $data');
        await send(data, [relay]);
      }
      return;
    }

    final sendResult = _sendTracker.handleOk(ok, relay);
    final authEventString = sendResult.authRequiredEventString;
    if (authEventString != null) {
      _authState.queueResend(relay, authEventString);
      await sendAuth(relay);
      return;
    }

    final failedRelay = sendResult.failedRelayForRequests;
    if (failedRelay != null) {
      await completeRelayRequests(failedRelay);
    }
  }
}
