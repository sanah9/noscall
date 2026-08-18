import 'package:noscall/call/calling_controller_dependencies.dart';
import 'package:noscall/call/constant/call_type.dart';
import 'package:noscall/call_history/constants/call_enums.dart';
import 'package:noscall/core/common/utils/log_utils.dart';

class CallingCallHistoryRecorder {
  const CallingCallHistoryRecorder();

  Future<void> record({
    required CallHistoryRecorder? recorder,
    required String callId,
    required String peerPubkey,
    required CallingRole role,
    required CallType callType,
    required DateTime startTime,
    required Duration duration,
    required bool hasConnected,
    required String reason,
  }) async {
    if (recorder == null) return;

    final direction = role == CallingRole.caller
        ? CallDirection.outgoing
        : CallDirection.incoming;
    final status = statusFor(reason: reason, hasConnected: hasConnected);

    await recorder.addCallRecord(
      callId: callId,
      peerPubkey: peerPubkey,
      direction: direction,
      type: callType,
      status: status,
      startTime: startTime,
      duration: duration.inSeconds > 0 ? duration : null,
    );

    LogUtils.info(
      className: 'CallingCallHistoryRecorder',
      funcName: 'record',
      message:
          'Call history recorded: $callId, $direction, $status, duration: ${duration.inSeconds}s',
    );
  }

  CallStatus statusFor({required String reason, required bool hasConnected}) {
    if (hasConnected) return CallStatus.completed;

    final callEndReason =
        CallEndReasonEx.fromValue(reason) ?? CallEndReason.disconnect;
    return switch (callEndReason) {
      CallEndReason.reject || CallEndReason.busy => CallStatus.declined,
      CallEndReason.iceConnectionFailed ||
      CallEndReason.iceDisconnected => CallStatus.failed,
      CallEndReason.timeout ||
      CallEndReason.hangup ||
      CallEndReason.disconnect ||
      CallEndReason.paymentRequired ||
      CallEndReason.networkDisconnected => CallStatus.cancelled,
    };
  }
}
