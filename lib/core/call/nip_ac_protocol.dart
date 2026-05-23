import 'dart:convert';

import 'package:bip340/bip340.dart' as bip340;
import 'package:nostr_core_dart/nostr.dart';

enum NipAcKind {
  offer(25050),
  answer(25051),
  candidate(25052),
  hangup(25053),
  reject(25054);

  final int value;
  const NipAcKind(this.value);

  static NipAcKind? fromValue(int value) {
    for (final item in NipAcKind.values) {
      if (item.value == value) return item;
    }
    return null;
  }
}

class NipAcSignaling {
  final String sender;
  final String receiver;
  final String content;
  final String callId;
  final String? callType;
  final NipAcKind kind;

  const NipAcSignaling({
    required this.sender,
    required this.receiver,
    required this.content,
    required this.callId,
    required this.kind,
    this.callType,
  });

  SignalingState get state {
    switch (kind) {
      case NipAcKind.offer:
        return SignalingState.offer;
      case NipAcKind.answer:
        return SignalingState.answer;
      case NipAcKind.candidate:
        return SignalingState.candidate;
      case NipAcKind.hangup:
      case NipAcKind.reject:
        return SignalingState.disconnect;
    }
  }
}

class NipAcProtocol {
  static const int wrapKind = 21059;
  static const String _alt = 'NIP-AC signaling';
  static const String callTypeVoice = 'voice';
  static const String callTypeVideo = 'video';

  static Future<Event> createOffer({
    required String toPubkey,
    required String callId,
    required String callType,
    required String sdp,
    required String pubkey,
    required String privkey,
  }) {
    return _createInnerEvent(
      kind: NipAcKind.offer.value,
      toPubkey: toPubkey,
      callId: callId,
      content: sdp,
      pubkey: pubkey,
      privkey: privkey,
      callType: callType,
    );
  }

  static Future<Event> createAnswer({
    required String toPubkey,
    required String callId,
    required String sdp,
    required String pubkey,
    required String privkey,
  }) {
    return _createInnerEvent(
      kind: NipAcKind.answer.value,
      toPubkey: toPubkey,
      callId: callId,
      content: sdp,
      pubkey: pubkey,
      privkey: privkey,
    );
  }

  static Future<Event> createCandidate({
    required String toPubkey,
    required String callId,
    required String candidateJson,
    required String pubkey,
    required String privkey,
  }) {
    return _createInnerEvent(
      kind: NipAcKind.candidate.value,
      toPubkey: toPubkey,
      callId: callId,
      content: candidateJson,
      pubkey: pubkey,
      privkey: privkey,
    );
  }

  static Future<Event> createHangup({
    required String toPubkey,
    required String callId,
    required String reason,
    required String pubkey,
    required String privkey,
  }) {
    return _createInnerEvent(
      kind: NipAcKind.hangup.value,
      toPubkey: toPubkey,
      callId: callId,
      content: reason,
      pubkey: pubkey,
      privkey: privkey,
    );
  }

  static Future<Event> createReject({
    required String toPubkey,
    required String callId,
    required String reason,
    required String pubkey,
    required String privkey,
  }) {
    return _createInnerEvent(
      kind: NipAcKind.reject.value,
      toPubkey: toPubkey,
      callId: callId,
      content: reason,
      pubkey: pubkey,
      privkey: privkey,
    );
  }

  static Future<Event> _createInnerEvent({
    required int kind,
    required String toPubkey,
    required String callId,
    required String content,
    required String pubkey,
    required String privkey,
    String? callType,
  }) async {
    final tags = <List<String>>[
      ['p', toPubkey],
      ['call-id', callId],
      ['alt', _alt],
    ];
    if (callType != null && kind == NipAcKind.offer.value) {
      tags.add(['call-type', _normalizeCallTypeForOutgoing(callType)]);
    }
    return Event.from(
      kind: kind,
      tags: tags,
      content: content,
      pubkey: pubkey,
      privkey: privkey,
    );
  }

  static Future<Event> wrap(Event innerEvent, String receiver,
      {String? sealedPrivkey}) async {
    final encodedInner = jsonEncode(innerEvent.toJson());
    final localSealedPrivkey = sealedPrivkey ?? Keychain.generate().private;
    final localSealedPubkey = bip340.getPublicKey(localSealedPrivkey);
    final content = await Nip44.encryptContent(
        encodedInner, receiver, localSealedPubkey, localSealedPrivkey);
    return Event.from(
      kind: wrapKind,
      tags: [
        ['p', receiver],
        if (innerEvent.kind == NipAcKind.offer.value)
          ['k', NipAcKind.offer.value.toString()],
      ],
      content: content,
      pubkey: localSealedPubkey,
      privkey: localSealedPrivkey,
    );
  }

  static Future<Event> unwrap(
      Event wrappedEvent, String myPubkey, String myPrivkey) async {
    if (wrappedEvent.kind != wrapKind) {
      throw Exception('${wrappedEvent.kind} is not nip-ac wrapped event');
    }
    final plainContent = await Nip44.decryptContent(
      wrappedEvent.content,
      wrappedEvent.pubkey,
      myPubkey,
      myPrivkey,
    );
    final map = jsonDecode(plainContent) as Map<String, dynamic>;
    // Inner signaling event MUST keep sender signature verifiable after unwrap.
    return Event.fromJson(map, verify: true);
  }

  static Future<Event?> tryUnwrap(
      Event wrappedEvent, String myPubkey, String myPrivkey) async {
    try {
      return await unwrap(wrappedEvent, myPubkey, myPrivkey);
    } catch (_) {
      return null;
    }
  }

  static NipAcSignaling decodeInner(Event innerEvent, String myPubkey) {
    final kind = NipAcKind.fromValue(innerEvent.kind);
    if (kind == null) {
      throw Exception('${innerEvent.kind} is not supported by nip-ac');
    }

    final receiver = _firstTagValue(innerEvent.tags, 'p');
    final callId = _firstTagValue(innerEvent.tags, 'call-id');
    final callType = _normalizeCallTypeForIncoming(
        _firstTagValue(innerEvent.tags, 'call-type'));
    if (receiver == null ||
        receiver != myPubkey ||
        callId == null ||
        callId.isEmpty) {
      throw Exception('invalid nip-ac signaling tags');
    }
    if (kind == NipAcKind.offer && (callType == null || callType.isEmpty)) {
      throw Exception('offer must include call-type');
    }

    return NipAcSignaling(
      sender: innerEvent.pubkey,
      receiver: receiver,
      content: innerEvent.content,
      callId: callId,
      kind: kind,
      callType: callType,
    );
  }

  static String? _firstTagValue(List<List<String>> tags, String key) {
    for (final tag in tags) {
      if (tag.length >= 2 && tag[0] == key) return tag[1];
    }
    return null;
  }

  static String _normalizeCallTypeForOutgoing(String callType) {
    if (callType == 'audio') return callTypeVoice;
    return callType;
  }

  static String? _normalizeCallTypeForIncoming(String? callType) {
    if (callType == null) return null;
    if (callType == 'audio') return callTypeVoice;
    return callType;
  }
}
