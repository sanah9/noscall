import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:noscall/call/constant/call_type.dart';
import 'package:noscall/call/start_call_helper.dart';
import 'package:noscall/core/account/account.dart';
import 'package:noscall/core/call/messages/messages.dart';
import 'package:noscall/core/call/messages/model/messageDB_isar.dart';

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
  bool _playbackError = false;
  bool _isPreloading = true;
  Duration? _cachedDuration;
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<ProcessingState>? _processingStateSubscription;

  Future<void> _markAsReadIfIncoming() async {
    final msg = widget.message;
    final isIncoming = msg.receiver == Account.sharedInstance.currentPubkey;
    if (isIncoming && !msg.read) {
      await Messages.onVoiceMessageOpened(msg.messageId);
    }
  }

  static String? _getVoiceUrl(MessageDBISAR message) {
    final payload = MessageDBISAR.parseVoiceContent(message.decryptContent) ??
        MessageDBISAR.parseVoiceContent(message.content);
    return payload?['url'] as String?;
  }

  /// Loads audio from [url] and prepares for playback (buffer until ready).
  Future<void> _prepareAudio(String url) async {
    if (url.isEmpty) return;
    try {
      await _player.setUrl(url);
      await _waitUntilReadyToPlay();
      if (!mounted) return;
      setState(() {
        _cachedDuration = _player.duration;
        _isPreloading = false;
        _playbackError = false;
      });
      _processingStateSubscription?.cancel();
      _processingStateSubscription = _player.processingStateStream.listen(_onProcessingState);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isPreloading = false;
        _playbackError = true;
      });
    }
  }

  /// Waits for the player to be ready to play (buffered) without starting playback.
  Future<void> _waitUntilReadyToPlay() async {
    if (_player.processingState == ProcessingState.ready ||
        _player.processingState == ProcessingState.completed) {
      return;
    }
    await _player.processingStateStream
        .where((s) => s == ProcessingState.ready || s == ProcessingState.completed)
        .first
        .timeout(const Duration(seconds: 30));
  }

  void _onProcessingState(ProcessingState state) {
    if (state != ProcessingState.completed) return;
    _player.seek(Duration.zero);
    _player.pause();
    if (mounted) setState(() {});
  }

  Future<void> _retryLoadAudio() async {
    setState(() => _playbackError = false);
    final url = _getVoiceUrl(widget.message) ?? '';
    await _prepareAudio(url);
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
            child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await Messages.deleteMessagesFromDB(messageIds: [widget.message.messageId], notify: true);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _togglePlayPause() async {
    if (_isPreloading) return;
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
    _markAsReadIfIncoming();
    final url = _getVoiceUrl(widget.message);
    if (url != null && url.isNotEmpty) {
      _prepareAudio(url);
    }
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
              _playbackError
                  ? _buildPlaybackErrorSection(context)
                  : _buildPlayerSection(context, durationSec, _isPreloading),
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
    return AppBar(
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text('Voice message', style: TextStyle(fontSize: 18)),
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      actions: [
        IconButton(
          icon: const Icon(Icons.videocam_outlined),
          onPressed: () =>
              StartCallHelper.startCall(context, peerId: otherPubkey, callType: CallType.video),
          tooltip: 'Video',
        ),
        IconButton(
          icon: const Icon(Icons.call_outlined),
          onPressed: () =>
              StartCallHelper.startCall(context, peerId: otherPubkey, callType: CallType.audio),
          tooltip: 'Voice',
        ),
      ],
    );
  }

  Widget _buildMessageTimeSection(BuildContext context, String timeStr) {
    final theme = Theme.of(context);
    return Text(
      timeStr,
      style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface),
      textAlign: TextAlign.center,
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
          style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
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

  Widget _buildPlayerSection(
    BuildContext context,
    int durationSec,
    bool isPreloading,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    if (isPreloading) {
      final placeholderDuration = Duration(seconds: durationSec);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildProgressTimeRow(theme, colorScheme, Duration.zero, placeholderDuration),
          const SizedBox(height: 4),
          _buildProgressSliderPlaceholder(context),
          const SizedBox(height: 24),
          _buildPlaybackActions(context, colorScheme, isPreloading),
        ],
      );
    }
    final duration = _cachedDuration ?? _player.duration ?? Duration(seconds: durationSec);
    return StreamBuilder<Duration>(
      stream: _player.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProgressTimeRow(theme, colorScheme, position, duration),
            const SizedBox(height: 4),
            _buildProgressSlider(context, position, duration, false),
            const SizedBox(height: 24),
            _buildPlaybackActions(context, colorScheme, false),
          ],
        );
      },
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

  Widget _buildProgressTimeRow(
    ThemeData theme,
    ColorScheme colorScheme,
    Duration position,
    Duration duration,
  ) {
    final posSec = position.inSeconds.clamp(0, duration.inSeconds);
    final positionStr = '${posSec ~/ 60}:${(posSec % 60).toString().padLeft(2, '0')}';
    final totalStr =
        '${duration.inSeconds ~/ 60}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
    final style = theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(positionStr, style: style),
        Text(totalStr, style: style),
      ],
    );
  }

  Widget _buildProgressSlider(
    BuildContext context,
    Duration position,
    Duration duration,
    bool isPreloading,
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
        onChanged: isPreloading ? null : (v) => _player.seek(Duration(milliseconds: v.round())),
      ),
    );
  }

  Widget _buildPlaybackActions(
    BuildContext context,
    ColorScheme colorScheme,
    bool isPreloading,
  ) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 44,
          height: 44,
          child: isPreloading
              ? Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.primary,
                    ),
                  ),
                )
              : IconButton(
                  icon: Icon(
                    _player.playing ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
                    color: colorScheme.primary,
                  ),
                  onPressed: _togglePlayPause,
                  iconSize: 44,
                  padding: EdgeInsets.zero,
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
}
