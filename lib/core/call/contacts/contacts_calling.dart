import 'dart:async';
import 'dart:convert';
import 'package:noscall/core/call/call_event_policy.dart';
import 'package:noscall/core/call/contacts/contacts_isolate_event.dart';
import 'package:noscall/core/call/nip_ac_protocol.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:noscall/core/common/utils/log_utils.dart';

import '../../account/account.dart';
import '../../common/network/connect.dart';
import '../messages/messages.dart';
import '../messages/model/message_db_isar.dart';
import 'contacts.dart';

extension Calling on Contacts {
  Future<OKEvent> sendHangup(
    String callId,
    String friendPubkey,
    String reason,
  ) async {
    return _sendSignaling(
      callId: callId,
      toPubkey: friendPubkey,
      state: SignalingState.disconnect,
      content: reason,
      reject: false,
    );
  }

  Future<OKEvent> sendReject(
    String callId,
    String friendPubkey,
    String reason,
  ) async {
    return _sendSignaling(
      callId: callId,
      toPubkey: friendPubkey,
      state: SignalingState.disconnect,
      content: reason,
      reject: true,
    );
  }

  Future<OKEvent> sendOffer(
    String friendPubkey,
    String callId,
    String callType,
    String sdp,
  ) async {
    return _sendSignaling(
      callId: callId,
      toPubkey: friendPubkey,
      state: SignalingState.offer,
      content: sdp,
      callType: callType,
    );
  }

  Future<OKEvent> sendAnswer(
    String callId,
    String friendPubkey,
    String sdp,
  ) async {
    return _sendSignaling(
      callId: callId,
      toPubkey: friendPubkey,
      state: SignalingState.answer,
      content: sdp,
    );
  }

  Future<OKEvent> sendCandidate(
    String callId,
    String friendPubkey,
    String content,
  ) async {
    return _sendSignaling(
      callId: callId,
      toPubkey: friendPubkey,
      state: SignalingState.candidate,
      content: content,
    );
  }

  Future<OKEvent> _sendSignaling({
    required String callId,
    required String toPubkey,
    required SignalingState state,
    required String content,
    String? callType,
    bool reject = false,
  }) async {
    final completer = Completer<OKEvent>();
    late final Event innerEvent;
    String? reason;
    switch (state) {
      case SignalingState.disconnect:
        reason = content;
        if (reject) {
          innerEvent = await NipAcProtocol.createReject(
            toPubkey: toPubkey,
            callId: callId,
            reason: content,
            pubkey: pubkey,
            privkey: privkey,
          );
        } else {
          innerEvent = await NipAcProtocol.createHangup(
            toPubkey: toPubkey,
            callId: callId,
            reason: content,
            pubkey: pubkey,
            privkey: privkey,
          );
        }
        break;
      case SignalingState.offer:
        innerEvent = await NipAcProtocol.createOffer(
          toPubkey: toPubkey,
          callId: callId,
          callType: callType ?? 'audio',
          sdp: content,
          pubkey: pubkey,
          privkey: privkey,
        );
        break;
      case SignalingState.answer:
        innerEvent = await NipAcProtocol.createAnswer(
          toPubkey: toPubkey,
          callId: callId,
          sdp: content,
          pubkey: pubkey,
          privkey: privkey,
        );
        break;
      case SignalingState.candidate:
        innerEvent = await NipAcProtocol.createCandidate(
          toPubkey: toPubkey,
          callId: callId,
          candidateJson: content,
          pubkey: pubkey,
          privkey: privkey,
        );
        break;
    }
    final signaling = NipAcSignaling(
      sender: innerEvent.pubkey,
      receiver: toPubkey,
      content: content,
      callId: callId,
      kind: switch (state) {
        SignalingState.offer => NipAcKind.offer,
        SignalingState.answer => NipAcKind.answer,
        SignalingState.candidate => NipAcKind.candidate,
        _ => reject ? NipAcKind.reject : NipAcKind.hangup,
      },
      callType: callType,
    );
    if (state != SignalingState.candidate) {
      await handleSignalingEvent(innerEvent, signaling, reason);
    }

    final wrapped = await NipAcProtocol.wrap(innerEvent, toPubkey);
    Connect.sharedInstance.sendEvent(
      relayKinds: [RelayKind.general],
      wrapped,
      sendCallBack: (ok, relay) async {
        if (!completer.isCompleted) {
          completer.complete(OKEvent(innerEvent.id, ok.status, ok.message));
        }
      },
    );
    return completer.future;
  }

  Future<void> handleCallEvent(Event event, String relay) async {
    if (CallEventPolicy.isCallPaymentKind(event.kind)) {
      final handler = onCallPaymentEvent;
      if (handler == null) {
        LogUtils.v(
          () =>
              'Drop call payment event: no handler, kind=${event.kind}, id=${event.id}',
        );
        return;
      }
      await handler(event, relay);
      return;
    }

    NipAcSignaling signaling;
    try {
      signaling = NipAcProtocol.decodeInner(event, pubkey);
    } catch (e) {
      LogUtils.w(
        () =>
            'Drop non NIP-AC signaling event: kind=${event.kind}, id=${event.id}, error=$e',
      );
      return;
    }
    String? reason;
    if (signaling.state == SignalingState.disconnect) {
      reason = signaling.content;
    }
    if (signaling.state == SignalingState.offer) {
      final gate = onIncomingCallOffer;
      if (gate != null && !await gate(event, signaling)) return;
    }
    bool result = await handleSignalingEvent(event, signaling, reason);
    if (result) {
      onCallStateChange?.call(
        event.pubkey,
        signaling.state,
        signaling.content,
        signaling.callId,
        signaling.callType,
      );
    }
  }

  Future<bool> handleSignalingEvent(
    Event event,
    NipAcSignaling signaling,
    String? reason,
  ) async {
    /// receive offer
    int eventTime = event.createdAt * 1000;
    if (signaling.state == SignalingState.offer) {
      CallMessage? callMessage = callMessages[signaling.callId];
      final media = signaling.callType ?? 'audio';
      if (callMessage != null) {
        /// outdated request
        callMessage.media = media;
        callMessage.start = eventTime;
        MessageDBISAR callMessageDB = callMessageToDB(callMessage);
        await Messages.saveMessageToDB(callMessageDB);
        privateChatMessageCallBack?.call(callMessageDB);
        return false;
      } else {
        callMessage = CallMessage(
          signaling.callId,
          signaling.sender,
          signaling.receiver,
          callMessage?.state ?? CallMessageState.offer,
          eventTime,
          callMessage?.end ?? eventTime,
          media,
        );
        callMessages[signaling.callId] = callMessage;
      }
    }
    /// receive answer
    else if (signaling.state == SignalingState.answer) {
      CallMessage? callMessage = callMessages[signaling.callId];
      if (callMessage != null) {
        callMessage.start = eventTime;
      }
    }
    /// receive disconnect & reject
    else if (signaling.state == SignalingState.disconnect) {
      CallMessageState state = CallMessageState.disconnect;
      switch (reason) {
        case 'hangUp':
        case 'hangup':
          state = CallMessageState.cancel;
          break;
        case 'reject':
          state = CallMessageState.reject;
          break;
        case 'busy':
        case 'inCalling':
          state = CallMessageState.inCalling;
          break;
        case 'timeout':
          state = CallMessageState.timeout;
          break;
      }
      CallMessage? callMessage = callMessages[signaling.callId];
      callMessage ??= CallMessage(
        signaling.callId,
        signaling.sender,
        signaling.receiver,
        state,
        eventTime,
        eventTime,
        '',
      );
      callMessage.end = eventTime;
      callMessage.state = state;
      callMessages[callMessage.callId] = callMessage;
      MessageDBISAR callMessageDB = callMessageToDB(callMessage);
      await Messages.saveMessageToDB(callMessageDB);
      privateChatMessageCallBack?.call(callMessageDB);

      // If this was an incoming call we didn't answer (missed/timeout/cancel), notify app to add to call history and show badge.
      if (callMessage.receiver == pubkey &&
          (state == CallMessageState.cancel ||
              state == CallMessageState.timeout ||
              state == CallMessageState.reject)) {
        final media = callMessage.media.isEmpty ? 'audio' : callMessage.media;
        onMissedCallFromRelay?.call(
          callMessage.callId,
          callMessage.sender,
          media,
          callMessage.start,
        );
      }
    }

    return true;
  }

  /// Sends an encrypted DM (kind 4, NIP4) wrapped in NIP17 (kind 1059).
  /// Returns the inner event id on success, null on failure.
  Future<String?> sendEncryptedDM(
    String toPubkey,
    String plainContent, {
    String? replyToMessageId,
  }) async {
    final encrypted = await Account.sharedInstance.encryptNip04(
      plainContent,
      toPubkey,
    );
    final now = currentUnixTimestampSeconds();
    final tags = <List<String>>[
      ['p', toPubkey],
    ];
    if (replyToMessageId != null && replyToMessageId.isNotEmpty) {
      tags.add(['e', replyToMessageId, '', 'reply']);
    }
    final eventMap = <String, dynamic>{
      'kind': 4,
      'content': encrypted,
      'tags': tags,
      'created_at': now,
      'pubkey': pubkey,
    };
    final signed = await Account.sharedInstance.signEvent(eventMap);
    final event = await Event.fromJson(signed, verify: false);
    final sealedFuture = encodeNip17Event(
      event,
      toPubkey,
      kind: 4,
      expiration: now + 86400,
      createAt: now,
    );
    final sealed = await sealedFuture;
    if (sealed == null) return null;
    final completer = Completer<String?>();
    Connect.sharedInstance.sendEvent(
      sealed,
      relayKinds: [RelayKind.general],
      sendCallBack: (ok, relay) {
        if (!completer.isCompleted) {
          completer.complete(ok.status ? event.id : null);
        }
      },
    );
    return completer.future;
  }

  MessageDBISAR callMessageToDB(CallMessage callMessage) {
    String content = jsonEncode({
      'contentType': 'call',
      'content': jsonEncode({
        'state': callMessage.state.toString(),
        'duration': (callMessage.end - callMessage.start),
        'media': callMessage.media,
      }),
    });
    return MessageDBISAR(
      messageId: callMessage.callId,
      sender: callMessage.sender,
      receiver: callMessage.receiver,
      content: content,
      kind: 25053,
      type: 'call',
      decryptContent: jsonEncode({
        'state': callMessage.state.toString(),
        'duration': (callMessage.end - callMessage.start),
        'media': callMessage.media,
      }),
      createTime: currentUnixTimestampSeconds(),
    );
  }
}
