import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:unifiedpush/unifiedpush.dart';
import 'package:uuid/uuid.dart';

import 'package:noscall/call/local_notification_service.dart';
import 'package:noscall/call/nostr_push_payload_handler.dart';
import 'package:noscall/call/nostr_relay_push_service.dart';
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
  static const String _standardAPNsLastUploadedTokenKey =
      'noscall_apns_last_uploaded_token';
  static const String _standardAPNsDeviceRegistrationIdKey =
      'noscall_apns_device_registration_id';
  static const String _standardAPNsCallbackUrlKey = 'noscall_apns_callback_url';
  static const String _deviceRegistrationIdKey =
      'noscall_push_device_registration_id';
  static const String _callbackUrlKey = 'noscall_push_callback_url';
  static const String _deviceIdKey = 'noscall_push_device_id';
  static const String _registeredTokenTypeKey =
      'noscall_push_registered_token_type';
  static const String _registeredPlatformKey =
      'noscall_push_registered_platform';
  static const String _pendingVoIPTokenKey = 'noscall_push_pending_voip_token';
  static const String _pendingStandardAPNsTokenKey =
      'noscall_push_pending_apns_token';

  static const MethodChannel _standardAPNsChannel =
      MethodChannel('sh.noscall.standard_push');

  static PushTokenApiClient _apiClient = HttpPushTokenApiClient();

  final PreferencesStore _prefs = PreferencesStore.shared;
  bool _androidMessagingInitialized = false;
  bool _standardAPNsInitialized = false;

  static void setTestOverrides({PushTokenApiClient? apiClient}) {
    _apiClient = apiClient ?? HttpPushTokenApiClient();
  }

  static void clearTestOverrides() {
    _apiClient = HttpPushTokenApiClient();
  }

  /// Registers platform push callbacks. Call this once after login.
  ///
  /// Android uses UnifiedPush. iOS listens for the standard APNs token from
  /// native code and uploads it with tokenType `apns`.
  Future<bool> initializePlatformPush() async {
    if (Platform.isIOS) return _initializeStandardAPNsPush();
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

  Future<bool> _initializeStandardAPNsPush() async {
    if (_standardAPNsInitialized) return true;

    try {
      _standardAPNsChannel.setMethodCallHandler(_handleStandardAPNsMethodCall);
      _standardAPNsInitialized = true;

      final token = await _standardAPNsChannel
          .invokeMethod<String>('getStandardAPNsToken');
      if (token != null && token.isNotEmpty) {
        await _handleStandardAPNsTokenUpdated(token);
      }
      return true;
    } catch (e, stack) {
      LogUtils.w(() =>
          'PushTokenService: standard APNs initialization failed: $e, $stack');
      return false;
    }
  }

  Future<dynamic> _handleStandardAPNsMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onStandardAPNsTokenUpdated':
        await _handleStandardAPNsTokenUpdated(call.arguments as String?);
        return null;
      default:
        LogUtils.w(() =>
            'PushTokenService: unknown standard APNs method ${call.method}');
        return null;
    }
  }

  Future<void> _onNewEndpoint(String endpoint, String instance) async {
    LogUtils.i(() => 'PushTokenService: UnifiedPush new endpoint received');
    final registration = await uploadToken(
      token: endpoint,
      tokenType: 'unifiedpush',
      platform: 'android',
    );
    if (registration != null) {
      // Endpoint registered — update relay push subscriptions immediately.
      unawaited(NostrRelayPushService().sync(force: true));
    } else {
      LogUtils.w(
          () => 'PushTokenService: Failed to register UnifiedPush endpoint');
    }
  }

  void _onMessage(Uint8List message, String instance) {
    try {
      final data =
          jsonDecode(String.fromCharCodes(message)) as Map<String, dynamic>;
      unawaited(NostrPushPayloadHandler().handle(data));
    } catch (e) {
      // Not a structured push payload — show a generic incoming-call notification.
      unawaited(LocalNotificationService.showIncomingCallBackground());
    }
  }

  void _onRegistrationFailed(String instance) {
    LogUtils.w(() =>
        'PushTokenService: UnifiedPush registration failed for $instance');
  }

  Future<void> _onUnregistered(String instance) async {
    LogUtils.i(() =>
        'PushTokenService: UnifiedPush unregistered ($instance) — clearing registration');
    // Clear local registration but don't try to call UnifiedPush.unregister
    // again (we're already inside the unregistered callback).
    final registration = await getCurrentRegistration();
    if (registration != null) {
      await _apiClient.unregisterDevice(registration.deviceRegistrationId);
    }
    await _clearLocalRegistration();
  }

  Future<void> _handleStandardAPNsTokenUpdated(String? token) async {
    if (token == null || token.isEmpty) {
      LogUtils.w(() => 'PushTokenService: Received empty standard APNs token');
      return;
    }

    final previewLength = token.length < 20 ? token.length : 20;
    LogUtils.i(() =>
        'PushTokenService: standard APNs token updated: ${token.substring(0, previewLength)}...');

    if (Account.sharedInstance.currentPubkey.isEmpty) {
      LogUtils.v(() =>
          'PushTokenService: User not authenticated, caching standard APNs token');
      await savePendingStandardAPNsToken(token);
      return;
    }

    if (await shouldUploadStandardAPNsToken(token)) {
      final success = await uploadStandardAPNsToken(token);
      if (!success) {
        LogUtils.w(
            () => 'PushTokenService: Failed to upload standard APNs token');
        await savePendingStandardAPNsToken(token);
      }
    } else {
      LogUtils.v(() =>
          'PushTokenService: standard APNs token unchanged, skipping upload');
    }
  }

  /// Cache a standard APNs token that arrived before the user was authenticated.
  Future<void> savePendingStandardAPNsToken(String token) async {
    await _prefs.setString(_pendingStandardAPNsTokenKey, token);
  }

  /// Upload a previously cached standard APNs token (iOS only).
  Future<void> uploadPendingStandardAPNsTokenIfNeeded() async {
    if (!Platform.isIOS) return;
    final token = await _prefs.getString(_pendingStandardAPNsTokenKey);
    if (token == null || token.isEmpty) return;

    LogUtils.i(
        () => 'PushTokenService: Uploading deferred standard APNs token');
    final success = await uploadStandardAPNsToken(token);
    if (success) {
      await _prefs.remove(_pendingStandardAPNsTokenKey);
    }
  }

  /// Cache an APNs VoIP token that arrived before the user was authenticated.
  /// Call [uploadPendingVoIPTokenIfNeeded] after login to flush it.
  Future<void> savePendingVoIPToken(String token) async {
    await _prefs.setString(_pendingVoIPTokenKey, token);
  }

  /// Upload a previously cached VoIP token (iOS only).
  /// Called from [initRelayPush] after login succeeds.
  Future<void> uploadPendingVoIPTokenIfNeeded() async {
    if (!Platform.isIOS) return;
    final token = await _prefs.getString(_pendingVoIPTokenKey);
    if (token == null || token.isEmpty) return;
    LogUtils.i(() => 'PushTokenService: Uploading deferred VoIP token');
    final success = await uploadVoIPToken(token);
    if (success) {
      await _prefs.remove(_pendingVoIPTokenKey);
    }
  }

  Future<bool> uploadVoIPToken(String token) async {
    final registration = await uploadToken(
      token: token,
      tokenType: 'apns_voip',
      platform: Platform.isIOS ? 'ios' : Platform.operatingSystem,
    );
    return registration != null;
  }

  /// Temporary registration path for standard APNs notifications.
  ///
  /// The server endpoint is the existing `POST /push/devices`; the temporary
  /// tokenType is `apns`. Standard APNs registration is persisted separately so
  /// it does not replace the VoIP registration used by relay call pushes.
  Future<bool> uploadStandardAPNsToken(String token) async {
    if (token.isEmpty) {
      LogUtils.w(() => 'PushTokenService: Cannot upload empty APNs token');
      return false;
    }

    final currentPubkey = Account.sharedInstance.currentPubkey;
    if (currentPubkey.isEmpty) {
      LogUtils.v(() =>
          'PushTokenService: User not authenticated, standard APNs upload deferred');
      await savePendingStandardAPNsToken(token);
      return false;
    }

    try {
      final registration = await _apiClient.registerDevice(
        PushTokenRegistrationRequest(
          pubkey: currentPubkey,
          platform: 'ios',
          tokenType: 'apns',
          token: token,
          deviceId: await _getOrCreateDeviceId(),
          appVersion: await _appVersion(),
        ),
      );
      if (registration == null) return false;

      await _persistStandardAPNsRegistration(
        token: token,
        registration: registration,
      );
      LogUtils.i(() => 'PushTokenService: standard APNs token uploaded');
      return true;
    } catch (e, stack) {
      LogUtils.e(() =>
          'PushTokenService: Error uploading standard APNs token: $e, $stack');
      return false;
    }
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

  Future<String?> getLastUploadedStandardAPNsToken() async {
    return _prefs.getString(_standardAPNsLastUploadedTokenKey);
  }

  Future<bool> shouldUploadVoIPToken(String newToken) async {
    final lastUploadedToken = await getLastUploadedToken();
    final registration = await getCurrentRegistration();
    if (lastUploadedToken == null || registration == null) return true;
    return lastUploadedToken != newToken;
  }

  Future<bool> shouldUploadStandardAPNsToken(String newToken) async {
    final lastUploadedToken = await getLastUploadedStandardAPNsToken();
    final registration = await getStandardAPNsRegistration();
    if (lastUploadedToken == null || registration == null) return true;
    return lastUploadedToken != newToken;
  }

  Future<PushTokenRegistration?> getStandardAPNsRegistration() async {
    final deviceRegistrationId =
        await _prefs.getString(_standardAPNsDeviceRegistrationIdKey) ?? '';
    final callbackUrl =
        await _prefs.getString(_standardAPNsCallbackUrlKey) ?? '';
    if (deviceRegistrationId.isEmpty || callbackUrl.isEmpty) return null;
    return PushTokenRegistration(
      deviceRegistrationId: deviceRegistrationId,
      callbackUrl: callbackUrl,
    );
  }

  Future<bool> unregisterCurrentDevice({bool clearLocal = true}) async {
    if (Platform.isAndroid) {
      try {
        // Calling unregister() will trigger _onUnregistered, which handles
        // server-side deregistration and local cleanup automatically.
        await UnifiedPush.unregister('default');
        return true;
      } catch (e) {
        LogUtils.w(() => 'PushTokenService: UnifiedPush unregister failed: $e');
      }
    }
    // iOS path (and Android fallback if unregister() threw).
    final registration = await getCurrentRegistration();
    final standardRegistration = await getStandardAPNsRegistration();
    final relayOk = registration == null
        ? true
        : await _apiClient.unregisterDevice(registration.deviceRegistrationId);
    final standardOk = standardRegistration == null
        ? true
        : await _apiClient
            .unregisterDevice(standardRegistration.deviceRegistrationId);
    final ok = relayOk && standardOk;
    if (clearLocal && ok) {
      await _clearLocalRegistration();
      await _clearStandardAPNsRegistration();
    }
    return ok;
  }

  Future<void> clearVoIPToken() async {
    await _clearLocalRegistration();
  }

  Future<void> clearStandardAPNsToken() async {
    await _clearStandardAPNsRegistration();
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

  Future<void> _persistStandardAPNsRegistration({
    required String token,
    required PushTokenRegistration registration,
  }) async {
    await Future.wait([
      _prefs.setString(_standardAPNsLastUploadedTokenKey, token),
      _prefs.setString(
        _standardAPNsDeviceRegistrationIdKey,
        registration.deviceRegistrationId,
      ),
      _prefs.setString(_standardAPNsCallbackUrlKey, registration.callbackUrl),
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

  Future<void> _clearStandardAPNsRegistration() async {
    await Future.wait([
      _prefs.remove(_standardAPNsLastUploadedTokenKey),
      _prefs.remove(_standardAPNsDeviceRegistrationIdKey),
      _prefs.remove(_standardAPNsCallbackUrlKey),
      _prefs.remove(_pendingStandardAPNsTokenKey),
    ]);
  }

  void dispose() {
    _androidMessagingInitialized = false;
    if (_standardAPNsInitialized) {
      _standardAPNsChannel.setMethodCallHandler(null);
      _standardAPNsInitialized = false;
    }
  }
}
