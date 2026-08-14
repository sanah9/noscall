import 'package:isar/isar.dart';

part 'call_payment_isar.g.dart';

@collection
class CallPaymentPolicyRecord {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  String ownerPubkey = '';

  bool enabled = false;
  String freePolicy = '';
  List<String> freePubkeys = const [];
  int audioPriceSatsPerMinute = 0;
  int videoPriceSatsPerMinute = 0;
  int billingPeriodSeconds = 60;
  int gracePeriodSeconds = 10;
  List<String> acceptedMintUrls = const [];
  int createdAt = 0;
  int updatedAt = 0;
}

@collection
class CallPaymentSessionRecord {
  Id id = Isar.autoIncrement;

  @Index(composite: [CompositeIndex('callId')], unique: true, replace: true)
  String ownerPubkey = '';

  String callId = '';
  String peerPubkey = '';
  String direction = '';
  String role = '';
  String callType = '';
  String status = '';
  String mintUrl = '';
  int priceSatsPerMinute = 0;
  int billingPeriodSeconds = 60;
  int maxSpendSats = 0;
  int? connectedAt;
  int? endedAt;
  int connectedDurationSeconds = 0;
  int chargedSats = 0;
  int refundedSats = 0;
  int createdAt = 0;
  int updatedAt = 0;
}

@collection
class CallPaymentInstallmentRecord {
  Id id = Isar.autoIncrement;

  @Index(
    composite: [CompositeIndex('idempotencyKey')],
    unique: true,
    replace: true,
  )
  String ownerPubkey = '';

  @Index(composite: [CompositeIndex('walletOperationId')])
  String ownerPubkeyForWalletOperation = '';

  String idempotencyKey = '';
  String callId = '';
  String paymentSessionId = '';
  int sequence = 0;
  String purpose = '';
  String direction = '';
  int amountSats = 0;
  String mintUrl = '';
  String walletOperationId = '';
  String? tokenHash;
  String status = '';
  int coversFromSecond = 0;
  int coversToSecond = 0;
  int createdAt = 0;
  int? sentAt;
  int? claimedAt;
  int? reclaimedAt;
  int? refundedAt;
  int updatedAt = 0;
  String? errorCode;
}
