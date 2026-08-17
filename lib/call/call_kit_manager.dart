import 'dart:async';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:noscall/call_payments/application/call_payment_runtime.dart';
import 'package:noscall/call_payments/infrastructure/mobile/mobile_call_payment_runtime_factory.dart';
import 'package:noscall/call_history/constants/call_enums.dart';
import 'package:noscall/call_history/controller/call_history_manager.dart';
import 'package:noscall/core/core.dart' as chat_core;
import 'package:noscall/utils/router.dart';

import 'package:nostr_core_dart/nostr.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

import 'constant/call_type.dart';
import 'callkeep_manager.dart';
import 'calling_controller.dart';
import 'calling_controller_dependencies.dart';
import 'pip_manager.dart';
import 'voip_push_service.dart';
import 'package:noscall/core/common/utils/log_utils.dart';
import 'package:noscall/utils/macos_permissions.dart';

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
  Future<CallingController>? get activeController =>
      activeControllerCmp?.future;

  CallingController? waitingShowController;
  Set<String> disconnectOfferId = {};
  final Map<String, List<String>> _globalCandidateBuffer = {};

  StreamSubscription? deviceChangeSubscription;
  ValueNotifier<bool> isBluetoothHeadsetConnected = ValueNotifier(false);

  CallHistoryManager? _callHistoryManager;
  CallHistoryManager get callHistoryManager =>
      _callHistoryManager ??= CallHistoryManager();
  CallKeepManager? _callKeepManager;
  VoIPPushService? _voipPushService;
  StreamSubscription<Map<String, dynamic>>? _callKeepEventSubscription;
  bool _isDisposed = false;

  CallType? callType;
  bool get getInCallIng => hasActiveCalling;

  RTCVideoRenderer? remoteRenderer;

  CallingState? callState;
  int counter = 0;

  Future<bool> _checkPermissions(CallType callType) async {
    try {
      if (Platform.isWindows || Platform.isLinux) {
        // Desktop platforms rely on OS-level media access and device selection.
        // Do not block call setup with mobile permission APIs.
        LogUtils.i(
          () => 'Desktop platform detected, skip mobile permission requests',
        );
        return true;
      }

      if (Platform.isMacOS) {
        final microphoneGranted = await MacOSPermissions.requestMicrophone();
        if (!microphoneGranted) {
          LogUtils.e(() => 'Microphone permission denied on macOS');
          return false;
        }

        if (callType.isVideo) {
          final cameraGranted = await MacOSPermissions.requestCamera();
          if (!cameraGranted) {
            LogUtils.e(() => 'Camera permission denied on macOS');
            return false;
          }
        }
      } else {
        final microphoneStatus = await Permission.microphone.request();
        if (microphoneStatus != PermissionStatus.granted) {
          LogUtils.e(() => 'Microphone permission denied');
          return false;
        }

        if (callType.isVideo) {
          final cameraStatus = await Permission.camera.request();
          if (cameraStatus != PermissionStatus.granted) {
            LogUtils.e(() => 'Camera permission denied');
            return false;
          }
        }
      }

      LogUtils.i(
        () => 'All required permissions granted for ${callType.value} call',
      );
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
      _isDisposed = false;
      // System call UI integration remains mobile-only for now.
      if (Platform.isIOS) {
        _callKeepManager = CallKeepManager();
      }
      await _callKeepManager?.initialize();

      // Setup CallKeep event handlers
      _setupCallKeepHandlers();

      // Setup Nostr call state handler
      chat_core.Contacts.sharedInstance.onCallStateChange =
          nostrCallStateChangeHandler;
      chat_core.Contacts.sharedInstance.onCallPaymentEvent =
          _handleCallPaymentEvent;
      unawaited(_recoverPendingCallPayments());

      // When user was offline and receives missed call (disconnect before answer), add to history and badge
      chat_core.Contacts.sharedInstance.onMissedCallFromRelay =
          _onMissedCallFromRelay;

      // Initialize VoIP push service (iOS only)
      if (Platform.isIOS) {
        _voipPushService = VoIPPushService();
        await _voipPushService?.initialize(this);
      } else if (Platform.isWindows || Platform.isLinux) {
        LogUtils.i(
          () =>
              'CallKitManager: ${Platform.isLinux ? 'Linux' : 'Windows'} desktop uses in-app call UI only',
        );
      }

      // Initialize PiP manager
      await PipManager.initialize();
      final isSupported = await PipManager.isPipSupported();
      LogUtils.i(() => 'PiP supported: $isSupported');

      // Audio management will be handled by WebRTC

      LogUtils.i(() => 'CallKitManager initialized successfully');
    } catch (e) {
      LogUtils.e(() => 'Failed to initialize CallKitManager: $e');
      rethrow;
    }
  }

  void _setupCallKeepHandlers() {
    _callKeepEventSubscription?.cancel();
    _callKeepEventSubscription = _callKeepManager?.callEventStream.listen((
      event,
    ) {
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

  Future<void> _handleCallPaymentEvent(Event event, String relay) async {
    CallPaymentRuntime? runtime;
    try {
      runtime = await MobileCallPaymentRuntimeFactory.create();
      final result = await runtime.eventHandler().handle(event);
      if (!result.handled) {
        LogUtils.v(
          () =>
              'Ignored call payment event: kind=${event.kind}, id=${event.id}, reason=${result.ignoredReason}, relay=$relay',
        );
      }
    } catch (e, stack) {
      LogUtils.e(
        () =>
            'Failed to handle call payment event: kind=${event.kind}, id=${event.id}, relay=$relay, error=$e, stack=$stack',
      );
    } finally {
      await runtime?.dispose();
    }
  }

  Future<void> _recoverPendingCallPayments() async {
    try {
      final report =
          await MobileCallPaymentRuntimeFactory.recoverPendingPayments();
      if (report.scannedSessions > 0) {
        LogUtils.i(
          () =>
              'Recovered call payments: sessions=${report.scannedSessions}, reclaimed=${report.reclaimedInstallments}, claimed=${report.claimedInstallments}, unknown=${report.unknownInstallments}',
        );
      }
    } catch (e, stack) {
      LogUtils.e(
        () => 'Failed to recover pending call payments: error=$e, stack=$stack',
      );
    }
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
    String? callId,
    CallingControllerLifecycleObserver? lifecycleObserver,
  }) async {
    try {
      await ensureCanStartCall(callType);

      final user = chat_core.Account.sharedInstance
          .getUserNotifier(peerId)
          .value;
      final controller = await openCallModule(
        user: user,
        callType: callType,
        role: CallingRole.caller,
        callId: callId,
        lifecycleObserver: lifecycleObserver,
      );

      LogUtils.i(() => 'Call started to $peerId with type ${callType.value}');
      return controller;
    } catch (e) {
      LogUtils.e(() => 'Failed to start call: $e');
      clean();
      return null;
    }
  }

  Future<void> ensureCanStartCall(CallType callType) async {
    if (!_canStartNewCall()) {
      LogUtils.e(
        () => 'Cannot start new call: maximum concurrent calls reached',
      );
      throw Exception('Maximum concurrent calls reached');
    }

    final hasPermissions = await _checkPermissions(callType);
    if (!hasPermissions) {
      LogUtils.e(
        () => 'Required permissions not granted for ${callType.value} call',
      );
      throw Exception('Required permissions not granted');
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

  void nostrCallStateChangeHandler(
    String friend,
    SignalingState state,
    String data,
    String? offerId,
    String? callType,
  ) {
    if (offerId == null || offerId.isEmpty) {
      LogUtils.e(() => 'nostrCallStateChangeHandler offerId: $offerId');
      return;
    }
    callStateChangeHandler(
      friend: friend,
      state: state,
      offerId: offerId,
      data: data,
      mediaType: CallTypeEx.fromValue(callType),
    );
  }

  void callStateChangeHandler({
    required String friend,
    required SignalingState state,
    required String offerId,
    String data = '',
    CallType? mediaType,
  }) async {
    final myPubkey = chat_core.Account.sharedInstance.currentPubkey;
    if (friend == myPubkey) {
      await _handleSelfEchoEvent(state: state, offerId: offerId);
      return;
    }

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
            callId: offerId,
            peerId: friend,
            reason: CallEndReason.busy,
            reject: true,
          );
        } else if (state == SignalingState.candidate) {
          _bufferGlobalCandidate(offerId, data);
        }
      } else {
        activeController.signalingCallbackHandler(
          nostrState: state,
          content: data,
        );
      }
      return;
    }
    if (state == SignalingState.candidate) {
      _bufferGlobalCandidate(offerId, data);
      return;
    }
    if (state == SignalingState.disconnect) {
      disconnectOfferId.add(offerId);
      return;
    }
    if (state == SignalingState.offer) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (disconnectOfferId.contains(offerId)) {
        LogUtils.i(() => 'offerId($offerId) has been disconnected');
        return;
      }

      mediaType ??= CallType.audio;

      final user = chat_core.Account.sharedInstance
          .getUserNotifier(friend)
          .value;

      final controller = await openCallModule(
        user: user,
        callType: mediaType,
        role: CallingRole.callee,
        offerId: offerId,
      );

      controller.signalingCallbackHandler(nostrState: state, content: data);
      _flushGlobalCandidates(offerId, controller);

      controller.callId.then((callId) async {
        await _callKeepManager?.displayIncomingCall(
          callId,
          user.name ?? user.shortEncodedPubkey,
          hasVideo: controller.callType.isVideo,
        );
      });
    }
  }

  Future<void> _handleSelfEchoEvent({
    required SignalingState state,
    required String offerId,
  }) async {
    final activeController = await activeControllerCmp?.future;
    if (activeController == null) return;
    if (await activeController.offerId != offerId) return;

    if (!shouldHandleSelfEchoEvent(
      state: state,
      role: activeController.role,
      callingState: activeController.state.value,
    )) {
      LogUtils.v(() => 'Ignore self echo event: state=$state callId=$offerId');
      return;
    }

    disconnectOfferId.add(offerId);
    await activeController.hangup(CallEndReason.disconnect, false, false);
    LogUtils.i(
      () =>
          'Handled self echo event, ended local call: state=$state callId=$offerId',
    );
  }

  static bool shouldHandleSelfEchoEvent({
    required SignalingState state,
    required CallingRole role,
    required CallingState callingState,
  }) {
    final isAnswerOrRejectElsewhere =
        state == SignalingState.answer || state == SignalingState.disconnect;
    final isIncomingCallRinging =
        role == CallingRole.callee && callingState == CallingState.ringing;
    return isAnswerOrRejectElsewhere && isIncomingCallRinging;
  }

  void _bufferGlobalCandidate(String callId, String content) {
    if (content.isEmpty) return;
    final queue = _globalCandidateBuffer.putIfAbsent(callId, () => <String>[]);
    if (!queue.contains(content)) {
      queue.add(content);
    }
  }

  void _flushGlobalCandidates(String callId, CallingController controller) {
    final queue = _globalCandidateBuffer.remove(callId);
    if (queue == null || queue.isEmpty) return;
    for (final candidateJson in queue) {
      controller.signalingCallbackHandler(
        nostrState: SignalingState.candidate,
        content: candidateJson,
      );
    }
    LogUtils.i(
      () => 'Flushed buffered ICE candidates: ${queue.length}, callId=$callId',
    );
  }

  Future<CallingController> openCallModule({
    required chat_core.UserDBISAR user,
    required CallType callType,
    required CallingRole role,
    String? sessionId,
    String? offerId,
    String? callId,
    CallingControllerLifecycleObserver? lifecycleObserver,
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
      lifecycleObserver: lifecycleObserver,
    );

    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      presentPageWithController(controller);
    } else {
      waitingShowController = controller;
    }

    cmp.complete(controller);

    switch (role) {
      case CallingRole.caller:
        final isSuccess = await controller.invitePeer(
          callId: callId,
          timeoutHandler: () {
            controller.hangup(CallEndReason.timeout);
          },
        );
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
    clean();
  }

  static void _onMissedCallFromRelay(
    String callId,
    String callerPubkey,
    String media,
    int startTimeMs,
  ) {
    final manager = CallKitManager.instance.callHistoryManager;
    final callType = CallTypeEx.fromValue(media) ?? CallType.audio;
    final startTime = DateTime.fromMillisecondsSinceEpoch(startTimeMs);

    manager
        .addCallRecord(
          callId: callId,
          peerPubkey: callerPubkey,
          direction: CallDirection.incoming,
          type: callType,
          status: CallStatus.cancelled,
          startTime: startTime,
          duration: null,
        )
        .then((added) {
          if (added) {
            manager.incrementUnreadMissed();
            LogUtils.i(
              () =>
                  'Missed call from relay recorded: $callId from $callerPubkey, unread count: ${manager.unreadMissedCountNotifier.value}',
            );
          }
        });
  }

  void clean() {
    activeControllerCmp = null;
  }

  /// Dispose resources. Should be called when the manager is no longer needed,
  /// typically during app shutdown.
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    deviceChangeSubscription?.cancel();
    deviceChangeSubscription = null;
    _callKeepEventSubscription?.cancel();
    _callKeepEventSubscription = null;
    _voipPushService?.dispose();
    _voipPushService = null;
    _callKeepManager?.dispose();
    _callKeepManager = null;
    _callHistoryManager?.dispose();
    _callHistoryManager = null;
    isBluetoothHeadsetConnected.dispose();
    clean();
    LogUtils.i(() => 'CallKitManager disposed');
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
