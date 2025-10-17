import 'dart:convert';
import 'package:nostr_core_dart/nostr.dart';
import 'package:isar/isar.dart';

import '../account.dart';

part 'userDB_isar.g.dart';

extension UserDBISARExtensions on UserDBISAR {
  UserDBISAR withGrowableLevels() => this
    ..blockedList = blockedList?.toList()
    ..followingList = followingList?.toList()
    ..followersList = followersList?.toList()
    ..relayList = relayList?.toList()
    ..dmRelayList = dmRelayList?.toList()
    ..inboxRelayList = inboxRelayList?.toList()
    ..outboxRelayList = outboxRelayList?.toList();
}

@collection
class UserDBISAR {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  String pubKey;

  String? encryptedPrivKey;
  String? privkey;
  String? defaultPassword;

  String? name;
  String? nickName;
  String? mainRelay;

  /// dns
  String? dns;

  /// zap url
  String? lnurl;

  /// profile badges
  String? badges;

  /// metadata infos
  String? gender;
  String? area;
  String? about;
  String? picture;

  String? banner;

  /// private chat
  String? aliasPubkey;
  String? toAliasPubkey;
  String? toAliasPrivkey;

  /// lists for me
  String? friendsList;

  List<String>? blockedList; // blocked users list
  List<String>? blockedHashTags; // blocked hash tags
  List<String>? blockedWords; // blocked words
  List<String>? blockedThreads; // blocked threads

  List<String>? followingList;
  List<String>? followersList;
  List<String>? relayList; // relay list
  List<String>? dmRelayList; // relay list
  List<String>? inboxRelayList; // inbox relay list
  List<String>? outboxRelayList; // outbox relay list

  /// list updated time
  int lastFriendsListUpdatedTime;
  int lastBlockListUpdatedTime;
  int lastRelayListUpdatedTime;
  int lastFollowingListUpdatedTime;
  int lastDMRelayListUpdatedTime;

  bool? mute;

  int lastUpdatedTime;

  // banner, website, display_name
  String? otherField;
  // nostr wallet connect URI
  String? nwcURI;

  // nip46
  String? remoteSignerURI;
  String? clientPrivateKey;
  String? remotePubkey;

  String? settings;

  UserDBISAR({
    this.pubKey = '',
    this.encryptedPrivKey = '',
    this.privkey = '',
    this.defaultPassword = '',
    this.name = '',
    this.nickName = '',
    this.mainRelay = '',
    this.dns = '',
    this.lnurl = '',
    this.badges = '',
    this.gender = '',
    this.area = '',
    this.about = '',
    this.picture = '',
    this.banner = '',
    this.aliasPubkey = '',
    this.toAliasPubkey = '',
    this.toAliasPrivkey = '',
    this.friendsList,
    this.blockedList,
    this.blockedHashTags,
    this.blockedThreads,
    this.blockedWords,
    this.followersList,
    this.followingList,
    this.relayList,
    this.dmRelayList,
    this.inboxRelayList,
    this.outboxRelayList,
    this.mute = false,
    this.lastUpdatedTime = 0,
    this.lastBlockListUpdatedTime = 0,
    this.lastFriendsListUpdatedTime = 0,
    this.lastRelayListUpdatedTime = 0,
    this.lastFollowingListUpdatedTime = 0,
    this.lastDMRelayListUpdatedTime = 0,
    this.otherField = '{}',
    this.nwcURI,
    this.settings,
    this.clientPrivateKey,
    this.remoteSignerURI,
    this.remotePubkey,
  });

  static UserDBISAR fromMap(Map<String, Object?> map) {
    return _userInfoFromMap(map);
  }

  static String? decodePubkey(String pubkey) {
    try {
      return Nip19.decodePubkey(pubkey);
    } catch (e) {
      return null;
    }
  }

  static String? decodePrivkey(String privkey) {
    try {
      return Nip19.decodePrivkey(privkey);
    } catch (e) {
      return null;
    }
  }

  @ignore
  String? _encodedPubkey;

  /// nip19 encode
  @ignore
  String get encodedPubkey {
    if (_encodedPubkey != null) return _encodedPubkey!;
    _encodedPubkey = Nip19.encodePubkey(pubKey);
    return _encodedPubkey!;
  }

  void updateEncodedPubkey(String value) {
    _encodedPubkey = value;
  }

  @ignore
  String get encodedPrivkey {
    if (pubKey == Account.sharedInstance.currentPubkey) {
      return Nip19.encodePrivkey(Account.sharedInstance.currentPrivkey);
    }
    return '';
  }

  @ignore
  String get shortEncodedPubkey {
    String k = encodedPubkey;
    if (k.length < 7) return k;
    final String start = k.substring(0, 6);
    final String end = k.substring(k.length - 6);

    return '$start:$end';
  }

  @ignore
  String get lnAddress {
    return lnurl ?? '';
  }

  @ignore
  NostrWalletConnection? get nwc {
    return NostrWalletConnection.fromURI(nwcURI);
  }

  static List<String> decodeStringList(String list) {
    try {
      if (list.isNotEmpty && list != 'null' && list != '[]') {
        List<dynamic> result = jsonDecode(list);
        return result.map((e) => e.toString()).toList();
      }
    } catch (e) {
      return [];
    }
    return [];
  }

  String displayName() {
    final nickName = (this.nickName ?? '').trim();
    final name = (this.name ?? '').trim();
    if (nickName.isNotEmpty) return nickName;
    if (name.isNotEmpty) return name;
    return shortEncodedPubkey;
  }
}

class NostrWalletConnection {
  String server; // server pubkey
  List<String> relays;
  String secret;
  String? lud16;

  NostrWalletConnection(this.server, this.relays, this.secret, this.lud16);

  static NostrWalletConnection? fromURI(String? uri) {
    if (uri != null && uri.startsWith('nostr+walletconnect://')) {
      var decodedUri = Uri.parse(uri);
      var server = decodedUri.host;
      var queryParams = decodedUri.queryParametersAll;
      var relays = queryParams['relay'] ?? [];
      var secret = queryParams['secret']?.first ?? '';
      var lud16 = queryParams['lud16']?.first;
      return NostrWalletConnection(server, relays, secret, lud16);
    }
    return null;
  }
}

UserDBISAR _userInfoFromMap(Map<String, dynamic> map) {
  return UserDBISAR(
    pubKey: map['pubKey'].toString(),
    encryptedPrivKey: map['encryptedPrivKey'].toString(),
    defaultPassword: map['defaultPassword'].toString(),
    name: map['name'].toString(),
    nickName: map['nickName'].toString(),
    mainRelay: map['mainRelay'].toString(),
    dns: map['dns'].toString(),
    lnurl: map['lnurl'].toString(),
    badges: map['badges'].toString(),
    gender: map['gender'].toString(),
    area: map['area'].toString(),
    about: map['about'].toString(),
    picture: map['picture'].toString(),
    banner: map['banner'].toString(),
    friendsList: map['friendsList'].toString(),
    blockedList: UserDBISAR.decodeStringList(map['blockedList'].toString()),
    followingList: UserDBISAR.decodeStringList(map['followingList'].toString()),
    followersList: UserDBISAR.decodeStringList(map['followersList'].toString()),
    relayList: UserDBISAR.decodeStringList(map['relayList'].toString()),
    dmRelayList: UserDBISAR.decodeStringList(map['dmRelayList'].toString()),
    aliasPubkey: map['aliasPubkey'],
    mute: map['mute'],
    lastUpdatedTime: map['lastUpdatedTime'],
    lastBlockListUpdatedTime: map['lastBlockListUpdatedTime'] ?? 0,
    lastFriendsListUpdatedTime: map['lastFriendsListUpdatedTime'] ?? 0,
    lastRelayListUpdatedTime: map['lastRelayListUpdatedTime'] ?? 0,
    lastFollowingListUpdatedTime: map['lastRelayListUpdatedTime'] ?? 0,
    lastDMRelayListUpdatedTime: map['lastDMRelayListUpdatedTime'] ?? 0,
    otherField: map['otherField']?.toString(),
    nwcURI: map['nwcURI']?.toString(),
    remoteSignerURI: map['remoteSignerURI']?.toString(),
    clientPrivateKey: map['clientPrivateKey']?.toString(),
    remotePubkey: map['remotePubkey']?.toString(),
    settings: map['settings']?.toString(),
  );
}
