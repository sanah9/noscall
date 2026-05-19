import 'dart:convert';

import 'package:nostr_core_dart/nostr.dart';

import 'connect_types.dart';

class ConnectTimeoutChecker {
  ConnectTimeoutChecker({required this.timeoutSeconds});

  final int timeoutSeconds;

  void check({
    required Map<String, Sends> sendsMap,
    required Map<String, Requests> requestsMap,
    required void Function(OKEvent ok, String relay) onOkTimeout,
    required void Function(String eose, String relay) onRequestTimeout,
    DateTime? now,
  }) {
    final nowMs = (now ?? DateTime.now()).millisecondsSinceEpoch;
    _checkSends(
      nowMs: nowMs,
      sendsMap: sendsMap,
      onOkTimeout: onOkTimeout,
    );
    _checkRequests(
      nowMs: nowMs,
      requestsMap: requestsMap,
      onRequestTimeout: onRequestTimeout,
    );
  }

  void _checkSends({
    required int nowMs,
    required Map<String, Sends> sendsMap,
    required void Function(OKEvent ok, String relay) onOkTimeout,
  }) {
    final eventIds = List<String>.from(sendsMap.keys);
    for (final eventId in eventIds) {
      final send = sendsMap[eventId];
      if (send == null) continue;
      if (nowMs - send.sendsTime <= timeoutSeconds * 1000) continue;

      final ok = OKEvent(eventId, false, 'Time Out');
      final relays = List<String>.from(send.relays);
      for (final relay in relays) {
        onOkTimeout(ok, relay);
      }
    }
  }

  void _checkRequests({
    required int nowMs,
    required Map<String, Requests> requestsMap,
    required void Function(String eose, String relay) onRequestTimeout,
  }) {
    final requestKeys = List<String>.from(requestsMap.keys);
    for (final requestKey in requestKeys) {
      final request = requestsMap[requestKey];
      if (request == null) continue;
      if (!request.closeSubscription && request.eoseCallBack == null) {
        continue;
      }
      if (request.requestTime <= 0) continue;
      if (nowMs - request.requestTime <= timeoutSeconds * 1000) continue;

      final relay = requestKey.substring(64);
      onRequestTimeout(jsonEncode([request.requestId]), relay);
    }
  }
}
