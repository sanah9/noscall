import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:noscall/call/calling_ice_state_handler.dart';
import 'package:noscall/call/constant/call_type.dart';

void main() {
  group('CallingIceStateHandler', () {
    const handler = CallingIceStateHandler();

    test('dispatches connected state', () async {
      var connected = false;

      await handler.handle(
        RTCIceConnectionState.RTCIceConnectionStateConnected,
        onConnected: () {
          connected = true;
        },
        onHangup: (_) {
          fail('connected state should not hang up');
        },
      );

      expect(connected, isTrue);
    });

    test('dispatches failure hangup reasons', () async {
      final reasons = <CallEndReason>[];

      await handler.handle(
        RTCIceConnectionState.RTCIceConnectionStateFailed,
        onConnected: () {
          fail('failed state should not connect');
        },
        onHangup: reasons.add,
      );
      await handler.handle(
        RTCIceConnectionState.RTCIceConnectionStateDisconnected,
        onConnected: () {
          fail('disconnected state should not connect');
        },
        onHangup: reasons.add,
      );

      expect(
        reasons,
        equals([
          CallEndReason.iceConnectionFailed,
          CallEndReason.iceDisconnected,
        ]),
      );
    });
  });
}
