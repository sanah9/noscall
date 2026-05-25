import 'package:nostr_core_dart/nostr.dart';

import 'connect_types.dart';

class ConnectSendOkResult {
  const ConnectSendOkResult._({
    this.authRequiredEventString,
    this.failedRelayForRequests,
  });

  const ConnectSendOkResult.ignored() : this._();

  const ConnectSendOkResult.handled() : this._();

  const ConnectSendOkResult.authRequired(String eventString)
      : this._(authRequiredEventString: eventString);

  const ConnectSendOkResult.failedRelay(String relay)
      : this._(failedRelayForRequests: relay);

  final String? authRequiredEventString;
  final String? failedRelayForRequests;
}

class ConnectSendTracker {
  final Map<String, Sends> sends = {};

  void trackEvent({
    required String eventId,
    required String eventString,
    required List<String> relays,
    OKCallBack? okCallBack,
    DateTime? now,
  }) {
    sends[eventId] = Sends(
      generate64RandomHexChars(),
      List<String>.from(relays),
      (now ?? DateTime.now()).millisecondsSinceEpoch,
      eventId,
      okCallBack,
      eventString,
    );
  }

  ConnectSendOkResult handleOk(OKEvent ok, String relay) {
    final send = sends[ok.eventId];
    if (send == null) return const ConnectSendOkResult.ignored();

    if (!ok.status && Nip42.authRequired(ok.message)) {
      return ConnectSendOkResult.authRequired(send.eventString);
    }

    final relays = send.relays;
    relays.remove(relay);
    final callback = send.okCallBack;
    if (callback != null) {
      if (ok.status || relays.isEmpty) {
        callback(ok, relay);
        sends.remove(ok.eventId);
      } else if (!ok.status && ok.eventId.isEmpty) {
        return ConnectSendOkResult.failedRelay(relay);
      }
    } else if (relays.isEmpty) {
      sends.remove(ok.eventId);
    }

    return const ConnectSendOkResult.handled();
  }

  void clear() {
    sends.clear();
  }
}
