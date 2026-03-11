import 'dart:io';

import 'package:nostr_core_dart/nostr.dart';

/// Notice callback
typedef NoticeCallBack = void Function(String notice, String relay);

/// Send event callback
typedef OKCallBack = void Function(OKEvent ok, String relay);

/// Request callback
typedef EventCallBack = void Function(Event event, String relay);
typedef EOSECallBack = void Function(
    String requestId, OKEvent ok, String relay, List<String> unCompletedRelays);

/// Connect callback
typedef ConnectStatusCallBack = void Function(
    String relay, int status, List<RelayKind> relayKinds);

class Sends {
  String sendsId;
  List<String> relays;
  int sendsTime;
  String eventId;
  OKCallBack? okCallBack;
  String eventString;

  Sends(this.sendsId, this.relays, this.sendsTime, this.eventId, this.okCallBack,
      this.eventString);
}

class Requests {
  String requestId;
  List<String> relays;
  int requestTime;
  Map<String, String> subscriptions;
  EventCallBack? eventCallBack;
  EOSECallBack? eoseCallBack;
  String subscriptionString;
  bool closeSubscription;

  Requests(
      this.requestId,
      this.relays,
      this.requestTime,
      this.subscriptions,
      this.eventCallBack,
      this.eoseCallBack,
      this.subscriptionString,
      this.closeSubscription);
}

class AuthData {
  String challenge;
  String eventId;
  List<String> resendDatas;

  AuthData(this.challenge, this.eventId, this.resendDatas);
}

class ISocket {
  WebSocket? socket;

  /// connecting = 0;
  /// open = 1;
  /// closing = 2;
  /// closed = 3;
  int connectStatus;
  List<RelayKind> relayKinds = [];

  ISocket(this.socket, this.connectStatus, this.relayKinds);
}

enum RelayKind {
  general,
  dm,
  inbox,
  outbox,
  remoteSigner,
  notification,
  temp,
}
