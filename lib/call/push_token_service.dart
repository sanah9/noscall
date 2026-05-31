import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:unifiedpush/unifiedpush.dart';
import 'package:uuid/uuid.dart';

import 'package:noscall/call/nostr_push_payload_handler.dart';
import 'package:noscall/call/local_notification_service.dart';
import 'package:noscall/core/account/account.dart';
import 'package:noscall/core/common/storage/preferences_store.dart';
import 'package:noscall/core/common/utils/log_utils.dart';

class PushTokenRegistration {
  const PushTokenRegistration({
    required this.deviceRegistrationId,
    required this.callbackUrl,
  });

  final String deviceRegistrationId;
  final String callbackUrl;
}

class PushTokenRegistrationRequest {
  const PushTokenRegistrationRequest({
    required this.pubkey,
    required this.platform,
    required this.tokenType,
    required this.token,
    required this.deviceId,
    required this.appVersion,
  });

  final String pubkey;
  final String platform;
  final String tokenType;
  final String token;
  final String deviceId;
  final String appVersion;

  Map<String, dynamic> toJson() => {
        'pubkey': pubkey,
        'platform': platform,
        'tokenType': tokenType,
        'token': token,
        'deviceId': deviceId,
        'appVersion': appVersion,
      };
}

abstract interface class PushTokenApiClient {
  Future<PushTokenRegistration?> registerDevice(
    PushTokenRegistrationRequest request,
  );

  Future<bool> unregisterDevice(String deviceRegistrationId);
}

class HttpPushTokenApiClient implements PushTokenApiClient {
  HttpPushTokenApiClient({
    String? baseUrl,
    http.Client? client,
  })  : baseUrl =
            baseUrl ?? const String.fromEnvironment('NOSCALL_PUSH_SERVER_URL'),
        _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  @override
  Future<PushTokenRegistration?> registerDevice(
    PushTokenRegistrationRequest request,
  ) async {
    final normalizedBaseUrl = baseUrl.trim();
    if (normalizedBaseUrl.isEmpty) {
      LogUtils.w(
          () => 'PushTokenService: NOSCALL_PUSH_SERVER_URL is not configured');
      return null;
    }

    final uri = Uri.parse(
      '${normalizedBaseUrl.replaceFirst(RegExp(r'/$'), '')}/push/devices',
    );
    final response = await _client.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      LogUtils.w(() =>
          'PushTokenService: device registration failed: ${response.statusCode}');
      return null;
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final deviceRegistrationId =
        decoded['deviceRegistrationId']?.toString() ?? '';
    final callbackUrl = decoded['callbackUrl']?.toString() ?? '';
    if (deviceRegistrationId.isEmpty || callbackUrl.isEmpty) {
      LogUtils.w(
          () => 'PushTokenService: registration response missing callbackUrl');
      return null;
    }
    return PushTokenRegistration(
      deviceRegistrationId: deviceRegistrationId,
      callbackUrl: callbackUrl,
    );
  }

  @override
  Future<bool> unregisterDevice(String deviceRegistrationId) async {
    final normalizedBaseUrl = baseUrl.trim();
    if (normalizedBaseUrl.isEmpty || deviceRegistrationId.isEmpty) {
      return true;
    }
    final uri = Uri.parse(
      '${normalizedBaseUrl.replaceFirst(RegExp(r'/$'), '')}/push/devices/$deviceRegistrationId',
    );
    final response = await _client.delete(uri);
    return response.statusCode == 200 ||
        response.statusCode == 202 ||
        response.statusCode == 204 ||
        response.statusCode == 404;
  }
}

/// Service for managing APNs VoIP and UnifiedPush notification tokens.
///
/// On Android, uses UnifiedPush (ntfy, NextPush, etc.) instead of FCM so the
/// app has no dependency on Google Play Services.
/// On iOS, continues to use APNs VoIP push via PushKit.
class PushTokenService {
  static final PushTokenService sharedInstance = PushTokenService._internal();
  PushTokenService._internal();
  factory PushTokenService() => sharedInstance;

  static const String _lastUploadedTokenKey =
      'noscall_voip_last_uploaded_token';
  static const String _deviceRegistrationIdKey =
      'noscall_push_device_registration_id';
  static const String _callbackUrlKey = 'noscall_push_callback_url';
  static const String _deviceIdKey = 'noscall_push_device_id';
  static const String _registeredTokenTypeKey =
      'noscall_push_registered_token_type';
  static const String _registeredPlatformKey =
      'noscall_push_registered_platform';

  static PushTokenApiClient _apiClient = HttpPushTokenApiClient();

  final PreferencesStore _prefs = PreferencesStore.shared;
  bool _androidMessagingInitialized = false;

  static void setTestOverrides({PushTokenApiClient? apiClient}) {
    _apiClient = apiClient ?? HttpPushTokenApiClient();
  }

  static void clearTestOverrides() {
    _apiClient = HttpPushTokenApiClient();
  }

  /// Registers UnifiedPush callbacks. Call this once at startup (no UI needed).
  /// To actually receive push you must also call
  /// [UnifiedPushDistributorService.ensureDistributorSelected] with a
  /// BuildContext once the UI is ready.
  Future<bool> initializePlatformPush() async {
    if (!Platform.isAndroid) return false;
    if (_androidMessagingInitialized) return true;

    try {
      await UnifiedPush.initialize(
        onNewEndpoint: _onNewEndpoint,
        onMessage: _onMessage,
        onRegistrationFailed: _onRegistrationFailed,
        onUnregistered: _onUnregistered,
      );
      _androidMessagingInitialized = true;
      return true;
    } catch (e, stack) {
      LogUtils.w(() =>
          'PushTokenService: UnifiedPush initialization failed: $e, $stack');
      return false;
    }
  }

  Future<void> _onNewEndpoint(String endpoint, String instance) async {
    LogUtils.i(
        () => 'PushTokenService: UnifiedPush new endpoint received');
    final registration = await uploadToken(
      token: endpoint,
      tokenType: 'unifiedpush',
      platform: 'android',
    );
    if (registration == null) {
      LogUtils.w(() => 'PushTokenService: Failed to register UnifiedPush endpoint');
    }
  }

  void _onMessage(List<int> message, String instance) {
    try {
      final jsonStr = String.fromCharCodes(message);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      unawaited(NostrPushPayloadHandler().handle(data));
    } catch (e) {
      // If not JSON, try showing a generic incoming call notification
      unawaited(LocalNotificationService.showIncomingCallBackground());
    }
  }

  void _onRegistrationFailed(String instance) {
    LogUtils.w(() => 'PushTokenService: UnifiedPush registration failed for $instance');
  }

  void _onUnregistered(String instance) {
    LogUtils.i(() => 'PushTokenService: UnifiedPush unregistered for $instance');
  }

  Future<bool> uploadVoIPToken(String token) async {
    final registration = await uploadToken(
      token: token,
      tokenType: 'apns_voip',
      platform: Platform.isIOS ? 'ios' : Platform.operatingSystem,
    );
    return registration != null;
  }

  Future<PushTokenRegistration?> uploadToken({
    required String token,
    required String tokenType,
    required String platform,
    String? pubkey,
  }) async {
    if (token.isEmpty) {
      LogUtils.w(() => 'PushTokenService: Cannot upload empty push token');
      return null;
    }

    final currentPubkey = pubkey ?? Account.sharedInstance.currentPubkey;
    if (currentPubkey.isEmpty) {
      LogUtils.v(() =>
          'PushTokenService: User not authenticated, token upload deferred');
      return null;
    }

    final previewLength = token.length < 20 ? token.length : 20;
    LogUtils.i(() =>
        'PushTokenService: Uploading $tokenType token: ${token.substring(0, previewLength)}...');

    try {
      final registration = await _apiClient.registerDevice(
        PushTokenRegistrationRequest(
          pubkey: currentPubkey,
          platform: platform,
          tokenType: tokenType,
          token: token,
          deviceId: await _getOrCreateDeviceId(),
          appVersion: await _appVersion(),
        ),
      );
      if (registration == null) return null;

      await _persistRegistration(
        token: token,
        tokenType: tokenType,
        platform: platform,
        registration: registration,
      );
      LogUtils.i(() => 'PushTokenService: Push token uploaded successfully');
      return registration;
    } catch (e, stack) {
      LogUtils.e(() => 'PushTokenService: Error uploading token: $e, $stack');
      return null;
    }
  }

  Future<PushTokenRegistration?> getCurrentRegistration() async {
    final deviceRegistrationId =
        await _prefs.getString(_deviceRegistrationIdKey) ?? '';
    final callbackUrl = await _prefs.getString(_callbackUrlKey) ?? '';
    if (deviceRegistrationId.isEmpty || callbackUrl.isEmpty) return null;
    return PushTokenRegistration(
      deviceRegistrationId: deviceRegistrationId,
      callbackUrl: callbackUrl,
    );
  }

  Future<String?> getLastUploadedToken() async {
    return _prefs.getString(_lastUploadedTokenKey);
  }

  Future<bool> shouldUploadVoIPToken(String newToken) async {
    final lastUploadedToken = await getLastUploadedToken();
    final registration = await getCurrentRegistration();
    if (lastUploadedToken == null || registration == null) return true;
    return lastUploadedToken != newToken;
  }

  Future<bool> unregisterCurrentDevice({bool clearLocal = true}) async {
    if (Platform.isAndroid) {
      try {
        await UnifiedPush.unregister('default');
      } catch (e) {
        LogUtils.w(() => 'PushTokenService: UnifiedPush unregister failed: $e');
      }
    }
    final registration = await getCurrentRegistration();
    final ok = registration == null
        ? true
        : await _apiClient.unregisterDevice(registration.deviceRegistrationId);
    if (clearLocal && ok) {
      await _clearLocalRegistration();
    }
    return ok;
  }

  Future<void> clearVoIPToken() async {
    await _clearLocalRegistration();
  }

  Future<String> _getOrCreateDeviceId() async {
    final existing = await _prefs.getString(_deviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final id = const Uuid().v4();
    await _prefs.setString(_deviceIdKey, id);
    return id;
  }

  Future<String> _appVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return '${info.version}+${info.buildNumber}';
    } catch (_) {
      return 'unknown';
    }
  }

  Future<void> _persistRegistration({
    required String token,
    required String tokenType,
    required String platform,
    required PushTokenRegistration registration,
  }) async {
    await Future.wait([
      _prefs.setString(_lastUploadedTokenKey, token),
      _prefs.setString(
        _deviceRegistrationIdKey,
        registration.deviceRegistrationId,
      ),
      _prefs.setString(_callbackUrlKey, registration.callbackUrl),
      _prefs.setString(_registeredTokenTypeKey, tokenType),
      _prefs.setString(_registeredPlatformKey, platform),
    ]);
  }

  Future<void> _clearLocalRegistration() async {
    await Future.wait([
      _prefs.remove(_lastUploadedTokenKey),
      _prefs.remove(_deviceRegistrationIdKey),
      _prefs.remove(_callbackUrlKey),
      _prefs.remove(_registeredTokenTypeKey),
      _prefs.remove(_registeredPlatformKey),
    ]);
  }

  void dispose() {
    _androidMessagingInitialized = false;
  }
}
