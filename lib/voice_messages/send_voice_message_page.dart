import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:noscall/core/account/account.dart';
import 'package:noscall/core/call/contacts/contacts.dart';
import 'package:noscall/core/call/contacts/contacts+calling.dart';
import 'package:noscall/core/call/messages/messages.dart';
import 'package:noscall/core/call/messages/model/messageDB_isar.dart';
import 'package:noscall/utils/file_upload_manager.dart';
import 'package:noscall/utils/microphone_permission_service.dart';
import 'package:noscall/utils/toast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';

const int _maxDurationSeconds = 120;
const int _maxFileSizeBytes = 5 * 1024 * 1024;

class SendVoiceMessagePage extends StatefulWidget {
  final String receiverPubkey;

  const SendVoiceMessagePage({
    super.key,
    required this.receiverPubkey,
  });

  @override
  State<SendVoiceMessagePage> createState() => _SendVoiceMessagePageState();
}

class _SendVoiceMessagePageState extends State<SendVoiceMessagePage> {
  final AudioRecorder _recorder = AudioRecorder();
  bool _hasPermission = false;
  bool _isRecording = false;
  bool _isSending = false;
  int _recordSeconds = 0;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  @override
  void dispose() {
    if (_isRecording) {
      _recorder.stop().ignore();
    }
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    final granted = await MicrophonePermissionService.instance.request();
    if (!mounted) return;
    setState(() => _hasPermission = granted);
  }

  void _showOpenSettingsDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Microphone access'),
        content: const Text(
          'Microphone permission is required to record voice messages. '
          'Please enable it in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Open settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleRecording() async {
    if (!_hasPermission) {
      _showOpenSettingsDialog();
      return;
    }
    if (_isSending) return;

    if (_isRecording) {
      await _stopAndSend();
      return;
    }

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
    setState(() {
      _isRecording = true;
      _recordSeconds = 0;
    });
    _startTimer();
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted || !_isRecording) return false;
      setState(() => _recordSeconds++);
      if (_recordSeconds >= _maxDurationSeconds) {
        final path = await _recorder.stop();
        setState(() => _isRecording = false);
        if (path != null && path.isNotEmpty && mounted) {
          await _uploadAndSend(path);
        }
        return false;
      }
      return true;
    });
  }

  Future<void> _stopAndSend() async {
    if (!_isRecording) return;
    final path = await _recorder.stop();
    setState(() => _isRecording = false);
    if (path == null || path.isEmpty || !mounted) return;
    await _uploadAndSend(path);
  }

  Future<void> _uploadAndSend(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      if (mounted) AppToast.showError(context, 'Recording file not found');
      return;
    }
    final size = await file.length();
    if (size > _maxFileSizeBytes) {
      if (mounted) AppToast.showError(context, 'Recording too large (max 5MB)');
      return;
    }
    if (!mounted) return;

    int durationSeconds = 0;
    try {
      final player = AudioPlayer();
      await player.setFilePath(path);
      final d = player.duration;
      await player.dispose();
      durationSeconds = d?.inSeconds ?? 0;
    } catch (_) {}
    if (durationSeconds <= 0) durationSeconds = 1;

    setState(() => _isSending = true);

    String? url;
    try {
      url = await FileUploadManager.uploadFile(file, onProgress: (_) {});
    } catch (e) {
      if (mounted) AppToast.showError(context, 'Upload failed');
      setState(() => _isSending = false);
      return;
    }
    if (url == null || url.isEmpty) {
      if (mounted) AppToast.showError(context, 'Upload failed');
      setState(() => _isSending = false);
      return;
    }

    final content = {
      'contentType': 'voice',
      'url': url,
      'durationSeconds': durationSeconds,
      'mimeType': 'audio/mp4',
    };
    final plainContent = jsonEncode(content);
    final eventId = await Contacts.sharedInstance.sendEncryptedDM(widget.receiverPubkey, plainContent);

    if (!mounted) return;
    setState(() => _isSending = false);

    if (eventId == null || eventId.isEmpty) {
      AppToast.showError(context, 'Send failed');
      return;
    }

    final myPubkey = Account.sharedInstance.currentPubkey;
    final message = MessageDBISAR(
      messageId: eventId,
      sender: myPubkey,
      receiver: widget.receiverPubkey,
      kind: 4,
      tags: '[]',
      content: plainContent,
      decryptContent: plainContent,
      type: 'voice',
      createTime: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      status: 1,
      plaintEvent: '',
    );
    await Messages.saveMessageToDB(message);
    Contacts.sharedInstance.privateChatMessageCallBack?.call(message);

    if (!mounted) return;
    AppToast.showSuccess(context, 'Voice message sent');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.close, color: colorScheme.onSurface),
          onPressed: _isSending ? null : () => Navigator.of(context).pop(),
        ),
        title: const Text('Send voice message'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
              if (!_hasPermission) ...[
                Icon(Icons.mic_off, size: 64, color: colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  'Microphone access is required',
                  style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.onSurface),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _showOpenSettingsDialog,
                  child: const Text('Open settings'),
                ),
              ] else if (_isSending)
                const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Sending...'),
                  ],
                )
              else ...[
                Icon(
                  _isRecording ? Icons.stop_circle : Icons.mic,
                  size: 80,
                  color: _isRecording ? colorScheme.error : colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  _isRecording
                      ? 'Tap to stop · ${_recordSeconds.clamp(0, _maxDurationSeconds)}s'
                      : 'Tap to start recording (max $_maxDurationSeconds s)',
                  style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: _toggleRecording,
                  icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                  label: Text(_isRecording ? 'Stop & send' : 'Start recording'),
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
