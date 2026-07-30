import 'package:nostr_core_dart/nostr.dart';

import 'package:noscall/core/common/utils/log_utils.dart';
import 'connect_request_tracker.dart';
import 'event_cache.dart';

typedef ConnectEventCachePredicate = bool Function(Event event);
typedef ConnectEventReceiver = Future<void> Function(Event event, String relay);

class ConnectEventProcessor {
  ConnectEventProcessor({
    ConnectEventCachePredicate? isCached,
    ConnectEventCachePredicate? isExpired,
    ConnectEventReceiver? receiveEvent,
  }) : _isCached =
           isCached ??
           ((event) => EventCache.sharedInstance.cacheIds.contains(event.id)),
       _isExpired = isExpired ?? Nip40.expired,
       _receiveEvent =
           receiveEvent ??
           ((event, relay) =>
               EventCache.sharedInstance.receiveEvent(event, relay));

  final ConnectEventCachePredicate _isCached;
  final ConnectEventCachePredicate _isExpired;
  final ConnectEventReceiver _receiveEvent;

  Future<void> handle(
    Event event,
    String relay, {
    required ConnectRequestTracker requestTracker,
  }) async {
    LogUtils.v(
      () =>
          'Received event, subscriptionId: ${event.subscriptionId}, ${event.toJson()}',
    );
    if (_isCached(event)) {
      return;
    }

    if (_isExpired(event)) {
      await _receiveEvent(event, relay);
      return;
    }

    final future = requestTracker.checkValidEvent(event, relay);
    final subscriptionId = event.subscriptionId;
    if (subscriptionId != null && subscriptionId.isNotEmpty) {
      requestTracker.trackEventCheck(subscriptionId, relay, future);
    }
  }
}
