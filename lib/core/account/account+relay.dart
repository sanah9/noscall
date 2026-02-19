import 'dart:async';

import 'package:nostr_core_dart/nostr.dart';

import 'package:noscall/core/common/network/connect.dart';
import 'package:noscall/core/account/account.dart';
import 'package:noscall/core/account/model/relayDB_isar.dart';
import 'package:noscall/core/account/model/userDB_isar.dart';
import 'package:noscall/core/account/relays.dart';

List<RelayDBISAR> _toRelayDBISARList(List<String> urls) {
  final result = <RelayDBISAR>[];
  for (var url in urls) {
    final normalized = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    result.add(Relays.sharedInstance.relays[normalized] ?? RelayDBISAR(url: normalized));
  }
  return result;
}

enum _RelayListType { general, inbox, outbox, dm }

extension AccountRelay on Account {
  List<RelayDBISAR> getMyDMRelayList() => _toRelayDBISARList(me?.dmRelayList ?? []);
  List<RelayDBISAR> getMyInboxRelayList() => _toRelayDBISARList(me?.inboxRelayList ?? []);
  List<RelayDBISAR> getMyOutboxRelayList() => _toRelayDBISARList(me?.outboxRelayList ?? []);
  List<RelayDBISAR> getMyGeneralRelayList() => _toRelayDBISARList(me?.relayList ?? []);
  List<RelayDBISAR> getMyRecommendGeneralRelaysList() =>
      _toRelayDBISARList(Relays.sharedInstance.recommendGeneralRelays);
  List<RelayDBISAR> getMyRecommendDMRelaysList() =>
      _toRelayDBISARList(Relays.sharedInstance.recommendDMRelays);

  Future<List<String>> getUserDMRelayList(String pubkey) async {
    UserDBISAR? userDB = await getUserInfo(pubkey);
    if (userDB != null) {
      return userDB.dmRelayList ?? [];
    }
    return [];
  }

  Future<List<String>> getUserGeneralRelayList(String pubkey) async {
    UserDBISAR? userDB = await getUserInfo(pubkey);
    if (userDB != null) {
      return userDB.relayList ?? [];
    }
    return [];
  }

  Future<OKEvent> setDMRelayListToRelay(List<String> relays) async {
    me!.dmRelayList = relays;
    me!.lastDMRelayListUpdatedTime = currentUnixTimestampSeconds();
    Relays.sharedInstance.connectDMRelays();
    syncMe();
    Completer<OKEvent> completer = Completer<OKEvent>();
    Event event = await Nip17.encodeDMRelays(relays, currentPubkey, currentPrivkey);
    Connect.sharedInstance.sendEvent(event, sendCallBack: (ok, relay) {
      if (!completer.isCompleted) {
        completer.complete(ok);
      }
    });
    return completer.future;
  }

  List<String> _getRelayListCopy(_RelayListType type) {
    switch (type) {
      case _RelayListType.general:
        return List.from(me?.relayList ?? []);
      case _RelayListType.inbox:
        return List.from(me?.inboxRelayList ?? []);
      case _RelayListType.outbox:
        return List.from(me?.outboxRelayList ?? []);
      case _RelayListType.dm:
        return List.from(me?.dmRelayList ?? []);
    }
  }

  Future<OKEvent> _setRelayList(List<String> relays, _RelayListType type) async {
    switch (type) {
      case _RelayListType.general:
        return setGeneralRelayListToLocal(relays);
      case _RelayListType.inbox:
        return setInboxRelayListToRelay(relays);
      case _RelayListType.outbox:
        return setOutboxRelayListToRelay(relays);
      case _RelayListType.dm:
        return setDMRelayListToRelay(relays);
    }
  }

  static RelayKind _relayKind(_RelayListType type) {
    switch (type) {
      case _RelayListType.general:
        return RelayKind.general;
      case _RelayListType.inbox:
        return RelayKind.inbox;
      case _RelayListType.outbox:
        return RelayKind.outbox;
      case _RelayListType.dm:
        return RelayKind.dm;
    }
  }

  Future<OKEvent> _addRelay(String relay, _RelayListType type) async {
    if (relay.isEmpty) return OKEvent(relay, false, 'empty relay');
    final list = _getRelayListCopy(type);
    if (list.contains(relay)) return OKEvent(relay, false, 'already exit');
    list.add(relay);
    Connect.sharedInstance.connectRelays([relay], relayKind: _relayKind(type));
    return _setRelayList(list, type);
  }

  Future<OKEvent> _removeRelay(String relay, _RelayListType type) async {
    if (relay.isEmpty) return OKEvent(relay, false, 'empty relay');
    final list = _getRelayListCopy(type);
    if (!list.contains(relay)) return OKEvent(relay, false, 'not exit');
    list.remove(relay);
    Connect.sharedInstance.closeConnects([relay], _relayKind(type));
    return _setRelayList(list, type);
  }

  Future<OKEvent> addGeneralRelay(String relay) => _addRelay(relay, _RelayListType.general);
  Future<OKEvent> removeGeneralRelay(String relay) => _removeRelay(relay, _RelayListType.general);
  Future<OKEvent> addInboxRelay(String relay) => _addRelay(relay, _RelayListType.inbox);
  Future<OKEvent> removeInboxRelay(String relay) => _removeRelay(relay, _RelayListType.inbox);
  Future<OKEvent> addOutboxRelay(String relay) => _addRelay(relay, _RelayListType.outbox);
  Future<OKEvent> removeOutboxRelay(String relay) => _removeRelay(relay, _RelayListType.outbox);
  Future<OKEvent> addDMRelay(String relay) => _addRelay(relay, _RelayListType.dm);
  Future<OKEvent> removeDMRelay(String relay) => _removeRelay(relay, _RelayListType.dm);

  Future<void> closeAllRelays() async {
    await Connect.sharedInstance.closeAllConnects();
  }

  Future<void> resumeAllRelays() async {
    await Relays.sharedInstance.connectGeneralRelays();
    await Relays.sharedInstance.connectDMRelays();
  }

  int getConnectedRelaysCount() {
    Set<RelayDBISAR> myRelays = Set.from(getMyGeneralRelayList());
    myRelays.addAll(getMyDMRelayList());
    myRelays.addAll(getMyInboxRelayList());
    myRelays.addAll(getMyOutboxRelayList());
    int connected = 0;
    for (var relay in myRelays) {
      if (relay.connectStatus == 1) ++connected;
    }
    return connected;
  }

  int getAllRelaysCount() {
    Set<RelayDBISAR> allRelays = Set.from(getMyGeneralRelayList());
    allRelays.addAll(getMyDMRelayList());
    allRelays.addAll(getMyInboxRelayList());
    allRelays.addAll(getMyOutboxRelayList());
    return allRelays.length;
  }

  Future<OKEvent> setGeneralRelayListToLocal(List<String> relays) async {
    me!.relayList = relays;
    me!.lastRelayListUpdatedTime = currentUnixTimestampSeconds();
    Relays.sharedInstance.connectGeneralRelays();
    syncMe();
    return OKEvent('', true, '');
  }

  Future<OKEvent> setInboxRelayListToRelay(List<String> relays) async {
    me!.inboxRelayList = relays;
    me!.lastRelayListUpdatedTime = currentUnixTimestampSeconds();
    Relays.sharedInstance.connectInboxOutboxRelays();
    syncMe();
    return setInboxOutboxToRelay();
  }

  Future<OKEvent> setOutboxRelayListToRelay(List<String> relays) async {
    me!.outboxRelayList = relays;
    me!.lastRelayListUpdatedTime = currentUnixTimestampSeconds();
    Relays.sharedInstance.connectInboxOutboxRelays();
    syncMe();
    return setInboxOutboxToRelay();
  }

  Future<OKEvent> setInboxOutboxToRelay() async {
    Completer<OKEvent> completer = Completer<OKEvent>();
    List<Relay> list = [];
    for (var relay in me!.inboxRelayList ?? []) {
      list.add(Relay(relay, 'read'));
    }
    for (var relay in me!.outboxRelayList ?? []) {
      list.add(Relay(relay, 'write'));
    }
    Event event = await Nip65.encode(list, currentPubkey, currentPrivkey);
    Connect.sharedInstance.sendEvent(event, sendCallBack: (ok, relay) {
      if (!completer.isCompleted) completer.complete(ok);
    });
    return completer.future;
  }
}
