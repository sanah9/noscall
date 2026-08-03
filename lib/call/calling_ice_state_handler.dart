import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'constant/call_type.dart';

typedef CallingIceConnected = FutureOr<void> Function();
typedef CallingIceHangup = FutureOr<void> Function(CallEndReason reason);

class CallingIceStateHandler {
  const CallingIceStateHandler();

  Future<void> handle(
    RTCIceConnectionState connectionState, {
    required CallingIceConnected onConnected,
    required CallingIceHangup onHangup,
  }) async {
    switch (connectionState) {
      case RTCIceConnectionState.RTCIceConnectionStateConnected:
        await onConnected();
        break;
      case RTCIceConnectionState.RTCIceConnectionStateFailed:
        await onHangup(CallEndReason.iceConnectionFailed);
        break;
      case RTCIceConnectionState.RTCIceConnectionStateDisconnected:
        await onHangup(CallEndReason.iceDisconnected);
        break;
      default:
        break;
    }
  }
}
