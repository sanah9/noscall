import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:noscall/core/account/account.dart';

import 'voice_draft_store.dart';

class VoiceDraftsPage extends StatefulWidget {
  const VoiceDraftsPage({super.key});
  @override
  State<VoiceDraftsPage> createState() => _VoiceDraftsPageState();
}

class _VoiceDraftsPageState extends State<VoiceDraftsPage> {
  late Future<List<VoiceDraft>> _drafts = _load();
  Future<List<VoiceDraft>> _load() =>
      FileVoiceDraftStore.list(Account.sharedInstance.currentPubkey);
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Voice drafts'),
      actions: [
        IconButton(
          tooltip: 'Refresh drafts',
          onPressed: () => setState(() => _drafts = _load()),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: FutureBuilder<List<VoiceDraft>>(
      future: _drafts,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Drafts could not be loaded.'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.isEmpty) {
          return const Center(child: Text('No saved drafts'));
        }
        return ListView(
          children: [
            for (final draft in snapshot.data!)
              ListTile(
                leading: const Icon(Icons.mic_outlined),
                title: Text(
                  Account.sharedInstance
                      .getUserNotifier(draft.receiver)
                      .value
                      .displayName(),
                ),
                subtitle: Text(
                  '${draft.durationSeconds}s - ${draft.published
                      ? 'Sent; finish saving'
                      : draft.prepared != null
                      ? 'Awaiting confirmation'
                      : 'Draft'}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await context.push(
                    '/send-voice-message',
                    extra: {
                      'receiverPubkey': draft.receiver,
                      'replyToMessageId': draft.replyId,
                    },
                  );
                  if (mounted) setState(() => _drafts = _load());
                },
              ),
          ],
        );
      },
    ),
  );
}
