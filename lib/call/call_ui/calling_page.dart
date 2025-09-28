import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:go_router/go_router.dart';
import 'package:noscall/contacts/user_avatar.dart';

import '../constant/call_type.dart';
import '../calling_controller.dart';
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

class CallingPageState extends State<CallingPage> {

  CallingController get controller => widget.controller;
  final GlobalKey<OverlayState> overlayKey = GlobalKey<OverlayState>();
  final GlobalKey<CallingControlsBarState> controlsBarKey = GlobalKey<CallingControlsBarState>();

  double localCameraPosTop = 120.0;
  double localCameraPosLeft = 20.0;

  late ThemeData theme;
  Color get onSurface => theme.colorScheme.onSurface;

  @override
  void initState() {
    super.initState();
    controller.state.addListener(_callStateUpdate);
    _setStatusBarMode();
  }

  @override
  void dispose() {
    if (controller.state.value != CallingState.ended) {
      controller.hangup(CallEndReason.hangup);
    }
    controller.state.removeListener(_callStateUpdate);
    _restoreStatusBarMode();
    super.dispose();
  }

  void counterValueChange(value) {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    theme = Theme.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _getStatusBarStyle(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          systemOverlayStyle: _getStatusBarStyle(),
          leading: BackButton(
            onPressed: () {
              controller.hangup(CallEndReason.hangup);
            },
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
    return Stack(
      children: [
        Positioned.fill(
          child: _buildBackgroundView(),
        ),
        Positioned.fill(
          left: 50,
          right: 50,
          child: _buildInfoView(),
        ),
        Positioned(
          bottom: 48,
          left: 30,
          right: 30,
          child: SafeArea(
            top: false,
            child: _buildControlsBar(),
          ),
        ),
        Positioned(
          top: localCameraPosTop,
          left: localCameraPosLeft,
          child: _buildCameraScreen(),
        ),
      ],
    );
  }

  Widget _buildBackgroundView() {
    return Visibility(
      visible: controller.callType.isVideo,
      child: ValueListenableBuilder(
        valueListenable: controller.state,
        builder: (BuildContext context, state, Widget? child) {
          return RTCVideoView(
            state == CallingState.connected
                ? controller.webRTCHandler.remoteRenderer
                : controller.webRTCHandler.localRenderer,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          );
        },
      ),
    );
  }

  Widget _buildCameraScreen() {
    return ValueListenableBuilder(
      valueListenable: controller.state,
      builder: (BuildContext context, state, Widget? child) {
        return Visibility(
          visible: controller.callType.isVideo
              && state == CallingState.connected,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                localCameraPosTop += details.delta.dy;
                localCameraPosLeft += details.delta.dx;
              });
            },
            child: SizedBox(
              width: 90,
              height: 120,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: RTCVideoView(
                  controller.webRTCHandler.localRenderer,
                  mirror: true,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
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
        if (controller.callType.isVideo  && state == CallingState.connected) {
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
      radius: 120,
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

  void _callStateUpdate() {
    if (!mounted) return;

    if (controller.state.value == CallingState.ended) {
      context.pop();
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