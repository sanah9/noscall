import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:nostr/nostr.dart';

import '../../account/model/relayDB_isar.dart';
import '../../account/relays.dart';
import '../../common/network/eventCache.dart';
import '../../common/utils/log_utils.dart';
import '../../core-manager.dart';
import '../../account/account.dart';
import '../../account/model/userDB_isar.dart';
import '../../common/network/connect.dart';
import '../messages/model/messageDB_isar.dart';
import 'contacts+blocklist.dart';
import 'contacts+calling.dart';
import 'contacts+isolateEvent.dart';

typedef PrivateChatMessageCallBack = void Function(MessageDBISAR);
typedef ContactUpdatedCallBack = void Function();

enum CallMessageState { disconnect, offer, answer, reject, timeout, cancel, inCalling }

class CallMessage {
  String callId;
  String sender;
  String receiver;
  CallMessageState state;
  int start;
  int end;
  String media;

  CallMessage(
      this.callId, this.sender, this.receiver, this.state, this.start, this.end, this.media);
}

class Contacts {
  static const String identifier = 'Chat-Friends';
  static const String blockListidentifier = 'Chat-Block';

  /// singleton
  Contacts._internal();
  factory Contacts() => sharedInstance;
  static final Contacts sharedInstance = Contacts._internal();

  /// memory storage
  String pubkey = '';
  String privkey = '';
  Map<String, UserDBISAR> allContacts = {};
  String friendMessageSubscription = '';
  int lastFriendListUpdateTime = 0;
  List<String>? blockList;
  Map<String, CallMessage> callMessages = {};
  int maxLimit = 2048;
  int offset2 = 24 * 60 * 60 * 3;

  /// callbacks
  ContactUpdatedCallBack? contactUpdatedCallBack;
  PrivateChatMessageCallBack? privateChatMessageCallBack;
  Map<String, bool> offlinePrivateMessageFinish = {};

  void Function(String friend, SignalingState state, String data, String? offerId)?
      onCallStateChange;

  Future<void> init({ContactUpdatedCallBack? callBack}) async {
    privkey = Account.sharedInstance.currentPrivkey;
    pubkey = Account.sharedInstance.currentPubkey;
    contactUpdatedCallBack = callBack;

    Account.sharedInstance.contactListUpdateCallback = () async {
      await _syncContactsFromDB();
    };
    // subscript friend requests
    Connect.sharedInstance.addConnectStatusListener((relay, status, relayKinds) async {
      if (status == 1 &&
          Account.sharedInstance.me != null &&
          (relayKinds.contains(RelayKind.general) ||
              relayKinds.contains(RelayKind.inbox) ||
              relayKinds.contains(RelayKind.dm))) {
        _subscriptMessages(relay: relay);
      }
    });
    _subscriptMessages();
    // sync friend list from DB & relays
    await syncBlockListFromDB();
    await _syncContactsFromDB();
  }

  /// contact list
  Future<void> _syncContactsToDB(String list) async {
    Account.sharedInstance.me?.friendsList = list;
    await Account.sharedInstance.syncMe();
  }

  Future<void> _syncContactsToRelay({OKCallBack? okCallBack}) async {
    List<People> friendList = [];
    for (UserDBISAR user in allContacts.values) {
      People p = People(user.pubKey, user.mainRelay, user.nickName, user.aliasPubkey);
      friendList.add(p);
    }
    Event event = await Nip51.createCategorizedPeople(identifier, [], friendList, privkey, pubkey);
    if (event.content.isNotEmpty) {
      Connect.sharedInstance.sendEvent(event, sendCallBack: (OKEvent ok, String relay) async {
        if (ok.status) {
          Account.sharedInstance.me!.lastFriendsListUpdatedTime = event.createdAt;
          await _syncContactsToDB(event.content);
        }
        okCallBack?.call(ok, relay);
      });
    } else {
      throw Exception('_syncFriendsToRelay error content!, $friendList');
    }
  }

  Future<void> syncContactsProfiles(List<People> peoples) async {
    await _syncContactsProfilesFromDB(peoples);
    List<People> friendList = [];
    for (UserDBISAR user in allContacts.values) {
      People p = People(user.pubKey, user.mainRelay, user.nickName, user.aliasPubkey);
      friendList.add(p);
    }
    Event event = await Nip51.createCategorizedPeople(identifier, [], friendList, privkey, pubkey);
    if (event.content.isNotEmpty) {
      _syncContactsToDB(event.content);
    } else {
      throw Exception('_syncFriendsToDB error content!, $friendList');
    }
  }

  Future<void> _syncContactsProfilesFromDB(List<People> peoples) async {
    allContacts.clear();
    await Future.forEach(peoples, (p) async {
      UserDBISAR? user = await Account.sharedInstance.getUserInfo(p.pubkey);
      if (user != null) {
        user.nickName = p.petName;
        allContacts[user.pubKey] = user;
      }
    });
  }

  Future<OKEvent> addToContact(List<String> pubkeys) async {
    Completer<OKEvent> completer = Completer<OKEvent>();

    await Future.forEach(pubkeys, (friendPubkey) async {
      UserDBISAR? friend = await Account.sharedInstance.getUserInfo(friendPubkey);
      friend ??= UserDBISAR(pubKey: friendPubkey);
      allContacts[friendPubkey] = friend;
    });
    _syncContactsToRelay(okCallBack: (OKEvent ok, String relay) {
      if (!completer.isCompleted) completer.complete(ok);
    });
    contactUpdatedCallBack?.call();
    return completer.future;
  }

  Future<OKEvent> removeContact(String friendPubkey) async {
    Completer<OKEvent> completer = Completer<OKEvent>();

    UserDBISAR? friend = allContacts.remove(friendPubkey);
    if (friend != null) {
      _syncContactsToRelay(okCallBack: (OKEvent ok, String relay) {
        if (!completer.isCompleted) completer.complete(ok);
      });
      contactUpdatedCallBack?.call();
    }
    return completer.future;
  }

  Future<OKEvent> updateContactNickName(String friendPubkey, String nickName) async {
    Completer<OKEvent> completer = Completer<OKEvent>();

    UserDBISAR? friend = allContacts[friendPubkey];
    if (friend != null) {
      friend.nickName = nickName;
      await Account.saveUserToDB(friend);
      _syncContactsToRelay(okCallBack: (ok, relay) {
        if (!completer.isCompleted) completer.complete(ok);
      });
    } else if (!completer.isCompleted) {
      completer.complete(OKEvent(friendPubkey, false, ''));
    }
    return completer.future;
  }

  List<UserDBISAR>? fuzzySearch(String keyword) {
    if (keyword.isNotEmpty) {
      RegExp regex = RegExp(keyword, caseSensitive: false);
      List<UserDBISAR> filteredFriends = allContacts.values
          .where((person) =>
              regex.hasMatch(person.name ?? '') ||
              regex.hasMatch(person.dns ?? '') ||
              regex.hasMatch(person.nickName ?? ''))
          .toList();
      return filteredFriends;
    }
    return null;
  }

  Future<void> muteFriend(String friendPubkey) async {
    _setMuteFriend(friendPubkey, true);
  }

  Future<void> unMuteFriend(String friendPubkey) async {
    _setMuteFriend(friendPubkey, false);
  }

  List<String> getAllUnMuteContacts() {
    return allContacts.entries
        .where((e) => e.value.mute == false)
        .map((e) => e.value.pubKey)
        .toList();
  }

  Future<void> _setMuteFriend(String friendPubkey, bool mute) async {
    if (allContacts.containsKey(friendPubkey)) {
      UserDBISAR friend = allContacts[friendPubkey]!;
      friend.mute = mute;
      await Account.saveUserToDB(friend);
    }
  }

  Uint8List? getFriendSharedSecret(String friendPubkey) {
    return Nip44.shareSecret(privkey, friendPubkey);
  }

  /// sync contacts
  Future<void> _syncContactsFromDB() async {
    String? list = Account.sharedInstance.me?.friendsList;
    if (list != null && list.isNotEmpty && list != 'null') {
      Map? map = await Nip51.fromContent(list, privkey, pubkey);
      if (map != null) {
        List<People> friendsList = map['people'];
        for (var p in friendsList) {
          UserDBISAR userDB = UserDBISAR(pubKey: p.pubkey);
          userDB.name = userDB.shortEncodedPubkey;
          allContacts[p.pubkey] = userDB;
        }
        contactUpdatedCallBack?.call();
        await Future.forEach(friendsList, (p) async {
          UserDBISAR? user = await Account.sharedInstance.getUserInfo(p.pubkey);
          if (user != null) {
            user.nickName = p.petName;
            allContacts[user.pubKey] = user;
          }
        });
        contactUpdatedCallBack?.call();
      }
    }
  }

  Future<void> _subscriptMessages({String? relay}) async {
    if (friendMessageSubscription.isNotEmpty) {
      await Connect.sharedInstance.closeRequests(friendMessageSubscription, relay: relay);
    }

    Map<String, List<Filter>> subscriptions = {};
    if (relay == null) {
      List<String> relays = Connect.sharedInstance.relays(relayKinds: [RelayKind.inbox]);
      relays.addAll(Connect.sharedInstance.relays(relayKinds: [RelayKind.dm]));
      relays.addAll(Connect.sharedInstance.relays(relayKinds: [RelayKind.general]));
      for (String relayURL in relays) {
        int friendMessageUntil = Relays.sharedInstance.getCommonMessageUntil(relayURL);

        /// all messages, contacts & unknown contacts
        Filter f1 = Filter(
            kinds: [4, 1059],
            p: [pubkey],
            since: friendMessageUntil > offset2 ? (friendMessageUntil - offset2 + 1) : 1,
            limit: maxLimit);
        Filter f2 =
            Filter(kinds: [4], authors: [pubkey], since: (friendMessageUntil + 1), limit: maxLimit);
        subscriptions[relayURL] = [f1, f2];
      }
    } else {
      int friendMessageUntil = Relays.sharedInstance.getCommonMessageUntil(relay);

      /// all messages, contacts & unknown contacts
      Filter f1 = Filter(
          kinds: [4, 1059],
          p: [pubkey],
          since: friendMessageUntil > offset2 ? (friendMessageUntil - offset2 + 1) : 1,
          limit: maxLimit);
      Filter f2 =
          Filter(kinds: [4], authors: [pubkey], since: (friendMessageUntil + 1), limit: maxLimit);
      subscriptions[relay] = [f1, f2];
    }
    friendMessageSubscription = Connect.sharedInstance.addSubscriptions(subscriptions,
        closeSubscription: false, eventCallBack: (event, relay) async {
      if (!ChatCoreManager().isAcceptedEventKind(event.kind)) return;
      if (event.kind == 1059) {
        Event? innerEvent = await decodeNip17Event(event);
        if (innerEvent == null || EventCache.sharedInstance.cacheIds.contains(innerEvent.id)) {
          return;
        }
        EventCache.sharedInstance.receiveEvent(innerEvent, relay);
        if (!inBlockList(innerEvent.pubkey) &&
            ChatCoreManager().isAcceptedEventKind(innerEvent.kind)) {
          updateFriendMessageTime(innerEvent.createdAt, relay);
          switch (innerEvent.kind) {
            case 25050:
              handleCallEvent(innerEvent, relay);
              break;
            default:
              LogUtils.v(() => 'contacts unhandled message ${innerEvent.toJson()}');
              break;
          }
        }
      }
    }, eoseCallBack: (requestId, ok, relay, unCompletedRelays) {
      offlinePrivateMessageFinish[relay] = true;
      if (ok.status) {
        updateFriendMessageTime(currentUnixTimestampSeconds() - 1, relay);
      }
    });
  }

  Future<bool> connectUserDMRelays(String pubkey) async {
    UserDBISAR? toUser = await Account.sharedInstance.getUserInfo(pubkey);
    List<String>? dmRelays = toUser?.dmRelayList ?? [];
    List<String>? inboxRelays = toUser?.inboxRelayList ?? [];
    var relays = [...dmRelays, ...inboxRelays];
    if (relays.isEmpty) return true;
    for (var relay in relays) {
      if (Connect.sharedInstance.webSockets[relay]?.connectStatus == 1) return true;
    }
    await Connect.sharedInstance.connectRelays(relays, relayKind: RelayKind.temp);
    for (var relay in relays) {
      int? status = Connect.sharedInstance.webSockets[relay]?.connectStatus;
      if (status == 1 || status == 0) return true;
    }
    return false;
  }

  Future<void> closeUserDMRelays(String pubkey) async {
    UserDBISAR? toUser = await Account.sharedInstance.getUserInfo(pubkey);
    List<String>? dmRelays = toUser?.dmRelayList ?? [];
    List<String>? inboxRelays = toUser?.inboxRelayList ?? [];
    var relays = [...dmRelays, ...inboxRelays];
    relays.addAll(toUser?.relayList ?? []);
    if (relays.isNotEmpty) {
      await Connect.sharedInstance.closeTempConnects(relays);
    }
  }

  Future<void> closeUserGeneralRelays(String pubkey) async {
    UserDBISAR? toUser = await Account.sharedInstance.getUserInfo(pubkey);
    List<String>? relays = toUser?.relayList;
    if (relays?.isNotEmpty == true) {
      await Connect.sharedInstance.closeTempConnects(relays!);
    }
  }

  void updateFriendMessageTime(int eventTime, String relay) {
    /// set friendMessageUntil friendMessageSince
    if (Relays.sharedInstance.relays.containsKey(relay)) {
      Relays.sharedInstance.setCommonMessageUntil(eventTime, relay);
    } else {
      Relays.sharedInstance.relays[relay] =
          RelayDBISAR(url: relay, commonMessagesUntil: eventTime, commonMessagesSince: eventTime);
    }
    if (offlinePrivateMessageFinish[relay] == true) {
      Relays.sharedInstance.syncRelaysToDB(r: relay);
    }
  }
}
