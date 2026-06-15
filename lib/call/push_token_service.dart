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

/// Persistence key set for one push registration channel.
///
/// VoIP/relay registrations also persist the token type and platform; the
/// standard APNs channel leaves [tokenTypeKey]/[platformKey] null.
class _PushChannel {
  const _PushChannel({
    required this.lastUploadedTokenKey,
    required this.deviceRegistrationIdKey,
    required this.callbackUrlKey,
    required this.pendingTokenKey,
    this.tokenTypeKey,
    this.platformKey,
  });

  final String lastUploadedTokenKey;
  final String deviceRegistrationIdKey;
  final String callbackUrlKey;
  final String pendingTokenKey;
  final String? tokenTypeKey;
  final String? platformKey;
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

  /// Relay/VoIP push channel — APNs VoIP token on iOS, UnifiedPush endpoint on
  /// Android. This registration drives the Nostr relay call pushes.
  static const _PushChannel _relayPushChannel = _PushChannel(
    lastUploadedTokenKey: 'noscall_voip_last_uploaded_token',
    deviceRegistrationIdKey: 'noscall_push_device_registration_id',
    callbackUrlKey: 'noscall_push_callback_url',
    pendingTokenKey: 'noscall_push_pending_voip_token',
    tokenTypeKey: 'noscall_push_registered_token_type',
    platformKey: 'noscall_push_registered_platform',
  );

  /// Standard APNs push channel (iOS). Persisted separately so it never
  /// replaces the VoIP registration used by relay call pushes.
  static const _PushChannel _standardAPNsPushChannel = _PushChannel(
    lastUploadedTokenKey: 'noscall_apns_last_uploaded_token',
    deviceRegistrationIdKey: 'noscall_apns_device_registration_id',
    callbackUrlKey: 'noscall_apns_callback_url',
    pendingTokenKey: 'noscall_push_pending_apns_token',
  );

  static const String _deviceIdKey = 'noscall_push_device_id';

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
    await _prefs.setString(_standardAPNsPushChannel.pendingTokenKey, token);
  }

  /// Upload a previously cached standard APNs token (iOS only).
  Future<void> uploadPendingStandardAPNsTokenIfNeeded() async {
    if (!Platform.isIOS) return;
    final token =
        await _prefs.getString(_standardAPNsPushChannel.pendingTokenKey);
    if (token == null || token.isEmpty) return;

    LogUtils.i(
        () => 'PushTokenService: Uploading deferred standard APNs token');
    final success = await uploadStandardAPNsToken(token);
    if (success) {
      await _prefs.remove(_standardAPNsPushChannel.pendingTokenKey);
    }
  }

  /// Cache an APNs VoIP token that arrived before the user was authenticated.
  /// Call [uploadPendingVoIPTokenIfNeeded] after login to flush it.
  Future<void> savePendingVoIPToken(String token) async {
    await _prefs.setString(_relayPushChannel.pendingTokenKey, token);
  }

  /// Upload a previously cached VoIP token (iOS only).
  /// Called from [initRelayPush] after login succeeds.
  Future<void> uploadPendingVoIPTokenIfNeeded() async {
    if (!Platform.isIOS) return;
    final token = await _prefs.getString(_relayPushChannel.pendingTokenKey);
    if (token == null || token.isEmpty) return;
    LogUtils.i(() => 'PushTokenService: Uploading deferred VoIP token');
    final success = await uploadVoIPToken(token);
    if (success) {
      await _prefs.remove(_relayPushChannel.pendingTokenKey);
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
    final registration = await _uploadToChannel(
      _standardAPNsPushChannel,
      token: token,
      tokenType: 'apns',
      platform: 'ios',
      savePendingOnUnauthenticated: true,
    );
    return registration != null;
  }

  Future<PushTokenRegistration?> uploadToken({
    required String token,
    required String tokenType,
    required String platform,
    String? pubkey,
  }) {
    return _uploadToChannel(
      _relayPushChannel,
      token: token,
      tokenType: tokenType,
      platform: platform,
      pubkey: pubkey,
    );
  }

  /// Registers [token] with the server and persists the resulting registration
  /// into [channel]. Shared by the relay/VoIP and standard APNs paths.
  Future<PushTokenRegistration?> _uploadToChannel(
    _PushChannel channel, {
    required String token,
    required String tokenType,
    required String platform,
    String? pubkey,
    bool savePendingOnUnauthenticated = false,
  }) async {
    if (token.isEmpty) {
      LogUtils.w(() => 'PushTokenService: Cannot upload empty push token');
      return null;
    }

    final currentPubkey = pubkey ?? Account.sharedInstance.currentPubkey;
    if (currentPubkey.isEmpty) {
      LogUtils.v(() =>
          'PushTokenService: User not authenticated, $tokenType token upload deferred');
      if (savePendingOnUnauthenticated) {
        await _prefs.setString(channel.pendingTokenKey, token);
      }
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
        channel,
        token: token,
        tokenType: tokenType,
        platform: platform,
        registration: registration,
      );
      LogUtils.i(() => 'PushTokenService: $tokenType token uploaded');
      return registration;
    } catch (e, stack) {
      LogUtils.e(
          () => 'PushTokenService: Error uploading $tokenType token: $e, $stack');
      return null;
    }
  }

  Future<PushTokenRegistration?> getCurrentRegistration() =>
      _getRegistration(_relayPushChannel);

  Future<String?> getLastUploadedToken() =>
      _prefs.getString(_relayPushChannel.lastUploadedTokenKey);

  Future<String?> getLastUploadedStandardAPNsToken() =>
      _prefs.getString(_standardAPNsPushChannel.lastUploadedTokenKey);

  Future<bool> shouldUploadVoIPToken(String newToken) =>
      _shouldUpload(_relayPushChannel, newToken);

  Future<bool> shouldUploadStandardAPNsToken(String newToken) =>
      _shouldUpload(_standardAPNsPushChannel, newToken);

  Future<PushTokenRegistration?> getStandardAPNsRegistration() =>
      _getRegistration(_standardAPNsPushChannel);

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

  Future<PushTokenRegistration?> _getRegistration(_PushChannel channel) async {
    final deviceRegistrationId =
        await _prefs.getString(channel.deviceRegistrationIdKey) ?? '';
    final callbackUrl = await _prefs.getString(channel.callbackUrlKey) ?? '';
    if (deviceRegistrationId.isEmpty || callbackUrl.isEmpty) return null;
    return PushTokenRegistration(
      deviceRegistrationId: deviceRegistrationId,
      callbackUrl: callbackUrl,
    );
  }

  Future<bool> _shouldUpload(_PushChannel channel, String newToken) async {
    final lastUploadedToken =
        await _prefs.getString(channel.lastUploadedTokenKey);
    final registration = await _getRegistration(channel);
    if (lastUploadedToken == null || registration == null) return true;
    return lastUploadedToken != newToken;
  }

  Future<void> _persistRegistration(
    _PushChannel channel, {
    required String token,
    required String tokenType,
    required String platform,
    required PushTokenRegistration registration,
  }) async {
    final tokenTypeKey = channel.tokenTypeKey;
    final platformKey = channel.platformKey;
    await Future.wait([
      _prefs.setString(channel.lastUploadedTokenKey, token),
      _prefs.setString(
        channel.deviceRegistrationIdKey,
        registration.deviceRegistrationId,
      ),
      _prefs.setString(channel.callbackUrlKey, registration.callbackUrl),
      if (tokenTypeKey != null) _prefs.setString(tokenTypeKey, tokenType),
      if (platformKey != null) _prefs.setString(platformKey, platform),
    ]);
  }

  /// Clears the relay/VoIP registration. The pending VoIP token is intentionally
  /// left in place so a token cached pre-login survives a logout/unregister.
  Future<void> _clearLocalRegistration() => _clearRegistration(_relayPushChannel);

  /// Clears the standard APNs registration along with any pending token.
  Future<void> _clearStandardAPNsRegistration() async {
    await _clearRegistration(_standardAPNsPushChannel);
    await _prefs.remove(_standardAPNsPushChannel.pendingTokenKey);
  }

  Future<void> _clearRegistration(_PushChannel channel) async {
    final tokenTypeKey = channel.tokenTypeKey;
    final platformKey = channel.platformKey;
    await Future.wait([
      _prefs.remove(channel.lastUploadedTokenKey),
      _prefs.remove(channel.deviceRegistrationIdKey),
      _prefs.remove(channel.callbackUrlKey),
      if (tokenTypeKey != null) _prefs.remove(tokenTypeKey),
      if (platformKey != null) _prefs.remove(platformKey),
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
