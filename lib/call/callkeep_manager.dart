import 'dart:async';
import 'dart:io';
import 'package:callkeep/callkeep.dart';
import 'package:flutter/services.dart';
import 'package:noscall/core/native_method_channel.dart';

import '../core/common/utils/log_utils.dart';

class CallKeepManager {
  static final CallKeepManager _instance = CallKeepManager._internal();
  factory CallKeepManager() => _instance;
  CallKeepManager._internal();

  static final FlutterCallkeep _callKeep = FlutterCallkeep();

  String? _currentCallId;
  String? _currentCallerName;
  bool _isVideoEnabled = false;

  final StreamController<Map<String, dynamic>> _callEventController = StreamController<Map<String, dynamic>>.broadcast();

  String? get currentCallId => _currentCallId;
  String? get currentCallerName => _currentCallerName;
  bool get isVideoEnabled => _isVideoEnabled;
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
            'foregroundService': {
              'channelId': 'sh.noscall.callkeep',
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
      if (Platform.isAndroid && e is PlatformException) {
        // PhoneAccount connection service requires BIND_TELECOM_CONNECTION_SERVICE permission
      } else {
        LogUtils.e(() => 'Failed to initialize CallKeep: $e');
        rethrow;
      }
    }
  }

  void _setupEventHandlers() {
    _callKeep.on<CallKeepPerformAnswerCallAction>((event) {
      LogUtils.i(() => 'Call answered: ${event.callData.callUUID}');
      _callEventController.add({
        'action': 'answer',
        'callId': event.callData.callUUID,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    });

    _callKeep.on<CallKeepPerformEndCallAction>((event) {
      LogUtils.i(() => 'Call ended: ${event.callUUID}');
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

    _callKeep.on<CallKeepDidActivateAudioSession>((_) {
      NativeMethodChannel.audioSessionDidActivate();
    });

    _callKeep.on<CallKeepDidDeactivateAudioSession>((_) {
      NativeMethodChannel.audioSessionDidDeactivate();
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

      LogUtils.i(() => 'Outgoing call started: $callId to $calleeName');
    } catch (e) {
      LogUtils.e(() => 'Failed to start call: $e');
      rethrow;
    }
  }

  Future<void> endCall(String callId) async {
    try {
      await _callKeep.endCall(callId);
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
      LogUtils.i(() => 'Call answered: $callId');
    } catch (e) {
      LogUtils.e(() => 'Failed to answer call: $e');
      rethrow;
    }
  }

  Future<void> rejectCall(String callId) async {
    try {
      await _callKeep.endCall(callId);
      LogUtils.i(() => 'Call rejected: $callId');
      _resetCallState();
    } catch (e) {
      LogUtils.e(() => 'Failed to reject call: $e');
      rethrow;
    }
  }

  Future<void> setMutedCall(String callId, bool shouldMute) async {
    await _callKeep.setMutedCall(uuid: callId, shouldMute: shouldMute);
  }

  void _resetCallState() {
    _currentCallId = null;
    _currentCallerName = null;
    _isVideoEnabled = false;
  }

  void dispose() {
    _callEventController.close();
  }
}
