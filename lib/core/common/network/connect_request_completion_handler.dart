import 'dart:async';
import 'dart:convert';

import 'package:nostr_core_dart/nostr.dart';

import 'package:noscall/core/common/utils/log_utils.dart';
import 'connect_auth_state.dart';
import 'connect_request_tracker.dart';
import 'connect_types.dart';

typedef ConnectCloseSubscription =
    FutureOr<void> Function(String subscriptionId, String relay);
typedef ConnectSendAuth = FutureOr<void> Function(String relay);

class ConnectRequestCompletionHandler {
  ConnectRequestCompletionHandler({
    required ConnectRequestTracker requestTracker,
    required ConnectAuthState authState,
  }) : _requestTracker = requestTracker,
       _authState = authState;

  final ConnectRequestTracker _requestTracker;
  final ConnectAuthState _authState;

  Future<void> handleEose(
    String eose,
    String relay,
    bool timeout, {
    required ConnectCloseSubscription closeSubscription,
  }) async {
    LogUtils.v(() => 'receive EOSE: $eose, $relay, timeout: $timeout');
    final subscriptionId = _requestTracker.requestIdFromEose(eose);
    if (_requestTracker.containsSubscription(subscriptionId, relay)) {
      await _requestTracker.waitForEventChecks(subscriptionId, relay);
      await completeRelay(
        subscriptionId,
        relay,
        timeout,
        closeSubscription: closeSubscription,
      );
    }
  }

  Future<void> handleClosed(
    Closed closed,
    String relay, {
    required ConnectCloseSubscription closeSubscription,
    required ConnectSendAuth sendAuth,
  }) async {
    LogUtils.v(() => 'receive closed: ${closed.serialize()}, $relay');
    final subscriptionId = closed.subscriptionId;
    if (!_requestTracker.containsSubscription(subscriptionId, relay)) return;

    if (Nip42.authRequired(closed.message)) {
      final subscriptionString = _requestTracker.subscriptionStringFor(
        subscriptionId,
        relay,
      );
      if (subscriptionString != null) {
        _authState.queueResend(relay, subscriptionString);
      }
      await sendAuth(relay);
      return;
    }

    await completeRelay(
      subscriptionId,
      relay,
      true,
      closeSubscription: closeSubscription,
    );
  }

  Future<void> handleNotice(
    String notice,
    String relay, {
    NoticeCallBack? noticeCallBack,
    required ConnectCloseSubscription closeSubscription,
  }) async {
    LogUtils.v(() => 'receive notice: $notice, $relay');
    final noticeText = jsonDecode(notice)[0];

    await completeAllForRelay(relay, closeSubscription: closeSubscription);

    noticeCallBack?.call(noticeText, relay);
  }

  Future<void> completeRelay(
    String subscriptionId,
    String relay,
    bool error, {
    required ConnectCloseSubscription closeSubscription,
  }) async {
    final shouldClose = _requestTracker.completeRelay(
      subscriptionId,
      relay,
      error,
    );
    if (shouldClose) {
      await closeSubscription(subscriptionId, relay);
    }
  }

  Future<void> completeAllForRelay(
    String relay, {
    required ConnectCloseSubscription closeSubscription,
  }) async {
    for (final subscriptionId in _requestTracker.subscriptionIdsForRelay(
      relay,
    )) {
      await completeRelay(
        subscriptionId,
        relay,
        true,
        closeSubscription: closeSubscription,
      );
    }
  }
}
