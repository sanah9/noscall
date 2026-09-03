import 'dart:convert';

import 'package:noscall/call_payments/domain/call_payment_models.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';

enum CallPaymentEventType {
  transfer('transfer', 25055),
  ack('ack', 25056),
  required('required', 25057),
  refund('refund', 25058);

  const CallPaymentEventType(this.value, this.kind);

  final String value;
  final int kind;

  static CallPaymentEventType fromValue(Object? value) {
    return CallPaymentEventType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => throw FormatException('Unknown payment event type: $value'),
    );
  }
}

final class CallPaymentEventPayload {
  const CallPaymentEventPayload({
    required this.type,
    required this.callId,
    required this.paymentSessionId,
    required this.sequence,
    required this.purpose,
    required this.callType,
    required this.payerPubkey,
    required this.payeePubkey,
    required this.mintUrl,
    required this.amountSats,
    required this.billingPeriodSeconds,
    required this.coversFromSecond,
    required this.coversToSecond,
    required this.tokenHash,
    required this.createdAt,
    required this.expiresAt,
    this.token,
  });

  static const currentVersion = 1;

  final CallPaymentEventType type;
  final String callId;
  final String paymentSessionId;
  final int sequence;
  final CallPaymentPurpose purpose;
  final CallPaymentCallType callType;
  final String payerPubkey;
  final String payeePubkey;
  final CashuMintUrl mintUrl;
  final int amountSats;
  final int billingPeriodSeconds;
  final int coversFromSecond;
  final int coversToSecond;
  final String tokenHash;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String? token;
}

final class CallPaymentEventCodec {
  const CallPaymentEventCodec();

  String encode(CallPaymentEventPayload payload) {
    return jsonEncode(encodeMap(payload));
  }

  Map<String, Object?> encodeMap(CallPaymentEventPayload payload) {
    _validate(payload);
    return {
      'version': CallPaymentEventPayload.currentVersion,
      'type': payload.type.value,
      'callId': payload.callId,
      'paymentSessionId': payload.paymentSessionId,
      'sequence': payload.sequence,
      'purpose': payload.purpose.name,
      'callType': payload.callType.name,
      'payerPubkey': payload.payerPubkey,
      'payeePubkey': payload.payeePubkey,
      'mintUrl': payload.mintUrl.toString(),
      'amountSats': payload.amountSats,
      'billingPeriodSeconds': payload.billingPeriodSeconds,
      'coversFromSecond': payload.coversFromSecond,
      'coversToSecond': payload.coversToSecond,
      'tokenHash': payload.tokenHash,
      'createdAt': payload.createdAt.toUtc().toIso8601String(),
      'expiresAt': payload.expiresAt.toUtc().toIso8601String(),
      if (payload.token case final token?) 'token': token,
    };
  }

  CallPaymentEventPayload decode(String encoded) {
    final decoded = jsonDecode(encoded);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Payment event payload must be an object');
    }
    return decodeMap(decoded);
  }

  CallPaymentEventPayload decodeMap(Map<String, Object?> map) {
    final version = _readInt(map, 'version');
    if (version != CallPaymentEventPayload.currentVersion) {
      throw FormatException('Unsupported payment event version: $version');
    }
    final payload = CallPaymentEventPayload(
      type: CallPaymentEventType.fromValue(map['type']),
      callId: _readString(map, 'callId'),
      paymentSessionId: _readString(map, 'paymentSessionId'),
      sequence: _readInt(map, 'sequence'),
      purpose: CallPaymentPurpose.values.byName(_readString(map, 'purpose')),
      callType: CallPaymentCallType.values.byName(_readString(map, 'callType')),
      payerPubkey: _readString(map, 'payerPubkey'),
      payeePubkey: _readString(map, 'payeePubkey'),
      mintUrl: CashuMintUrl.parse(_readString(map, 'mintUrl')),
      amountSats: _readInt(map, 'amountSats'),
      billingPeriodSeconds: _readInt(map, 'billingPeriodSeconds'),
      coversFromSecond: _readInt(map, 'coversFromSecond'),
      coversToSecond: _readInt(map, 'coversToSecond'),
      tokenHash: _readString(map, 'tokenHash'),
      createdAt: DateTime.parse(_readString(map, 'createdAt')).toUtc(),
      expiresAt: DateTime.parse(_readString(map, 'expiresAt')).toUtc(),
      token: map['token'] == null ? null : _readString(map, 'token'),
    );
    _validate(payload);
    return payload;
  }

  void _validate(CallPaymentEventPayload payload) {
    if (payload.callId.isEmpty || payload.paymentSessionId.isEmpty) {
      throw ArgumentError('Payment event requires call and session ids');
    }
    if (payload.sequence <= 0) {
      throw ArgumentError('Payment event sequence must be positive');
    }
    if (payload.amountSats <= 0) {
      throw ArgumentError('Payment event amount must be positive');
    }
    if (payload.billingPeriodSeconds <= 0 ||
        payload.coversFromSecond < 0 ||
        payload.coversToSecond <= payload.coversFromSecond) {
      throw ArgumentError('Payment event coverage is invalid');
    }
    if (payload.coversToSecond - payload.coversFromSecond !=
        payload.billingPeriodSeconds) {
      throw ArgumentError('Payment event coverage must match billing period');
    }
    switch (payload.type) {
      case CallPaymentEventType.transfer:
        if (payload.purpose == CallPaymentPurpose.refund) {
          throw ArgumentError('Payment transfer purpose is invalid');
        }
        if (payload.token == null || payload.token!.isEmpty) {
          throw ArgumentError('Payment transfer events require a token');
        }
      case CallPaymentEventType.refund:
        if (payload.purpose != CallPaymentPurpose.refund) {
          throw ArgumentError('Payment refund purpose is invalid');
        }
        if (payload.token == null || payload.token!.isEmpty) {
          throw ArgumentError('Payment transfer events require a token');
        }
      case CallPaymentEventType.ack:
        if (payload.purpose == CallPaymentPurpose.refund) {
          throw ArgumentError('Payment ack purpose is invalid');
        }
        if (payload.token != null) {
          throw ArgumentError(
            'Payment control events must not include a token',
          );
        }
      case CallPaymentEventType.required:
        if (payload.purpose != CallPaymentPurpose.initial) {
          throw ArgumentError('Payment required purpose is invalid');
        }
        if (payload.token != null) {
          throw ArgumentError(
            'Payment control events must not include a token',
          );
        }
    }
  }

  String _readString(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is String && value.isNotEmpty) return value;
    throw FormatException('Payment event field "$key" must be a string');
  }

  int _readInt(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is int) return value;
    throw FormatException('Payment event field "$key" must be an integer');
  }
}
