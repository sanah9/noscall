import 'package:noscall/wallet/domain/cashu_account_id.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';

import '../domain/call_payment_models.dart';
import '../domain/call_payment_repositories.dart';
import 'call_payment_initial_payment_service.dart';

abstract interface class CallPaymentTokenRecoverer {
  Future<CashuSendState> checkSendStatus({
    required CashuMintUrl mintUrl,
    required String operationId,
  });

  Future<CashuAmount> reclaimSend({
    required CashuMintUrl mintUrl,
    required String operationId,
  });
}

final class CallPaymentRecoveryReport {
  const CallPaymentRecoveryReport({
    required this.scannedSessions,
    required this.reclaimedInstallments,
    required this.claimedInstallments,
    required this.unknownInstallments,
  });

  final int scannedSessions;
  final int reclaimedInstallments;
  final int claimedInstallments;
  final int unknownInstallments;
}

final class CallPaymentRecoveryService {
  CallPaymentRecoveryService({
    required CallPaymentSessionRepository sessionRepository,
    required CallPaymentInstallmentRepository installmentRepository,
    required CallPaymentTokenRecoverer tokenRecoverer,
    CallPaymentClock? clock,
  }) : _sessionRepository = sessionRepository,
       _installmentRepository = installmentRepository,
       _tokenRecoverer = tokenRecoverer,
       _clock = clock ?? DateTime.now;

  final CallPaymentSessionRepository _sessionRepository;
  final CallPaymentInstallmentRepository _installmentRepository;
  final CallPaymentTokenRecoverer _tokenRecoverer;
  final CallPaymentClock _clock;

  Future<CallPaymentRecoveryReport> recover(CashuAccountId owner) async {
    final sessions = await _sessionRepository.list(owner);
    var scannedSessions = 0;
    var reclaimedInstallments = 0;
    var claimedInstallments = 0;
    var unknownInstallments = 0;

    for (final session in sessions) {
      if (!_shouldRecover(session)) continue;
      scannedSessions++;

      final result = await _recoverSession(session);
      reclaimedInstallments += result.reclaimedInstallments;
      claimedInstallments += result.claimedInstallments;
      unknownInstallments += result.unknownInstallments;
    }

    return CallPaymentRecoveryReport(
      scannedSessions: scannedSessions,
      reclaimedInstallments: reclaimedInstallments,
      claimedInstallments: claimedInstallments,
      unknownInstallments: unknownInstallments,
    );
  }

  bool _shouldRecover(CallPaymentSession session) {
    return session.role == CallPaymentRole.payer &&
        session.status == CallPaymentSessionStatus.reclaimPending;
  }

  Future<CallPaymentRecoveryReport> _recoverSession(
    CallPaymentSession session,
  ) async {
    final installments = await _installmentRepository.listForCall(
      owner: session.owner,
      callId: session.callId,
    );
    var reclaimedInstallments = 0;
    var claimedInstallments = 0;
    var unknownInstallments = 0;
    var reclaimedSats = 0;

    for (final installment in installments.where(_shouldRecoverInstallment)) {
      final operationId = installment.walletOperationId!;
      final status = await _tokenRecoverer.checkSendStatus(
        mintUrl: installment.mintUrl,
        operationId: operationId,
      );
      switch (status) {
        case CashuSendState.prepared:
        case CashuSendState.recoverable:
          final reclaimed = await _tokenRecoverer.reclaimSend(
            mintUrl: installment.mintUrl,
            operationId: operationId,
          );
          await _saveInstallment(
            installment,
            status: CallPaymentInstallmentStatus.reclaimed,
            reclaimedAt: _clock(),
          );
          reclaimedInstallments++;
          reclaimedSats += reclaimed.value;
          break;
        case CashuSendState.reclaimed:
          await _saveInstallment(
            installment,
            status: CallPaymentInstallmentStatus.reclaimed,
            reclaimedAt: installment.reclaimedAt ?? _clock(),
          );
          reclaimedInstallments++;
          reclaimedSats += installment.amountSats;
          break;
        case CashuSendState.claimed:
          await _saveInstallment(
            installment,
            status: CallPaymentInstallmentStatus.claimed,
            claimedAt: installment.claimedAt ?? _clock(),
          );
          claimedInstallments++;
          break;
        case CashuSendState.unknown:
          await _saveInstallment(
            installment,
            status: CallPaymentInstallmentStatus.unknown,
            errorCode: 'payment_reclaim_status_unknown',
          );
          unknownInstallments++;
          break;
      }
    }

    await _saveRecoveredSession(
      session,
      reclaimedSats: reclaimedSats,
      hasClaimedInstallment: claimedInstallments > 0,
      hasUnknownInstallment: unknownInstallments > 0,
    );

    return CallPaymentRecoveryReport(
      scannedSessions: 1,
      reclaimedInstallments: reclaimedInstallments,
      claimedInstallments: claimedInstallments,
      unknownInstallments: unknownInstallments,
    );
  }

  bool _shouldRecoverInstallment(CallPaymentInstallment installment) {
    return installment.direction == CallPaymentTransferDirection.sent &&
        installment.walletOperationId != null &&
        switch (installment.status) {
          CallPaymentInstallmentStatus.prepared ||
          CallPaymentInstallmentStatus.sent ||
          CallPaymentInstallmentStatus.reclaimable ||
          CallPaymentInstallmentStatus.unknown => true,
          _ => false,
        };
  }

  Future<void> _saveInstallment(
    CallPaymentInstallment installment, {
    required CallPaymentInstallmentStatus status,
    DateTime? claimedAt,
    DateTime? reclaimedAt,
    String? errorCode,
  }) {
    return _installmentRepository.save(
      installment.copyWith(
        status: status,
        claimedAt: claimedAt,
        reclaimedAt: reclaimedAt,
        updatedAt: _clock(),
        errorCode: errorCode,
        clearErrorCode: errorCode == null,
      ),
    );
  }

  Future<void> _saveRecoveredSession(
    CallPaymentSession session, {
    required int reclaimedSats,
    required bool hasClaimedInstallment,
    required bool hasUnknownInstallment,
  }) {
    final status = hasClaimedInstallment
        ? CallPaymentSessionStatus.refundPending
        : hasUnknownInstallment
        ? CallPaymentSessionStatus.reclaimPending
        : CallPaymentSessionStatus.completed;
    return _sessionRepository.save(
      session.copyWith(
        status: status,
        refundedSats: session.refundedSats + reclaimedSats,
        updatedAt: _clock(),
      ),
    );
  }
}
