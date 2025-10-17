import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:noscall/core/core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../core/common/utils/log_utils.dart';
import '../core/account/account.dart';
import '../core/account/model/userDB_isar.dart';
import '../core/common/database/db_isar.dart';
import '../core/common/thread/threadPoolManager.dart';
import '../core/account/relays.dart';
import '../core/call/messages/messages.dart';
import '../core/core-manager.dart';
import '../core/common/config/call_core_init_config.dart';
import '../call/call_manager.dart';
import 'package:nostr_core_dart/nostr.dart';

enum LoginMethod {
  privateKey('privateKey'),
  amber('amber'),
  bunker('bunker');

  const LoginMethod(this.value);
  final String value;

  static LoginMethod fromString(String value) {
    for (LoginMethod method in LoginMethod.values) {
      if (method.value == value) {
        return method;
      }
    }
    throw ArgumentError('Unknown login method: $value');
  }

  SignerApplication getSignerApplication() {
    switch (this) {
      case LoginMethod.privateKey:
        return SignerApplication.none;
      case LoginMethod.amber:
        return SignerApplication.androidSigner;
      case LoginMethod.bunker:
        return SignerApplication.remoteSigner;
    }
  }
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _userKey = 'noscall_user_pubkey';
  static const String _loginMethodKey = 'noscall_login_method';
  static const String _userBunkerUrlKey = 'noscall_user_bunker_url';

  String? _currentUserPubkey;
  String? _currentUserNpub;
  LoginMethod? _currentLoginMethod;

  bool isAuthenticated = false;

  final StreamController<bool> _authStateController = StreamController<bool>.broadcast();

  // Getters
  String? get currentUserPubkey => _currentUserPubkey;
  String? get currentUserNpub => _currentUserNpub;
  Stream<bool> get authStateStream => _authStateController.stream;

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final pubkey = prefs.getString(_userKey);
      if (pubkey == null) return;

      final loginMethodString = prefs.getString(_loginMethodKey);
      if (loginMethodString == null) return;

      final loginMethod = LoginMethod.fromString(loginMethodString);

      _currentUserPubkey = pubkey;
      _currentUserNpub = _pubkeyToNpub(_currentUserPubkey!);
      _currentLoginMethod = loginMethod;

      await _initDatabase(pubkey);

      await _autoLoginWithMethod(pubkey, loginMethod);

      await _initChatCore(pubkey);

      LogUtils.i(() => 'Auth service initialized. Method: ${loginMethod.value}');
    } catch (e) {
      LogUtils.e(() => 'Failed to initialize auth service: $e');
    }
  }

  Future<void> _autoLoginWithMethod(String pubkey, LoginMethod loginMethod) async {
    try {
      switch (loginMethod) {
        case LoginMethod.privateKey:
          await Account.sharedInstance.loginWithPubKey(pubkey, loginMethod.getSignerApplication());
          break;
        case LoginMethod.amber:
          if (Platform.isAndroid && await _isAmberInstalled()) {
            final signerApplication = loginMethod.getSignerApplication();
            await Account.sharedInstance.loginWithPubKey(pubkey, signerApplication);
            LogUtils.i(() => 'Auto-login with Amber successful');
          } else {
            LogUtils.w(() => 'Amber not available for auto-login');
          }
          break;
        case LoginMethod.bunker:
          final prefs = await SharedPreferences.getInstance();
          final bunkerUrl = prefs.getString(_userBunkerUrlKey);
          if (bunkerUrl != null) {
            await Account.sharedInstance.loginWithNip46URI(bunkerUrl);
            LogUtils.i(() => 'Auto-login with Bunker successful');
          } else {
            LogUtils.w(() => 'Bunker login requires URL, cannot auto-login');
          }
          break;
      }
    } catch (e) {
      LogUtils.e(() => 'Auto-login failed for method ${loginMethod.value}: $e');
      throw e;
    }
  }

  Future<bool> loginWithPrivateKey(String privateKey) async {
    try {
      String actualPrivateKey = privateKey;

      if (privateKey.startsWith('nsec')) {
        actualPrivateKey = _decodeNsec(privateKey);
        if (actualPrivateKey.isEmpty) {
          throw Exception('Failed to decode nsec format');
        }
      }

      if (actualPrivateKey.length != 64) {
        throw Exception('Private key must be 64 characters long');
      }

      final pubkey = Account.getPublicKey(actualPrivateKey);
      if (pubkey.isEmpty) {
        throw Exception('Failed to generate public key from private key');
      }

      await _initDatabase(pubkey);

      final userDB = await Account.sharedInstance.loginWithPriKey(actualPrivateKey);
      if (userDB == null) {
        throw Exception('Login failed');
      }

      await _initChatCore(pubkey);

      await _saveUserInfo(pubkey, LoginMethod.privateKey);

      LogUtils.i(() => 'Successfully logged in with private key. Pubkey: ${pubkey.substring(0, 8)}...');
      return true;
    } catch (e) {
      LogUtils.e(() => 'Private key login failed: $e');
      return false;
    }
  }

  Future<void> loginWithAmber() async {
    if (!Platform.isAndroid) {
      throw Exception('Amber login is only available on Android');
    }

    bool isInstalled = await _isAmberInstalled();
    if (!isInstalled) {
      throw Exception('Amber app is not installed');
    }

    String pubkey = await _getAmberPublicKey() ?? '';
    if (pubkey.startsWith('npub')) {
      pubkey = UserDBISAR.decodePubkey(pubkey) ?? '';
    }
    if (pubkey.isEmpty) {
      throw Exception('Failed to get public key from Amber');
    }

    await _initDatabase(pubkey);

    final userDB = await Account.sharedInstance.loginWithPubKey(
      pubkey,
      LoginMethod.amber.getSignerApplication(),
    );
    if (userDB == null) {
      throw Exception('Login failed');
    }

    await _initChatCore(pubkey);

    await _saveUserInfo(pubkey, LoginMethod.amber);

    LogUtils.i(() => 'Successfully logged in with Amber. Pubkey: ${pubkey.substring(0, 8)}...');
  }

  Future<bool> loginWithBunkerUrl(String bunkerUrl) async {
    try {
      if (bunkerUrl.trim().isEmpty) {
        throw Exception('Bunker URL cannot be empty');
      }

      // Get public key from Bunker URL
      final pubkey = await Account.getPublicKeyWithNIP46URI(bunkerUrl);
      if (pubkey.isEmpty) {
        throw Exception('Failed to get public key from Bunker URL');
      }

      await _initDatabase(pubkey);

      final userDB = await Account.sharedInstance.loginWithNip46URI(bunkerUrl);

      if (userDB == null) {
        throw Exception('Login failed');
      }

      await _initChatCore(pubkey);

      await _saveUserInfo(pubkey, LoginMethod.bunker, bunkerUrl);

      LogUtils.i(() => 'Successfully logged in with Bunker URL. Pubkey: ${pubkey.substring(0, 8)}...');
      return true;
    } catch (e) {
      LogUtils.e(() => 'Bunker URL login failed: $e');
      return false;
    }
  }

  Future<void> _initDatabase(String pubkey) async {
    try {
      if (pubkey.isEmpty) return;

      await ThreadPoolManager.sharedInstance.initialize();

      await DBISAR.sharedInstance.open(pubkey);

      await Relays.sharedInstance.init();

      Messages.sharedInstance.init();

      LogUtils.i(() => 'Database and services initialized for pubkey: ${pubkey.substring(0, 8)}...');
    } catch (e) {
      LogUtils.e(() => 'Failed to initialize database: $e');
      rethrow;
    }
  }

  Future<void> _initChatCore(String pubkey) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final databasePath = '${appDir.path}/noscall_$pubkey';

      final config = ChatCoreInitConfig(
        pubkey: pubkey,
        databasePath: databasePath,
        encryptionPassword: _generateEncryptionPassword(pubkey),
        isLite: false,
        contactUpdatedCallBack: _onContactUpdated,
        allowSendNotification: true,
        allowReceiveNotification: true,
      );
      await ChatCoreManager().initChatCoreWithConfig(config);

      await CallKitManager().initRTC();

      isAuthenticated = true;
      LogUtils.i(() => 'Chat core initialized successfully for pubkey: ${pubkey.substring(0, 8)}...');
    } catch (e) {
      LogUtils.e(() => 'Failed to initialize chat core: $e');
      rethrow;
    }
  }

  String _generateEncryptionPassword(String pubkey) {
    return 'noscall_${pubkey.substring(0, 16)}';
  }

  void _onContactUpdated() {
    LogUtils.i(() => 'Contact list updated');
  }

  String generatePrivateKey() {
    try {
      final random = Random.secure();
      final randomBytes = List<int>.generate(32, (i) => random.nextInt(256));
      return randomBytes.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
    } catch (e) {
      LogUtils.e(() => 'Failed to generate private key: $e');
      return 'a'.padRight(64, '0');
    }
  }

  Future<void> _saveUserInfo(String pubkey, LoginMethod loginMethod, [String bunkerUrl = '']) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, pubkey);
      await prefs.setString(_loginMethodKey, loginMethod.value);
      await prefs.setString(_userBunkerUrlKey, bunkerUrl);

      _currentUserPubkey = pubkey;
      _currentUserNpub = _pubkeyToNpub(pubkey);
      _currentLoginMethod = loginMethod;

      _authStateController.add(true);

      LogUtils.i(() => 'User info saved successfully with login method: ${loginMethod.value}');
    } catch (e) {
      LogUtils.e(() => 'Failed to save user info: $e');
    }
  }

  Future<void> logout() async {
    try {
      await _logout();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      await prefs.remove(_loginMethodKey);

      _currentUserPubkey = null;
      _currentUserNpub = null;
      _currentLoginMethod = null;

      _authStateController.add(false);
      isAuthenticated = false;

      LogUtils.i(() => 'User logged out successfully');
    } catch (e) {
      LogUtils.e(() => 'Failed to logout: $e');
    }
  }

  /// Internal logout method
  Future<void> _logout() async {
    try {
      await Account.sharedInstance.logout();
      LogUtils.i(() => 'Internal logout completed');
    } catch (e) {
      LogUtils.e(() => 'Failed to perform internal logout: $e');
    }
  }

  String _decodeNsec(String nsec) {
    try {
      if (nsec.startsWith('nsec1') && nsec.length > 5) {
        return Nip19.decodePrivkey(nsec);
      }
      return '';
    } catch (e) {
      LogUtils.e(() => 'Failed to decode nsec: $e');
      return '';
    }
  }

  String _pubkeyToNpub(String pubkey) {
    try {
      return Nip19.encodePubkey(pubkey);
    } catch (e) {
      LogUtils.e(() => 'Failed to convert pubkey to npub: $e');
      return pubkey;
    }
  }

  Map<String, String> getUserInfo() {
    return {
      'pubkey': _currentUserPubkey ?? '',
      'npub': _currentUserNpub ?? '',
      'loginMethod': _currentLoginMethod?.value ?? '',
    };
  }

  UserDBISAR? getCurrentUserDB() {
    return Account.sharedInstance.me;
  }

  bool get isUserLoggedIn => Account.sharedInstance.me != null;

  String? getCurrentPubkey() {
    return Account.sharedInstance.currentPubkey;
  }

  Future<bool> _isAmberInstalled() async {
    return CoreMethodChannel.isInstalledAmber();
  }

  Future<String?> _getAmberPublicKey() async {
    return ExternalSignerTool.getPubKey();
  }

  void dispose() {
    _authStateController.close();
  }
}