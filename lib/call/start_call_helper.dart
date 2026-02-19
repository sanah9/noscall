import 'package:flutter/material.dart';
import 'package:noscall/call/call_manager.dart';
import 'package:noscall/call/constant/call_type.dart';
import 'package:noscall/utils/toast.dart';

/// Centralized helper to start a voice or video call with permission check,
/// CallKitManager.startCall, and consistent toasts. Caller should check
/// pre-conditions (e.g. blocked user) before calling.
class StartCallHelper {
  /// Starts a call. Shows "Call already in progress" if one is active,
  /// then "Starting voice/video call...", then success or error toast.
  static Future<void> startCall(
    BuildContext context, {
    required String peerId,
    required CallType callType,
  }) async {
    if (CallKitManager.instance.hasActiveCalling) {
      AppToast.showInfo(context, 'Call already in progress');
      return;
    }

    final isVideo = callType.isVideo;
    try {
      AppToast.showInfo(
        context,
        isVideo ? 'Starting video call...' : 'Starting voice call...',
      );
      final controller = await CallKitManager.instance.startCall(
        peerId: peerId,
        callType: callType,
      );
      if (!context.mounted) return;
      if (controller == null) {
        AppToast.showError(
          context,
          isVideo ? 'Failed to start video call' : 'Failed to start voice call',
        );
      } else {
        AppToast.showSuccess(
          context,
          isVideo ? 'Video call started' : 'Voice call started',
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      final errorMessage = _errorMessage(e.toString(), isVideo);
      AppToast.showError(context, errorMessage);
    }
  }

  static String _errorMessage(String e, bool isVideo) {
    if (e.contains('Maximum concurrent calls reached')) {
      return 'Another call is already in progress';
    }
    if (e.contains('Required permissions not granted')) {
      return isVideo
          ? 'Camera and microphone permissions required for video calls'
          : 'Microphone permission required for voice calls';
    }
    if (e.contains('permission')) {
      return 'Permission denied. Please check app settings';
    }
    return isVideo ? 'Video call failed' : 'Voice call failed';
  }
}
