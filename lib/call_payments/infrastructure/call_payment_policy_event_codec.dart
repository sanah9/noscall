import 'dart:convert';

import 'package:noscall/call_payments/domain/call_payment_models.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';

enum CallPaymentPolicyEventType {
  query('policy_query', 25059),
  response('policy_response', 25060);

  const CallPaymentPolicyEventType(this.value, this.kind);

  final String value;
  final int kind;

  static CallPaymentPolicyEventType fromValue(Object? value) {
    return CallPaymentPolicyEventType.values.firstWhere(
      (type) => type.value == value,
      orElse: () =>
          throw FormatException('Unknown payment policy event type: $value'),
    );
  }
}

final class CallPaymentPolicyEventPayload {
  const CallPaymentPolicyEventPayload({
    required this.type,
    required this.requestId,
    required this.requesterPubkey,
    required this.responderPubkey,
    required this.createdAt,
    this.policy,
  });

  static const currentVersion = 1;

  final CallPaymentPolicyEventType type;
  final String requestId;
  final String requesterPubkey;
  final String responderPubkey;
  final DateTime createdAt;
  final CallPaymentPolicy? policy;
}

final class CallPaymentPolicyEventCodec {
  const CallPaymentPolicyEventCodec();

  String encode(CallPaymentPolicyEventPayload payload) {
    return jsonEncode(encodeMap(payload));
  }

  Map<String, Object?> encodeMap(CallPaymentPolicyEventPayload payload) {
    _validate(payload);
    return {
      'version': CallPaymentPolicyEventPayload.currentVersion,
      'type': payload.type.value,
      'requestId': payload.requestId,
      'requesterPubkey': payload.requesterPubkey,
      'responderPubkey': payload.responderPubkey,
      'createdAt': payload.createdAt.toUtc().toIso8601String(),
      if (payload.policy case final policy?) 'policy': _policyToMap(policy),
    };
  }

  CallPaymentPolicyEventPayload decode(String encoded) {
    final decoded = jsonDecode(encoded);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Policy event payload must be an object');
    }
    return decodeMap(decoded);
  }

  CallPaymentPolicyEventPayload decodeMap(Map<String, Object?> map) {
    final version = _readInt(map, 'version');
    if (version != CallPaymentPolicyEventPayload.currentVersion) {
      throw FormatException('Unsupported policy event version: $version');
    }
    final type = CallPaymentPolicyEventType.fromValue(map['type']);
    return CallPaymentPolicyEventPayload(
      type: type,
      requestId: _readString(map, 'requestId'),
      requesterPubkey: _readString(map, 'requesterPubkey'),
      responderPubkey: _readString(map, 'responderPubkey'),
      createdAt: DateTime.parse(_readString(map, 'createdAt')).toUtc(),
      policy: map['policy'] == null
          ? null
          : _policyFromMap(_readMap(map, 'policy')),
    );
  }

  void _validate(CallPaymentPolicyEventPayload payload) {
    if (payload.requestId.isEmpty ||
        payload.requesterPubkey.isEmpty ||
        payload.responderPubkey.isEmpty) {
      throw ArgumentError('Policy event requires request and participant ids');
    }
    if (payload.type == CallPaymentPolicyEventType.response &&
        payload.policy == null) {
      throw ArgumentError('Policy response requires a policy');
    }
    if (payload.policy case final policy?
        when policy.owner.value != payload.responderPubkey) {
      throw ArgumentError('Policy response owner must match responder');
    }
  }

  Map<String, Object?> _policyToMap(CallPaymentPolicy policy) {
    return {
      'owner': policy.owner.value,
      'enabled': policy.enabled,
      'freePolicy': policy.freePolicy.name,
      'freePubkeys': policy.freePubkeys,
      'audioPriceSatsPerMinute': policy.audioPriceSatsPerMinute,
      'videoPriceSatsPerMinute': policy.videoPriceSatsPerMinute,
      'billingPeriodSeconds': policy.billingPeriodSeconds,
      'gracePeriodSeconds': policy.gracePeriodSeconds,
      'acceptedMintUrls': policy.acceptedMintUrls
          .map((mintUrl) => mintUrl.toString())
          .toList(growable: false),
      'createdAt': policy.createdAt.toUtc().toIso8601String(),
      'updatedAt': policy.updatedAt.toUtc().toIso8601String(),
    };
  }

  CallPaymentPolicy _policyFromMap(Map<String, Object?> map) {
    return CallPaymentPolicy(
      owner: CashuAccountId.fromNostrPubkey(_readString(map, 'owner')),
      enabled: _readBool(map, 'enabled'),
      freePolicy: CallPaymentFreePolicy.values.byName(
        _readString(map, 'freePolicy'),
      ),
      freePubkeys: _readStringList(map, 'freePubkeys'),
      audioPriceSatsPerMinute: _readInt(map, 'audioPriceSatsPerMinute'),
      videoPriceSatsPerMinute: _readInt(map, 'videoPriceSatsPerMinute'),
      billingPeriodSeconds: _readInt(map, 'billingPeriodSeconds'),
      gracePeriodSeconds: _readInt(map, 'gracePeriodSeconds'),
      acceptedMintUrls: _readStringList(
        map,
        'acceptedMintUrls',
      ).map(CashuMintUrl.parse),
      createdAt: DateTime.parse(_readString(map, 'createdAt')).toUtc(),
      updatedAt: DateTime.parse(_readString(map, 'updatedAt')).toUtc(),
    );
  }

  Map<String, Object?> _readMap(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is Map) {
      return value.cast<String, Object?>();
    }
    throw FormatException('Policy event field "$key" must be an object');
  }

  List<String> _readStringList(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is List && value.every((item) => item is String)) {
      return value.cast<String>();
    }
    throw FormatException('Policy event field "$key" must be a string list');
  }

  String _readString(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is String && value.isNotEmpty) return value;
    throw FormatException('Policy event field "$key" must be a string');
  }

  int _readInt(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is int) return value;
    throw FormatException('Policy event field "$key" must be an integer');
  }

  bool _readBool(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is bool) return value;
    throw FormatException('Policy event field "$key" must be a bool');
  }
}
