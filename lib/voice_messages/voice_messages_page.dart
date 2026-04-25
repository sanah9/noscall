import 'package:flutter/material.dart';
import 'package:noscall/contacts/user_avatar.dart';
import 'package:noscall/core/account/account.dart';
import 'package:noscall/core/account/model/userDB_isar.dart';
import 'package:noscall/core/call/contacts/contacts.dart';
import 'package:noscall/core/call/messages/messages.dart';
import 'package:noscall/core/call/messages/model/messageDB_isar.dart';
import 'package:noscall/core/call/messages/unread_message_manager.dart';
import 'package:noscall/core/navigation/app_navigator_scope.dart';
import 'package:noscall/voice_messages/widgets/voice_waveform_bar.dart';
import 'package:noscall/utils/snackbar_helper.dart';

class VoiceMessagesPage extends StatefulWidget {
  const VoiceMessagesPage({super.key});

  @override
  State<VoiceMessagesPage> createState() => _VoiceMessagesPageState();
}

class _VoiceMessagesPageState extends State<VoiceMessagesPage> {
  List<MessageDBISAR> _messages = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  Map<String, int> _replyCounts = {};
  Map<String, MessageDBISAR> _replyTargets = {};
  static const int _pageSize = 50;
  final ScrollController _scrollController = ScrollController();

  void _onNewMessage(MessageDBISAR message) {
    if (message.type != MessageDBISAR.messageTypeToString(MessageType.voice)) {
      return;
    }
    if (!mounted) return;
    if (_messages.any((m) => m.messageId == message.messageId)) return;
    final isIncoming = message.receiver == Account.sharedInstance.currentPubkey;
    setState(() {
      _messages.insert(0, message.withGrowableLevels());
    });
    _loadThreadMeta();
    if (isIncoming) {
      VoiceUnreadManager.instance.addUnread(message.messageId);
    }
    if (mounted && isIncoming) {
      AppSnackBar.info(context, 'New voice message');
    }
  }

  Future<void> _loadMessages() async {
    setState(() => _loading = true);
    try {
      final result = await Messages.loadMessagesFromDB(
        messageTypes: const [MessageType.voice],
        limit: _pageSize,
      );
      if (!mounted) return;
      final list = (result['messages'] as List<MessageDBISAR>?) ?? [];
      final lastTime = list.isEmpty
          ? 0
          : list.map((m) => m.createTime).reduce((a, b) => a < b ? a : b);
      if (!mounted) return;
      setState(() {
        _messages = list;
        _hasMore = list.length >= _pageSize;
      });
      _oldestCreateTime = lastTime;
      await _loadThreadMeta();
    } catch (e, st) {
      if (mounted) {
        setState(() => _messages = []);
        AppSnackBar.error(context, 'Load failed: $e');
      }
      debugPrint('Voice messages load error: $e\n$st');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int _oldestCreateTime = 0;

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _messages.isEmpty) return;
    setState(() => _loadingMore = true);
    try {
      final result = await Messages.loadMessagesFromDB(
        messageTypes: const [MessageType.voice],
        until: _oldestCreateTime,
        limit: _pageSize,
      );
      if (!mounted) return;
      final list = (result['messages'] as List<MessageDBISAR>?) ?? [];
      if (list.isEmpty) {
        setState(() => _hasMore = false);
        return;
      }
      final newOldest =
          list.map((m) => m.createTime).reduce((a, b) => a < b ? a : b);
      if (!mounted) return;
      setState(() {
        _messages.addAll(list);
        _hasMore = list.length >= _pageSize;
      });
      _oldestCreateTime = newOldest;
      await _loadThreadMeta();
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _onMessagesDeleted(List<MessageDBISAR> deleted) {
    final ids = deleted.map((m) => m.messageId).toSet();
    if (!mounted) return;
    setState(() {
      _messages.removeWhere((m) => ids.contains(m.messageId));
    });
    _loadThreadMeta();
  }

  Future<void> _loadThreadMeta() async {
    final parentIds = _messages.map((m) => m.messageId).toList();
    final counts = await Messages.countRepliesForParentIds(parentIds);
    final replyIds = _messages
        .map((m) => m.replyId)
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    Map<String, MessageDBISAR> targets = {};
    if (replyIds.isNotEmpty) {
      final targetMessages =
          await Messages.sharedInstance.loadMessageDBFromDBWithMsgIds(replyIds);
      targets = {for (final m in targetMessages) m.messageId: m};
    }
    if (!mounted) return;
    setState(() {
      _replyCounts = counts;
      _replyTargets = targets;
    });
  }

  @override
  void initState() {
    super.initState();
    // Ensure unread voice IDs are loaded for current account.
    VoiceUnreadManager.instance.init();
    _loadMessages();
    Contacts.sharedInstance.privateChatMessageCallBack = _onNewMessage;
    Messages.sharedInstance.deleteCallBack = _onMessagesDeleted;
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_hasMore || _loadingMore || _messages.length < _pageSize) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) _loadMore();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    if (Contacts.sharedInstance.privateChatMessageCallBack == _onNewMessage) {
      Contacts.sharedInstance.privateChatMessageCallBack = null;
    }
    if (Messages.sharedInstance.deleteCallBack == _onMessagesDeleted) {
      Messages.sharedInstance.deleteCallBack = null;
    }
    super.dispose();
  }

  Future<void> _onTapSendVoice() async {
    final selected =
        await AppNavigatorScope.requireOf(context).pushContactSelect(context);
    if (selected == null || selected.isEmpty || !mounted) return;
    final receiverPubkey = selected.first;
    AppNavigatorScope.requireOf(context).pushSendVoiceMessage(
      context,
      receiverPubkey,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final surface = colorScheme.surface;
    final onSurface = colorScheme.onSurface;
    final onSurfaceVariant = colorScheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Messages'),
        centerTitle: true,
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.mic_none),
            onPressed: _onTapSendVoice,
            tooltip: 'Send voice message',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.mic_none,
                          size: 64,
                          color: onSurfaceVariant.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text(
                        'No voice messages yet',
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(color: onSurfaceVariant),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the mic above to send one',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadMessages,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount:
                        _messages.length + (_hasMore && _loadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= _messages.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                              child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2))),
                        );
                      }
                      final msg = _messages[index];
                      return _VoiceMessageListItem(
                        message: msg,
                        replyCount: _replyCounts[msg.messageId] ?? 0,
                        replyTarget: msg.replyId.isEmpty
                            ? null
                            : _replyTargets[msg.replyId],
                        onTap: () async {
                          final myPubkey = Account.sharedInstance.currentPubkey;
                          final isIncoming = msg.receiver == myPubkey;
                          if (isIncoming && !msg.read) {
                            await Messages.markVoiceMessageRead(msg.messageId);
                            if (!mounted) return;
                            setState(() {
                              _messages[index] = msg.copyWith(read: true);
                            });
                            await VoiceUnreadManager.instance
                                .removeUnread(msg.messageId);
                          }
                          if (!context.mounted) return;
                          AppNavigatorScope.requireOf(context)
                              .pushVoiceMessageDetail(context, msg);
                        },
                      );
                    },
                  ),
                ),
    );
  }
}

class _VoiceMessageListItem extends StatelessWidget {
  final MessageDBISAR message;
  final int replyCount;
  final MessageDBISAR? replyTarget;
  final VoidCallback onTap;

  const _VoiceMessageListItem({
    required this.message,
    required this.replyCount,
    this.replyTarget,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final myPubkey = Account.sharedInstance.currentPubkey;
    final otherPubkey =
        message.sender == myPubkey ? message.receiver : message.sender;
    final userNotifier = Account.sharedInstance.getUserNotifier(otherPubkey);

    return ValueListenableBuilder<UserDBISAR>(
      valueListenable: userNotifier,
      builder: (context, user, _) =>
          _buildContent(context, theme, colorScheme, user),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    UserDBISAR user,
  ) {
    final myPubkey = Account.sharedInstance.currentPubkey;
    final isIncoming = message.receiver == myPubkey;
    final isUnread =
        isIncoming && VoiceUnreadManager.instance.isUnread(message.messageId);
    final voicePayload =
        MessageDBISAR.parseVoiceContent(message.decryptContent) ??
            MessageDBISAR.parseVoiceContent(message.content);
    final durationSec =
        (voicePayload?['durationSeconds'] as num?)?.toInt() ?? 0;
    final peaks = ((voicePayload?['waveformPeaks'] as List?) ?? const [])
        .map((e) => (e as num?)?.toInt() ?? 0)
        .where((v) => v > 0)
        .toList();
    final durationStr =
        '${durationSec ~/ 60}:${(durationSec % 60).toString().padLeft(2, '0')}';

    final date = DateTime.fromMillisecondsSinceEpoch(message.createTime * 1000);
    final timeStr = _formatMessageTime(date);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              UserAvatar(user: user, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight:
                            isUnread ? FontWeight.w700 : FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.mic,
                          size: 14,
                          color: isUnread
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          durationStr,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isUnread
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeStr,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isUnread
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                    if (peaks.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      VoiceWaveformBar(
                        peaks: peaks,
                        progress: 0,
                        height: 14,
                        maxBars: 20,
                      ),
                    ],
                    if (message.replyId.isNotEmpty || replyCount > 0) ...[
                      const SizedBox(height: 8),
                      _buildThreadMeta(theme, colorScheme),
                    ],
                  ],
                ),
              ),
              if (isUnread)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: colorScheme.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.chevron_right,
                        color: colorScheme.onSurfaceVariant),
                  ],
                )
              else
                Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThreadMeta(ThemeData theme, ColorScheme colorScheme) {
    final textStyle = theme.textTheme.bodySmall
        ?.copyWith(color: colorScheme.onSurfaceVariant);
    final targetPreview = replyTarget == null
        ? 'Reply target unavailable'
        : MessageDBISAR.getContent(
            MessageDBISAR.stringtoMessageType(replyTarget!.type),
            replyTarget!.decryptContent,
            null,
          );
    if (message.replyId.isNotEmpty && replyCount > 0) {
      return Text(
        'Replying to: $targetPreview · $replyCount repl${replyCount == 1 ? 'y' : 'ies'}',
        style: textStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    if (message.replyId.isNotEmpty) {
      return Text(
        'Replying to: $targetPreview',
        style: textStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    return Text(
      '$replyCount repl${replyCount == 1 ? 'y' : 'ies'}',
      style: textStyle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  static String _formatMessageTime(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    if (date.year == now.year) {
      return '${date.month}/${date.day}';
    }
    return '${date.year}/${date.month}/${date.day}';
  }
}
