import 'package:flutter/material.dart';
import 'package:noscall/flutter_utils/list_extension.dart';

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

  OverlayEntry? extentItem;
  bool get isExtentItemShowing => extentItem != null
      || isSpeakerToggleShowing
      || isRecordToggleShowing
      || isCameraToggleShowing;

  GlobalKey speakerWidgetKey = GlobalKey();
  GlobalKey recordWidgetKey = GlobalKey();
  GlobalKey cameraWidgetKey = GlobalKey();

  bool isSpeakerToggleShowing = false;
  bool isRecordToggleShowing = false;
  bool isCameraToggleShowing = false;

  double get iconSize => 48;
  double get mainIconSize => 60;

  @override
  Widget build(BuildContext context) {
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
        double horizontal = 0.0;
        switch (items.length) {
          case 2: horizontal = 75; break;
          case 3: horizontal = 36; break;
          case 4: horizontal = 24; break;
          case 5: horizontal = 36; break;
        }
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
            borderRadius: const BorderRadius.all(Radius.circular(24)),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.6),
              width: 0.5,
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: horizontal),
          height: 100,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
    final isConnected = [CallingState.connected, CallingState.ended].contains(state);

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
    builder: (_, speakerType, __) => Container(
      key: speakerWidgetKey,
      child: speakerItem(speakerType),
    ),
  );

  Widget recordWidget() => ValueListenableBuilder(
    valueListenable: controller.isRecordOn,
    builder: (_, isRecordOn, __) => Container(
      key: recordWidgetKey,
      child: recordItem(isRecordOn),
    ),
  );

  Widget cameraWidget() => ValueListenableBuilder(
    valueListenable: controller.isCameraOn,
    builder: (_, isCameraOn, __) => Container(
      key: cameraWidgetKey,
      child: cameraItem(isCameraOn),
    ),
  );

  Widget speakerToggle() => ValueListenableBuilder(
    valueListenable: CallKitManager.instance.isBluetoothHeadsetConnected,
    builder: (_, isBluetoothHeadsetConnected, __) {
      return ValueListenableBuilder(
        valueListenable: controller.speakerType,
        builder: (_, currentSpeakerType, __) {
          List<AudioOutputType> toggleType;
          switch (currentSpeakerType) {
            case AudioOutputType.none:
              toggleType = [
                if (isBluetoothHeadsetConnected)
                  AudioOutputType.bluetooth,
                AudioOutputType.speaker,
              ];
              break;
            case AudioOutputType.speaker:
              toggleType = [
                if (isBluetoothHeadsetConnected)
                  AudioOutputType.bluetooth,
                AudioOutputType.none,
              ];
              break;
            case AudioOutputType.bluetooth:
              toggleType = [
                AudioOutputType.speaker,
                AudioOutputType.none,
              ];
              break;
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: toggleType.map((e) {
              return GestureDetector(
                onTap: () {
                  hideAllToggle();
                  controller.speakerToggleHandler(e);
                },
                child: speakerItem(e),
              );
            }).toList().cast<Widget>().insertEveryN(1, const SizedBox(height: 32)),
          );
        },
      );
    },
  );

  Widget recordToggle() => ValueListenableBuilder(
    valueListenable: controller.isRecordOn,
    builder: (_, value, __) {
      return recordItem(!value);
    },
  );

  Widget cameraToggle() => ValueListenableBuilder(
    valueListenable: controller.isCameraOn,
    builder: (_, value, __) {
      return cameraItem(!value);
    },
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
      onTap: () {
        if (!isSpeakerToggleShowing) {
          showToggleWidget(
            itemKey: speakerWidgetKey,
            child: speakerToggle(),
          );
          isSpeakerToggleShowing = true;
        } else {
          hideAllToggle();
          controller.speakerToggleHandler(speakerType);
        }
      },
      child: Image.asset(
        'assets/images/$iconName',
        width: iconSize,
        height: iconSize,
      ),
    );
  }

  Widget recordItem(bool isRecordOn) {
    final iconName =  isRecordOn
        ? 'icon_call_mic_on.png'
        : 'icon_call_mic_off.png';
    return GestureDetector(
      onTap: () {
        if (!isRecordToggleShowing) {
          showToggleWidget(
            itemKey: recordWidgetKey,
            child: recordToggle(),
          );
          isRecordToggleShowing = true;
        } else {
          hideAllToggle();
          controller.recordToggleHandler(isRecordOn);
        }
      },
      child: Image.asset(
        'assets/images/$iconName',
        height: iconSize,
        width: iconSize,
      ),
    );
  }

  Widget cameraItem(bool isCameraOn) {
    final iconName = isCameraOn
        ? 'icon_call_video_on.png'
        : 'icon_call_video_off.png';
    return GestureDetector(
      onTap: () {
        if (!isCameraToggleShowing) {
          showToggleWidget(
            itemKey: cameraWidgetKey,
            child: cameraToggle(),
          );
          isCameraToggleShowing = true;
        } else {
          hideAllToggle();
          controller.cameraToggleHandler(isCameraOn);
        }
      },
      child: Image.asset(
        'assets/images/$iconName',
        height: iconSize,
        width: iconSize,
      ),
    );
  }

  Widget cameraSwitch() => GestureDetector(
    onTap: widget.controller.cameraSwitchHandler,
    child: Image.asset(
      'assets/images/icon_call_camera_flip.png',
      height: iconSize,
      width: iconSize,
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

  void showToggleWidget({
    required GlobalKey itemKey,
    required Widget child,
  }) {
    if (extentItem != null) {
      hideAllToggle();
    }

    final ancestor = widget.overlayKey.currentContext?.findRenderObject() as RenderBox?;
    final itemBox = itemKey.currentContext?.findRenderObject() as RenderBox?;
    if (ancestor == null || itemBox == null) return;

    final offsetGlobal = itemBox.localToGlobal(Offset.zero, ancestor: ancestor);
    final bottom = ancestor.size.height - offsetGlobal.dy + 64;

    extentItem = OverlayEntry(
      builder: (BuildContext context) {
        return Positioned(
          left: offsetGlobal.dx,
          bottom: bottom,
          child: child,
        );
      },
    );

    widget.overlayKey.currentState!.insert(extentItem!);
  }

  void hideAllToggle() {
    extentItem?.remove();
    extentItem = null;
    isSpeakerToggleShowing = false;
    isRecordToggleShowing = false;
    isCameraToggleShowing = false;
  }
}