import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:go_router/go_router.dart';
import 'package:noscall/contacts/user_avatar.dart';

import '../constant/call_type.dart';
import '../calling_controller.dart';
import '../pip_manager.dart';
import 'calling_controls_bar.dart';

class CallingPage extends StatefulWidget {

  const CallingPage({
    super.key,
    required this.controller,
  });

  final CallingController controller;

  @override
  State<StatefulWidget> createState() {
    return CallingPageState();
  }
}

class CallingPageState extends State<CallingPage> with WidgetsBindingObserver {

  CallingController get controller => widget.controller;
  final GlobalKey<OverlayState> overlayKey = GlobalKey<OverlayState>();
  final GlobalKey<CallingControlsBarState> controlsBarKey = GlobalKey<CallingControlsBarState>();

  double _cameraPosTopRatio = 0.15;
  double _cameraPosLeftRatio = 0.05;

  static const double _cameraWidthRatio = 0.25;
  static const double _cameraHeightRatio = 0.20;
  static const double _cameraAspectRatio = 3.0 / 4.0;

  // Store initial drag position and cumulative delta for accurate 1:1 dragging
  double? _dragStartTop;
  double? _dragStartLeft;
  double _cumulativeDeltaX = 0.0;
  double _cumulativeDeltaY = 0.0;

  late ThemeData theme;
  Color get onSurface => theme.colorScheme.onSurface;

  StreamSubscription<bool>? _pipStateSubscription;

  bool _showControls = true;
  Timer? _autoHideTimer;

  // Track if video view is ready to render (for Android)
  bool _isVideoViewReady = false;

  bool get _isVideoConnected =>
      controller.state.value == CallingState.connected &&
      controller.callType.isVideo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller.state.addListener(_callStateUpdate);
    _setStatusBarMode();

    if (Platform.isAndroid) {
      _pipStateSubscription = PipManager.pipStateStream.listen((isPip) {
        if (mounted) {
          // Future: Could adjust UI based on PiP mode
        }
      });
    }

    _checkVideoRendererReady();

    _startAutoHideTimer();
  }

  void _checkVideoRendererReady() {
    if (!controller.callType.isVideo) {
      _isVideoViewReady = true;
      return;
    }

    // Check if renderer is initialized by checking textureId
    // On Android, RTCVideoView needs renderer to have textureId before it can display
    // The renderer should be initialized during WebRTCHandler.create() -> prepareMedia()
    // But we need to wait until it's ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pollRendererReady();
    });
  }

  void _pollRendererReady() {
    if (!mounted || !controller.callType.isVideo) return;

    final localRenderer = controller.webRTCHandler.localRenderer;

    // Check if renderer has textureId (indicating it's initialized and ready)
    if (localRenderer.textureId != null) {
      // Renderer is ready, update state to show video
      if (mounted && !_isVideoViewReady) {
        setState(() {
          _isVideoViewReady = true;
        });
      }
    } else {
      // Renderer not ready yet, check again after a short delay
      // This polls until textureId is available (up to a reasonable timeout)
      Future.delayed(const Duration(milliseconds: 50), () {
        _pollRendererReady();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    PipManager.disableAndroidPip();
    PipManager.detachIOSPiP();
    _pipStateSubscription?.cancel();
    _cancelAutoHideTimer();
    if (controller.state.value != CallingState.ended) {
      controller.hangup(CallEndReason.hangup);
    }
    controller.state.removeListener(_callStateUpdate);
    _restoreStatusBarMode();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (!mounted) return;

    final appStateBackground = state == AppLifecycleState.paused || state == AppLifecycleState.inactive;
    if (_isVideoConnected && appStateBackground) {
      if (appStateBackground && _showControls) {
        setState(() {
          _showControls = false;
        });
        _cancelAutoHideTimer();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    theme = Theme.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _getStatusBarStyle(),
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: AnimatedOpacity(
            opacity: _showControls ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: AppBar(
              backgroundColor: Colors.transparent,
              systemOverlayStyle: _getStatusBarStyle(),
              leading: BackButton(
                onPressed: () {
                  controller.hangup(CallEndReason.hangup);
                },
              ),
            ),
          ),
        ),
        extendBodyBehindAppBar: true,
        body: Overlay(
          key: overlayKey,
          initialEntries: [
            OverlayEntry(
              builder: (_) => _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final screenWidth = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final screenHeight = constraints.maxHeight.isFinite && constraints.maxHeight > 0
            ? constraints.maxHeight
            : MediaQuery.of(context).size.height;

        if (screenWidth <= 0 || screenHeight <= 0 || !screenWidth.isFinite || !screenHeight.isFinite) {
          return _buildBackgroundView();
        }

        // Calculate camera window size based on screen size
        // Use width-based calculation to maintain aspect ratio
        final cameraWidth = screenWidth * _cameraWidthRatio;
        final cameraHeight = cameraWidth / _cameraAspectRatio;

        // Ensure camera height doesn't exceed screen height limit
        final maxCameraHeight = screenHeight * _cameraHeightRatio;
        final finalCameraWidth = cameraHeight > maxCameraHeight
            ? maxCameraHeight * _cameraAspectRatio
            : cameraWidth;
        final finalCameraHeight = cameraHeight > maxCameraHeight
            ? maxCameraHeight
            : cameraHeight;

        // Validate calculated dimensions
        final safeCameraWidth = finalCameraWidth.isFinite && finalCameraWidth > 0
            ? finalCameraWidth.clamp(0.0, screenWidth)
            : 90.0;
        final safeCameraHeight = finalCameraHeight.isFinite && finalCameraHeight > 0
            ? finalCameraHeight.clamp(0.0, screenHeight)
            : 120.0;

        // Calculate absolute position from relative ratios
        // This ensures camera window scales properly with screen size
        final localCameraPosTop = (screenHeight * _cameraPosTopRatio).clamp(0.0, screenHeight);
        final localCameraPosLeft = (screenWidth * _cameraPosLeftRatio).clamp(0.0, screenWidth);

        return Stack(
          children: [
            // Background with tap gesture
            Positioned.fill(
              child: GestureDetector(
                onTap: _handleBackgroundTap,
                behavior: HitTestBehavior.translucent,
                child: _buildBackgroundView(),
              ),
            ),
            // Info view
            Positioned.fill(
              left: screenWidth * 0.1,
              right: screenWidth * 0.1,
              child: IgnorePointer(
                ignoring: !_showControls,
                child: AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: _buildInfoView(),
                ),
              ),
            ),
            // Controls bar
            Positioned(
              bottom: screenHeight * 0.05,
              left: screenWidth * 0.08,
              right: screenWidth * 0.08,
              child: SafeArea(
                top: false,
                child: IgnorePointer(
                  ignoring: !_showControls,
                  child: AnimatedOpacity(
                    opacity: _showControls ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: _buildControlsBar(),
                  ),
                ),
              ),
            ),
            // Camera screen - placed last to receive gestures first
            Positioned(
              top: localCameraPosTop,
              left: localCameraPosLeft,
              child: _buildCameraScreen(
                width: safeCameraWidth,
                height: safeCameraHeight,
                screenWidth: screenWidth,
                screenHeight: screenHeight,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBackgroundView() {
    return Visibility(
      visible: controller.callType.isVideo,
      child: ValueListenableBuilder(
        valueListenable: controller.hasConnected,
        builder: (BuildContext context, hasConnected, Widget? child) {
          // Determine which renderer to use
          final renderer = hasConnected
              ? controller.webRTCHandler.remoteRenderer
              : controller.webRTCHandler.localRenderer;

          // Show black background while waiting for renderer to be ready
          // This prevents white background flash on iOS when renderer is not initialized yet
          if (!_isVideoViewReady && !hasConnected) {
            return Container(
              color: Colors.black,
            );
          }

          return Container(
            color: Colors.black,
            child: RTCVideoView(
              renderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
          );
        },
      ),
    );
  }

  Widget _buildCameraScreen({
    required double width,
    required double height,
    required double screenWidth,
    required double screenHeight,
  }) {
    final borderRadius = (width * 0.12).floorToDouble();

    return ValueListenableBuilder(
      valueListenable: controller.state,
      builder: (BuildContext context, state, Widget? child) {
        return Visibility(
          visible: _isVideoConnected,
          child: GestureDetector(
            // Use behavior: HitTestBehavior.opaque to ensure gestures are captured
            behavior: HitTestBehavior.opaque,
            onPanStart: (_) => _handleCameraPanStart(screenWidth, screenHeight),
            onPanUpdate: (details) => _handleCameraPanUpdate(
              details,
              screenWidth,
              screenHeight,
              width,
              height,
            ),
            onPanEnd: (_) => _handleCameraPanEnd(),
            onPanCancel: () => _handleCameraPanCancel(),
            child: SizedBox(
              width: width,
              height: height,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(borderRadius),
                  child: RTCVideoView(
                    controller.webRTCHandler.localRenderer,
                    mirror: true,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoView() {
    return ValueListenableBuilder(
      valueListenable: controller.state,
      builder: (BuildContext context, state, Widget? child) {
        if (_isVideoConnected) {
          return const SizedBox();
        }

        return SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 64),
              _buildHeadImage(),
              const SizedBox(height: 16),
              _buildHeadName(),
              const SizedBox(height: 2),
              _buildHint(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControlsBar() {
    return CallingControlsBar(
      key: controlsBarKey,
      controller: widget.controller,
      overlayKey: overlayKey,
    );
  }

  Widget _buildHeadImage() {
    return UserAvatar(
      user: controller.user,
      size: 240,
    );
  }

  Widget _buildHeadName() {
    String showName = controller.user.displayName();
    return Text(
      showName,
      style: TextStyle(
        color: onSurface,
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
      maxLines: 1,
      textAlign: TextAlign.center,
    );
  }

  Widget _buildHint() {
    return ListenableBuilder(
      listenable: Listenable.merge([
        controller.state,
        controller.connectedDuration,
      ]),
      builder: (BuildContext context, Widget? child) {
        final state = controller.state.value;
        final duration = controller.connectedDuration.value;
        String showHint = 'Calling...';
        if (state == CallingState.ringing && controller.role == CallingRole.callee) {
          showHint = controller.callType == CallType.audio
              ? 'Invites you to a call...'
              : 'Invites you to a video call...';
        } else if (state == CallingState.connecting) {
          showHint = 'Connecting...';
        } else if (state == CallingState.connected) {
          String twoDigits(int n) => n.toString().padLeft(2, "0");
          String twoDigitMinutes = twoDigits(duration.inMinutes);
          String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
          showHint = '$twoDigitMinutes:$twoDigitSeconds';
        }
        return Text(
          showHint,
          style: TextStyle(
            color: onSurface,
            fontSize: 14,
          ),
          maxLines: 1,
          textAlign: TextAlign.center,
        );
      },
    );
  }

  void _handleCameraPanStart(double screenWidth, double screenHeight) {
    // Calculate initial absolute position from current ratios
    // Don't use setState here to avoid rebuild that might interrupt gesture
    _dragStartTop = screenHeight * _cameraPosTopRatio;
    _dragStartLeft = screenWidth * _cameraPosLeftRatio;
    _cumulativeDeltaX = 0.0;
    _cumulativeDeltaY = 0.0;
  }

  void _handleCameraPanUpdate(
      DragUpdateDetails details,
      double screenWidth,
      double screenHeight,
      double width,
      double height,
      ) {
    // Validate screen dimensions
    if (screenWidth <= 0 || screenHeight <= 0 ||
        !screenWidth.isFinite || !screenHeight.isFinite) {
      return;
    }

    // Ensure we have initial drag position (fallback if onPanStart didn't fire)
    if (_dragStartTop == null || _dragStartLeft == null) {
      _dragStartTop = screenHeight * _cameraPosTopRatio;
      _dragStartLeft = screenWidth * _cameraPosLeftRatio;
      _cumulativeDeltaX = 0.0;
      _cumulativeDeltaY = 0.0;
    }

    // Accumulate delta values for accurate 1:1 drag tracking
    // details.delta is the incremental movement since last update
    _cumulativeDeltaX += details.delta.dx;
    _cumulativeDeltaY += details.delta.dy;

    // Calculate constraints
    const minMargin = 8.0;
    final maxTop = (screenHeight - height - minMargin).clamp(0.0, screenHeight);
    final maxLeft = (screenWidth - width - minMargin).clamp(0.0, screenWidth);

    // Calculate new position from initial drag position + accumulated delta
    // This ensures 1:1 drag tracking (finger movement = widget movement)
    final newTop = _dragStartTop! + _cumulativeDeltaY;
    final newLeft = _dragStartLeft! + _cumulativeDeltaX;

    // Constrain within bounds
    final constrainedTop = newTop.clamp(0.0, maxTop);
    final constrainedLeft = newLeft.clamp(0.0, maxLeft);

    // If constrained, adjust cumulative delta to match constrained position
    // This prevents dragging from getting stuck at boundaries
    if (constrainedTop != newTop) {
      _cumulativeDeltaY = constrainedTop - _dragStartTop!;
    }
    if (constrainedLeft != newLeft) {
      _cumulativeDeltaX = constrainedLeft - _dragStartLeft!;
    }

    // Update ratios and trigger rebuild
    setState(() {
      if (screenHeight > 0 && screenWidth > 0) {
        _cameraPosTopRatio = (constrainedTop / screenHeight).clamp(0.0, 1.0);
        _cameraPosLeftRatio = (constrainedLeft / screenWidth).clamp(0.0, 1.0);
      }
    });
  }

  void _handleCameraPanEnd() {
    // Clear drag state when drag ends
    _dragStartTop = null;
    _dragStartLeft = null;
    _cumulativeDeltaX = 0.0;
    _cumulativeDeltaY = 0.0;
  }

  void _handleCameraPanCancel() {
    // Clear drag state if drag is cancelled
    _dragStartTop = null;
    _dragStartLeft = null;
    _cumulativeDeltaX = 0.0;
    _cumulativeDeltaY = 0.0;
  }

  void _startAutoHideTimer() {
    if (_isVideoConnected) {
      _autoHideTimer?.cancel();
      _autoHideTimer = Timer(const Duration(seconds: 10), () {
        if (mounted && _showControls) {
          setState(() {
            _showControls = false;
          });
        }
      });
    }
  }

  void _cancelAutoHideTimer() {
    _autoHideTimer?.cancel();
    _autoHideTimer = null;
  }

  void _handleBackgroundTap() {
    if (_isVideoConnected) {
      _toggleControls();
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });

    if (_showControls) {
      _startAutoHideTimer();
    } else {
      _cancelAutoHideTimer();
    }
  }

  void _callStateUpdate() {
    if (!mounted) return;

    final state = controller.state.value;

    if (state == CallingState.ended) {
      context.pop();
    } else if (_isVideoConnected) {
      // Restart auto-hide timer when call is connected
      _startAutoHideTimer();

      if (Platform.isAndroid) {
        PipManager.enableAndroidPip();
      }
    }
  }

  SystemUiOverlayStyle _getStatusBarStyle() {
    if (controller.callType.isVideo) {
      return const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      );
    } else {
      return const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      );
    }
  }

  void _setStatusBarMode() {
    SystemChrome.setSystemUIOverlayStyle(_getStatusBarStyle());
  }

  void _restoreStatusBarMode() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
  }
}