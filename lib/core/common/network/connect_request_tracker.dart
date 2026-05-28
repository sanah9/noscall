import 'dart:convert';

import 'package:nostr_core_dart/nostr.dart';

import 'connect_types.dart';
import 'event_cache.dart';

class ConnectSubscriptionCloseTarget {
  const ConnectSubscriptionCloseTarget({
    required this.subscriptionId,
    required this.relay,
  });

  final String subscriptionId;
  final String relay;
}

class ConnectRequestTracker {
  final Map<String, Requests> requests = {};
  final Map<String, List<Future<bool>>> eventChecks = {};

  String addSubscriptions(
    Map<String, List<Filter>> filters, {
    EventCallBack? eventCallBack,
    EOSECallBack? eoseCallBack,
    bool closeSubscription = true,
    required void Function(
      String requestId,
      String relay,
      String subscriptionString,
    ) onSubscription,
  }) {
    final requestId = generate64RandomHexChars();
    final relays = filters.keys.toList();
    for (final relay in filters.keys) {
      final requestWithFilter = Request(requestId, filters[relay]!);
      final subscriptionString = requestWithFilter.serialize();
      final request = Requests(
        requestId,
        relays,
        0,
        {},
        eventCallBack,
        eoseCallBack,
        subscriptionString,
        closeSubscription,
      );
      request.subscriptions[relay] = requestWithFilter.subscriptionId;
      requests[requestWithFilter.subscriptionId + relay] = request;
      onSubscription(requestId, relay, subscriptionString);
    }
    return requestId;
  }

  Requests? markSubscriptionSent(
    String subscriptionId,
    String relay, {
    DateTime? now,
  }) {
    final request = requestFor(subscriptionId, relay);
    if (request == null) return null;
    request.requestTime = (now ?? DateTime.now()).millisecondsSinceEpoch;
    return request;
  }

  Requests? requestFor(String subscriptionId, String relay) {
    return requests[subscriptionId + relay];
  }

  bool containsSubscription(String subscriptionId, String relay) {
    return subscriptionId.isNotEmpty &&
        requests.containsKey(subscriptionId + relay);
  }

  String? subscriptionStringFor(String subscriptionId, String relay) {
    return requestFor(subscriptionId, relay)?.subscriptionString;
  }

  void removeSubscription(String subscriptionId, String relay) {
    requests.remove(subscriptionId + relay);
  }

  Future<bool> checkValidEvent(Event event, String relay) async {
    final subscriptionId = event.subscriptionId;
    if (subscriptionId == null || subscriptionId.isEmpty) return false;
    final request = requestFor(subscriptionId, relay);
    if (request == null) return false;

    request.requestTime = DateTime.now().millisecondsSinceEpoch;
    final callback = request.eventCallBack;
    if (callback == null) return false;

    EventCache.sharedInstance.receiveEvent(event, relay);
    if (await event.isValid() == false) return false;
    callback(event, relay);
    return true;
  }

  void trackEventCheck(
      String subscriptionId, String relay, Future<bool> future) {
    if (subscriptionId.isEmpty) return;
    eventChecks[subscriptionId + relay] ??= [];
    eventChecks[subscriptionId + relay]?.add(future);
  }

  Future<void> waitForEventChecks(String subscriptionId, String relay) async {
    final key = subscriptionId + relay;
    final checks = eventChecks[key];
    if (checks == null) return;
    await Future.wait(checks);
    eventChecks.remove(key);
  }

  bool completeRelay(String subscriptionId, String relay, bool error) {
    final request = requestFor(subscriptionId, relay);
    if (request == null) return false;

    request.relays.remove(relay);
    for (final otherRequest in requests.values) {
      if (otherRequest.requestId == request.requestId) {
        otherRequest.relays.remove(relay);
      }
    }

    final callback = request.eoseCallBack;
    final ok = OKEvent(subscriptionId, !error, '');
    if (callback != null) {
      callback(subscriptionId, ok, relay, request.relays);
    }
    request.eoseCallBack = null;
    return request.closeSubscription;
  }

  List<String> subscriptionIdsForRelay(String relay) {
    return requests.keys
        .where((key) => key.contains(relay))
        .map((key) => key.replaceAll(relay, ''))
        .toList();
  }

  List<ConnectSubscriptionCloseTarget> closeTargets(
    String requestId, {
    String? relay,
    required Iterable<String> connectedRelays,
  }) {
    for (final key in List<String>.from(requests.keys)) {
      final request = requests[key];
      if (request == null || request.requestId != requestId) continue;
      if (relay != null) {
        final subscriptionId = request.subscriptions[relay];
        if (subscriptionId == null) return const [];
        return [
          ConnectSubscriptionCloseTarget(
            subscriptionId: subscriptionId,
            relay: relay,
          ),
        ];
      }

      return [
        for (final connectedRelay in connectedRelays)
          if (request.subscriptions[connectedRelay] != null)
            ConnectSubscriptionCloseTarget(
              subscriptionId: request.subscriptions[connectedRelay]!,
              relay: connectedRelay,
            ),
      ];
    }
    return const [];
  }

  String requestIdFromEose(String eose) {
    return jsonDecode(eose)[0];
  }

  void clear() {
    requests.clear();
    eventChecks.clear();
  }
}
