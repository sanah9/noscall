import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:pointycastle/export.dart';
import 'package:convert/convert.dart';

import 'package:nostr_core_dart/nostr.dart';

import 'package:noscall/core/call/contacts/contacts.dart';
import 'package:noscall/core/common/network/connect.dart';
import 'package:noscall/core/common/network/event_cache.dart';
import 'package:noscall/core/common/utils/log_utils.dart';
import 'account_nip46.dart';
import 'account_profile.dart';
import 'account_dependencies.dart';
import 'account_secret_store.dart';
import 'model/user_db_isar.dart';
import 'relays.dart';

enum NIP46ConnectionStatus {
  connected,
  disconnected,
  connecting,
  waitingForSigning,
  approvedSigning,
}

typedef AccountUpdateCallback = void Function();
typedef NIP46CommandResultCallback = void Function(NIP46CommandResult result);
typedef NIP46ConnectionStatusCallback =
    void Function(NIP46ConnectionStatus status);

class UserDBISARNotifier extends ValueNotifier<UserDBISAR> {
  UserDBISARNotifier(super.value);

  void refresh() => notifyListeners();
}

class Account {
  static AccountPersistence _persistence = const DefaultAccountPersistence();
  static AccountSecretStore _secretStore =
      const MethodChannelAccountSecretStore();

  /// singleton
  Account._internal();
  factory Account() => sharedInstance;
  static final Account sharedInstance = Account._internal();

  UserDBISAR? me;
  String currentPubkey = '';
  String currentPrivkey = '';
  Timer? timer;

  RemoteSignerConnection? currentRemoteConnection;
  RemoteSignerConnection? tempRemoteConnection;

  Map<String, Completer<NIP46CommandResult>> resultCompleters = {};
  NIP46CommandResultCallback? nip46commandResultCallback;
  NIP46ConnectionStatusCallback? nip46connectionStatusCallback;

  // Map<String, UserDB> userCache = {};
  Map<String, UserDBISARNotifier> userCache = {};

  List<String> pQueue = [];
  List<Event> unsentNIP46EventQueue = [];
  bool _coreBindingsInitialized = false;
  bool _sessionInitialized = false;
  String _initializedSessionPubkey = '';

  AccountUpdateCallback? relayListUpdateCallback;
  AccountUpdateCallback? dmRelayListUpdateCallback;
  AccountUpdateCallback? contactListUpdateCallback;
  AccountUpdateCallback? channelListUpdateCallback;
  AccountUpdateCallback? groupListUpdateCallback;
  AccountUpdateCallback? relayGroupListUpdateCallback;

  static void setTestDependencies({
    AccountPersistence? persistence,
    AccountSecretStore? secretStore,
  }) {
    _persistence = persistence ?? const DefaultAccountPersistence();
    _secretStore = secretStore ?? const MethodChannelAccountSecretStore();
  }

  static void clearTestDependencies() {
    _persistence = const DefaultAccountPersistence();
    _secretStore = const MethodChannelAccountSecretStore();
  }

  Future<void> init() async {
    _ensureCoreBindingsInitialized();
    if (!hasAuthenticatedSession) return;

    await _restartSessionIfNeeded();
    if (_sessionInitialized) return;

    await Connect.sharedInstance.init();
    startHeartBeat();
    _resetUserCache();
    await _loadAllUsers();
    await loginSuccess();
    _sessionInitialized = true;
    _initializedSessionPubkey = currentPubkey;
  }

  bool get hasAuthenticatedSession =>
      me != null && currentPubkey.isNotEmpty && currentPrivkey.isNotEmpty;

  bool get isSessionInitialized =>
      _sessionInitialized && _initializedSessionPubkey == currentPubkey;

  void _ensureCoreBindingsInitialized() {
    if (_coreBindingsInitialized) return;
    initNIP46Callback();
    _coreBindingsInitialized = true;
  }

  Future<void> _restartSessionIfNeeded() async {
    if (!_sessionInitialized || _initializedSessionPubkey == currentPubkey) {
      return;
    }
    await _shutdownSessionRuntime();
    _resetSessionState(keepIdentity: true);
  }

  Future<void> _shutdownSessionRuntime() async {
    timer?.cancel();
    timer = null;
    disposeProfileConnectListeners();
    disposeNip46ConnectListeners();
    await Contacts.sharedInstance.dispose();
    await Connect.sharedInstance.closeAllConnects();
  }

  void _resetUserCache() {
    userCache.clear();
    pQueue.clear();
  }

  void _resetSessionState({required bool keepIdentity}) {
    _sessionInitialized = false;
    _initializedSessionPubkey = '';
    currentRemoteConnection = null;
    tempRemoteConnection = null;
    resultCompleters.clear();
    unsentNIP46EventQueue.clear();
    _resetUserCache();
    Contacts.sharedInstance.allContacts.clear();
    Relays.sharedInstance.relays.clear();
    EventCache.sharedInstance.cacheIds.clear();
    contactListUpdateCallback = null;
    if (keepIdentity) return;
    me = null;
    currentPubkey = '';
    currentPrivkey = '';
  }

  Future<void> _activateAuthenticatedUser(
    UserDBISAR userDB,
    String privkey, {
    bool persistUser = false,
  }) async {
    me = userDB;
    currentPubkey = userDB.pubKey;
    currentPrivkey = privkey;
    userDB.privkey = privkey;
    updateOrCreateUserNotifier(currentPubkey, userDB);
    _sessionInitialized = false;
    _initializedSessionPubkey = '';
    if (persistUser) {
      await saveUserToDB(userDB);
    }
  }

  void startHeartBeat() {
    if (timer == null || timer!.isActive == false) {
      timer = Timer.periodic(const Duration(seconds: 15), (Timer t) async {
        await syncProfilesFromRelay();
      });
    }
  }

  Future<void> _loadAllUsers() async {
    final users = await _persistence.loadAllUsers();
    for (var user in users) {
      user = user.withGrowableLevels();
      updateOrCreateUserNotifier(user.pubKey, user);
    }
  }

  Future<void> syncMe() async {
    await saveUserToDB(me!);
  }

  static Future<void> saveUserToDB(UserDBISAR user) async {
    await _persistence.saveUser(user);
  }

  Future<String?> _readSecret(String key) async {
    try {
      return await _secretStore.read(key);
    } on MissingPluginException {
      return null;
    } on PlatformException catch (e) {
      LogUtils.e(() => 'Failed to read account secret: ${e.message}');
      return null;
    }
  }

  Future<bool> _writeSecret(String key, String value) async {
    try {
      await _secretStore.write(key, value);
      return true;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (e) {
      LogUtils.e(() => 'Failed to write account secret: ${e.message}');
      return false;
    }
  }

  Future<void> _writeSecretRequired(String key, String value) async {
    if (await _writeSecret(key, value)) return;
    throw AccountSecretStoreUnavailableException(key);
  }

  Future<String?> _privateKeyPasswordFor(UserDBISAR user) async {
    final key = AccountSecretKeys.privateKeyPassword(user.pubKey);
    final storedPassword = await _readSecret(key);
    if (storedPassword != null && storedPassword.isNotEmpty) {
      return storedPassword;
    }

    final legacyPassword = user.defaultPassword;
    if (legacyPassword == null || legacyPassword.isEmpty) return null;

    await _writeSecretRequired(key, legacyPassword);
    user.defaultPassword = '';
    await saveUserToDB(user);
    return legacyPassword;
  }

  Future<void> _persistPrivateKeyPassword(
    UserDBISAR user,
    String password,
  ) async {
    final key = AccountSecretKeys.privateKeyPassword(user.pubKey);
    await _writeSecretRequired(key, password);
    user.defaultPassword = '';
  }

  Future<String?> remoteSignerClientPrivateKeyFor(UserDBISAR? user) async {
    if (user == null) return null;
    final key = AccountSecretKeys.remoteSignerClientPrivateKey(user.pubKey);
    final storedClientKey = await _readSecret(key);
    if (storedClientKey != null && storedClientKey.isNotEmpty) {
      return storedClientKey;
    }

    final legacyClientKey = user.clientPrivateKey;
    if (legacyClientKey == null || legacyClientKey.isEmpty) return null;

    await _writeSecretRequired(key, legacyClientKey);
    user.clientPrivateKey = null;
    await saveUserToDB(user);
    return legacyClientKey;
  }

  Future<void> persistRemoteSignerClientPrivateKey(
    UserDBISAR user,
    String clientPrivateKey,
  ) async {
    final key = AccountSecretKeys.remoteSignerClientPrivateKey(user.pubKey);
    await _writeSecretRequired(key, clientPrivateKey);
    user.clientPrivateKey = null;
  }

  bool isValidPubKey(String pubKey) {
    final pattern = RegExp(r'^[a-fA-F0-9]{64}$');
    return pattern.hasMatch(pubKey);
  }

  /// Strips optional 66-char secp256k1 `02` prefix form used by some callers.
  String _normalizePubkeyString(String pubkey) {
    if (pubkey.length == 66 && pubkey.startsWith('02')) {
      return pubkey.replaceFirst('02', '');
    }
    return pubkey;
  }

  FutureOr<UserDBISAR?> getUserInfo(String pubkey) {
    pubkey = _normalizePubkeyString(pubkey);
    if (!isValidPubKey(pubkey)) return null;

    UserDBISAR? user = userCache[pubkey]?.value;
    if (user != null) {
      _addToPQueue(user);
      return user;
    }

    Completer<UserDBISAR?> completer = Completer();
    getUserFromDB(pubkey: pubkey).then((user) {
      if (user != null) {
        updateOrCreateUserNotifier(pubkey, user);
        _addToPQueue(user);
      }
      completer.complete(user);
    });
    return completer.future;
  }

  Future<Map<String, UserDBISAR>> getUserInfos(List<String> pubkeys) async {
    Map<String, UserDBISAR> result = {};
    for (var p in pubkeys) {
      UserDBISAR? user = await getUserInfo(p);
      if (user != null) result[p] = user;
    }
    return result;
  }

  /// Resolves profile via [getUserInfo] without awaiting: sync [UserDBISAR]
  /// is wrapped in a new notifier; on [Future], uses a pubkey-only placeholder
  /// until [updateOrCreateUserNotifier] runs from the completed [getUserInfo].
  ValueNotifier<UserDBISAR> getUserNotifier(String pubkey) {
    final normalized = _normalizePubkeyString(pubkey);
    if (!isValidPubKey(normalized)) {
      return userCache.putIfAbsent(
        pubkey,
        () => UserDBISARNotifier(UserDBISAR(pubKey: pubkey)),
      );
    }
    return userCache.putIfAbsent(normalized, () {
      final FutureOr<UserDBISAR?> info = getUserInfo(normalized);
      if (info is Future<UserDBISAR?>) {
        return UserDBISARNotifier(UserDBISAR(pubKey: normalized));
      }
      final UserDBISAR? user = info;
      return UserDBISARNotifier(user ?? UserDBISAR(pubKey: normalized));
    });
  }

  void _addToPQueue(UserDBISAR user) {
    if (user.lastUpdatedTime != 0) return;
    final pubkey = user.pubKey;
    if (pubkey.isNotEmpty && !pQueue.contains(pubkey)) {
      pQueue.add(pubkey);
    }
  }

  Future<UserDBISAR?> _searchUserFromDB(String pubkey) async {
    UserDBISAR? user = await _persistence.findUserByPubkey(pubkey);
    if (user != null) {
      user = user.withGrowableLevels();
      updateOrCreateUserNotifier(user.pubKey, user);
    }
    return user;
  }

  Future<UserDBISAR?> getUserFromDB({
    String pubkey = '',
    String privkey = '',
  }) async {
    if (privkey.isNotEmpty) {
      pubkey = Keychain.getPublicKey(privkey);
    }
    if (pubkey.isNotEmpty) {
      UserDBISAR? db = await _searchUserFromDB(pubkey);
      if (db != null) {
        return db;
      } else {
        db = UserDBISAR(pubKey: pubkey);
        db.name = db.shortEncodedPubkey;
        await saveUserToDB(db);
        return db;
      }
    }
    return null;
  }

  Future<UserDBISAR?> loginWithPubKey(
    String pubkey,
    SignerApplication signerApplication,
  ) async {
    UserDBISAR? userDB = await getUserFromDB(pubkey: pubkey);
    if (userDB != null) {
      await _activateAuthenticatedUser(
        userDB,
        SignerHelper.getSignerApplicationKey(signerApplication, ''),
        persistUser: true,
      );
    }
    return userDB;
  }

  Future<UserDBISAR?> loginWithPubKeyAndPassword(String pubkey) async {
    UserDBISAR? db = await _searchUserFromDB(pubkey);
    if (db == null) return null;
    if (db.remoteSignerURI != null) {
      return await loginWithNip46Pubkey(pubkey);
    }
    final defaultPassword = await _privateKeyPasswordFor(db);
    if (db.encryptedPrivKey != null &&
        db.encryptedPrivKey!.isNotEmpty &&
        defaultPassword != null &&
        defaultPassword.isNotEmpty) {
      String encryptedPrivKey = db.encryptedPrivKey!;
      Uint8List privkey = decryptPrivateKey(
        hexToBytes(encryptedPrivKey),
        defaultPassword,
      );
      if (Keychain.getPublicKey(bytesToHex(privkey)) == pubkey) {
        await _activateAuthenticatedUser(db, bytesToHex(privkey));
        return db;
      }
    }
    return null;
  }

  Future<UserDBISAR?> loginWithPriKey(String privkey) async {
    String pubkey = Keychain.getPublicKey(privkey);
    UserDBISAR? db = await _searchUserFromDB(pubkey);

    /// insert a new account
    db ??= UserDBISAR();
    db.pubKey = pubkey;
    var password = await _privateKeyPasswordFor(db);
    if (password == null || password.isEmpty) {
      password = generateStrongPassword(16);
    }
    Uint8List enPrivkey = encryptPrivateKey(hexToBytes(privkey), password);
    db.encryptedPrivKey = bytesToHex(enPrivkey);
    await _persistPrivateKeyPassword(db, password);
    await saveUserToDB(db);
    await _activateAuthenticatedUser(db, privkey);
    return db;
  }

  static Future<bool> checkDNS(DNS dns) async {
    String? pubkey = await getDNSPubkey(dns.name, dns.domain);
    return (pubkey != null && pubkey == dns.pubkey);
  }

  static Future<String?> getDNSPubkey(String name, String domain) async {
    try {
      final response = await http.get(
        Uri.parse('https://$domain/.well-known/nostr.json?name=$name'),
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        return jsonResponse["names"][name];
      } else {
        return null;
      }
    } catch (e) {
      LogUtils.v(() => e.toString());
      return null;
    }
  }

  // static String signData(List data, String privateKey) {
  //   return Nip101.getSig(data, privateKey);
  // }

  static Uint8List encryptPrivateKeyWithMap(Map map) {
    return encryptPrivateKey(hexToBytes(map['privkey']), map['password']);
  }

  static Keychain generateNewKeychain() {
    return Keychain.generate();
  }

  static String getPublicKey(String privkey) {
    return Keychain.getPublicKey(privkey);
  }

  static Future<String> getPublicKeyWithNIP46URI(String uri) async {
    if (uri.startsWith('bunker://')) {
      RemoteSignerConnection remoteSignerConnection = Nip46.parseBunkerUri(uri);
      return remoteSignerConnection.remotePubkey;
    } else if (uri.startsWith('nostrconnect://')) {
      return await Account.sharedInstance.getPublicKeyWithNostrConnectURI(uri);
    }
    return '';
  }

  static Future<UserDBISAR> newAccount({Keychain? user}) async {
    user ?? Keychain.generate();
    String defaultPassword = generateStrongPassword(16);
    Uint8List enPrivkey = await compute(encryptPrivateKeyWithMap, {
      'privkey': user!.private,
      'password': defaultPassword,
    });
    UserDBISAR db = UserDBISAR();
    db.pubKey = user.public;
    db.encryptedPrivKey = bytesToHex(enPrivkey);
    await Account.sharedInstance._persistPrivateKeyPassword(
      db,
      defaultPassword,
    );
    await Account.saveUserToDB(db);
    return db;
  }

  Uint8List decryptPrivateKeyWithMap(Map map) {
    return decryptPrivateKey(hexToBytes(map['privkey']), map['password']);
  }

  Future<UserDBISAR> newAccountWithPassword(String password) async {
    var user = Keychain.generate();
    Uint8List enPrivkey = await compute(encryptPrivateKeyWithMap, {
      'privkey': user.private,
      'password': password,
    });
    UserDBISAR db = UserDBISAR();
    db.pubKey = user.public;
    db.encryptedPrivKey = bytesToHex(enPrivkey);
    await _persistPrivateKeyPassword(db, password);
    await saveUserToDB(db);
    return db;
  }

  List<Profile> toProfiles(List<String> pubkeys) {
    List<Profile> result = [];
    for (var p in pubkeys) {
      result.add(Profile(p, '', ''));
    }
    return result;
  }

  Future<UserDBISAR?> updatePassword(String password) async {
    UserDBISAR? db = await getUserFromDB(privkey: currentPrivkey);
    if (db != null) {
      Uint8List enPrivkey = encryptPrivateKey(
        hexToBytes(currentPrivkey),
        password,
      );
      db.encryptedPrivKey = bytesToHex(enPrivkey);
      await _persistPrivateKeyPassword(db, password);
      await saveUserToDB(db);
      return db;
    }
    return null;
  }

  Future<void> logout() async {
    await _shutdownSessionRuntime();
    _resetSessionState(keepIdentity: false);
    await _persistence.close();
  }

  static Future<Event?> loadAddress(String d, String pubkey) async {
    Completer<Event?> completer = Completer<Event?>();
    Filter f = Filter(d: [d], authors: [pubkey]);
    Connect.sharedInstance.addSubscription(
      [f],
      eventCallBack: (event, relay) async {
        if (!completer.isCompleted) completer.complete(event);
      },
      eoseCallBack: (requestId, status, relay, unRelays) {
        if (unRelays.isEmpty) {
          if (!completer.isCompleted) completer.complete(null);
        }
      },
    );
    return completer.future;
  }

  static Future<Event?> loadEvent(
    String eventId, {
    List<String>? relays,
  }) async {
    EventCache.sharedInstance.cacheIds.remove(eventId);
    Completer<Event?> completer = Completer<Event?>();
    Timer(const Duration(seconds: 15), () {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    });

    if (relays == null && Connect.sharedInstance.relays().isEmpty) return null;
    if (relays != null && relays.isNotEmpty) {
      await Connect.sharedInstance.connectRelays(
        relays,
        relayKind: RelayKind.temp,
      );
    }
    Filter f = Filter(ids: [eventId]);
    Connect.sharedInstance.addSubscription(
      [f],
      relays: relays,
      eventCallBack: (event, relay) async {
        if (!completer.isCompleted) completer.complete(event);
      },
      eoseCallBack: (requestId, status, relay, unRelays) {
        if (unRelays.isEmpty) {
          if (!completer.isCompleted) completer.complete(null);
        }
      },
    );
    return completer.future;
  }

  static String encodeProfile(String pubkey, List<String> relays) {
    String profile = Nip19.encodeShareableEntity(
      'nprofile',
      pubkey,
      relays,
      null,
      null,
    );
    return Nip21.encode(profile);
  }

  static Map<String, dynamic>? decodeProfile(String profile) {
    if (profile.startsWith('nostr:')) {
      profile = Nip21.decode(profile)!;
    }
    if (profile.startsWith('npub')) {
      return {'pubkey': Nip19.decodePubkey(profile), 'relays': []};
    } else if (profile.startsWith('nprofile')) {
      Map result = Nip19.decodeShareableEntity(profile);
      if (result['prefix'] == 'nprofile') {
        return {'pubkey': result['special'], 'relays': result['relays']};
      }
    }
    return null;
  }

  Future<Map<String, dynamic>> signEvent(Map<String, dynamic> json) async {
    if (json['pubkey'] == null) json['pubkey'] = currentPubkey;
    if (json['id'] == null) {
      var tags = (json['tags'] as List<dynamic>)
          .map((e) => (e as List<dynamic>).map((e) => e.toString()).toList())
          .toList();
      json['id'] = Event.processEventId(
        json['pubkey'],
        json['created_at'],
        json['kind'],
        tags,
        json['content'],
      );
    }
    Event event = await Event.fromJson(json, verify: false);
    if (SignerHelper.needSigner(currentPrivkey)) {
      final pubkey = Account.sharedInstance.currentPubkey;
      final privkey = Account.sharedInstance.currentPrivkey;
      event.sig =
          await SignerHelper.signMessage(event.id, pubkey, privkey) ?? '';
    } else {
      event.sig = event.getSignature(currentPrivkey);
    }
    assert(await event.isValid() == true);
    return event.toJson();
  }

  Future<String> encryptNip04(String content, String peer) async {
    return await Nip4.encryptContent(
      content,
      peer,
      currentPubkey,
      currentPrivkey,
    );
  }

  Future<String> decryptNip04(String content, String peer) async {
    return await Nip4.decryptContent(
      content,
      peer,
      currentPubkey,
      currentPrivkey,
    );
  }

  static Future<String> getSignatureWithSecret(
    String secret, [
    String? privkey,
  ]) async {
    privkey ??= Account.sharedInstance.currentPrivkey;
    if (SignerHelper.needSigner(privkey)) {
      final pubkey = Account.sharedInstance.currentPubkey;
      final privkey = Account.sharedInstance.currentPrivkey;
      return await SignerHelper.signMessage(secret, pubkey, privkey) ?? '';
    }
    final hexMessage = hex.encode(
      SHA256Digest().process(Uint8List.fromList(utf8.encode(secret))),
    );
    return Keychain(privkey).sign(hexMessage);
  }

  /// Helper method to update or create ValueNotifier for user cache
  void updateOrCreateUserNotifier(String pubkey, UserDBISAR user) {
    if (userCache.containsKey(pubkey)) {
      userCache[pubkey]!.value = user;
      userCache[pubkey]!.refresh();
    } else {
      userCache[pubkey] = UserDBISARNotifier(user);
    }
  }
}
