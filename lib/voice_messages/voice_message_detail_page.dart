import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:noscall/core/account/account.dart';
import 'package:noscall/core/call/messages/messages.dart';
import 'package:noscall/core/call/messages/model/messageDB_isar.dart';
import 'package:noscall/contacts/user_avatar.dart';

class VoiceMessageDetailPage extends StatefulWidget {
  final String messageId;

  const VoiceMessageDetailPage({
    super.key,
    required this.messageId,
  });

  @override
  State<VoiceMessageDetailPage> createState() => _VoiceMessageDetailPageState();
}

class _VoiceMessageDetailPageState extends State<VoiceMessageDetailPage> {
  MessageDBISAR? _message;
  bool _loading = true;
  bool _playbackError = false;
  final AudioPlayer _player = AudioPlayer();

  Future<void> _loadMessage() async {
    final msg = await Messages.sharedInstance.loadMessageDBFromDB(widget.messageId);
    if (!mounted) return;
    setState(() {
      _message = msg?.withGrowableLevels();
      _loading = false;
    });
    if (_message != null) {
      final payload = MessageDBISAR.parseVoiceContent(_message!.decryptContent) ??
          MessageDBISAR.parseVoiceContent(_message!.content);
      final url = payload?['url'] as String?;
      if (url != null && url.isNotEmpty) {
        try {
          await _player.setUrl(url);
          if (mounted) setState(() => _playbackError = false);
        } catch (_) {
          if (mounted) setState(() => _playbackError = true);
        }
      }
    }
  }

  Future<void> _retryLoadAudio() async {
    setState(() => _playbackError = false);
    await _loadMessage();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _onDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete voice message?'),
        content: const Text(
          'This will only remove it from this device. It cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await Messages.deleteMessagesFromDB(messageIds: [widget.messageId], notify: true);
    if (!mounted) return;
    context.pop();
  }

  Future<void> _togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _loadMessage();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_message == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: Text('Message not found')),
      );
    }

    final msg = _message!;
    final myPubkey = Account.sharedInstance.currentPubkey;
    final otherPubkey = msg.sender == myPubkey ? msg.receiver : msg.sender;
    final user = Account.sharedInstance.getUserNotifier(otherPubkey).value;
    final voicePayload = MessageDBISAR.parseVoiceContent(msg.decryptContent) ?? MessageDBISAR.parseVoiceContent(msg.content);
    final durationSec = (voicePayload?['durationSeconds'] as num?)?.toInt() ?? 0;
    final durationStr = '${durationSec ~/ 60}:${(durationSec % 60).toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(user.displayName(), style: TextStyle(color: colorScheme.onSurface, fontSize: 18)),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline, color: colorScheme.onSurface),
            onPressed: _onDelete,
            tooltip: 'Delete',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              UserAvatar(user: user, size: 80),
              const SizedBox(height: 24),
              Text(
                'Voice message · $durationStr',
                style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 32),
              if (_playbackError) ...[
                Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  'Playback failed',
                  style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _retryLoadAudio,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ] else
                StreamBuilder<Duration>(
                  stream: _player.positionStream,
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    final duration = _player.duration ?? Duration(seconds: durationSec);
                    final positionSec = position.inSeconds.clamp(0, duration.inSeconds);
                    final positionStr = '${positionSec ~/ 60}:${(positionSec % 60).toString().padLeft(2, '0')}';
                    final totalStr = '${duration.inSeconds ~/ 60}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
                    final positionValue = duration.inSeconds > 0
                        ? position.inSeconds.toDouble().clamp(0.0, duration.inSeconds.toDouble())
                        : 0.0;
                    final durationValue = duration.inSeconds.toDouble().clamp(1.0, double.infinity);

                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton.filled(
                              icon: Icon(_player.playing ? Icons.pause : Icons.play_arrow),
                              onPressed: _togglePlayPause,
                              iconSize: 40,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          '$positionStr / $totalStr',
                          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 8),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                          ),
                          child: Slider(
                            value: positionValue,
                            max: durationValue,
                            onChanged: (v) => _player.seek(Duration(seconds: v.round())),
                          ),
                        ),
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
