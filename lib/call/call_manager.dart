import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:noscall/call_history/controller/call_history_manager.dart';
import 'package:noscall/core/core.dart' as ChatCore;
import 'package:noscall/utils/router.dart';

import 'package:nostr_core_dart/nostr.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

import 'constant/call_type.dart';
import 'callkeep_manager.dart';
import 'calling_controller.dart';
import '../core/common/utils/log_utils.dart';

class CallKitManager with WidgetsBindingObserver {
  static final CallKitManager instance = CallKitManager._internal();

  CallKitManager._internal() {
    WidgetsBinding.instance.addObserver(this);
  }

  factory CallKitManager() {
    return instance;
  }

  Completer<CallingController>? activeControllerCmp;
  bool get hasActiveCalling => activeControllerCmp != null;
  Future<CallingController>? get activeController => activeControllerCmp?.future;

  CallingController? waitingShowController;
  Set<String> disconnectOfferId = {};

  StreamSubscription? deviceChangeSubscription;
  ValueNotifier<bool> isBluetoothHeadsetConnected = ValueNotifier(false);

  CallHistoryManager? callHistoryManager;
  CallKeepManager? _callKeepManager;

  CallType? callType;
  bool get getInCallIng => hasActiveCalling;

  RTCVideoRenderer? remoteRenderer;

  CallingState? callState;
  int counter = 0;

  Future<bool> _checkPermissions(CallType callType) async {
    try {
      // Check microphone permission (required for all calls)
      final microphoneStatus = await Permission.microphone.request();
      if (microphoneStatus != PermissionStatus.granted) {
        LogUtils.e(() => 'Microphone permission denied');
        return false;
      }

      // Check camera permission (required for video calls)
      if (callType.isVideo) {
        final cameraStatus = await Permission.camera.request();
        if (cameraStatus != PermissionStatus.granted) {
          LogUtils.e(() => 'Camera permission denied');
          return false;
        }
      }

      LogUtils.i(() => 'All required permissions granted for ${callType.value} call');
      return true;
    } catch (e) {
      LogUtils.e(() => 'Error checking permissions: $e');
      return false;
    }
  }

  // Call limit checking
  bool _canStartNewCall() {
    return !hasActiveCalling;
  }

  Future<void> initRTC() async {
    try {
      // Initialize CallKeep
      if (Platform.isIOS) {
        _callKeepManager = CallKeepManager();
      }
      await _callKeepManager?.initialize();

      // Setup CallKeep event handlers
      _setupCallKeepHandlers();

      // Setup Nostr call state handler
      ChatCore.Contacts.sharedInstance.onCallStateChange = nostrCallStateChangeHandler;

      // Audio management will be handled by WebRTC

      LogUtils.i(() => 'CallKitManager initialized successfully');
    } catch (e) {
      LogUtils.e(() => 'Failed to initialize CallKitManager: $e');
      rethrow;
    }
  }

  void _setupCallKeepHandlers() {
    _callKeepManager?.callEventStream.listen((event) {
      final action = event['action'] as String;
      final callId = event['callId'] as String;

      switch (action) {
        case 'answer':
          _handleCallKeepAnswer(callId);
          break;
        case 'end':
          _handleCallKeepEnd(callId);
          break;
        case 'mute':
          _handleCallKeepMute(callId, event['muted'] as bool);
          break;
      }
    });
  }

  Future<void> _handleCallKeepAnswer(String callId) async {
    final activeController = await this.activeController;
    if (activeController != null) {
      activeController.accept();
    }
  }

  Future<void> _handleCallKeepEnd(String callId) async {
    final activeController = await this.activeController;
    if (activeController != null) {
      activeController.hangup(CallEndReason.hangup, false);
    }
  }

  void _handleCallKeepMute(String callId, bool muted) async {
    final activeController = await this.activeController;
    if (activeController != null) {
      activeController.recordToggleHandler(!muted, false);
    }
  }

  Future<CallingController?> startCall({
    required String peerId,
    required CallType callType,
  }) async {
    try {
      // Check if we can start a new call
      if (!_canStartNewCall()) {
        LogUtils.e(() => 'Cannot start new call: maximum concurrent calls reached');
        throw Exception('Maximum concurrent calls reached');
      }

      // Check permissions
      final hasPermissions = await _checkPermissions(callType);
      if (!hasPermissions) {
        LogUtils.e(() => 'Required permissions not granted for ${callType.value} call');
        throw Exception('Required permissions not granted');
      }

      final user = ChatCore.Account.sharedInstance.getUserNotifier(peerId).value;
      final controller = await openCallModule(
        user: user,
        callType: callType,
        role: CallingRole.caller,
      );

      LogUtils.i(() => 'Call started to $peerId with type ${callType.value}');
      return controller;
    } catch (e) {
      LogUtils.e(() => 'Failed to start call: $e');
      return null;
    }
  }

  /// Get current call state
  Map<String, dynamic> getCallState() {
    return {
      'hasActiveCalling': hasActiveCalling,
      'callType': callType?.value,
      'isBluetoothConnected': isBluetoothHeadsetConnected.value,
      'canStartNewCall': _canStartNewCall(),
    };
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    deviceChangeSubscription?.cancel();
    deviceChangeSubscription = null;
    _callKeepManager?.dispose();
  }

  void nostrCallStateChangeHandler(String friend, SignalingState state, String data, String? offerId,) {
    if (offerId == null || offerId.isEmpty) {
      LogUtils.e(() => 'nostrCallStateChangeHandler offerId: $offerId');
      return;
    }
    callStateChangeHandler(
      friend: friend,
      state: state,
      offerId: offerId,
      data: data,
    );
  }

  void callStateChangeHandler({
    required String friend,
    required SignalingState state,
    required String offerId,
    String data = '',
    CallType? mediaType,
  }) async {
    if (disconnectOfferId.contains(offerId)) {
      LogUtils.i(() => 'offerId($offerId) has been disconnected');
      return;
    }

    if (state == SignalingState.disconnect) {
      disconnectOfferId.add(offerId);
    }
    if (hasActiveCalling) {
      final activeController = await this.activeController;
      if (activeController == null) return;

      if (await activeController.offerId != offerId) {
        if (state == SignalingState.offer) {
          CallingControllerNostrSignalingEx.sendDisconnect(
            sessionId: '',
            offerId: offerId,
            peerId: friend,
            reason: 'hangUp',
          );
        }
      } else {
        activeController.signalingCallbackHandler(
          nostrState: state,
          content: data,
        );
      }
      return;
    }
    if (state == SignalingState.offer) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (disconnectOfferId.contains(offerId)) {
        LogUtils.i(() => 'offerId($offerId) has been disconnected');
        return;
      }

      Map dataMap = {};
      try {
        dataMap = jsonDecode(data);
      } catch (_) {}

      var media = dataMap['media'];
      mediaType ??= CallTypeEx.fromValue(media);
      if (mediaType == null) {
        LogUtils.e(() => 'Call type is null, ${StackTrace.current}');
        return;
      }

      final user = ChatCore.Account.sharedInstance.getUserNotifier(friend).value;

      final controller = await openCallModule(
        user: user,
        callType: mediaType,
        role: CallingRole.callee,
        offerId: offerId,
      );

      controller.signalingCallbackHandler(
        nostrState: state,
        content: data,
      );

      controller.callId.then((callId) async {
        await _callKeepManager?.displayIncomingCall(
          callId,
          user.name ?? user.shortEncodedPubkey,
          hasVideo: controller.callType.isVideo,
        );
      });
    }
  }

  Future<CallingController> openCallModule({
    required ChatCore.UserDBISAR user,
    required CallType callType,
    required CallingRole role,
    String? sessionId,
    String? offerId,
  }) async {
    final cmp = Completer<CallingController>();
    activeControllerCmp = cmp;

    final controller = await CallingController.create(
      user: user,
      role: role,
      callType: callType,
      sessionId: sessionId ?? '',
      offerId: offerId ?? '',
      state: CallingState.ringing,
      speakerType: defaultOutputType(callType),
      isCameraOn: true,
      isRecordOn: true,
      isFrontCamera: false,
      disposeCallback: callControllerDisposeHandler,
      callHistoryManager: callHistoryManager,
      callKeepManager: _callKeepManager,
    );

    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      presentPageWithController(controller);
    } else {
      waitingShowController = controller;
    }

    cmp.complete(controller);

    switch (role) {
      case CallingRole.caller:
        final isSuccess = await controller.invitePeer(timeoutHandler: () {
          controller.hangup(CallEndReason.timeout);
        });
        if (!isSuccess) {
          controller.hangup(CallEndReason.timeout);
          return controller;
        }

        await controller.callId.then((callId) async {
          await _callKeepManager?.startCall(
            callId,
            user.displayName(),
            hasVideo: callType.isVideo,
          );
        });
        break;
      case CallingRole.callee:
        break;
    }

    return controller;
  }

  void callControllerDisposeHandler(String offerId) {
    disconnectOfferId.add(offerId);
    activeControllerCmp = null;
  }

  void presentPageWithController(CallingController controller) {
    AppRouter.router.push('/call', extra: controller);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state != AppLifecycleState.resumed) return;

    final controller = waitingShowController;
    waitingShowController = null;
    if (controller == null) return;

    final offerId = await controller.offerId;
    if (offerId.isEmpty || disconnectOfferId.contains(offerId)) return;

    presentPageWithController(controller);
    // Controller is ready when app comes to foreground
    LogUtils.i(() => 'Call controller ready for foreground: $offerId');
  }
}

extension CallManagerDefaultEx on CallKitManager {

  AudioOutputType defaultOutputType(CallType callType) {
    if (isBluetoothHeadsetConnected.value) return AudioOutputType.bluetooth;

    if (callType.isVideo) return AudioOutputType.speaker;

    return AudioOutputType.none;
  }
}

extension CallCacheObserverEx on CallKitManager {
  // Audio management simplified - will be handled by WebRTC
  void loadAudioManager() {
    // Placeholder for future audio management
    LogUtils.i(() => 'Audio manager loaded');
  }

  void addAudioListener() {
    // Placeholder for future audio listener
    LogUtils.i(() => 'Audio listener added');
  }
}