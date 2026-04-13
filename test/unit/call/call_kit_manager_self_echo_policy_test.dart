import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/call/call_kit_manager.dart';
import 'package:noscall/call/constant/call_type.dart';
import 'package:nostr_core_dart/nostr.dart';

void main() {
  group('CallKitManager.shouldHandleSelfEchoEvent', () {
    test('handles self answer only for incoming ringing call', () {
      expect(
        CallKitManager.shouldHandleSelfEchoEvent(
          state: SignalingState.answer,
          role: CallingRole.callee,
          callingState: CallingState.ringing,
        ),
        isTrue,
      );
    });

    test('handles self reject(disconnect) only for incoming ringing call', () {
      expect(
        CallKitManager.shouldHandleSelfEchoEvent(
          state: SignalingState.disconnect,
          role: CallingRole.callee,
          callingState: CallingState.ringing,
        ),
        isTrue,
      );
    });

    test('ignores self echo for non-ringing or caller states', () {
      expect(
        CallKitManager.shouldHandleSelfEchoEvent(
          state: SignalingState.answer,
          role: CallingRole.caller,
          callingState: CallingState.connecting,
        ),
        isFalse,
      );
      expect(
        CallKitManager.shouldHandleSelfEchoEvent(
          state: SignalingState.disconnect,
          role: CallingRole.callee,
          callingState: CallingState.connected,
        ),
        isFalse,
      );
      expect(
        CallKitManager.shouldHandleSelfEchoEvent(
          state: SignalingState.offer,
          role: CallingRole.callee,
          callingState: CallingState.ringing,
        ),
        isFalse,
      );
    });
  });
}
