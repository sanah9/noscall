import 'package:flutter/material.dart';
import 'package:noscall/call/call_kit_manager.dart';
import 'package:noscall/call/constant/call_type.dart';
import 'package:noscall/call_payments/application/call_payment_start_guard.dart';
import 'package:noscall/call_payments/domain/call_payment_models.dart';
import 'package:noscall/call_payments/pages/call_payment_confirm_page.dart';
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
    CallPaymentStartGuard? paymentGuard,
  }) async {
    if (CallKitManager.instance.hasActiveCalling) {
      AppToast.showInfo(context, 'Call already in progress');
      return;
    }

    final isVideo = callType.isVideo;
    try {
      final shouldContinue = await _confirmPaidCallIfNeeded(
        context,
        peerId: peerId,
        callType: callType,
        paymentGuard: paymentGuard,
      );
      if (!shouldContinue) return;
      if (!context.mounted) return;

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

  static Future<bool> _confirmPaidCallIfNeeded(
    BuildContext context, {
    required String peerId,
    required CallType callType,
    required CallPaymentStartGuard? paymentGuard,
  }) async {
    if (paymentGuard == null) return true;

    final decision = await paymentGuard.evaluate(
      peerPubkey: peerId,
      callType: callType.toCallPaymentCallType(),
    );
    if (!context.mounted) return false;

    switch (decision.kind) {
      case CallPaymentStartDecisionKind.free:
        return true;
      case CallPaymentStartDecisionKind.paid:
        final result = await Navigator.of(context)
            .push<CallPaymentConfirmResult>(
              MaterialPageRoute(
                builder: (context) => CallPaymentConfirmPage(
                  arguments: CallPaymentConfirmArguments.fromDecision(decision),
                ),
              ),
            );
        if (!context.mounted) return false;
        if (result == null) return false;
        AppToast.showInfo(
          context,
          'Paid call payment preparation is not available yet.',
        );
        return false;
      case CallPaymentStartDecisionKind.noCommonMint:
      case CallPaymentStartDecisionKind.insufficientBalance:
      case CallPaymentStartDecisionKind.unsupported:
        AppToast.showError(
          context,
          decision.message ?? 'Paid call cannot be started.',
        );
        return false;
    }
  }
}

extension on CallType {
  CallPaymentCallType toCallPaymentCallType() {
    return switch (this) {
      CallType.audio => CallPaymentCallType.audio,
      CallType.video => CallPaymentCallType.video,
    };
  }
}
