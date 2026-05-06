import 'dart:async';

import 'package:nostr_core_dart/nostr.dart';

import 'package:noscall/core/account/relays.dart';
import 'package:noscall/core/common/network/connect.dart';

abstract class AccountRelayRuntime {
  void connectRelay(String relay, RelayKind relayKind);
  void closeRelay(String relay, RelayKind relayKind);
  void connectGeneralRelays();
  void connectDMRelays();
  void connectInboxOutboxRelays();
  Future<void> closeAllRelays();
  Future<void> resumeAllRelays();
  Future<OKEvent> sendEvent(Event event);
}

class DefaultAccountRelayRuntime implements AccountRelayRuntime {
  const DefaultAccountRelayRuntime();

  @override
  void closeRelay(String relay, RelayKind relayKind) {
    Connect.sharedInstance.closeConnects([relay], relayKind);
  }

  @override
  Future<void> closeAllRelays() async {
    await Connect.sharedInstance.closeAllConnects();
  }

  @override
  void connectDMRelays() {
    Relays.sharedInstance.connectDMRelays();
  }

  @override
  void connectGeneralRelays() {
    Relays.sharedInstance.connectGeneralRelays();
  }

  @override
  void connectInboxOutboxRelays() {
    Relays.sharedInstance.connectInboxOutboxRelays();
  }

  @override
  void connectRelay(String relay, RelayKind relayKind) {
    Connect.sharedInstance.connectRelays([relay], relayKind: relayKind);
  }

  @override
  Future<void> resumeAllRelays() async {
    await Relays.sharedInstance.connectGeneralRelays();
    await Relays.sharedInstance.connectDMRelays();
  }

  @override
  Future<OKEvent> sendEvent(Event event) {
    final completer = Completer<OKEvent>();
    Connect.sharedInstance.sendEvent(
      event,
      sendCallBack: (ok, relay) {
        if (!completer.isCompleted) {
          completer.complete(ok);
        }
      },
    );
    return completer.future;
  }
}

AccountRelayRuntime _runtime = const DefaultAccountRelayRuntime();

AccountRelayRuntime get accountRelayRuntime => _runtime;

void setAccountRelayRuntimeForTest(AccountRelayRuntime runtime) {
  _runtime = runtime;
}

void clearAccountRelayRuntimeForTest() {
  _runtime = const DefaultAccountRelayRuntime();
}
