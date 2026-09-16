import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:noscall/core/account/account.dart';
import 'package:permission_handler/permission_handler.dart';

import 'voice_draft_store.dart';
import 'voice_recording_device.dart';
import 'voice_send_controller.dart';

class SendVoiceMessagePage extends StatefulWidget {
  const SendVoiceMessagePage({
    super.key,
    required this.receiverPubkey,
    this.replyToMessageId,
    this.controller,
    this.recorder,
  });
  final String receiverPubkey;
  final String? replyToMessageId;
  final VoiceSendController? controller;
  final VoiceRecordingDevice? recorder;
  @override
  State<SendVoiceMessagePage> createState() => _SendVoiceMessagePageState();
}

class _SendVoiceMessagePageState extends State<SendVoiceMessagePage>
    with WidgetsBindingObserver {
  VoiceSendController? _controller;
  late final _recorder = widget.recorder ?? DefaultVoiceRecordingDevice();
  final _stopwatch = Stopwatch();
  Timer? _timer;
  AudioPlayer? _player;
  StreamSubscription<PlayerState>? _playerSubscription;
  bool _recording = false;
  bool _working = false;
  bool _allowPop = false;
  bool _permissionDenied = false;
  bool _playing = false;
  bool _previewLoading = false;
  int _seconds = 0;
  String? _error;
  File? _unsavedRecording;
  bool get _busy => _working || _previewLoading || (_controller?.busy ?? false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    try {
      final owner = Account.sharedInstance.currentPubkey;
      _controller =
          widget.controller ??
          VoiceSendController(
            store: FileVoiceDraftStore(
              owner: owner,
              receiver: widget.receiverPubkey,
              replyId: widget.replyToMessageId ?? '',
            ),
            backend: DefaultVoiceSendBackend(owner),
          );
      _controller!.addListener(_changed);
      _controller!.load();
    } catch (_) {
      _error = 'Sign in and select a contact before recording.';
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_recording && !_working) _stopRecording();
      _player?.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _playerSubscription?.cancel();
    _player?.dispose();
    _recorder.dispose();
    _controller?.removeListener(_changed);
    if (widget.controller == null) _controller?.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (_busy || _controller == null) return;
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      if (!await _recorder.requestPermission()) {
        if (mounted) setState(() => _permissionDenied = true);
        return;
      }
      if (!mounted) return;
      await _recorder.start();
      if (!mounted) {
        await _recorder.stop();
        return;
      }
      _stopwatch
        ..reset()
        ..start();
      setState(() {
        _recording = true;
        _seconds = 0;
        _permissionDenied = false;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _seconds = _stopwatch.elapsed.inSeconds);
        if (_seconds >= 120) _stopRecording();
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Recording could not start. Check microphone access.',
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<bool> _stopRecording() async {
    if (_working || !_recording) return false;
    setState(() => _working = true);
    _timer?.cancel();
    _stopwatch.stop();
    try {
      final file = await _recorder.stop();
      if (mounted) setState(() => _recording = false);
      if (file == null) throw StateError('Recording unavailable');
      _unsavedRecording = file;
      _seconds = ((_stopwatch.elapsedMilliseconds + 999) ~/ 1000).clamp(1, 120);
      await _controller!.saveRecording(file, _seconds);
      _unsavedRecording = null;
      if (mounted) setState(() => _error = null);
      if (file.path != _controller!.draft?.path && await file.exists()) {
        await file.delete();
      }
      return true;
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = _recording
              ? 'Recording could not stop. Please try stopping again.'
              : 'Recording is not saved yet. Retry saving or discard it.',
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _retrySave() async {
    if (_unsavedRecording == null || _busy) return;
    try {
      await _controller!.saveRecording(_unsavedRecording!, _seconds);
      if (_unsavedRecording!.path != _controller!.draft?.path) {
        await _unsavedRecording!.delete();
      }
      _unsavedRecording = null;
      if (mounted) setState(() => _error = null);
    } catch (_) {
      /* Keep the recording for another retry. */
    }
  }

  Future<void> _preview() async {
    final draft = _controller?.draft;
    if (draft == null || _busy) return;
    setState(() => _previewLoading = true);
    try {
      if (_playing) {
        await _player?.pause();
        return;
      }
      if (_player == null) {
        _player = AudioPlayer();
        _playerSubscription = _player!.playerStateStream.listen((state) {
          if (mounted) {
            setState(
              () => _playing =
                  state.playing &&
                  state.processingState != ProcessingState.completed,
            );
          }
        });
      }
      await _player!.setFilePath(draft.path);
      unawaited(
        _player!.play().catchError((Object _) {
          if (mounted) setState(() => _error = 'Audio preview could not play.');
        }),
      );
    } catch (_) {
      if (mounted) setState(() => _error = 'Audio preview could not play.');
    } finally {
      if (mounted) setState(() => _previewLoading = false);
    }
  }

  Future<void> _discard() async {
    if (_busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard draft?'),
        content: Text(
          _controller?.draft?.prepared != null
              ? 'This message may already have reached a relay. Discarding removes only the local draft.'
              : 'This recording will be removed from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _player?.stop();
    await _controller?.discard();
    if (_unsavedRecording != null && await _unsavedRecording!.exists()) {
      await _unsavedRecording!.delete();
    }
    _unsavedRecording = null;
    if (mounted) setState(() => _error = null);
  }

  Future<void> _leave() async {
    if (_busy) return;
    if (_recording && !await _stopRecording()) return;
    if (_unsavedRecording != null) return;
    if (!mounted) return;
    setState(() => _allowPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _send() async {
    await _player?.pause();
    if (await _controller!.send() && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voice message accepted by relay')),
      );
      await _leave();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final draft = controller?.draft;
    final error = _error ?? controller?.error;
    final phase = controller?.phase ?? VoiceSendPhase.draft;
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Voice message'),
          leading: IconButton(
            tooltip: 'Save draft and close',
            onPressed: _busy ? null : _leave,
            icon: const Icon(Icons.close),
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 24),
                Icon(
                  _recording ? Icons.mic : Icons.graphic_eq,
                  size: 80,
                  color: _recording
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  _recording
                      ? '${_seconds}s / 120s'
                      : draft == null
                      ? 'New recording'
                      : '${draft.durationSeconds}s',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                if (error != null) ...[
                  Text(
                    error,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_busy) ...[
                  LinearProgressIndicator(
                    value: phase == VoiceSendPhase.uploading
                        ? controller?.progress
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(switch (phase) {
                    VoiceSendPhase.uploading =>
                      'Uploading encrypted audio: ${((controller?.progress ?? 0) * 100).round()}%',
                    VoiceSendPhase.preparing => 'Preparing message...',
                    VoiceSendPhase.sending =>
                      'Waiting for relay confirmation...',
                    VoiceSendPhase.saving => 'Saving sent message...',
                    _ => 'Saving...',
                  }),
                ],
                if (_permissionDenied)
                  OutlinedButton.icon(
                    onPressed: openAppSettings,
                    icon: const Icon(Icons.settings),
                    label: const Text('Microphone settings'),
                  ),
                if (_unsavedRecording != null) ...[
                  FilledButton.icon(
                    onPressed: _busy ? null : _retrySave,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Retry saving'),
                  ),
                  TextButton.icon(
                    onPressed: _busy ? null : _discard,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Discard recording'),
                  ),
                ],
                if (controller?.loadFailed ?? false)
                  TextButton.icon(
                    onPressed: _busy ? null : _discard,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Discard unreadable draft'),
                  ),
                const SizedBox(height: 24),
                if (_recording)
                  FilledButton.icon(
                    onPressed: _busy ? null : _stopRecording,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop recording'),
                  )
                else if (draft == null &&
                    _unsavedRecording == null &&
                    controller != null &&
                    !controller.loadFailed)
                  FilledButton.icon(
                    onPressed: _busy ? null : _startRecording,
                    icon: const Icon(Icons.mic),
                    label: const Text('Record'),
                  ),
                if (draft != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        tooltip: _playing
                            ? 'Pause preview'
                            : 'Preview recording',
                        onPressed: _busy ? null : _preview,
                        icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
                      ),
                      IconButton(
                        tooltip: 'Discard and re-record',
                        onPressed: _busy ? null : _discard,
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _busy ? null : _send,
                    icon: const Icon(Icons.send),
                    label: Text(
                      draft.published
                          ? 'Finish saving'
                          : controller!.error != null
                          ? 'Retry send'
                          : 'Send',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Draft saved on this device',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
