import 'dart:async';
import 'package:callkeep/callkeep.dart';

import '../core/common/utils/log_utils.dart';

enum CallState {
  idle,
  incoming,
  outgoing,
  connected,
  ended,
  failed
}

class CallKeepManager {
  static final CallKeepManager _instance = CallKeepManager._internal();
  factory CallKeepManager() => _instance;
  CallKeepManager._internal();

  static final FlutterCallkeep _callKeep = FlutterCallkeep();

  CallState _currentState = CallState.idle;
  String? _currentCallId;
  String? _currentCallerName;
  bool _isVideoEnabled = false;

  final StreamController<CallState> _callStateController = StreamController<CallState>.broadcast();
  final StreamController<Map<String, dynamic>> _callEventController = StreamController<Map<String, dynamic>>.broadcast();

  CallState get currentState => _currentState;
  String? get currentCallId => _currentCallId;
  String? get currentCallerName => _currentCallerName;
  bool get isVideoEnabled => _isVideoEnabled;
  Stream<CallState> get callStateStream => _callStateController.stream;
  Stream<Map<String, dynamic>> get callEventStream => _callEventController.stream;

  Future<void> initialize() async {
    try {
      await _callKeep.setup(
        options: {
          'ios': {
            'appName': 'Noscall',
          },
          'android': {
            'alertTitle': 'Permission Request',
            'alertDescription': 'This app needs access to your phone account permissions',
            'cancelButton': 'Cancel',
            'okButton': 'OK',
            'additionalPermissions': [
              'android.permission.CALL_PHONE',
              'android.permission.READ_PHONE_STATE',
            ],
            'foregroundService': {
              'channelId': 'com.noscall.callkeep',
              'channelName': 'Call Service',
              'notificationTitle': 'Call in Progress',
              'notificationIcon': 'mipmap/ic_launcher',
            },
          },
        },
      );

      _setupEventHandlers();
      LogUtils.i(() => 'CallKeep initialized successfully');
    } catch (e) {
      LogUtils.e(() => 'Failed to initialize CallKeep: $e');
      rethrow;
    }
  }

  void _setupEventHandlers() {
    _callKeep.on<CallKeepPerformAnswerCallAction>((event) {
      LogUtils.i(() => 'Call answered: ${event.callData.callUUID}');
      _updateCallState(CallState.connected);
      _callEventController.add({
        'action': 'answer',
        'callId': event.callData.callUUID,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    });

    _callKeep.on<CallKeepPerformEndCallAction>((event) {
      LogUtils.i(() => 'Call ended: ${event.callUUID}');
      _updateCallState(CallState.ended);
      _callEventController.add({
        'action': 'end',
        'callId': event.callUUID,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      _resetCallState();
    });

    _callKeep.on<CallKeepDidPerformSetMutedCallAction>((event) {
      LogUtils.i(() => 'Call muted: ${event.muted}');
      _callEventController.add({
        'action': 'mute',
        'callId': event.callUUID,
        'muted': event.muted,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    });

    _callKeep.on<CallKeepDidToggleHoldAction>((event) {
      LogUtils.i(() => 'Call hold toggled: ${event.hold}');
      _callEventController.add({
        'action': 'hold',
        'callId': event.callUUID,
        'hold': event.hold,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    });
  }

  Future<void> displayIncomingCall(String callId, String callerName, {bool hasVideo = false}) async {
    try {
      _currentCallId = callId;
      _currentCallerName = callerName;
      _isVideoEnabled = hasVideo;

      await _callKeep.displayIncomingCall(
        uuid: callId,
        handle: callerName,
        hasVideo: hasVideo,
      );

      _updateCallState(CallState.incoming);
      LogUtils.i(() => 'Incoming call displayed: $callId from $callerName');
    } catch (e) {
      LogUtils.e(() => 'Failed to display incoming call: $e');
      rethrow;
    }
  }

  Future<void> startCall(String callId, String calleeName, {bool hasVideo = false}) async {
    try {
      _currentCallId = callId;
      _currentCallerName = calleeName;
      _isVideoEnabled = hasVideo;

      await _callKeep.startCall(
        uuid: callId,
        handle: calleeName,
        callerName: calleeName,
        hasVideo: hasVideo,
      );

      _updateCallState(CallState.outgoing);
      LogUtils.i(() => 'Outgoing call started: $callId to $calleeName');
    } catch (e) {
      LogUtils.e(() => 'Failed to start call: $e');
      rethrow;
    }
  }

  Future<void> endCall(String callId) async {
    try {
      await _callKeep.endCall(callId);
      _updateCallState(CallState.ended);
      LogUtils.i(() => 'Call ended: $callId');
      _resetCallState();
    } catch (e) {
      LogUtils.e(() => 'Failed to end call: $e');
      rethrow;
    }
  }

  Future<void> answerCall(String callId) async {
    try {
      await _callKeep.answerIncomingCall(callId);
      _updateCallState(CallState.connected);
      LogUtils.i(() => 'Call answered: $callId');
    } catch (e) {
      LogUtils.e(() => 'Failed to answer call: $e');
      rethrow;
    }
  }

  Future<void> rejectCall(String callId) async {
    try {
      await _callKeep.endCall(callId);
      _updateCallState(CallState.ended);
      LogUtils.i(() => 'Call rejected: $callId');
      _resetCallState();
    } catch (e) {
      LogUtils.e(() => 'Failed to reject call: $e');
      rethrow;
    }
  }

  void _updateCallState(CallState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      _callStateController.add(newState);
      LogUtils.d(() => 'Call state changed: $newState');
    }
  }

  void _resetCallState() {
    _currentCallId = null;
    _currentCallerName = null;
    _isVideoEnabled = false;
    _updateCallState(CallState.idle);
  }

  bool get hasActiveCall =>
      _currentState == CallState.connected ||
      _currentState == CallState.incoming ||
      _currentState == CallState.outgoing;

  Map<String, dynamic> getCurrentCallInfo() {
    return {
      'callId': _currentCallId,
      'callerName': _currentCallerName,
      'state': _currentState.toString(),
      'isVideoEnabled': _isVideoEnabled,
      'hasActiveCall': hasActiveCall,
    };
  }

  void dispose() {
    _callStateController.close();
    _callEventController.close();
  }
}
