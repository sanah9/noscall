import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:noscall/call_payments/domain/call_payment_models.dart';
import 'package:noscall/call_payments/infrastructure/call_payment_isar.dart';
import 'package:noscall/call_payments/infrastructure/isar_call_payment_repository.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';

void main() {
  late Directory directory;
  Isar? isar;
  late IsarCallPaymentPolicyRepository policyRepository;
  late IsarCallPaymentSessionRepository sessionRepository;
  late IsarCallPaymentInstallmentRepository installmentRepository;

  setUpAll(_initializeIsarForTests);

  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'noscall_call_payment_isar_',
    );
    final database = isar = await Isar.open(
      [
        CallPaymentPolicyRecordSchema,
        CallPaymentSessionRecordSchema,
        CallPaymentInstallmentRecordSchema,
      ],
      directory: directory.path,
      name: 'call_payment_test',
    );
    policyRepository = IsarCallPaymentPolicyRepository(database);
    sessionRepository = IsarCallPaymentSessionRepository(database);
    installmentRepository = IsarCallPaymentInstallmentRepository(database);
  });

  tearDown(() async {
    final database = isar;
    if (database != null && database.isOpen) {
      await database.close(deleteFromDisk: true);
    }
    isar = null;
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  test('upserts one paid call policy per Nostr account', () async {
    final owner = _account('a');
    final now = DateTime.utc(2026, 8, 13);

    await policyRepository.save(
      _policy(owner: owner, enabled: false, audioPrice: 10, now: now),
    );
    await policyRepository.save(
      _policy(
        owner: owner,
        enabled: true,
        audioPrice: 21,
        now: now.add(const Duration(minutes: 1)),
      ),
    );

    final stored = await policyRepository.find(owner);
    expect(stored?.enabled, isTrue);
    expect(stored?.audioPriceSatsPerMinute, 21);
    expect(await isar!.callPaymentPolicyRecords.count(), 1);
  });

  test('isolates equal paid call sessions between Nostr accounts', () async {
    final ownerA = _account('a');
    final ownerB = _account('b');
    final now = DateTime.utc(2026, 8, 13);

    await sessionRepository.save(
      _session(
        owner: ownerA,
        callId: 'call-1',
        status: CallPaymentSessionStatus.initialPaymentSent,
        now: now,
      ),
    );
    await sessionRepository.save(
      _session(
        owner: ownerB,
        callId: 'call-1',
        status: CallPaymentSessionStatus.connected,
        now: now,
      ),
    );
    await sessionRepository.save(
      _session(
        owner: ownerA,
        callId: 'call-1',
        status: CallPaymentSessionStatus.completed,
        now: now.add(const Duration(minutes: 2)),
      ),
    );

    expect(
      (await sessionRepository.find(ownerA, 'call-1'))?.status,
      CallPaymentSessionStatus.completed,
    );
    expect(
      (await sessionRepository.find(ownerB, 'call-1'))?.status,
      CallPaymentSessionStatus.connected,
    );
    expect(await sessionRepository.list(ownerA), hasLength(1));
  });

  test('upserts and lists installments by idempotency key', () async {
    final owner = _account('a');
    final now = DateTime.utc(2026, 8, 13);

    await installmentRepository.save(
      _installment(
        owner: owner,
        callId: 'call-1',
        sequence: 1,
        purpose: CallPaymentPurpose.initial,
        direction: CallPaymentTransferDirection.sent,
        status: CallPaymentInstallmentStatus.sent,
        walletOperationId: 'wallet-op-1',
        now: now,
      ),
    );
    await installmentRepository.save(
      _installment(
        owner: owner,
        callId: 'call-1',
        sequence: 1,
        purpose: CallPaymentPurpose.initial,
        direction: CallPaymentTransferDirection.sent,
        status: CallPaymentInstallmentStatus.claimed,
        walletOperationId: 'wallet-op-1',
        now: now.add(const Duration(minutes: 1)),
      ),
    );
    await installmentRepository.save(
      _installment(
        owner: owner,
        callId: 'call-1',
        sequence: 2,
        purpose: CallPaymentPurpose.topUp,
        direction: CallPaymentTransferDirection.sent,
        status: CallPaymentInstallmentStatus.prepared,
        walletOperationId: 'wallet-op-2',
        now: now.add(const Duration(minutes: 2)),
      ),
    );

    final first = await installmentRepository.find(
      owner: owner,
      callId: 'call-1',
      sequence: 1,
      purpose: CallPaymentPurpose.initial,
      direction: CallPaymentTransferDirection.sent,
    );
    final byOperation = await installmentRepository.findByWalletOperationId(
      owner: owner,
      walletOperationId: 'wallet-op-1',
    );
    final all = await installmentRepository.listForCall(
      owner: owner,
      callId: 'call-1',
    );

    expect(first?.status, CallPaymentInstallmentStatus.claimed);
    expect(byOperation?.sequence, 1);
    expect(all.map((record) => record.sequence), [1, 2]);
    expect(await isar!.callPaymentInstallmentRecords.count(), 2);
  });

  test('isolates wallet operation lookup by Nostr account', () async {
    final ownerA = _account('a');
    final ownerB = _account('b');
    final now = DateTime.utc(2026, 8, 13);

    await installmentRepository.save(
      _installment(
        owner: ownerA,
        callId: 'call-a',
        sequence: 1,
        purpose: CallPaymentPurpose.initial,
        direction: CallPaymentTransferDirection.sent,
        status: CallPaymentInstallmentStatus.sent,
        walletOperationId: 'same-wallet-op',
        now: now,
      ),
    );
    await installmentRepository.save(
      _installment(
        owner: ownerB,
        callId: 'call-b',
        sequence: 1,
        purpose: CallPaymentPurpose.initial,
        direction: CallPaymentTransferDirection.sent,
        status: CallPaymentInstallmentStatus.reclaimed,
        walletOperationId: 'same-wallet-op',
        now: now,
      ),
    );

    expect(
      (await installmentRepository.findByWalletOperationId(
        owner: ownerA,
        walletOperationId: 'same-wallet-op',
      ))?.callId,
      'call-a',
    );
    expect(
      (await installmentRepository.findByWalletOperationId(
        owner: ownerB,
        walletOperationId: 'same-wallet-op',
      ))?.callId,
      'call-b',
    );
  });
}

Future<void> _initializeIsarForTests() async {
  final pubCache =
      Platform.environment['PUB_CACHE'] ??
      '${Platform.environment['HOME']}/.pub-cache';
  final packageRoot =
      '$pubCache/hosted/pub.dev/isar_flutter_libs-${Isar.version}';
  late final String libraryPath;
  if (Platform.isMacOS) {
    libraryPath = '$packageRoot/macos/libisar.dylib';
  } else if (Platform.isLinux) {
    libraryPath = '$packageRoot/linux/libisar.so';
  } else if (Platform.isWindows) {
    libraryPath = '$packageRoot/windows/isar.dll';
  } else {
    throw UnsupportedError('Isar VM tests are unsupported on this platform');
  }
  await Isar.initializeIsarCore(libraries: {Abi.current(): libraryPath});
}

CallPaymentPolicy _policy({
  required CashuAccountId owner,
  required bool enabled,
  required int audioPrice,
  required DateTime now,
}) {
  return CallPaymentPolicy(
    owner: owner,
    enabled: enabled,
    freePolicy: CallPaymentFreePolicy.contactsFree,
    freePubkeys: const [],
    audioPriceSatsPerMinute: audioPrice,
    videoPriceSatsPerMinute: 30,
    billingPeriodSeconds: 60,
    gracePeriodSeconds: 10,
    acceptedMintUrls: [CashuMintUrl.parse('https://mint.example.com')],
    createdAt: now,
    updatedAt: now,
  );
}

CallPaymentSession _session({
  required CashuAccountId owner,
  required String callId,
  required CallPaymentSessionStatus status,
  required DateTime now,
}) {
  return CallPaymentSession(
    owner: owner,
    callId: callId,
    peerPubkey: 'c' * 64,
    direction: CallPaymentCallDirection.outgoing,
    role: CallPaymentRole.payer,
    callType: CallPaymentCallType.audio,
    status: status,
    mintUrl: CashuMintUrl.parse('https://mint.example.com'),
    priceSatsPerMinute: 10,
    billingPeriodSeconds: 60,
    maxSpendSats: 100,
    connectedDurationSeconds: status == CallPaymentSessionStatus.completed
        ? 61
        : 0,
    chargedSats: status == CallPaymentSessionStatus.completed ? 20 : 10,
    refundedSats: 0,
    createdAt: now,
    updatedAt: now,
  );
}

CallPaymentInstallment _installment({
  required CashuAccountId owner,
  required String callId,
  required int sequence,
  required CallPaymentPurpose purpose,
  required CallPaymentTransferDirection direction,
  required CallPaymentInstallmentStatus status,
  required String walletOperationId,
  required DateTime now,
}) {
  return CallPaymentInstallment(
    owner: owner,
    callId: callId,
    paymentSessionId: 'session-$callId',
    sequence: sequence,
    purpose: purpose,
    direction: direction,
    amountSats: 10,
    mintUrl: CashuMintUrl.parse('https://mint.example.com'),
    walletOperationId: walletOperationId,
    tokenHash: 'hash-$sequence',
    status: status,
    coversFromSecond: (sequence - 1) * 60,
    coversToSecond: sequence * 60,
    createdAt: now,
    sentAt: now,
    updatedAt: now,
  );
}

CashuAccountId _account(String character) =>
    CashuAccountId.fromNostrPubkey(character * 64);
