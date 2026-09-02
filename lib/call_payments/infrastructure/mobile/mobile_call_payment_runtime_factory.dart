import 'package:noscall/call_payments/application/call_payment_recovery_service.dart';
import 'package:noscall/call_payments/application/call_payment_runtime.dart';
import 'package:noscall/call_payments/application/call_payment_coordinator.dart';
import 'package:noscall/call_payments/application/call_payment_incoming_offer_gate.dart';
import 'package:noscall/call_payments/application/call_payment_outgoing_refund_service.dart';
import 'package:noscall/call_payments/domain/call_payment_models.dart';
import 'package:noscall/call_payments/infrastructure/call_payment_nostr_gateway.dart';
import 'package:noscall/call_payments/infrastructure/call_payment_nostr_policy_query.dart';
import 'package:noscall/call_payments/infrastructure/isar_call_payment_repository.dart';
import 'package:noscall/core/account/account.dart';
import 'package:noscall/core/call/contacts/contacts.dart';
import 'package:noscall/core/common/database/db_isar.dart';
import 'package:noscall/core/common/utils/log_utils.dart';
import 'package:noscall/wallet/application/wallet_session_manager.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';
import 'package:noscall/wallet/domain/wallet_errors.dart';
import 'package:noscall/wallet/infrastructure/mobile/mobile_account_wallet_factory.dart';

typedef CallPaymentRuntimeFactory = Future<CallPaymentRuntime> Function();

final class MobileCallPaymentRuntimeFactory {
  const MobileCallPaymentRuntimeFactory._();

  static Future<CallPaymentRuntime?> tryCreate({
    CallPaymentStopCallCallback? stopCall,
  }) async {
    try {
      return await create(stopCall: stopCall);
    } catch (e, stack) {
      LogUtils.e(
        () =>
            'Call payment runtime is unavailable; paid call precheck cannot run: error=$e, stack=$stack',
      );
      return null;
    }
  }

  static Future<CallPaymentRuntime> create({
    CallPaymentStopCallCallback? stopCall,
  }) async {
    final account = Account.sharedInstance;
    final pubkey = account.currentPubkey;
    final privkey = account.currentPrivkey;
    if (pubkey.isEmpty || privkey.isEmpty) {
      throw StateError('A Nostr account is required to use paid calls.');
    }

    final owner = CashuAccountId.fromNostrPubkey(pubkey);
    final walletFactory = await MobileAccountWalletFactory.create();
    final sessionManager = WalletSessionManager(factory: walletFactory);
    final state = await sessionManager.activate(owner);
    final wallet = state.wallet;
    if (wallet == null) {
      await sessionManager.dispose();
      throw const WalletNotReadyException();
    }

    final isar = DBISAR.sharedInstance.isar;
    final gateway = CallPaymentNostrGateway(pubkey: pubkey, privkey: privkey);
    final policyQuery = CallPaymentNostrPolicyQuery(
      pubkey: pubkey,
      privkey: privkey,
      gateway: gateway,
    );
    return CallPaymentRuntime(
      owner: owner,
      wallet: wallet,
      policyRepository: IsarCallPaymentPolicyRepository(isar),
      sessionRepository: IsarCallPaymentSessionRepository(isar),
      installmentRepository: IsarCallPaymentInstallmentRepository(isar),
      gateway: gateway,
      peerIsContact: Contacts.sharedInstance.allContacts.containsKey,
      queryPeerPolicy: policyQuery.query,
      sendPolicyResponse: gateway.sendPolicyEvent,
      stopCall: stopCall,
      dispose: sessionManager.dispose,
    );
  }

  static Future<CallPaymentIncomingOfferGate> createIncomingOfferGate() async {
    final account = Account.sharedInstance;
    final pubkey = account.currentPubkey;
    final privkey = account.currentPrivkey;
    if (pubkey.isEmpty || privkey.isEmpty) {
      throw StateError('A Nostr account is required to use paid calls.');
    }

    final owner = CashuAccountId.fromNostrPubkey(pubkey);
    final isar = DBISAR.sharedInstance.isar;
    final gateway = CallPaymentNostrGateway(pubkey: pubkey, privkey: privkey);
    return CallPaymentIncomingOfferGate(
      owner: owner,
      policyRepository: IsarCallPaymentPolicyRepository(isar),
      sessionRepository: IsarCallPaymentSessionRepository(isar),
      peerIsContact: Contacts.sharedInstance.allContacts.containsKey,
      sendPaymentRequired: gateway.send,
    );
  }

  static Future<CallPaymentRecoveryReport> recoverPendingPayments() async {
    final runtime = await create();
    try {
      final report = await runtime.recoveryService.recover(runtime.owner);
      final expiredSessions = await runtime.recoveryService
          .expireStaleIncomingRingingSessions(runtime.owner);
      var sentRefundInstallments = 0;
      for (final session in expiredSessions) {
        try {
          final result = await runtime.outgoingRefundService.prepareAndSend(
            CallPaymentOutgoingRefundRequest(
              owner: runtime.owner,
              callId: session.callId,
            ),
          );
          sentRefundInstallments += result.installments
              .where(
                (installment) =>
                    installment.status == CallPaymentInstallmentStatus.sent,
              )
              .length;
        } catch (e, stack) {
          LogUtils.e(
            () =>
                'Failed to refund stale incoming paid call: callId=${session.callId}, error=$e, stack=$stack',
          );
        }
      }
      return CallPaymentRecoveryReport(
        scannedSessions: report.scannedSessions,
        reclaimedInstallments: report.reclaimedInstallments,
        claimedInstallments: report.claimedInstallments,
        unknownInstallments: report.unknownInstallments,
        expiredIncomingSessions: expiredSessions.length,
        sentRefundInstallments: sentRefundInstallments,
      );
    } finally {
      await runtime.dispose();
    }
  }
}
