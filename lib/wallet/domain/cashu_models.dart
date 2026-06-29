import 'dart:collection';

import 'cashu_account_id.dart';

/// Cashu protocol features required or recognized by the wallet.
enum CashuNut {
  nut00(0),
  nut01(1),
  nut02(2),
  nut03(3),
  nut04(4),
  nut05(5),
  nut06(6),
  nut07(7),
  nut08(8),
  nut09(9),
  nut12(12),
  nut13(13),
  nut23(23);

  const CashuNut(this.number);

  final int number;
}

/// A normalized HTTPS Cashu mint URL.
final class CashuMintUrl {
  CashuMintUrl._(this.uri);

  factory CashuMintUrl.parse(String value, {bool allowInsecureHttp = false}) {
    final trimmed = value.trim();
    final parsed = Uri.tryParse(trimmed);
    if (parsed == null || !parsed.hasScheme || parsed.host.isEmpty) {
      throw const FormatException('Invalid Cashu mint URL');
    }

    final scheme = parsed.scheme.toLowerCase();
    final allowedScheme =
        scheme == 'https' || (allowInsecureHttp && scheme == 'http');
    if (!allowedScheme) {
      throw const FormatException('Cashu mint URL must use HTTPS');
    }
    if (parsed.hasQuery || parsed.hasFragment || parsed.userInfo.isNotEmpty) {
      throw const FormatException(
        'Cashu mint URL cannot contain credentials, query, or fragment',
      );
    }

    var path = parsed.path;
    while (path.endsWith('/') && path.length > 1) {
      path = path.substring(0, path.length - 1);
    }
    if (path == '/') path = '';

    return CashuMintUrl._(
      parsed.replace(
        scheme: scheme,
        host: parsed.host.toLowerCase(),
        path: path,
        query: null,
        fragment: null,
      ),
    );
  }

  final Uri uri;

  @override
  String toString() => uri.toString();

  @override
  bool operator ==(Object other) => other is CashuMintUrl && other.uri == uri;

  @override
  int get hashCode => uri.hashCode;
}

/// A non-negative amount denominated in satoshis.
final class CashuAmount {
  const CashuAmount._(this.value);

  factory CashuAmount.sats(int value) {
    if (value < 0) {
      throw ArgumentError.value(value, 'value', 'Amount cannot be negative');
    }
    return CashuAmount._(value);
  }

  factory CashuAmount.positiveSats(int value) {
    if (value <= 0) {
      throw ArgumentError.value(value, 'value', 'Amount must be positive');
    }
    return CashuAmount._(value);
  }

  final int value;

  CashuAmount operator +(CashuAmount other) =>
      CashuAmount.sats(value + other.value);

  CashuAmount operator -(CashuAmount other) {
    if (other.value > value) {
      throw StateError('Cashu amount cannot become negative');
    }
    return CashuAmount.sats(value - other.value);
  }

  @override
  bool operator ==(Object other) =>
      other is CashuAmount && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => '$value sat';
}

enum CashuQuoteState { unpaid, pending, paid, issued, expired, failed, unknown }

enum CashuSendState { prepared, recoverable, claimed, reclaimed, unknown }

final class CashuMintSnapshot {
  CashuMintSnapshot({
    required this.url,
    required Set<CashuNut> supportedNuts,
    required this.supportsSat,
    required this.supportsBolt11Mint,
    required this.supportsBolt11Melt,
    this.name,
    this.description,
    this.version,
  }) : supportedNuts = UnmodifiableSetView(Set.of(supportedNuts));

  final CashuMintUrl url;
  final String? name;
  final String? description;
  final String? version;
  final Set<CashuNut> supportedNuts;
  final bool supportsSat;
  final bool supportsBolt11Mint;
  final bool supportsBolt11Melt;
}

final class CashuTokenSummary {
  const CashuTokenSummary({
    required this.encodedToken,
    required this.mintUrl,
    required this.amount,
    required this.version,
    this.memo,
  });

  final String encodedToken;
  final CashuMintUrl mintUrl;
  final CashuAmount amount;
  final int version;
  final String? memo;
}

final class CashuReceiveRequest {
  const CashuReceiveRequest({required this.encodedToken});

  final String encodedToken;
}

final class CashuReceiveResult {
  const CashuReceiveResult({required this.operationId, required this.amount});

  final String operationId;
  final CashuAmount amount;
}

final class CashuSendRequest {
  const CashuSendRequest({
    required this.mintUrl,
    required this.amount,
    this.memo,
  });

  final CashuMintUrl mintUrl;
  final CashuAmount amount;
  final String? memo;
}

final class CashuPreparedSend {
  const CashuPreparedSend({
    required this.operationId,
    required this.token,
    required this.amount,
  });

  final String operationId;
  final String token;
  final CashuAmount amount;
}

final class CashuMintQuote {
  const CashuMintQuote({
    required this.quoteId,
    required this.mintUrl,
    required this.amount,
    required this.request,
    required this.state,
    required this.expiry,
  });

  final String quoteId;
  final CashuMintUrl mintUrl;
  final CashuAmount amount;
  final String request;
  final CashuQuoteState state;
  final DateTime expiry;
}

final class CashuMeltQuote {
  const CashuMeltQuote({
    required this.quoteId,
    required this.mintUrl,
    required this.amount,
    required this.feeReserve,
    required this.state,
    required this.expiry,
  });

  final String quoteId;
  final CashuMintUrl mintUrl;
  final CashuAmount amount;
  final CashuAmount feeReserve;
  final CashuQuoteState state;
  final DateTime expiry;
}

final class CashuMeltResult {
  const CashuMeltResult({
    required this.quoteId,
    required this.state,
    required this.amountSpent,
    required this.feePaid,
    this.paymentPreimage,
  });

  final String quoteId;
  final CashuQuoteState state;
  final CashuAmount amountSpent;
  final CashuAmount feePaid;
  final String? paymentPreimage;
}

final class CashuRestoreResult {
  CashuRestoreResult({
    required this.restoredAmount,
    required Iterable<CashuMintUrl> restoredMints,
  }) : restoredMints = List.unmodifiable(restoredMints);

  final CashuAmount restoredAmount;
  final List<CashuMintUrl> restoredMints;
}

final class CashuReconciliationResult {
  const CashuReconciliationResult({
    required this.recoveredOperations,
    required this.pendingOperations,
  });

  final int recoveredOperations;
  final int pendingOperations;
}

final class CashuTokenSendRecord {
  const CashuTokenSendRecord({
    required this.owner,
    required this.operationId,
    required this.mintUrl,
    required this.amount,
    required this.state,
    required this.createdAt,
    required this.updatedAt,
    this.memo,
  });

  final CashuAccountId owner;
  final String operationId;
  final CashuMintUrl mintUrl;
  final CashuAmount amount;
  final CashuSendState state;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? memo;

  CashuTokenSendRecord copyWith({CashuSendState? state, DateTime? updatedAt}) {
    return CashuTokenSendRecord(
      owner: owner,
      operationId: operationId,
      mintUrl: mintUrl,
      amount: amount,
      state: state ?? this.state,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      memo: memo,
    );
  }
}

abstract interface class CashuTokenSendRepository {
  Future<CashuTokenSendRecord?> find(CashuAccountId owner, String operationId);

  Future<List<CashuTokenSendRecord>> list(CashuAccountId owner);

  Future<void> save(CashuTokenSendRecord record);
}
