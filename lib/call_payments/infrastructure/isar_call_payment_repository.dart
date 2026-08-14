import 'package:isar/isar.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';

import '../domain/call_payment_models.dart';
import '../domain/call_payment_repositories.dart';
import 'call_payment_isar.dart';

final class IsarCallPaymentPolicyRepository
    implements CallPaymentPolicyRepository {
  const IsarCallPaymentPolicyRepository(this._isar);

  final Isar _isar;

  @override
  Future<CallPaymentPolicy?> find(CashuAccountId owner) async {
    final record = await _isar.callPaymentPolicyRecords
        .where()
        .ownerPubkeyEqualTo(owner.value)
        .findFirst();
    return record == null ? null : _policyFromRecord(record);
  }

  @override
  Future<void> save(CallPaymentPolicy policy) async {
    await _isar.writeTxn(
      () => _isar.callPaymentPolicyRecords.put(_policyToRecord(policy)),
    );
  }
}

final class IsarCallPaymentSessionRepository
    implements CallPaymentSessionRepository {
  const IsarCallPaymentSessionRepository(this._isar);

  final Isar _isar;

  @override
  Future<CallPaymentSession?> find(CashuAccountId owner, String callId) async {
    final record = await _isar.callPaymentSessionRecords
        .where()
        .ownerPubkeyCallIdEqualTo(owner.value, callId)
        .findFirst();
    return record == null ? null : _sessionFromRecord(record);
  }

  @override
  Future<List<CallPaymentSession>> list(CashuAccountId owner) async {
    final records = await _isar.callPaymentSessionRecords
        .filter()
        .ownerPubkeyEqualTo(owner.value)
        .findAll();
    records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(records.map(_sessionFromRecord));
  }

  @override
  Future<void> save(CallPaymentSession session) async {
    await _isar.writeTxn(
      () => _isar.callPaymentSessionRecords.put(_sessionToRecord(session)),
    );
  }
}

final class IsarCallPaymentInstallmentRepository
    implements CallPaymentInstallmentRepository {
  const IsarCallPaymentInstallmentRepository(this._isar);

  final Isar _isar;

  @override
  Future<CallPaymentInstallment?> find({
    required CashuAccountId owner,
    required String callId,
    required int sequence,
    required CallPaymentPurpose purpose,
    required CallPaymentTransferDirection direction,
  }) async {
    final record = await _isar.callPaymentInstallmentRecords
        .where()
        .ownerPubkeyIdempotencyKeyEqualTo(
          owner.value,
          _installmentIdempotencyKey(
            callId: callId,
            sequence: sequence,
            purpose: purpose,
            direction: direction,
          ),
        )
        .findFirst();
    return record == null ? null : _installmentFromRecord(record);
  }

  @override
  Future<CallPaymentInstallment?> findByWalletOperationId({
    required CashuAccountId owner,
    required String walletOperationId,
  }) async {
    final record = await _isar.callPaymentInstallmentRecords
        .where()
        .ownerPubkeyForWalletOperationWalletOperationIdEqualTo(
          owner.value,
          walletOperationId,
        )
        .findFirst();
    return record == null ? null : _installmentFromRecord(record);
  }

  @override
  Future<List<CallPaymentInstallment>> listForCall({
    required CashuAccountId owner,
    required String callId,
  }) async {
    final records = await _isar.callPaymentInstallmentRecords
        .filter()
        .ownerPubkeyEqualTo(owner.value)
        .callIdEqualTo(callId)
        .findAll();
    records.sort((a, b) {
      final sequence = a.sequence.compareTo(b.sequence);
      if (sequence != 0) return sequence;
      return a.createdAt.compareTo(b.createdAt);
    });
    return List.unmodifiable(records.map(_installmentFromRecord));
  }

  @override
  Future<void> save(CallPaymentInstallment installment) async {
    await _isar.writeTxn(
      () => _isar.callPaymentInstallmentRecords.put(
        _installmentToRecord(installment),
      ),
    );
  }
}

CallPaymentPolicy _policyFromRecord(CallPaymentPolicyRecord record) {
  return CallPaymentPolicy(
    owner: CashuAccountId.fromNostrPubkey(record.ownerPubkey),
    enabled: record.enabled,
    freePolicy: CallPaymentFreePolicy.values.byName(record.freePolicy),
    freePubkeys: record.freePubkeys,
    audioPriceSatsPerMinute: record.audioPriceSatsPerMinute,
    videoPriceSatsPerMinute: record.videoPriceSatsPerMinute,
    billingPeriodSeconds: record.billingPeriodSeconds,
    gracePeriodSeconds: record.gracePeriodSeconds,
    acceptedMintUrls: record.acceptedMintUrls.map(CashuMintUrl.parse),
    createdAt: _dateFromMillis(record.createdAt),
    updatedAt: _dateFromMillis(record.updatedAt),
  );
}

CallPaymentPolicyRecord _policyToRecord(CallPaymentPolicy policy) {
  return CallPaymentPolicyRecord()
    ..ownerPubkey = policy.owner.value
    ..enabled = policy.enabled
    ..freePolicy = policy.freePolicy.name
    ..freePubkeys = policy.freePubkeys
    ..audioPriceSatsPerMinute = policy.audioPriceSatsPerMinute
    ..videoPriceSatsPerMinute = policy.videoPriceSatsPerMinute
    ..billingPeriodSeconds = policy.billingPeriodSeconds
    ..gracePeriodSeconds = policy.gracePeriodSeconds
    ..acceptedMintUrls = policy.acceptedMintUrls
        .map((url) => url.toString())
        .toList(growable: false)
    ..createdAt = policy.createdAt.millisecondsSinceEpoch
    ..updatedAt = policy.updatedAt.millisecondsSinceEpoch;
}

CallPaymentSession _sessionFromRecord(CallPaymentSessionRecord record) {
  return CallPaymentSession(
    owner: CashuAccountId.fromNostrPubkey(record.ownerPubkey),
    callId: record.callId,
    peerPubkey: record.peerPubkey,
    direction: CallPaymentCallDirection.values.byName(record.direction),
    role: CallPaymentRole.values.byName(record.role),
    callType: CallPaymentCallType.values.byName(record.callType),
    status: CallPaymentSessionStatus.values.byName(record.status),
    mintUrl: CashuMintUrl.parse(record.mintUrl),
    priceSatsPerMinute: record.priceSatsPerMinute,
    billingPeriodSeconds: record.billingPeriodSeconds,
    maxSpendSats: record.maxSpendSats,
    connectedAt: _nullableDateFromMillis(record.connectedAt),
    endedAt: _nullableDateFromMillis(record.endedAt),
    connectedDurationSeconds: record.connectedDurationSeconds,
    chargedSats: record.chargedSats,
    refundedSats: record.refundedSats,
    createdAt: _dateFromMillis(record.createdAt),
    updatedAt: _dateFromMillis(record.updatedAt),
  );
}

CallPaymentSessionRecord _sessionToRecord(CallPaymentSession session) {
  return CallPaymentSessionRecord()
    ..ownerPubkey = session.owner.value
    ..callId = session.callId
    ..peerPubkey = session.peerPubkey
    ..direction = session.direction.name
    ..role = session.role.name
    ..callType = session.callType.name
    ..status = session.status.name
    ..mintUrl = session.mintUrl.toString()
    ..priceSatsPerMinute = session.priceSatsPerMinute
    ..billingPeriodSeconds = session.billingPeriodSeconds
    ..maxSpendSats = session.maxSpendSats
    ..connectedAt = session.connectedAt?.millisecondsSinceEpoch
    ..endedAt = session.endedAt?.millisecondsSinceEpoch
    ..connectedDurationSeconds = session.connectedDurationSeconds
    ..chargedSats = session.chargedSats
    ..refundedSats = session.refundedSats
    ..createdAt = session.createdAt.millisecondsSinceEpoch
    ..updatedAt = session.updatedAt.millisecondsSinceEpoch;
}

CallPaymentInstallment _installmentFromRecord(
  CallPaymentInstallmentRecord record,
) {
  return CallPaymentInstallment(
    owner: CashuAccountId.fromNostrPubkey(record.ownerPubkey),
    callId: record.callId,
    paymentSessionId: record.paymentSessionId,
    sequence: record.sequence,
    purpose: CallPaymentPurpose.values.byName(record.purpose),
    direction: CallPaymentTransferDirection.values.byName(record.direction),
    amountSats: record.amountSats,
    mintUrl: CashuMintUrl.parse(record.mintUrl),
    walletOperationId: record.walletOperationId.isEmpty
        ? null
        : record.walletOperationId,
    tokenHash: record.tokenHash,
    status: CallPaymentInstallmentStatus.values.byName(record.status),
    coversFromSecond: record.coversFromSecond,
    coversToSecond: record.coversToSecond,
    createdAt: _dateFromMillis(record.createdAt),
    sentAt: _nullableDateFromMillis(record.sentAt),
    claimedAt: _nullableDateFromMillis(record.claimedAt),
    reclaimedAt: _nullableDateFromMillis(record.reclaimedAt),
    refundedAt: _nullableDateFromMillis(record.refundedAt),
    updatedAt: _dateFromMillis(record.updatedAt),
    errorCode: record.errorCode,
  );
}

CallPaymentInstallmentRecord _installmentToRecord(
  CallPaymentInstallment installment,
) {
  return CallPaymentInstallmentRecord()
    ..ownerPubkey = installment.owner.value
    ..ownerPubkeyForWalletOperation = installment.owner.value
    ..idempotencyKey = _installmentIdempotencyKey(
      callId: installment.callId,
      sequence: installment.sequence,
      purpose: installment.purpose,
      direction: installment.direction,
    )
    ..callId = installment.callId
    ..paymentSessionId = installment.paymentSessionId
    ..sequence = installment.sequence
    ..purpose = installment.purpose.name
    ..direction = installment.direction.name
    ..amountSats = installment.amountSats
    ..mintUrl = installment.mintUrl.toString()
    ..walletOperationId = installment.walletOperationId ?? ''
    ..tokenHash = installment.tokenHash
    ..status = installment.status.name
    ..coversFromSecond = installment.coversFromSecond
    ..coversToSecond = installment.coversToSecond
    ..createdAt = installment.createdAt.millisecondsSinceEpoch
    ..sentAt = installment.sentAt?.millisecondsSinceEpoch
    ..claimedAt = installment.claimedAt?.millisecondsSinceEpoch
    ..reclaimedAt = installment.reclaimedAt?.millisecondsSinceEpoch
    ..refundedAt = installment.refundedAt?.millisecondsSinceEpoch
    ..updatedAt = installment.updatedAt.millisecondsSinceEpoch
    ..errorCode = installment.errorCode;
}

DateTime _dateFromMillis(int millis) {
  return DateTime.fromMillisecondsSinceEpoch(millis);
}

DateTime? _nullableDateFromMillis(int? millis) {
  return millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
}

String _installmentIdempotencyKey({
  required String callId,
  required int sequence,
  required CallPaymentPurpose purpose,
  required CallPaymentTransferDirection direction,
}) {
  return '$callId:$sequence:${purpose.name}:${direction.name}';
}
