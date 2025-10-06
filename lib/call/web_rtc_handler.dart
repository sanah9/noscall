import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:noscall/core/native_method_channel.dart';

import '../core/common/utils/log_utils.dart';
import 'ice_server_manager.dart';
import 'constant/call_type.dart';

class WebRTCHandler {
  WebRTCHandler._({
    required this.callType,
    this.state,
    this.speakerType,
    this.isCameraOn,
    this.isRecordOn,
    this.isFrontCamera,
    this.onIceCandidateCallback,
    this.onIceConnectionStateCallback,
  });

  late RTCPeerConnection peerConnection;

  late MediaStream localMedia;
  MediaStream? remoteMedia;

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  Function(RTCIceCandidate candidate)? onIceCandidateCallback;
  Function(RTCIceConnectionState candidate)? onIceConnectionStateCallback;

  // State
  CallType callType;
  ValueNotifier<CallingState>? state;
  ValueNotifier<AudioOutputType>? speakerType;
  ValueNotifier<bool>? isCameraOn;
  ValueNotifier<bool>? isRecordOn;
  ValueNotifier<bool>? isFrontCamera;

  final List<RTCIceCandidate> _pendingCandidates = [];

  static Future<WebRTCHandler> create({
    required CallType callType,
    ValueNotifier<CallingState>? state,
    ValueNotifier<AudioOutputType>? speakerType,
    ValueNotifier<bool>? isCameraOn,
    ValueNotifier<bool>? isRecordOn,
    ValueNotifier<bool>? isFrontCamera,
    Function(RTCIceCandidate candidate)? onIceCandidateCallback,
    Function(RTCIceConnectionState candidate)? onIceConnectionStateCallback,
  }) async {
    final handler = WebRTCHandler._(
      callType: callType,
      state: state,
      speakerType: speakerType,
      isCameraOn: isCameraOn,
      isRecordOn: isRecordOn,
      isFrontCamera: isFrontCamera,
      onIceCandidateCallback: onIceCandidateCallback,
      onIceConnectionStateCallback: onIceConnectionStateCallback,
    );

    await handler.initialize();
    return handler;
  }

  Future initialize() async {
    await preparePeerConnection();
    await prepareMedia();
    prepareForSdpSemantics();
    prepareCallback();
    NativeMethodChannel.useManualAudio();
  }

  Future preparePeerConnection() async {
    final iceServers = ICEServerManager.shared.defaultICEServers;
    peerConnection = await WebRTCHelper.createConnection(
      iceServers: iceServers,
    );
  }

  Future<RTCSessionDescription> createOffer() => WebRTCHelper.createOffer(peerConnection, callType.isVideo);

  Future<RTCSessionDescription> createAnswer() => WebRTCHelper.createAnswer(peerConnection, callType.isVideo);

  Future setRemoteDescription({
    required String? remoteSdp,
    required String? remoteType,
  }) async {
    LogUtils.info(
      className: 'WebRTCHandler',
      funcName: 'setRemoteDescription',
      message: 'remoteSdp.length: ${remoteSdp?.length}, remoteType: $remoteType',
    );
    await peerConnection.setRemoteDescription(RTCSessionDescription(remoteSdp, remoteType));
    for (final candidate in _pendingCandidates) {
      try {
        LogUtils.info(
          className: 'WebRTCHandler',
          funcName: 'addCandidate',
          message: 'candidate: $candidate',
        );
        await peerConnection.addCandidate(candidate);
      } catch (e, stack) {
        LogUtils.e(() => '$e, $stack');
      }
    }
    _pendingCandidates.clear();
  }

  Future addCandidate({
    required String? candidate,
    required String? sdpMid,
    required int? sdpMLineIndex,
  }) async {
    try {
      final candidateEntry = RTCIceCandidate(
        candidate,
        sdpMid,
        sdpMLineIndex,
      );
      if (await peerConnection.getRemoteDescription() == null) {
        _pendingCandidates.add(candidateEntry);
      } else {
        LogUtils.info(
          className: 'WebRTCHandler',
          funcName: 'addCandidate',
          message: 'candidate: $candidate',
        );
        await peerConnection.addCandidate(candidateEntry);
      }
    } catch (e, stack) {
      LogUtils.e(() => '$e, $stack');
    }
  }

  Future<bool> recordToggle(bool isOpen) async {
    final audioTracks = [...localMedia.getAudioTracks()];
    for (final track in audioTracks) {
      track.enabled = isOpen;
    }
    return true;
  }

  Future<bool> cameraToggle(bool isOpen) async {
    final audioTracks = [...localMedia.getVideoTracks()];
    for (final track in audioTracks) {
      track.enabled = isOpen;
    }
    return true;
  }

  Completer<bool>? switchCameraAction;
  Future<bool> switchCamera() async {
    final switchCameraAction = this.switchCameraAction;
    if (switchCameraAction != null && !switchCameraAction.isCompleted) {
      return switchCameraAction.future;
    }

    final newAction = Completer<bool>();
    this.switchCameraAction = newAction;

    final track = localMedia.getVideoTracks().firstOrNull;
    if (track != null) {
      newAction.complete(Helper.switchCamera(track));
    } else {
      newAction.complete(false);
    }

    return newAction.future;
  }

  Completer? setSpeakerAction;
  Future setSpeakerType(AudioOutputType value) async {
    final setSpeakerAction = this.setSpeakerAction;
    if (setSpeakerAction != null && !setSpeakerAction.isCompleted) {
      return setSpeakerAction.future;
    }

    final newAction = Completer();
    this.setSpeakerAction = newAction;

    switch(value) {
      case AudioOutputType.none:
        await Helper.setSpeakerphoneOn(false);
        break;
      case AudioOutputType.speaker:
        await Helper.setSpeakerphoneOn(true);
        break;
      case AudioOutputType.bluetooth:
        await Helper.setSpeakerphoneOnButPreferBluetooth();
        break;
    }

    newAction.complete();
  }

  Future close() async {
    try {
      final tracks = localMedia.getTracks();
      await Future.wait(tracks.map((e) => e.stop()));
      await localMedia.dispose();

      peerConnection.close();
    } catch (e, stack) {
      LogUtils.e(() => '$e, $stack');
    }
  }

  void dispose() {
    peerConnection.dispose();
    localRenderer.dispose();
    remoteRenderer.dispose();
  }
}

extension WebRTCPeerConnectionMediaEx on WebRTCHandler {
  Future prepareMedia() async {
    final isVideo = callType.isVideo;
    final media = await WebRTCHelper.createStream(
      isAudio: true,
      isVideo: isVideo,
    );
    localMedia = media;

    // Audio Prepare
    final audioTracks = [...localMedia.getAudioTracks()];
    for (final track in audioTracks) {
      track.enabled = isRecordOn?.value ?? true;
    }

    // Video Prepare
    final videoTracks = [...localMedia.getVideoTracks()];
    for (final track in videoTracks) {
      track.enabled = isCameraOn?.value ?? true;
    }

    if (isVideo) {
      WebRTCHelper.addStreamToRenderer(media, localRenderer);
    }
  }
}

extension WebRTCPeerConnectionCallbackEx on WebRTCHandler {
  void prepareForSdpSemantics() {
    final sdpSemantics = peerConnection.getConfiguration['sdpSemantics'];
    switch (sdpSemantics) {
      case 'plan-b':
        peerConnection.onAddStream = (MediaStream stream) async {
          WebRTCHelper.addStreamToRenderer(stream, remoteRenderer);
        };
        peerConnection.addStream(localMedia);
        break;
      case 'unified-plan':
        peerConnection.onTrack = onTrackHandler;

        final tracks = localMedia.getTracks();
        for (final track in tracks) {
          peerConnection.addTrack(track, localMedia);
        }
        break;
    }
  }

  void prepareCallback() {
    peerConnection.onIceCandidate = onIceCandidateCallback;
    peerConnection.onIceConnectionState = onIceConnectionStateCallback;
    peerConnection.onRemoveStream = onRemoveStreamHandler;
  }

  void onRemoveStreamHandler(MediaStream stream) {
    if (remoteRenderer.srcObject == stream) {
      remoteRenderer.srcObject = null;
    }
  }

  void onTrackHandler(RTCTrackEvent event) {
    final stream = event.streams.firstOrNull;
    if (stream == null) return;

    switch (event.track.kind) {
      case 'audio':
        remoteMedia = stream;
        break;
      case 'video':
        WebRTCHelper.addStreamToRenderer(stream, remoteRenderer);
        break;
    }
  }
}

class WebRTCHelper {
  static Future<RTCPeerConnection> createConnection({
    required List<ICEServerModel> iceServers,
  }) {
    Map<String, dynamic> configuration = {
      'iceServers': iceServers.expand((e) => e.serverConfigs).toList(),
      'iceTransportPolicy': 'all',
      'iceCandidatePoolSize': 4,
      'bundlePolicy': 'max-bundle',
      'rtcpMuxPolicy': 'require',
      'sdpSemantics': 'unified-plan',
    };

    Map<String, dynamic> constraints = {
      'mandatory': {},
      'optional': [
        {
          'DtlsSrtpKeyAgreement': true,
        },
      ]
    };

    return createPeerConnection(configuration, constraints);
  }

  static Future<MediaStream> createStream({
    required bool isAudio,
    required bool isVideo,
  }) {
    final videoConstraints = {
      'facingMode': 'user',
    };
    final Map<String, dynamic> mediaConstraints = {
      'audio': isAudio,
      'video': isVideo ? videoConstraints : false,
    };
    return navigator.mediaDevices.getUserMedia(mediaConstraints);
  }

  static Future<RTCSessionDescription> createOffer(RTCPeerConnection connection, bool isVideo) async {

    final description = await connection.createOffer({
      'mandatory': {
        'OfferToReceiveAudio': true,
        'OfferToReceiveVideo': isVideo,
      },
    });

    final sdp = description.sdp;
    description.sdp = sdp?.replaceAll('profile-level-id=640c1f', 'profile-level-id=42e032');

    LogUtils.info(
      className: 'WebRTCHandler',
      funcName: 'createOffer',
      message: 'setLocalDescription: $description',
    );
    await connection.setLocalDescription(description);

    return description;
  }

  static Future<RTCSessionDescription> createAnswer(RTCPeerConnection connection, bool isVideo) async {

    final description = await connection.createAnswer({
      'mandatory': {
        'OfferToReceiveAudio': true,
        'OfferToReceiveVideo': isVideo,
      },
    });

    final sdp = description.sdp;
    description.sdp = sdp?.replaceAll('profile-level-id=640c1f', 'profile-level-id=42e032');

    LogUtils.info(
      className: 'WebRTCHandler',
      funcName: 'createAnswer',
      message: 'setLocalDescription: $description',
    );
    await connection.setLocalDescription(description);

    return description;
  }

  static Future addStreamToRenderer(MediaStream stream, RTCVideoRenderer renderer) async {
    if (renderer.textureId == null) await renderer.initialize();
    renderer.srcObject = stream;
  }

  static Future<List<RTCRtpSender>> getVideoSender(RTCPeerConnection connection) async {
    final senders = await connection.getSenders();
    return senders.where((e) => e.track?.kind == 'video').toList();
  }

  static Future<List<RTCRtpSender>> getAudioSender(RTCPeerConnection connection) async {
    final senders = await connection.getSenders();
    return senders.where((e) => e.track?.kind == 'audio').toList();
  }
}