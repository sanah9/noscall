import 'package:noscall/wallet/domain/cashu_account_id.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';

enum CallPaymentFreePolicy {
  everyonePays,
  contactsFree,
  whitelistFree,
  everyoneFree,
}

enum CallPaymentCallDirection { incoming, outgoing }

enum CallPaymentCallType { audio, video }

enum CallPaymentRole { payer, payee }

enum CallPaymentPurpose { initial, topUp, refund }

enum CallPaymentTransferDirection { sent, received }

enum CallPaymentSessionStatus {
  idle,
  awaitingUserConfirmation,
  preparingInitialPayment,
  initialPaymentSent,
  ringing,
  connected,
  toppingUp,
  ending,
  completed,
  paymentFailed,
  insufficientBalance,
  noCommonMint,
  rejected,
  timeout,
  reclaimPending,
  refundPending,
  disputed,
}

enum CallPaymentInstallmentStatus {
  created,
  prepared,
  sent,
  received,
  claimed,
  reclaimable,
  reclaimed,
  refunded,
  failed,
  unknown,
}

final class CallPaymentPolicy {
  CallPaymentPolicy({
    required this.owner,
    required this.enabled,
    required this.freePolicy,
    required Iterable<String> freePubkeys,
    required this.audioPriceSatsPerMinute,
    required this.videoPriceSatsPerMinute,
    required this.billingPeriodSeconds,
    required this.gracePeriodSeconds,
    required Iterable<CashuMintUrl> acceptedMintUrls,
    required this.createdAt,
    required this.updatedAt,
  }) : freePubkeys = List.unmodifiable(freePubkeys),
       acceptedMintUrls = List.unmodifiable(acceptedMintUrls) {
    if (audioPriceSatsPerMinute < 0 || videoPriceSatsPerMinute < 0) {
      throw ArgumentError('Call payment prices cannot be negative');
    }
    if (billingPeriodSeconds <= 0 || gracePeriodSeconds < 0) {
      throw ArgumentError('Invalid call payment timing configuration');
    }
  }

  final CashuAccountId owner;
  final bool enabled;
  final CallPaymentFreePolicy freePolicy;
  final List<String> freePubkeys;
  final int audioPriceSatsPerMinute;
  final int videoPriceSatsPerMinute;
  final int billingPeriodSeconds;
  final int gracePeriodSeconds;
  final List<CashuMintUrl> acceptedMintUrls;
  final DateTime createdAt;
  final DateTime updatedAt;

  CallPaymentPolicy copyWith({
    bool? enabled,
    CallPaymentFreePolicy? freePolicy,
    Iterable<String>? freePubkeys,
    int? audioPriceSatsPerMinute,
    int? videoPriceSatsPerMinute,
    int? billingPeriodSeconds,
    int? gracePeriodSeconds,
    Iterable<CashuMintUrl>? acceptedMintUrls,
    DateTime? updatedAt,
  }) {
    return CallPaymentPolicy(
      owner: owner,
      enabled: enabled ?? this.enabled,
      freePolicy: freePolicy ?? this.freePolicy,
      freePubkeys: freePubkeys ?? this.freePubkeys,
      audioPriceSatsPerMinute:
          audioPriceSatsPerMinute ?? this.audioPriceSatsPerMinute,
      videoPriceSatsPerMinute:
          videoPriceSatsPerMinute ?? this.videoPriceSatsPerMinute,
      billingPeriodSeconds: billingPeriodSeconds ?? this.billingPeriodSeconds,
      gracePeriodSeconds: gracePeriodSeconds ?? this.gracePeriodSeconds,
      acceptedMintUrls: acceptedMintUrls ?? this.acceptedMintUrls,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

final class CallPaymentSession {
  const CallPaymentSession({
    required this.owner,
    required this.callId,
    required this.peerPubkey,
    required this.direction,
    required this.role,
    required this.callType,
    required this.status,
    required this.mintUrl,
    required this.priceSatsPerMinute,
    required this.billingPeriodSeconds,
    required this.maxSpendSats,
    required this.connectedDurationSeconds,
    required this.chargedSats,
    required this.refundedSats,
    required this.createdAt,
    required this.updatedAt,
    this.connectedAt,
    this.endedAt,
  });

  final CashuAccountId owner;
  final String callId;
  final String peerPubkey;
  final CallPaymentCallDirection direction;
  final CallPaymentRole role;
  final CallPaymentCallType callType;
  final CallPaymentSessionStatus status;
  final CashuMintUrl mintUrl;
  final int priceSatsPerMinute;
  final int billingPeriodSeconds;
  final int maxSpendSats;
  final DateTime? connectedAt;
  final DateTime? endedAt;
  final int connectedDurationSeconds;
  final int chargedSats;
  final int refundedSats;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get netSats => chargedSats - refundedSats;

  CallPaymentSession copyWith({
    CallPaymentSessionStatus? status,
    DateTime? connectedAt,
    DateTime? endedAt,
    int? connectedDurationSeconds,
    int? chargedSats,
    int? refundedSats,
    DateTime? updatedAt,
  }) {
    return CallPaymentSession(
      owner: owner,
      callId: callId,
      peerPubkey: peerPubkey,
      direction: direction,
      role: role,
      callType: callType,
      status: status ?? this.status,
      mintUrl: mintUrl,
      priceSatsPerMinute: priceSatsPerMinute,
      billingPeriodSeconds: billingPeriodSeconds,
      maxSpendSats: maxSpendSats,
      connectedAt: connectedAt ?? this.connectedAt,
      endedAt: endedAt ?? this.endedAt,
      connectedDurationSeconds:
          connectedDurationSeconds ?? this.connectedDurationSeconds,
      chargedSats: chargedSats ?? this.chargedSats,
      refundedSats: refundedSats ?? this.refundedSats,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

final class CallPaymentInstallment {
  const CallPaymentInstallment({
    required this.owner,
    required this.callId,
    required this.paymentSessionId,
    required this.sequence,
    required this.purpose,
    required this.direction,
    required this.amountSats,
    required this.mintUrl,
    required this.status,
    required this.coversFromSecond,
    required this.coversToSecond,
    required this.createdAt,
    required this.updatedAt,
    this.walletOperationId,
    this.tokenHash,
    this.sentAt,
    this.claimedAt,
    this.reclaimedAt,
    this.refundedAt,
    this.errorCode,
  });

  final CashuAccountId owner;
  final String callId;
  final String paymentSessionId;
  final int sequence;
  final CallPaymentPurpose purpose;
  final CallPaymentTransferDirection direction;
  final int amountSats;
  final CashuMintUrl mintUrl;
  final String? walletOperationId;
  final String? tokenHash;
  final CallPaymentInstallmentStatus status;
  final int coversFromSecond;
  final int coversToSecond;
  final DateTime createdAt;
  final DateTime? sentAt;
  final DateTime? claimedAt;
  final DateTime? reclaimedAt;
  final DateTime? refundedAt;
  final DateTime updatedAt;
  final String? errorCode;

  CallPaymentInstallment copyWith({
    String? walletOperationId,
    String? tokenHash,
    CallPaymentInstallmentStatus? status,
    DateTime? sentAt,
    DateTime? claimedAt,
    DateTime? reclaimedAt,
    DateTime? refundedAt,
    DateTime? updatedAt,
    String? errorCode,
    bool clearErrorCode = false,
  }) {
    return CallPaymentInstallment(
      owner: owner,
      callId: callId,
      paymentSessionId: paymentSessionId,
      sequence: sequence,
      purpose: purpose,
      direction: direction,
      amountSats: amountSats,
      mintUrl: mintUrl,
      walletOperationId: walletOperationId ?? this.walletOperationId,
      tokenHash: tokenHash ?? this.tokenHash,
      status: status ?? this.status,
      coversFromSecond: coversFromSecond,
      coversToSecond: coversToSecond,
      createdAt: createdAt,
      sentAt: sentAt ?? this.sentAt,
      claimedAt: claimedAt ?? this.claimedAt,
      reclaimedAt: reclaimedAt ?? this.reclaimedAt,
      refundedAt: refundedAt ?? this.refundedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      errorCode: clearErrorCode ? null : errorCode ?? this.errorCode,
    );
  }
}
