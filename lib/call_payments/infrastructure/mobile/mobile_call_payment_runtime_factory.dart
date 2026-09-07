import 'package:noscall/call_payments/application/call_payment_coordinator.dart';
import 'package:noscall/call_payments/application/call_payment_incoming_offer_gate.dart';
import 'package:noscall/call_payments/application/call_payment_recovery_service.dart';
import 'package:noscall/call_payments/application/call_payment_runtime.dart';
import 'package:noscall/call_payments/infrastructure/call_payment_runtime_factory.dart';

typedef CallPaymentRuntimeFactory = Future<CallPaymentRuntime> Function();

@Deprecated(
  'Use DefaultCallPaymentRuntimeFactory; it supports mobile and desktop.',
)
final class MobileCallPaymentRuntimeFactory {
  const MobileCallPaymentRuntimeFactory._();

  static Future<CallPaymentRuntime?> tryCreate({
    CallPaymentStopCallCallback? stopCall,
  }) {
    return DefaultCallPaymentRuntimeFactory.tryCreate(stopCall: stopCall);
  }

  static Future<CallPaymentRuntime> create({
    CallPaymentStopCallCallback? stopCall,
  }) {
    return DefaultCallPaymentRuntimeFactory.create(stopCall: stopCall);
  }

  static Future<CallPaymentIncomingOfferGate> createIncomingOfferGate() {
    return DefaultCallPaymentRuntimeFactory.createIncomingOfferGate();
  }

  static Future<CallPaymentRecoveryReport> recoverPendingPayments() {
    return DefaultCallPaymentRuntimeFactory.recoverPendingPayments();
  }
}
