import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:noscall/core/common/utils/log_utils.dart';
import 'package:noscall/auth/auth_service.dart';
import 'call_kit_manager.dart';
import 'constant/call_type.dart';
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
      LogUtils.e(() => 'VoIPPushService: Error handling ${call.method}: $e, $stack');
    }
  }

  /// Handle VoIP push token update
  Future<void> _handleVoIPTokenUpdated(String? token) async {
    if (token == null || token.isEmpty) {
      LogUtils.w(() => 'VoIPPushService: Received empty token');
      return;
    }

    LogUtils.i(() => 'VoIPPushService: VoIP push token updated: ${token.substring(0, 20)}...');
    
    // Only upload token when user is authenticated
    final authService = AuthService();
    if (!authService.isAuthenticated) {
      LogUtils.v(() => 'VoIPPushService: User not authenticated, token upload deferred');
      return;
    }

    // Only upload token when it changes (avoid duplicate uploads)
    final shouldUpload = await PushTokenService().shouldUploadVoIPToken(token);
    if (shouldUpload) {
      final success = await PushTokenService().uploadVoIPToken(token);
      if (success) {
        LogUtils.i(() => 'VoIPPushService: VoIP token uploaded to server successfully');
      } else {
        LogUtils.w(() => 'VoIPPushService: Failed to upload VoIP token to server');
      }
    } else {
      LogUtils.v(() => 'VoIPPushService: VoIP token unchanged, skipping upload');
    }
  }

  /// Handle received VoIP push notification
  /// This method processes the push payload and triggers the incoming call flow
  Future<void> _handleVoIPPushReceived(dynamic payload) async {
    if (payload == null) {
      LogUtils.w(() => 'VoIPPushService: Received null payload');
      return;
    }

    try {
      LogUtils.i(() => 'VoIPPushService: Received VoIP push notification');
      
      // Parse payload - the payload structure depends on your server implementation
      // Expected format:
      // {
      //   "peerId": "string",      // The caller's public key or user ID
      //   "offerId": "string",     // Unique call offer ID
      //   "data": "string",        // JSON string containing call signaling data
      //   "media": "audio" | "video"  // Call type
      // }
      
      Map<String, dynamic> payloadMap;
      if (payload is Map) {
        payloadMap = Map<String, dynamic>.from(payload);
      } else if (payload is String) {
        payloadMap = jsonDecode(payload) as Map<String, dynamic>;
      } else {
        LogUtils.e(() => 'VoIPPushService: Invalid payload type: ${payload.runtimeType}');
        return;
      }

      // Extract call information from payload
      final peerId = payloadMap['peerId'] as String?;
      final offerId = payloadMap['offerId'] as String?;
      final data = payloadMap['data'] as String?;
      final media = payloadMap['media'] as String?;

      if (peerId == null || peerId.isEmpty) {
        LogUtils.e(() => 'VoIPPushService: Missing peerId in payload');
        return;
      }

      if (offerId == null || offerId.isEmpty) {
        LogUtils.e(() => 'VoIPPushService: Missing offerId in payload');
        return;
      }

      if (data == null || data.isEmpty) {
        LogUtils.e(() => 'VoIPPushService: Missing data in payload');
        return;
      }

      LogUtils.i(() => 'VoIPPushService: Processing incoming call from $peerId, offerId: $offerId');

      // Trigger the incoming call flow through CallKitManager
      // This will display the incoming call UI using CallKit
      if (_callKitManager != null) {
        _callKitManager!.callStateChangeHandler(
          friend: peerId,
          state: _parseSignalingState(payloadMap),
          offerId: offerId,
          data: data,
          mediaType: _parseCallType(media),
        );
      } else {
        LogUtils.e(() => 'VoIPPushService: CallKitManager is not initialized');
      }
    } catch (e, stack) {
      LogUtils.e(() => 'VoIPPushService: Error processing VoIP push: $e, $stack');
    }
  }

  /// Handle VoIP push token invalidation
  Future<void> _handleVoIPTokenInvalidated() async {
    LogUtils.w(() => 'VoIPPushService: VoIP push token invalidated');
    // TODO: Notify server that token is invalid
    // await yourServerApi.invalidateVoIPToken();
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

