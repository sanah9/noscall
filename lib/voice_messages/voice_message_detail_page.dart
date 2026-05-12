import 'dart:async';
import 'dart:io';

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

import 'widgets/voice_message_detail_sections.dart';

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
  late Future<VoiceThreadPreview> _threadPreviewFuture;
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
              VoiceMessageTimestampSection(timeText: timeStr),
              const SizedBox(height: 32),
              FutureBuilder<VoiceThreadPreview>(
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
                    child: VoiceMessageThreadPreviewSection(preview: preview),
                  );
                },
              ),
              FutureBuilder<File>(
                future: _fileFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return VoiceMessageLoadingSection(
                      durationSec: durationSec,
                      onDelete: _onDelete,
                    );
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return VoiceMessagePlaybackErrorSection(
                      onRetry: _retryLoadAudio,
                    );
                  }
                  return VoicePlayerSection(
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

  Future<VoiceThreadPreview> _loadThreadPreview() async {
    final msg = widget.message;
    MessageDBISAR? parent;
    if (msg.replyId.isNotEmpty) {
      parent = await Messages.sharedInstance.loadMessageDBFromDB(msg.replyId);
    }
    final replyCount = await Messages.countReplies(msg.messageId);
    final recentReplies = await Messages.loadReplies(msg.messageId, limit: 2);
    return VoiceThreadPreview(
      parent: parent,
      replyCount: replyCount,
      recentReplies: recentReplies,
    );
  }
}
