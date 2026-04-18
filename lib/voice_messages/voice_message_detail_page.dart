import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:noscall/call/constant/call_type.dart';
import 'package:noscall/call/start_call_helper.dart';
import 'package:noscall/core/account/account.dart';
import 'package:noscall/core/account/model/userDB_isar.dart';
import 'package:noscall/core/call/messages/messages.dart';
import 'package:noscall/core/call/messages/model/messageDB_isar.dart';
import 'package:noscall/core/call/messages/unread_message_manager.dart';
import 'package:noscall/core/call/messages/voice_cache_manager.dart';
import 'package:noscall/core/navigation/app_navigator_scope.dart';
import 'package:noscall/voice_messages/widgets/voice_waveform_bar.dart';

class VoiceMessageDetailPage extends StatefulWidget {
  final MessageDBISAR message;

  const VoiceMessageDetailPage({
    super.key,
    required this.message,
  });

  @override
  State<VoiceMessageDetailPage> createState() => _VoiceMessageDetailPageState();
}

class _VoiceMessageDetailPageState extends State<VoiceMessageDetailPage> {
  late Future<File> _fileFuture;
  late Future<_VoiceThreadPreview> _threadPreviewFuture;
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<ProcessingState>? _processingStateSubscription;

  Future<void> _markAsReadIfIncoming() async {
    final msg = widget.message;
    final isIncoming = msg.receiver == Account.sharedInstance.currentPubkey;
    if (isIncoming && !msg.read) {
      await Messages.onVoiceMessageOpened(msg.messageId);
      await VoiceUnreadManager.instance.removeUnread(msg.messageId);
    }
  }

  void _retryLoadAudio() {
    setState(() {
      _fileFuture = VoiceCacheManager.instance.getOrDownload(widget.message);
    });
  }

  @override
  void initState() {
    super.initState();
    _markAsReadIfIncoming();
    _fileFuture = VoiceCacheManager.instance.getOrDownload(widget.message);
    _threadPreviewFuture = _loadThreadPreview();
  }

  @override
  void dispose() {
    _processingStateSubscription?.cancel();
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
            child: Text('Delete',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await VoiceCacheManager.instance
        .deleteCacheForMessage(widget.message.messageId);
    await Messages.deleteMessagesFromDB(
        messageIds: [widget.message.messageId], notify: true);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final msg = widget.message;
    final otherPubkey = _otherPubkey(msg);
    final durationSec = _durationSeconds(msg);
    final timeStr = _formatMessageTime(msg.createTime);

    return Scaffold(
      appBar: _buildAppBar(context, colorScheme, otherPubkey),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              _buildMessageTimeSection(context, timeStr),
              const SizedBox(height: 32),
              FutureBuilder<_VoiceThreadPreview>(
                future: _threadPreviewFuture,
                builder: (context, snapshot) {
                  final preview = snapshot.data;
                  if (preview == null ||
                      (preview.parent == null &&
                          preview.replyCount == 0 &&
                          preview.recentReplies.isEmpty)) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: _buildThreadPreviewSection(context, preview),
                  );
                },
              ),
              FutureBuilder<File>(
                future: _fileFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingSection(context, durationSec);
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return _buildPlaybackErrorSection(context);
                  }
                  return _VoicePlayerSection(
                    file: snapshot.data!,
                    player: _player,
                    durationSec: durationSec,
                    waveformPeaks: _waveformPeaks(msg),
                    onReady: () => setState(() {}),
                    onDelete: _onDelete,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _otherPubkey(MessageDBISAR msg) {
    final myPubkey = Account.sharedInstance.currentPubkey;
    return msg.sender == myPubkey ? msg.receiver : msg.sender;
  }

  int _durationSeconds(MessageDBISAR msg) {
    final payload = MessageDBISAR.parseVoiceContent(msg.decryptContent) ??
        MessageDBISAR.parseVoiceContent(msg.content);
    return (payload?['durationSeconds'] as num?)?.toInt() ?? 0;
  }

  List<int> _waveformPeaks(MessageDBISAR msg) {
    final payload = MessageDBISAR.parseVoiceContent(msg.decryptContent) ??
        MessageDBISAR.parseVoiceContent(msg.content);
    final raw = payload?['waveformPeaks'] as List?;
    final peaks = (raw ?? const [])
        .map((e) => (e as num?)?.toInt() ?? 0)
        .where((v) => v > 0)
        .toList();
    if (peaks.isNotEmpty) return peaks;
    return List<int>.filled(24, 24);
  }

  static String _formatMessageTime(int createTimeSeconds) {
    final t = DateTime.fromMillisecondsSinceEpoch(createTimeSeconds * 1000);
    return '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')} '
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ColorScheme colorScheme,
    String otherPubkey,
  ) {
    final theme = Theme.of(context);
    final userNotifier = Account.sharedInstance.getUserNotifier(otherPubkey);
    return AppBar(
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: ValueListenableBuilder<UserDBISAR>(
        valueListenable: userNotifier,
        builder: (context, user, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final maxW = constraints.maxWidth.isFinite
                  ? constraints.maxWidth
                  : MediaQuery.sizeOf(context).width * 0.5;
              const arrowGap = 4.0;
              const arrowW = 22.0;
              final textMaxW =
                  (maxW - arrowGap - arrowW).clamp(0.0, double.infinity);
              return InkWell(
                onTap: () => AppNavigatorScope.requireOf(context)
                    .pushUserDetail(context, otherPubkey),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: textMaxW),
                        child: Text(
                          user.displayName(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.start,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right,
                        size: arrowW,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      centerTitle: true,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      actions: [
        IconButton(
          icon: const Icon(Icons.videocam_outlined),
          onPressed: () => StartCallHelper.startCall(context,
              peerId: otherPubkey, callType: CallType.video),
          tooltip: 'Video',
        ),
        IconButton(
          icon: const Icon(Icons.call_outlined),
          onPressed: () => StartCallHelper.startCall(context,
              peerId: otherPubkey, callType: CallType.audio),
          tooltip: 'Voice',
        ),
      ],
    );
  }

  Widget _buildMessageTimeSection(BuildContext context, String timeStr) {
    final theme = Theme.of(context);
    return Text(
      timeStr,
      style: theme.textTheme.titleMedium
          ?.copyWith(color: theme.colorScheme.onSurface),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildLoadingSection(BuildContext context, int durationSec) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final placeholderDuration = Duration(seconds: durationSec);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildProgressTimeRow(
            theme, colorScheme, Duration.zero, placeholderDuration),
        const SizedBox(height: 4),
        _buildProgressSliderPlaceholder(context),
        const SizedBox(height: 24),
        _buildPlaybackActionsPlaceholder(context, colorScheme),
      ],
    );
  }

  Widget _buildProgressSliderPlaceholder(BuildContext context) {
    return Container(
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildPlaybackActionsPlaceholder(
      BuildContext context, ColorScheme colorScheme) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
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
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            icon: Icon(CupertinoIcons.delete, color: colorScheme.primary),
            onPressed: _onDelete,
            iconSize: 28,
            tooltip: 'Delete',
          ),
        ),
      ],
    );
  }

  Widget _buildPlaybackErrorSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline, size: 48, color: colorScheme.error),
        const SizedBox(height: 16),
        Text(
          'Playback failed',
          style: theme.textTheme.bodyLarge
              ?.copyWith(color: colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _retryLoadAudio,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ],
    );
  }

  Widget _buildProgressTimeRow(
    ThemeData theme,
    ColorScheme colorScheme,
    Duration position,
    Duration duration,
  ) {
    final posSec = position.inSeconds.clamp(0, duration.inSeconds);
    final positionStr =
        '${posSec ~/ 60}:${(posSec % 60).toString().padLeft(2, '0')}';
    final totalStr =
        '${duration.inSeconds ~/ 60}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
    final style = theme.textTheme.bodySmall
        ?.copyWith(color: colorScheme.onSurfaceVariant);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(positionStr, style: style),
        Text(totalStr, style: style),
      ],
    );
  }

  Future<_VoiceThreadPreview> _loadThreadPreview() async {
    final msg = widget.message;
    MessageDBISAR? parent;
    if (msg.replyId.isNotEmpty) {
      parent = await Messages.sharedInstance.loadMessageDBFromDB(msg.replyId);
    }
    final replyCount = await Messages.countReplies(msg.messageId);
    final recentReplies = await Messages.loadReplies(msg.messageId, limit: 2);
    return _VoiceThreadPreview(
      parent: parent,
      replyCount: replyCount,
      recentReplies: recentReplies,
    );
  }

  Widget _buildThreadPreviewSection(
      BuildContext context, _VoiceThreadPreview preview) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textStyle = theme.textTheme.bodySmall
        ?.copyWith(color: colorScheme.onSurfaceVariant);
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

/// Loads [file] into [player], then builds the progress/play UI when ready.
class _VoicePlayerSection extends StatefulWidget {
  final File file;
  final AudioPlayer player;
  final int durationSec;
  final List<int> waveformPeaks;
  final VoidCallback onReady;
  final Future<void> Function() onDelete;

  const _VoicePlayerSection({
    required this.file,
    required this.player,
    required this.durationSec,
    required this.waveformPeaks,
    required this.onReady,
    required this.onDelete,
  });

  @override
  State<_VoicePlayerSection> createState() => _VoicePlayerSectionState();
}

class _VoicePlayerSectionState extends State<_VoicePlayerSection> {
  bool _ready = false;
  StreamSubscription<ProcessingState>? _sub;

  @override
  void initState() {
    super.initState();
    _loadFile();
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

  AudioPlayer get _player => widget.player;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _onProcessingState(ProcessingState state) {
    if (state != ProcessingState.completed) return;
    _player.seek(Duration.zero);
    _player.pause();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;
      final placeholderDuration = Duration(seconds: widget.durationSec);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildProgressTimeRow(
              theme, colorScheme, Duration.zero, placeholderDuration),
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
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
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
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: Icon(CupertinoIcons.delete, color: colorScheme.primary),
                  onPressed: widget.onDelete,
                  iconSize: 28,
                  tooltip: 'Delete',
                ),
              ),
            ],
          ),
        ],
      );
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final duration = _player.duration ?? Duration(seconds: widget.durationSec);

    return StreamBuilder<Duration>(
      stream: _player.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProgressTimeRow(theme, colorScheme, position, duration),
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
            _buildSlider(context, position, duration),
            const SizedBox(height: 24),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
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
                      if (mounted) setState(() {});
                    },
                    iconSize: 44,
                    padding: EdgeInsets.zero,
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon:
                        Icon(CupertinoIcons.delete, color: colorScheme.primary),
                    onPressed: widget.onDelete,
                    iconSize: 28,
                    tooltip: 'Delete',
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildProgressTimeRow(
    ThemeData theme,
    ColorScheme colorScheme,
    Duration position,
    Duration duration,
  ) {
    final posSec = position.inSeconds.clamp(0, duration.inSeconds);
    final positionStr =
        '${posSec ~/ 60}:${(posSec % 60).toString().padLeft(2, '0')}';
    final totalStr =
        '${duration.inSeconds ~/ 60}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
    final style = theme.textTheme.bodySmall
        ?.copyWith(color: colorScheme.onSurfaceVariant);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(positionStr, style: style),
        Text(totalStr, style: style),
      ],
    );
  }

  Widget _buildSlider(
    BuildContext context,
    Duration position,
    Duration duration,
  ) {
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
        onChanged: (v) => _player.seek(Duration(milliseconds: v.round())),
      ),
    );
  }
}

class _VoiceThreadPreview {
  final MessageDBISAR? parent;
  final int replyCount;
  final List<MessageDBISAR> recentReplies;

  const _VoiceThreadPreview({
    required this.parent,
    required this.replyCount,
    required this.recentReplies,
  });
}
