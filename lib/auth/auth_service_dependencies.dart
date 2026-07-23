import 'dart:io';

import 'package:noscall/call/call_kit_manager.dart';
import 'package:noscall/call/nostr_relay_push_service.dart';
import 'package:noscall/call/push_token_service.dart';
import 'package:noscall/core/common/config/call_core_init_config.dart';
import 'package:noscall/core/common/database/db_isar.dart';
import 'package:noscall/core/core_manager.dart';
import 'package:noscall/core/account/account.dart';
import 'package:noscall/core/account/account_nip46.dart';
import 'package:noscall/core/account/model/user_db_isar.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class AuthPreferencesStore {
  Future<String?> getString(String key);
  Future<void> setString(String key, String value);
  Future<void> remove(String key);
}

class SharedPreferencesAuthStore implements AuthPreferencesStore {
  const SharedPreferencesAuthStore();

  Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  @override
  Future<String?> getString(String key) async {
    return (await _prefs()).getString(key);
  }

  @override
  Future<void> setString(String key, String value) async {
    await (await _prefs()).setString(key, value);
  }

  @override
  Future<void> remove(String key) async {
    await (await _prefs()).remove(key);
  }
}

abstract class AuthAccountGateway {
  Future<UserDBISAR?> loginWithPubKeyAndPassword(String pubkey);
  Future<UserDBISAR?> loginWithPubKey(
    String pubkey,
    SignerApplication signerApplication,
  );
  Future<UserDBISAR?> loginWithPriKey(String privkey);
  Future<UserDBISAR?> loginWithNip46URI(String uri);
  Future<void> initAccount();
  Future<void> logout();
  String getPublicKey(String privkey);
  Future<String> getPublicKeyWithNIP46URI(String uri);
  UserDBISAR? get currentUser;
  String get currentPubkey;
}

class DefaultAuthAccountGateway implements AuthAccountGateway {
  const DefaultAuthAccountGateway();

  @override
  Future<void> initAccount() async {
    await Account.sharedInstance.init();
  }

  @override
  Future<UserDBISAR?> loginWithNip46URI(String uri) {
    return Account.sharedInstance.loginWithNip46URI(uri);
  }

  @override
  Future<UserDBISAR?> loginWithPriKey(String privkey) {
    return Account.sharedInstance.loginWithPriKey(privkey);
  }

  @override
  Future<UserDBISAR?> loginWithPubKey(
    String pubkey,
    SignerApplication signerApplication,
  ) {
    return Account.sharedInstance.loginWithPubKey(pubkey, signerApplication);
  }

  @override
  Future<UserDBISAR?> loginWithPubKeyAndPassword(String pubkey) {
    return Account.sharedInstance.loginWithPubKeyAndPassword(pubkey);
  }

  @override
  Future<void> logout() async {
    await Account.sharedInstance.logout();
  }

  @override
  UserDBISAR? get currentUser => Account.sharedInstance.me;

  @override
  String get currentPubkey => Account.sharedInstance.currentPubkey;

  @override
  String getPublicKey(String privkey) {
    return Account.getPublicKey(privkey);
  }

  @override
  Future<String> getPublicKeyWithNIP46URI(String uri) {
    return Account.getPublicKeyWithNIP46URI(uri);
  }
}

abstract class AuthDatabaseGateway {
  Future<void> open(String pubkey);
}

class DefaultAuthDatabaseGateway implements AuthDatabaseGateway {
  const DefaultAuthDatabaseGateway();

  @override
  Future<void> open(String pubkey) async {
    await DBISAR.sharedInstance.open(pubkey);
  }
}

abstract class AuthRuntimeGateway {
  Future<String> getApplicationDocumentsPath();
  Future<void> initChatCore(ChatCoreInitConfig config);
  Future<void> initRtc();
  Future<void> initRelayPush();
  Future<void> clearPushTokens();
}

class DefaultAuthRuntimeGateway implements AuthRuntimeGateway {
  const DefaultAuthRuntimeGateway();

  @override
  Future<void> clearPushTokens() async {
    await NostrRelayPushService().stopAndDelete();
  }

  @override
  Future<String> getApplicationDocumentsPath() async {
    return (await getApplicationDocumentsDirectory()).path;
  }

  @override
  Future<void> initChatCore(ChatCoreInitConfig config) async {
    await ChatCoreManager().initChatCoreWithConfig(config);
  }

  @override
  Future<void> initRtc() async {
    await CallKitManager.instance.initRTC();
  }

  @override
  Future<void> initRelayPush() async {
    await PushTokenService().initializePlatformPush();
    // iOS: upload any standard APNs token that arrived before login.
    await PushTokenService().uploadPendingStandardAPNsTokenIfNeeded();
    // iOS: upload any VoIP token that arrived before the user logged in.
    // PushKit only fires onVoIPTokenUpdated once per token lifetime, so we
    // must not rely on it firing again after login.
    await PushTokenService().uploadPendingVoIPTokenIfNeeded();
    await NostrRelayPushService().syncIfDue(force: true);
  }
}

abstract class AuthPlatformGateway {
  bool get isAndroid;
  Future<bool> isAmberInstalled();
  Future<String?> getAmberPublicKey();
}

class DefaultAuthPlatformGateway implements AuthPlatformGateway {
  const DefaultAuthPlatformGateway();

  @override
  Future<String?> getAmberPublicKey() {
    return ExternalSignerTool.getPubKey();
  }

  @override
  Future<bool> isAmberInstalled() {
    return CoreMethodChannel.isInstalledAmber();
  }

  @override
  bool get isAndroid => Platform.isAndroid;
}

class AuthServiceDependencies {
  const AuthServiceDependencies({
    this.preferences = const SharedPreferencesAuthStore(),
    this.account = const DefaultAuthAccountGateway(),
    this.database = const DefaultAuthDatabaseGateway(),
    this.runtime = const DefaultAuthRuntimeGateway(),
    this.platform = const DefaultAuthPlatformGateway(),
  });

  final AuthPreferencesStore preferences;
  final AuthAccountGateway account;
  final AuthDatabaseGateway database;
  final AuthRuntimeGateway runtime;
  final AuthPlatformGateway platform;
}
