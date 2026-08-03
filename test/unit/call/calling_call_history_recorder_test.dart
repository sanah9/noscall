import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/call/calling_call_history_recorder.dart';
import 'package:noscall/call/constant/call_type.dart';
import 'package:noscall/call_history/constants/call_enums.dart';

void main() {
  group('CallingCallHistoryRecorder', () {
    const recorder = CallingCallHistoryRecorder();

    test('maps connected calls to completed regardless of reason', () {
      expect(
        recorder.statusFor(
          reason: CallEndReason.hangup.value,
          hasConnected: true,
        ),
        CallStatus.completed,
      );
    });

    test('maps rejected and busy calls to declined', () {
      expect(
        recorder.statusFor(
          reason: CallEndReason.reject.value,
          hasConnected: false,
        ),
        CallStatus.declined,
      );
      expect(
        recorder.statusFor(
          reason: CallEndReason.busy.value,
          hasConnected: false,
        ),
        CallStatus.declined,
      );
    });

    test('maps ICE failures to failed', () {
      expect(
        recorder.statusFor(
          reason: CallEndReason.iceConnectionFailed.value,
          hasConnected: false,
        ),
        CallStatus.failed,
      );
      expect(
        recorder.statusFor(
          reason: CallEndReason.iceDisconnected.value,
          hasConnected: false,
        ),
        CallStatus.failed,
      );
    });

    test('maps timeout and hangup before connection to cancelled', () {
      expect(
        recorder.statusFor(
          reason: CallEndReason.timeout.value,
          hasConnected: false,
        ),
        CallStatus.cancelled,
      );
      expect(
        recorder.statusFor(
          reason: CallEndReason.hangup.value,
          hasConnected: false,
        ),
        CallStatus.cancelled,
      );
    });
  });
}
