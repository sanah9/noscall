import 'package:flutter/material.dart';
import 'package:noscall/call/call_kit_manager.dart';
import 'package:noscall/call/calling_controller.dart';
import 'package:noscall/call/calling_controller_dependencies.dart';
import 'package:noscall/call/constant/call_type.dart';
import 'package:noscall/call_payments/application/call_payment_initial_payment_service.dart';
import 'package:noscall/call_payments/application/call_payment_runtime.dart';
import 'package:noscall/call_payments/application/call_payment_start_guard.dart';
import 'package:noscall/call_payments/domain/call_payment_models.dart';
import 'package:noscall/call_payments/infrastructure/mobile/mobile_call_payment_runtime_factory.dart';
import 'package:noscall/call_payments/pages/call_payment_confirm_page.dart';
import 'package:noscall/utils/toast.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';
import 'package:uuid/uuid.dart';

typedef CallPaymentInitialPaymentPreparer =
    Future<CallPaymentInitialPaymentResult> Function(
      CallPaymentInitialPaymentRequest request,
    );
typedef CallPaymentRuntimeLoader = Future<CallPaymentRuntime?> Function();
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
    CallPaymentRuntimeLoader? paymentRuntimeFactory,
    CallingControllerLifecycleObserver? lifecycleObserver,
    CallIdFactory? callIdFactory,
  }) async {
    if (CallKitManager.instance.hasActiveCalling) {
      AppToast.showInfo(context, 'Call already in progress');
      return;
    }

    final isVideo = callType.isVideo;
    CallPaymentRuntime? paymentRuntime;
    CallingController? paidController;
    Future<void> stopPaidCall({
      required String callId,
      required CallEndReason reason,
    }) async {
      final controller = paidController;
      if (controller == null || await controller.callId != callId) return;
      await controller.hangup(reason);
    }

    try {
      final effectivePaymentRuntimeFactory =
          paymentRuntimeFactory ??
          () =>
              MobileCallPaymentRuntimeFactory.tryCreate(stopCall: stopPaidCall);
      if (paymentGuard == null ||
          paymentOwner == null ||
          prepareInitialPayment == null) {
        paymentRuntime = await effectivePaymentRuntimeFactory();
        if (paymentRuntime == null) {
          if (!context.mounted) return;
          AppToast.showError(
            context,
            'Paid call payment check is unavailable. Please try again later.',
          );
          return;
        }
      }
      if (!context.mounted) {
        await paymentRuntime?.dispose();
        paymentRuntime = null;
        return;
      }

      final paymentStart = await _confirmPaidCallIfNeeded(
        context,
        peerId: peerId,
        callType: callType,
        paymentGuard: paymentGuard ?? paymentRuntime?.startGuard,
        paymentOwner: paymentOwner ?? paymentRuntime?.owner,
        prepareInitialPayment:
            prepareInitialPayment ?? paymentRuntime?.prepareInitialPayment,
        callIdFactory: callIdFactory,
      );
      if (!paymentStart.shouldStart) {
        await paymentRuntime?.dispose();
        paymentRuntime = null;
        return;
      }
      if (!context.mounted) {
        await paymentRuntime?.dispose();
        paymentRuntime = null;
        return;
      }

      final retainedPaymentRuntime = paymentStart.isPaid
          ? paymentRuntime
          : null;
      final paymentFailureObserver = _PaymentRequiredToastLifecycleObserver(
        context,
      );
      if (!paymentStart.isPaid) {
        await paymentRuntime?.dispose();
        paymentRuntime = null;
        if (!context.mounted) return;
      }

      AppToast.showInfo(
        context,
        isVideo ? 'Starting video call...' : 'Starting voice call...',
      );
      final controller = await CallKitManager.instance.startCall(
        peerId: peerId,
        callType: callType,
        callId: paymentStart.callId,
        lifecycleObserver: _combineLifecycleObservers(
          lifecycleObserver,
          _combineLifecycleObservers(
            paymentFailureObserver,
            retainedPaymentRuntime == null
                ? null
                : _DisposingCallPaymentLifecycleObserver(
                    retainedPaymentRuntime,
                  ),
          ),
        ),
      );
      if (controller == null) {
        if (retainedPaymentRuntime != null && paymentStart.callId != null) {
          await retainedPaymentRuntime.coordinator.onEnded(
            callId: paymentStart.callId!,
            peerPubkey: peerId,
            role: CallingRole.caller,
            reason: CallEndReason.hangup,
            hasConnected: false,
          );
          await retainedPaymentRuntime.dispose();
          paymentRuntime = null;
        }
        if (!context.mounted) return;
        AppToast.showError(
          context,
          isVideo ? 'Failed to start video call' : 'Failed to start voice call',
        );
      } else {
        if (paymentStart.isPaid) {
          paidController = controller;
        }
        if (!context.mounted) return;
        AppToast.showSuccess(
          context,
          isVideo ? 'Video call started' : 'Voice call started',
        );
      }
    } catch (e) {
      await paymentRuntime?.dispose();
      paymentRuntime = null;
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
        return _CallPaymentStartResult.start(callId: callId, isPaid: true);
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

CallingControllerLifecycleObserver? _combineLifecycleObservers(
  CallingControllerLifecycleObserver? first,
  CallingControllerLifecycleObserver? second,
) {
  if (first == null) return second;
  if (second == null) return first;
  return _CompositeCallingControllerLifecycleObserver([first, second]);
}

final class _CompositeCallingControllerLifecycleObserver
    implements CallingControllerLifecycleObserver {
  const _CompositeCallingControllerLifecycleObserver(this._observers);

  final List<CallingControllerLifecycleObserver> _observers;

  @override
  Future<void> onConnected({
    required String callId,
    required String peerPubkey,
    required CallingRole role,
  }) async {
    for (final observer in _observers) {
      await observer.onConnected(
        callId: callId,
        peerPubkey: peerPubkey,
        role: role,
      );
    }
  }

  @override
  Future<void> onEnded({
    required String callId,
    required String peerPubkey,
    required CallingRole role,
    required CallEndReason reason,
    required bool hasConnected,
  }) async {
    for (final observer in _observers) {
      await observer.onEnded(
        callId: callId,
        peerPubkey: peerPubkey,
        role: role,
        reason: reason,
        hasConnected: hasConnected,
      );
    }
  }
}

final class _DisposingCallPaymentLifecycleObserver
    implements CallingControllerLifecycleObserver {
  _DisposingCallPaymentLifecycleObserver(this._runtime);

  final CallPaymentRuntime _runtime;
  bool _disposed = false;

  @override
  Future<void> onConnected({
    required String callId,
    required String peerPubkey,
    required CallingRole role,
  }) {
    return _runtime.coordinator.onConnected(
      callId: callId,
      peerPubkey: peerPubkey,
      role: role,
    );
  }

  @override
  Future<void> onEnded({
    required String callId,
    required String peerPubkey,
    required CallingRole role,
    required CallEndReason reason,
    required bool hasConnected,
  }) async {
    try {
      await _runtime.coordinator.onEnded(
        callId: callId,
        peerPubkey: peerPubkey,
        role: role,
        reason: reason,
        hasConnected: hasConnected,
      );
    } finally {
      if (!_disposed) {
        _disposed = true;
        await _runtime.dispose();
      }
    }
  }
}

final class _PaymentRequiredToastLifecycleObserver
    implements CallingControllerLifecycleObserver {
  _PaymentRequiredToastLifecycleObserver(this._context);

  final BuildContext _context;

  @override
  Future<void> onConnected({
    required String callId,
    required String peerPubkey,
    required CallingRole role,
  }) async {}

  @override
  Future<void> onEnded({
    required String callId,
    required String peerPubkey,
    required CallingRole role,
    required CallEndReason reason,
    required bool hasConnected,
  }) async {
    if (reason != CallEndReason.paymentRequired || !_context.mounted) return;
    AppToast.showError(
      _context,
      'Paid call payment is required or insufficient.',
    );
  }
}

final class _CallPaymentStartResult {
  const _CallPaymentStartResult.start({this.callId, this.isPaid = false})
    : shouldStart = true;
  const _CallPaymentStartResult.cancel()
    : shouldStart = false,
      callId = null,
      isPaid = false;

  final bool shouldStart;
  final String? callId;
  final bool isPaid;
}

extension on CallType {
  CallPaymentCallType toCallPaymentCallType() {
    return switch (this) {
      CallType.audio => CallPaymentCallType.audio,
      CallType.video => CallPaymentCallType.video,
    };
  }
}
