import 'package:flutter/material.dart';
import 'package:noscall/call/call_kit_manager.dart';
import 'package:noscall/call/constant/call_type.dart';
import 'package:noscall/call_payments/application/call_payment_initial_payment_service.dart';
import 'package:noscall/call_payments/application/call_payment_start_guard.dart';
import 'package:noscall/call_payments/domain/call_payment_models.dart';
import 'package:noscall/call_payments/pages/call_payment_confirm_page.dart';
import 'package:noscall/utils/toast.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';
import 'package:uuid/uuid.dart';

typedef CallPaymentInitialPaymentPreparer =
    Future<CallPaymentInitialPaymentResult> Function(
      CallPaymentInitialPaymentRequest request,
    );
typedef CallIdFactory = String Function();

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
    CashuAccountId? paymentOwner,
    CallPaymentInitialPaymentPreparer? prepareInitialPayment,
    CallIdFactory? callIdFactory,
  }) async {
    if (CallKitManager.instance.hasActiveCalling) {
      AppToast.showInfo(context, 'Call already in progress');
      return;
    }

    final isVideo = callType.isVideo;
    try {
      final paymentStart = await _confirmPaidCallIfNeeded(
        context,
        peerId: peerId,
        callType: callType,
        paymentGuard: paymentGuard,
        paymentOwner: paymentOwner,
        prepareInitialPayment: prepareInitialPayment,
        callIdFactory: callIdFactory,
      );
      if (!paymentStart.shouldStart) return;
      if (!context.mounted) return;

      AppToast.showInfo(
        context,
        isVideo ? 'Starting video call...' : 'Starting voice call...',
      );
      final controller = await CallKitManager.instance.startCall(
        peerId: peerId,
        callType: callType,
        callId: paymentStart.callId,
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

  static Future<_CallPaymentStartResult> _confirmPaidCallIfNeeded(
    BuildContext context, {
    required String peerId,
    required CallType callType,
    required CallPaymentStartGuard? paymentGuard,
    required CashuAccountId? paymentOwner,
    required CallPaymentInitialPaymentPreparer? prepareInitialPayment,
    required CallIdFactory? callIdFactory,
  }) async {
    if (paymentGuard == null) return const _CallPaymentStartResult.start();

    final decision = await paymentGuard.evaluate(
      peerPubkey: peerId,
      callType: callType.toCallPaymentCallType(),
    );
    if (!context.mounted) return const _CallPaymentStartResult.cancel();

    switch (decision.kind) {
      case CallPaymentStartDecisionKind.free:
        return const _CallPaymentStartResult.start();
      case CallPaymentStartDecisionKind.paid:
        final result = await Navigator.of(context)
            .push<CallPaymentConfirmResult>(
              MaterialPageRoute(
                builder: (context) => CallPaymentConfirmPage(
                  arguments: CallPaymentConfirmArguments.fromDecision(decision),
                ),
              ),
            );
        if (!context.mounted) return const _CallPaymentStartResult.cancel();
        if (result == null) return const _CallPaymentStartResult.cancel();
        if (paymentOwner == null || prepareInitialPayment == null) {
          AppToast.showInfo(
            context,
            'Paid call payment preparation is not available yet.',
          );
          return const _CallPaymentStartResult.cancel();
        }
        await CallKitManager.instance.ensureCanStartCall(callType);

        final quote = decision.quote!;
        final mintUrl = decision.mintUrl!;
        final callId = (callIdFactory ?? () => const Uuid().v4())();
        final payment = await prepareInitialPayment(
          CallPaymentInitialPaymentRequest(
            owner: paymentOwner,
            callId: callId,
            peerPubkey: peerId,
            callType: callType.toCallPaymentCallType(),
            mintUrl: mintUrl,
            amountSats: quote.periodAmountSats,
            priceSatsPerMinute: quote.priceSatsPerMinute,
            billingPeriodSeconds: quote.billingPeriodSeconds,
            maxSpendSats: result.maxSpendSats,
          ),
        );
        if (!context.mounted) return const _CallPaymentStartResult.cancel();
        if (!payment.okEvent.status) {
          AppToast.showError(
            context,
            payment.okEvent.message.isNotEmpty
                ? payment.okEvent.message
                : 'Paid call payment failed. Please try again.',
          );
          return const _CallPaymentStartResult.cancel();
        }
        return _CallPaymentStartResult.start(callId: callId);
      case CallPaymentStartDecisionKind.noCommonMint:
      case CallPaymentStartDecisionKind.insufficientBalance:
      case CallPaymentStartDecisionKind.unsupported:
        AppToast.showError(
          context,
          decision.message ?? 'Paid call cannot be started.',
        );
        return const _CallPaymentStartResult.cancel();
    }
  }
}

final class _CallPaymentStartResult {
  const _CallPaymentStartResult.start({this.callId}) : shouldStart = true;
  const _CallPaymentStartResult.cancel() : shouldStart = false, callId = null;

  final bool shouldStart;
  final String? callId;
}

extension on CallType {
  CallPaymentCallType toCallPaymentCallType() {
    return switch (this) {
      CallType.audio => CallPaymentCallType.audio,
      CallType.video => CallPaymentCallType.video,
    };
  }
}
