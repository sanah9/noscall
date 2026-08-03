import 'dart:convert';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'package:noscall/core/common/utils/log_utils.dart';
import 'calling_controller_dependencies.dart';
import 'constant/call_type.dart';

class CallingNostrSignalSender {
  const CallingNostrSignalSender();

  Future<bool> sendOffer({
    required CallingControllerWebRTCSession webRTCHandler,
    required CallingControllerSignalingGateway signalingGateway,
    required String peerId,
    required String callId,
    required CallType callType,
  }) async {
    try {
      final description = await webRTCHandler.createOffer();
      LogUtils.info(
        className: 'CallingNostrSignalSender',
        funcName: 'sendOffer',
        message:
            '[send offer] sdp.length: ${description.sdp?.length}, type: ${description.type}',
      );

      final okEvent = await signalingGateway.sendOffer(
        peerId,
        callId,
        callType.value,
        description.sdp ?? '',
      );

      LogUtils.info(
        className: 'CallingNostrSignalSender',
        funcName: 'sendOffer',
        message:
            '[send offer] okEvent id:${okEvent.eventId}, status: ${okEvent.status}, message: ${okEvent.message}',
      );

      return okEvent.status;
    } catch (e, stack) {
      LogUtils.error(
        className: 'CallingNostrSignalSender',
        funcName: 'sendOffer',
        message: '$e, $stack',
      );
      return false;
    }
  }

  Future<void> sendAnswer({
    required CallingControllerWebRTCSession webRTCHandler,
    required CallingControllerSignalingGateway signalingGateway,
    required String sessionId,
    required String offerId,
    required String peerId,
  }) async {
    try {
      final description = await webRTCHandler.createAnswer();

      LogUtils.info(
        className: 'CallingNostrSignalSender',
        funcName: 'sendAnswer',
        message:
            '[send answer] sessionId: $sessionId, offerId: $offerId, peerId: $peerId, sdp.length: ${description.sdp?.length}, type: ${description.type}',
      );

      final okEvent = await signalingGateway.sendAnswer(
        offerId,
        peerId,
        description.sdp ?? '',
      );

      LogUtils.info(
        className: 'CallingNostrSignalSender',
        funcName: 'sendAnswer',
        message:
            '[send answer] offerId: $offerId, okEvent status: ${okEvent.status}, message: ${okEvent.message}',
      );
    } catch (e, stack) {
      LogUtils.error(
        className: 'CallingNostrSignalSender',
        funcName: 'sendAnswer',
        message: '$e, $stack',
      );
    }
  }

  Future<void> sendCandidate({
    required RTCIceCandidate candidate,
    required Set<String> sentCandidateKeys,
    required CallingControllerSignalingGateway signalingGateway,
    required String sessionId,
    required String offerId,
    required String peerId,
  }) async {
    final candidateKey = keyForCandidate(candidate);
    if (sentCandidateKeys.contains(candidateKey)) return;

    final meta = jsonEncode({
      'candidate': candidate.candidate,
      'sdpMid': candidate.sdpMid,
      'sdpMLineIndex': candidate.sdpMLineIndex,
    });

    LogUtils.info(
      className: 'CallingNostrSignalSender',
      funcName: 'sendCandidate',
      message:
          '[send candidate] sessionId: $sessionId, offerId: $offerId, peerId: $peerId, candidate: ${candidate.candidate}, sdpMid: ${candidate.sdpMid}, sdpMLineIndex: ${candidate.sdpMLineIndex}',
    );

    final okEvent = await signalingGateway.sendCandidate(offerId, peerId, meta);
    if (okEvent.status) {
      sentCandidateKeys.add(candidateKey);
    }

    LogUtils.info(
      className: 'CallingNostrSignalSender',
      funcName: 'sendCandidate',
      message:
          '[send candidate] okEvent status: ${okEvent.status}, message: ${okEvent.message}',
    );
  }

  Future<void> sendDisconnect({
    required String callId,
    required String peerId,
    required CallEndReason reason,
    required bool reject,
    CallingControllerSignalingGateway? signalingGateway,
  }) async {
    LogUtils.info(
      className: 'CallingNostrSignalSender',
      funcName: 'sendDisconnect',
      message:
          '[send disconnect] callId: $callId, peerId: $peerId, reason: ${reason.value}, reject: $reject',
    );

    final gateway =
        signalingGateway ?? DefaultCallingControllerSignalingGateway();
    final okEvent = reject
        ? await gateway.sendReject(callId, peerId, reason.value)
        : await gateway.sendHangup(callId, peerId, reason.value);

    LogUtils.info(
      className: 'CallingNostrSignalSender',
      funcName: 'sendDisconnect',
      message:
          '[send disconnect] okEvent status: ${okEvent.status}, message: ${okEvent.message}',
    );
  }

  String keyForCandidate(RTCIceCandidate candidate) {
    return '${candidate.candidate}|${candidate.sdpMid}|${candidate.sdpMLineIndex}';
  }
}
