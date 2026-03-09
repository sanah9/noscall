import 'package:flutter/material.dart';

import 'package:noscall/call/call_kit_manager.dart';
import 'package:noscall/call/calling_controller.dart';
import 'package:noscall/call/constant/call_type.dart';

class CallingControlsBar extends StatefulWidget {
  const CallingControlsBar({
    super.key,
    required this.controller,
    required this.overlayKey,
  });

  final CallingController controller;
  final GlobalKey<OverlayState> overlayKey;

  @override
  State<StatefulWidget> createState() => CallingControlsBarState();
}

class CallingControlsBarState extends State<CallingControlsBar> {

  CallingController get controller => widget.controller;

  double get iconSize => 48;
  double get mainIconSize => 60;

  late ThemeData theme;
  Color get surface => theme.colorScheme.surface;
  Color get outline => theme.colorScheme.outline;
  Color get primary => theme.colorScheme.primary;
  Color get errorColor => theme.colorScheme.error;

  @override
  Widget build(BuildContext context) {
    theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        content(),
      ],
    );
  }

  Widget content() {
    return ValueListenableBuilder(
      valueListenable: controller.hasConnected,
      builder: (_, hasConnected, __) {
        return ValueListenableBuilder(
          valueListenable: controller.state,
          builder: (_, state, __) {
            final items = controlWidgets(state, hasConnected);
            return Container(
              decoration: BoxDecoration(
                color: surface.withValues(alpha: 0.6),
                borderRadius: const BorderRadius.all(Radius.circular(24)),
                border: Border.all(
                  color: outline.withValues(alpha: 0.6),
                  width: 0.5,
                ),
              ),
              height: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: items,
              ),
            );
          },
        );
      }
    );
  }

  List<Widget> controlWidgets(CallingState state, bool hasConnected) {
    final role = controller.role;
    final type = controller.callType;
    final isEnded = state == CallingState.ended;

    List<Widget> widgets = switch ((hasConnected, role, type)) {
      (false, CallingRole.callee, CallType.audio) => controlsForInvitedAudio(),
      (false, CallingRole.callee, CallType.video) => controlsForInvitedVideo(),
      (false, CallingRole.caller, CallType.audio) => controlsForInvitingAudio(),
      (false, CallingRole.caller, CallType.video) => controlsForInvitingVideo(),
      (true, _, CallType.audio) => controlsForConnectedAudio(),
      (true, _, CallType.video) => controlsForConnectedVideo(),
    };

    // If ended, wrap all widgets to disable them
    if (isEnded) {
      widgets = widgets.map((widget) => Opacity(
        opacity: 0.5,
        child: IgnorePointer(
          child: widget,
        ),
      )).toList();
    }

    return widgets;
  }

  List<Widget> controlsForInvitedAudio([bool toggleMode = false]) => [
    hangupBtn(),
    acceptBtn(),
  ];

  List<Widget> controlsForInvitedVideo() => [
    cameraWidget(),
    hangupBtn(),
    acceptBtn(),
    cameraSwitch(),
  ];

  List<Widget> controlsForInvitingAudio() => [
    recordWidget(),
    hangupBtn(),
    speakerWidget(),
  ];

  List<Widget> controlsForInvitingVideo() => [
    cameraWidget(),
    hangupBtn(),
    cameraSwitch(),
  ];

  List<Widget> controlsForConnectedAudio() => [
    recordWidget(),
    hangupBtn(),
    speakerWidget(),
  ];

  List<Widget> controlsForConnectedVideo() => [
    recordWidget(),
    cameraWidget(),
    hangupBtn(),
    cameraSwitch(),
    speakerWidget(),
  ];

  Widget speakerWidget() => ValueListenableBuilder(
    valueListenable: controller.speakerType,
    builder: (_, speakerType, __) => speakerItem(speakerType),
  );

  Widget recordWidget() => ValueListenableBuilder(
    valueListenable: controller.isRecordOn,
    builder: (_, isRecordOn, __) => recordItem(isRecordOn),
  );

  Widget cameraWidget() => ValueListenableBuilder(
    valueListenable: controller.isCameraOn,
    builder: (_, isCameraOn, __) => cameraItem(isCameraOn),
  );

  Widget speakerItem(AudioOutputType speakerType) {
    String iconName;
    switch (speakerType) {
      case AudioOutputType.none:
        iconName = 'icon_call_speaker_off.png';
        break;
      case AudioOutputType.speaker:
        iconName = 'icon_call_speaker_on.png';
        break;
      case AudioOutputType.bluetooth:
        iconName = 'icon_call_speaker_of_bluetooth.png';
        break;
    }
    return GestureDetector(
      onTap: _handleSpeakerTap,
      child: Image.asset(
        'assets/images/$iconName',
        width: iconSize,
        height: iconSize,
        color: primary,
      ),
    );
  }

  Widget recordItem(bool isRecordOn) {
    final iconName =  isRecordOn
        ? 'icon_call_mic_on.png'
        : 'icon_call_mic_off.png';
    return GestureDetector(
      onTap: _handleRecordTap,
      child: Image.asset(
        'assets/images/$iconName',
        height: iconSize,
        width: iconSize,
        color: primary,
      ),
    );
  }

  Widget cameraItem(bool isCameraOn) {
    final iconName = isCameraOn
        ? 'icon_call_video_on.png'
        : 'icon_call_video_off.png';
    return GestureDetector(
      onTap: _handleCameraTap,
      child: Image.asset(
        'assets/images/$iconName',
        height: iconSize,
        width: iconSize,
        color: primary,
      ),
    );
  }

  Widget cameraSwitch() => GestureDetector(
    onTap: widget.controller.cameraSwitchHandler,
    child: Image.asset(
      'assets/images/icon_call_camera_flip.png',
      height: iconSize,
      width: iconSize,
      color: primary,
    ),
  );

  Widget acceptBtn() => ValueListenableBuilder(
    valueListenable: controller.isAccepting,
    builder: (_, value, __) {
      final isAccepting = value && controller.state.value == CallingState.connecting;
      return  GestureDetector(
        onTap: isAccepting ? null : () => widget.controller.accept(),
        child:  Container(
          width: mainIconSize,
          height: mainIconSize,
          decoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.green.withValues(alpha: 0.2),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: isAccepting ? const CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ) : Icon(
            Icons.call,
            color: Colors.white,
            size: mainIconSize * 0.5,
          ),
        ),
      );
    }
  );

  Widget hangupBtn() => ValueListenableBuilder(
    valueListenable: controller.isHangingUp,
    builder: (_, value, __) {
      final isHangingUp = value;
      return  GestureDetector(
        onTap: isHangingUp ? null : () => widget.controller.hangup(CallEndReason.hangup),
        child: Container(
          width: mainIconSize,
          height: mainIconSize,
          decoration: BoxDecoration(
            color: errorColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: errorColor.withValues(alpha: 0.2),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: isHangingUp ? const CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ) : Icon(
            Icons.call_end,
            color: Colors.white,
            size: mainIconSize * 0.5,
          ),
        ),
      );
    }
  );

  void _handleSpeakerTap() {
    final isBluetoothConnected = CallKitManager.instance.isBluetoothHeadsetConnected.value;

    if (isBluetoothConnected) {
      _showSpeakerSelectionDialog();
    } else {
      _toggleSpeakerDirectly();
    }
  }

  void _handleRecordTap() {
    final currentRecordState = controller.isRecordOn.value;
    controller.recordToggleHandler(!currentRecordState);
  }

  void _handleCameraTap() {
    final currentCameraState = controller.isCameraOn.value;
    controller.cameraToggleHandler(!currentCameraState);
  }

  void _toggleSpeakerDirectly() {
    final currentSpeakerType = controller.speakerType.value;
    AudioOutputType nextType;

    switch (currentSpeakerType) {
      case AudioOutputType.none:
        nextType = AudioOutputType.speaker;
        break;
      case AudioOutputType.speaker:
        nextType = AudioOutputType.none;
        break;
      case AudioOutputType.bluetooth:
        nextType = AudioOutputType.speaker;
        break;
    }

    controller.speakerToggleHandler(nextType);
  }

  void _showSpeakerSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => _buildSpeakerSelectionDialog(),
    );
  }

  Widget _buildSpeakerSelectionDialog() {
    final currentSpeakerType = controller.speakerType.value;
    final isBluetoothConnected = CallKitManager.instance.isBluetoothHeadsetConnected.value;

    return AlertDialog(
      title: const Text('Select Audio Output'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSpeakerOption(
            AudioOutputType.none,
            Icons.volume_off,
            'Phone Speaker',
            currentSpeakerType == AudioOutputType.none,
          ),
          _buildSpeakerOption(
            AudioOutputType.speaker,
            Icons.volume_up,
            'Speaker',
            currentSpeakerType == AudioOutputType.speaker,
          ),
          if (isBluetoothConnected)
            _buildSpeakerOption(
              AudioOutputType.bluetooth,
              Icons.bluetooth,
              'Bluetooth',
              currentSpeakerType == AudioOutputType.bluetooth,
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _buildSpeakerOption(AudioOutputType type, IconData icon, String label, bool isSelected) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? primary : null),
      title: Text(label),
      trailing: isSelected ? Icon(Icons.check, color: primary) : null,
      onTap: () {
        Navigator.of(context).pop();
        controller.speakerToggleHandler(type);
      },
    );
  }
}