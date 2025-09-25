import 'package:flutter/material.dart';

import '../call_manager.dart';
import '../calling_controller.dart';
import '../constant/call_type.dart';

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
      valueListenable: controller.state,
      builder: (_, state, __) {
        final items = controlWidgets(state);
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

  List<Widget> controlWidgets(CallingState state) {
    final role = controller.role;
    final type = controller.callType;
    final isConnected = state == CallingState.connected;
    final isEnded = state == CallingState.ended;

    if (isEnded) {
      return [];
    }

    switch ((isConnected, role, type)) {
      case (false, CallingRole.callee, CallType.audio):
      // Audio - Invited
        return controlsForInvitedAudio();
      case (false, CallingRole.callee, CallType.video):
      // Video - Invited
        return controlsForInvitedVideo();
      case (false, CallingRole.caller, CallType.audio):
      // Audio - Inviting
        return controlsForInvitingAudio();
      case (false, CallingRole.caller, CallType.video):
      // Video - Inviting
        return controlsForInvitingVideo();
      case (true, _, CallType.audio):
      // Audio - Connected
        return controlsForConnectedAudio();
      case (true, _, CallType.video):
      // Video - Connected
        return controlsForConnectedVideo();
    }
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

  Widget acceptBtn() => GestureDetector(
    onTap: () => widget.controller.accept(),
    child: Image.asset(
      'assets/images/icon_call_accept.png',
      height: mainIconSize,
      width: mainIconSize,
    ),
  );

  Widget hangupBtn() => GestureDetector(
    onTap: () => widget.controller.hangup('hangup'),
    child: Image.asset(
      'assets/images/icon_call_end.png',
      height: mainIconSize,
      width: mainIconSize,
    ),
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
      title: Text('Select Audio Output'),
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
          child: Text('Cancel'),
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