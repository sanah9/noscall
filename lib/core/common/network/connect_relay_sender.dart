import 'package:nostr_core_dart/nostr.dart';

import 'connect_socket_registry.dart';

class ConnectRelaySender {
  void send(
    String data, {
    required ConnectSocketRegistry socketRegistry,
    required void Function(OKEvent ok, String relay) onOkFailure,
    required void Function(Closed closed, String relay) onClosed,
    List<String>? toRelays,
    String? eventId,
    String? subscriptionId,
  }) {
    if (toRelays != null && toRelays.isNotEmpty) {
      for (final relay in Set<String>.from(toRelays)) {
        _sendToRelay(
          data,
          relay,
          socketRegistry: socketRegistry,
          onOkFailure: onOkFailure,
          onClosed: onClosed,
          eventId: eventId,
          subscriptionId: subscriptionId,
        );
      }
      return;
    }

    socketRegistry.sockets.forEach((relay, socket) {
      if (socketRegistry.isOpen(relay)) {
        socket.socket?.add(data);
      } else {
        _reportFailure(
          relay,
          onOkFailure: onOkFailure,
          onClosed: onClosed,
          eventId: eventId,
          subscriptionId: subscriptionId,
        );
      }
    });
  }

  void _sendToRelay(
    String data,
    String relay, {
    required ConnectSocketRegistry socketRegistry,
    required void Function(OKEvent ok, String relay) onOkFailure,
    required void Function(Closed closed, String relay) onClosed,
    String? eventId,
    String? subscriptionId,
  }) {
    if (socketRegistry.contains(relay)) {
      final socket = socketRegistry.socketFor(relay);
      if (socketRegistry.isOpen(relay) && socket != null) {
        socket.add(data);
        return;
      }
    }

    _reportFailure(
      relay,
      onOkFailure: onOkFailure,
      onClosed: onClosed,
      eventId: eventId,
      subscriptionId: subscriptionId,
    );
  }

  void _reportFailure(
    String relay, {
    required void Function(OKEvent ok, String relay) onOkFailure,
    required void Function(Closed closed, String relay) onClosed,
    String? eventId,
    String? subscriptionId,
  }) {
    if (eventId != null) {
      onOkFailure(OKEvent(eventId, false, 'not connect to relay'), relay);
    } else if (subscriptionId != null) {
      onClosed(Closed(subscriptionId), relay);
    }
  }
}
