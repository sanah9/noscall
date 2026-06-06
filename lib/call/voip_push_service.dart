import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:noscall/core/common/utils/log_utils.dart';
import 'package:noscall/auth/auth_service.dart';
import 'call_kit_manager.dart';
import 'constant/call_type.dart';
import 'nostr_push_payload_handler.dart';
import 'nostr_relay_push_service.dart';
import 'push_token_service.dart';

/// Service for handling iOS VoIP push notifications
///
/// This service listens to VoIP push notifications from native layer
/// and processes incoming call notifications when the app is in background or killed state
class VoIPPushService {
  static final VoIPPushService _instance = VoIPPushService._internal();
  factory VoIPPushService() => _instance;
  VoIPPushService._internal();

  static const MethodChannel _channel = MethodChannel('sh.noscall.voip_push');

  bool _isInitialized = false;
  CallKitManager? _callKitManager;
  String? _pendingVoIPCallUUID;

  /// Initialize the VoIP push service
  /// Should be called after CallKitManager is initialized
  Future<void> initialize(CallKitManager callKitManager) async {
    if (_isInitialized) {
      LogUtils.i(() => 'VoIPPushService: Already initialized');
      return;
    }

    if (!Platform.isIOS) {
      LogUtils.i(() => 'VoIPPushService: VoIP push is only supported on iOS');
      return;
    }

    _callKitManager = callKitManager;

    try {
      // Listen to method calls from native layer
      _channel.setMethodCallHandler(_handleMethodCall);
      _isInitialized = true;
      LogUtils.i(() => 'VoIPPushService: Initialized successfully');
    } catch (e) {
      LogUtils.e(() => 'VoIPPushService: Failed to initialize: $e');
      rethrow;
    }
  }

  /// Handle method calls from native layer
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    try {
      switch (call.method) {
        case 'onVoIPTokenUpdated':
          await _handleVoIPTokenUpdated(call.arguments as String?);
          break;
        case 'onVoIPPushReceived':
          await _handleVoIPPushReceived(call.arguments);
          break;
        case 'onVoIPTokenInvalidated':
          await _handleVoIPTokenInvalidated();
          break;
        default:
          LogUtils.w(() => 'VoIPPushService: Unknown method: ${call.method}');
      }
    } catch (e, stack) {
      LogUtils.e(
          () => 'VoIPPushService: Error handling ${call.method}: $e, $stack');
    }
  }

  /// Handle VoIP push token update
  Future<void> _handleVoIPTokenUpdated(String? token) async {
    if (token == null || token.isEmpty) {
      LogUtils.w(() => 'VoIPPushService: Received empty token');
      return;
    }

    LogUtils.i(() =>
        'VoIPPushService: VoIP push token updated: ${token.substring(0, 20)}...');

    // Only upload token when user is authenticated; otherwise cache it so
    // it can be uploaded once the user logs in (PushKit only fires once per
    // token, so we must not lose it here).
    final authService = AuthService();
    if (!authService.isAuthenticated) {
      LogUtils.v(() =>
          'VoIPPushService: User not authenticated — caching token for upload after login');
      await PushTokenService().savePendingVoIPToken(token);
      return;
    }

    // Only upload token when it changes (avoid duplicate uploads)
    final shouldUpload = await PushTokenService().shouldUploadVoIPToken(token);
    if (shouldUpload) {
      final success = await PushTokenService().uploadVoIPToken(token);
      if (success) {
        LogUtils.i(() =>
            'VoIPPushService: VoIP token uploaded to server successfully');
        await NostrRelayPushService().sync(force: true);
      } else {
        LogUtils.w(
            () => 'VoIPPushService: Failed to upload VoIP token to server');
      }
    } else {
      LogUtils.v(
          () => 'VoIPPushService: VoIP token unchanged, skipping upload');
      await NostrRelayPushService().syncIfDue(force: true);
    }
  }

  /// Handle received VoIP push notification
  Future<void> _handleVoIPPushReceived(dynamic payload) async {
    if (payload == null) {
      LogUtils.w(() => 'VoIPPushService: Received null payload');
      return;
    }

    try {
      LogUtils.i(() => 'VoIPPushService: Received VoIP push notification');

      Map<String, dynamic> payloadMap;
      if (payload is Map) {
        payloadMap = Map<String, dynamic>.from(payload);
      } else if (payload is String) {
        payloadMap = jsonDecode(payload) as Map<String, dynamic>;
      } else {
        LogUtils.e(() =>
            'VoIPPushService: Invalid payload type: ${payload.runtimeType}');
        return;
      }

      // Extract the placeholder UUID injected by AppDelegate.  It is removed
      // from the map so it doesn't interfere with Nostr payload validation.
      final callUUID = payloadMap.remove('_callUUID') as String?;
      _pendingVoIPCallUUID = callUUID;

      final nostrHandler = NostrPushPayloadHandler();
      if (nostrHandler.isNostrRelayPushPayload(payloadMap)) {
        final handled = await nostrHandler.handle(payloadMap);
        if (handled) {
          // The real CallKit call is now being shown via callkeep.  End the
          // AppDelegate placeholder so the user does not see two incoming calls.
          await _endPlaceholderCall(callUUID);
        } else {
          // Invalid / stale push — dismiss the placeholder immediately.
          await _endPlaceholderCall(callUUID);
        }
        return;
      }

      // Legacy push format (peerId / offerId).
      final peerId = payloadMap['peerId'] as String?;
      final offerId = payloadMap['offerId'] as String?;
      final data = payloadMap['data'] as String?;
      final media = payloadMap['media'] as String?;

      if (peerId == null || peerId.isEmpty ||
          offerId == null || offerId.isEmpty ||
          data == null || data.isEmpty) {
        LogUtils.e(() => 'VoIPPushService: Incomplete legacy push payload');
        await _endPlaceholderCall(callUUID);
        return;
      }

      LogUtils.i(() =>
          'VoIPPushService: Processing incoming call from $peerId, offerId: $offerId');

      if (_callKitManager != null) {
        // Real call flow takes over; end the placeholder first.
        await _endPlaceholderCall(callUUID);
        _callKitManager!.callStateChangeHandler(
          friend: peerId,
          state: _parseSignalingState(payloadMap),
          offerId: offerId,
          data: data,
          mediaType: _parseCallType(media),
        );
      } else {
        LogUtils.e(() => 'VoIPPushService: CallKitManager is not initialized');
        await _endPlaceholderCall(callUUID);
      }
    } catch (e, stack) {
      LogUtils.e(
          () => 'VoIPPushService: Error processing VoIP push: $e, $stack');
      await _endPlaceholderCall(_pendingVoIPCallUUID);
    }
  }

  Future<void> _endPlaceholderCall(String? uuid) async {
    if (uuid == null) return;
    if (_pendingVoIPCallUUID == uuid) _pendingVoIPCallUUID = null;
    try {
      await _channel.invokeMethod('endVoIPPlaceholderCall', uuid);
    } catch (e) {
      LogUtils.w(() => 'VoIPPushService: endVoIPPlaceholderCall failed: $e');
    }
  }

  /// Handle VoIP push token invalidation
  Future<void> _handleVoIPTokenInvalidated() async {
    LogUtils.w(() => 'VoIPPushService: VoIP push token invalidated');
    await NostrRelayPushService().stopAndDelete();
  }

  /// Parse signaling state from payload
  /// Default to 'offer' state for incoming calls
  SignalingState _parseSignalingState(Map<String, dynamic> payload) {
    // VoIP push notifications are for incoming calls, so always use 'offer' state
    return SignalingState.offer;
  }

  /// Parse call type from media string
  CallType? _parseCallType(String? media) {
    if (media == null || media.isEmpty) {
      return null; // Let CallKitManager determine from data
    }

    return CallTypeEx.fromValue(media);
  }

  /// Dispose the service
  void dispose() {
    if (_isInitialized) {
      _channel.setMethodCallHandler(null);
      _isInitialized = false;
      _callKitManager = null;
      LogUtils.i(() => 'VoIPPushService: Disposed');
    }
  }
}
