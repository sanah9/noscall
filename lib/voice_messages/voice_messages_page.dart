import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:noscall/contacts/user_avatar.dart';
import 'package:noscall/core/account/account.dart';
import 'package:noscall/core/account/model/userDB_isar.dart';
import 'package:noscall/core/call/contacts/contacts.dart';
import 'package:noscall/core/call/messages/messages.dart';
import 'package:noscall/core/call/messages/model/messageDB_isar.dart';

class VoiceMessagesPage extends StatefulWidget {
  const VoiceMessagesPage({super.key});

  @override
  State<VoiceMessagesPage> createState() => _VoiceMessagesPageState();
}

class _VoiceMessagesPageState extends State<VoiceMessagesPage> {
  List<MessageDBISAR> _messages = [];
  bool _loading = true;
  static const int _pageSize = 100;

  void _onNewMessage(MessageDBISAR message) {
    if (message.type != MessageDBISAR.messageTypeToString(MessageType.voice)) return;
    if (!mounted) return;
    setState(() {
      _messages.insert(0, message.withGrowableLevels());
    });
  }

  Future<void> _loadMessages() async {
    setState(() => _loading = true);
    final result = await Messages.loadMessagesFromDB(
      messageTypes: const [MessageType.voice],
      limit: _pageSize,
    );
    if (!mounted) return;
    final list = (result['messages'] as List<MessageDBISAR>?) ?? [];
    setState(() {
      _messages = list;
      _loading = false;
    });
  }

  void _onMessagesDeleted(List<MessageDBISAR> deleted) {
    final ids = deleted.map((m) => m.messageId).toSet();
    if (!mounted) return;
    setState(() {
      _messages.removeWhere((m) => ids.contains(m.messageId));
    });
  }

  @override
  void initState() {
    super.initState();
    _loadMessages();
    Contacts.sharedInstance.privateChatMessageCallBack = _onNewMessage;
    Messages.sharedInstance.deleteCallBack = _onMessagesDeleted;
  }

  @override
  void dispose() {
    if (Contacts.sharedInstance.privateChatMessageCallBack == _onNewMessage) {
      Contacts.sharedInstance.privateChatMessageCallBack = null;
    }
    if (Messages.sharedInstance.deleteCallBack == _onMessagesDeleted) {
      Messages.sharedInstance.deleteCallBack = null;
    }
    super.dispose();
  }

  Future<void> _onTapSendVoice() async {
    final selected = await context.push<List<String>>(
      '/contact-select',
      extra: <String, dynamic>{},
    );
    if (selected == null || selected.isEmpty || !mounted) return;
    final receiverPubkey = selected.first;
    if (!mounted) return;
    context.push('/send-voice-message', extra: {'receiverPubkey': receiverPubkey});
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
                      Icon(Icons.mic_none, size: 64, color: onSurfaceVariant.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text(
                        'No voice messages yet',
                        style: theme.textTheme.bodyLarge?.copyWith(color: onSurfaceVariant),
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
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return _VoiceMessageListItem(
                        message: msg,
                        onTap: () {
                          context.push(
                            '/voice-message-detail',
                            extra: {'messageId': msg.messageId},
                          );
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
  final VoidCallback onTap;

  const _VoiceMessageListItem({
    required this.message,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final myPubkey = Account.sharedInstance.currentPubkey;
    final otherPubkey = message.sender == myPubkey ? message.receiver : message.sender;
    final userNotifier = Account.sharedInstance.getUserNotifier(otherPubkey);

    return ValueListenableBuilder<UserDBISAR>(
      valueListenable: userNotifier,
      builder: (context, user, _) => _buildContent(context, theme, colorScheme, user),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    UserDBISAR user,
  ) {

    final voicePayload = MessageDBISAR.parseVoiceContent(message.decryptContent) ??
        MessageDBISAR.parseVoiceContent(message.content);
    final durationSec = (voicePayload?['durationSeconds'] as num?)?.toInt() ?? 0;
    final durationStr = '${durationSec ~/ 60}:${(durationSec % 60).toString().padLeft(2, '0')}';

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
                        fontWeight: FontWeight.w600,
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
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          durationStr,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeStr,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatMessageTime(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    if (date.year == now.year) {
      return '${date.month}/${date.day}';
    }
    return '${date.year}/${date.month}/${date.day}';
  }
}
