import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:noscall/core/call/messages/model/message_db_isar.dart';
import 'package:noscall/voice_messages/widgets/voice_waveform_bar.dart';

class VoiceMessageTimestampSection extends StatelessWidget {
  const VoiceMessageTimestampSection({
    super.key,
    required this.timeText,
  });

  final String timeText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      timeText,
      style: theme.textTheme.titleMedium?.copyWith(
        color: theme.colorScheme.onSurface,
      ),
      textAlign: TextAlign.center,
    );
  }
}

class VoiceMessageLoadingSection extends StatelessWidget {
  const VoiceMessageLoadingSection({
    super.key,
    required this.durationSec,
    required this.onDelete,
  });

  final int durationSec;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final placeholderDuration = Duration(seconds: durationSec);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _VoiceProgressTimeRow(
          position: Duration.zero,
          duration: placeholderDuration,
        ),
        const SizedBox(height: 4),
        Container(
          height: 4,
          margin: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 24),
        _VoicePlaybackActionBar(
          primaryAction: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),
          onDelete: onDelete,
          deleteColor: colorScheme.primary,
        ),
      ],
    );
  }
}

class VoiceMessagePlaybackErrorSection extends StatelessWidget {
  const VoiceMessagePlaybackErrorSection({
    super.key,
    required this.onRetry,
  });

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline, size: 48, color: colorScheme.error),
        const SizedBox(height: 16),
        Text(
          'Playback failed',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ],
    );
  }
}

class VoiceMessageThreadPreviewSection extends StatelessWidget {
  const VoiceMessageThreadPreviewSection({
    super.key,
    required this.preview,
  });

  final VoiceThreadPreview preview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textStyle = theme.textTheme.bodySmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (preview.parent != null)
            Text(
              'Replying to: ${MessageDBISAR.getContent(MessageDBISAR.stringtoMessageType(preview.parent!.type), preview.parent!.decryptContent, null)}',
              style: textStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (preview.replyCount > 0)
            Padding(
              padding: EdgeInsets.only(top: preview.parent == null ? 0 : 6),
              child: Text(
                '${preview.replyCount} repl${preview.replyCount == 1 ? 'y' : 'ies'} in this thread',
                style: textStyle,
              ),
            ),
          if (preview.recentReplies.isNotEmpty) ...[
            const SizedBox(height: 6),
            for (final reply in preview.recentReplies)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  MessageDBISAR.getContent(
                    MessageDBISAR.stringtoMessageType(reply.type),
                    reply.decryptContent,
                    null,
                  ),
                  style: textStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class VoicePlayerSection extends StatefulWidget {
  const VoicePlayerSection({
    super.key,
    required this.file,
    required this.player,
    required this.durationSec,
    required this.waveformPeaks,
    required this.onReady,
    required this.onDelete,
  });

  final File file;
  final AudioPlayer player;
  final int durationSec;
  final List<int> waveformPeaks;
  final VoidCallback onReady;
  final Future<void> Function() onDelete;

  @override
  State<VoicePlayerSection> createState() => _VoicePlayerSectionState();
}

class _VoicePlayerSectionState extends State<VoicePlayerSection> {
  bool _ready = false;
  StreamSubscription<ProcessingState>? _sub;

  AudioPlayer get _player => widget.player;

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _loadFile() async {
    try {
      await widget.player.setFilePath(widget.file.path);
      if (_player.processingState == ProcessingState.ready ||
          _player.processingState == ProcessingState.completed) {
        if (mounted) {
          setState(() => _ready = true);
          widget.onReady();
          _sub = widget.player.processingStateStream.listen(_onProcessingState);
        }
        return;
      }
      _sub = widget.player.processingStateStream.listen((state) {
        if (state == ProcessingState.ready ||
            state == ProcessingState.completed) {
          _sub?.cancel();
          if (mounted) {
            setState(() => _ready = true);
            widget.onReady();
            _sub =
                widget.player.processingStateStream.listen(_onProcessingState);
          }
        }
      });
      await widget.player.processingStateStream
          .where((s) =>
              s == ProcessingState.ready || s == ProcessingState.completed)
          .first
          .timeout(const Duration(seconds: 30));
    } catch (_) {
      if (mounted) {
        setState(() => _ready = false);
        widget.onReady();
      }
    }
  }

  void _onProcessingState(ProcessingState state) {
    if (state != ProcessingState.completed) {
      return;
    }
    _player.seek(Duration.zero);
    _player.pause();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return VoiceMessageLoadingSection(
        durationSec: widget.durationSec,
        onDelete: widget.onDelete,
      );
    }

    final duration = _player.duration ?? Duration(seconds: widget.durationSec);

    return StreamBuilder<Duration>(
      stream: _player.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _VoiceProgressTimeRow(
              position: position,
              duration: duration,
            ),
            const SizedBox(height: 4),
            VoiceWaveformBar(
              peaks: widget.waveformPeaks,
              progress: duration.inMilliseconds <= 0
                  ? 0
                  : (position.inMilliseconds / duration.inMilliseconds)
                      .clamp(0.0, 1.0),
              height: 28,
              maxBars: 40,
            ),
            const SizedBox(height: 8),
            _VoiceProgressSlider(
              player: _player,
              position: position,
              duration: duration,
            ),
            const SizedBox(height: 24),
            _VoicePlaybackActionBar(
              primaryAction: SizedBox(
                width: 44,
                height: 44,
                child: IconButton(
                  icon: Icon(
                    _player.playing
                        ? CupertinoIcons.pause_fill
                        : CupertinoIcons.play_fill,
                    color: colorScheme.primary,
                  ),
                  onPressed: () async {
                    if (_player.playing) {
                      await _player.pause();
                    } else {
                      await _player.play();
                    }
                    if (mounted) {
                      setState(() {});
                    }
                  },
                  iconSize: 44,
                  padding: EdgeInsets.zero,
                ),
              ),
              onDelete: widget.onDelete,
              deleteColor: colorScheme.primary,
            ),
          ],
        );
      },
    );
  }
}

class VoiceThreadPreview {
  const VoiceThreadPreview({
    required this.parent,
    required this.replyCount,
    required this.recentReplies,
  });

  final MessageDBISAR? parent;
  final int replyCount;
  final List<MessageDBISAR> recentReplies;
}

class _VoiceProgressTimeRow extends StatelessWidget {
  const _VoiceProgressTimeRow({
    required this.position,
    required this.duration,
  });

  final Duration position;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final posSec = position.inSeconds.clamp(0, duration.inSeconds);
    final positionStr =
        '${posSec ~/ 60}:${(posSec % 60).toString().padLeft(2, '0')}';
    final totalStr =
        '${duration.inSeconds ~/ 60}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
    final style = theme.textTheme.bodySmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(positionStr, style: style),
        Text(totalStr, style: style),
      ],
    );
  }
}

class _VoiceProgressSlider extends StatelessWidget {
  const _VoiceProgressSlider({
    required this.player,
    required this.position,
    required this.duration,
  });

  final AudioPlayer player;
  final Duration position;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final totalMs = duration.inMilliseconds;
    final positionValue = totalMs > 0
        ? position.inMilliseconds.toDouble().clamp(0.0, totalMs.toDouble())
        : 0.0;
    final durationValue = totalMs > 0 ? totalMs.toDouble() : 1.0;

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
      ),
      child: Slider(
        value: positionValue,
        max: durationValue,
        onChanged: (value) =>
            player.seek(Duration(milliseconds: value.round())),
      ),
    );
  }
}

class _VoicePlaybackActionBar extends StatelessWidget {
  const _VoicePlaybackActionBar({
    required this.primaryAction,
    required this.onDelete,
    required this.deleteColor,
  });

  final Widget primaryAction;
  final Future<void> Function() onDelete;
  final Color deleteColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        primaryAction,
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            icon: Icon(CupertinoIcons.delete, color: deleteColor),
            onPressed: onDelete,
            iconSize: 28,
            tooltip: 'Delete',
          ),
        ),
      ],
    );
  }
}
