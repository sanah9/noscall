import 'dart:convert';

import 'package:noscall/core/common/storage/preferences_store.dart';

enum AccountSetupStep { profile, backup, notifications, contact }

enum AccountSetupStatus { pending, completed, skipped }

class AccountSetupProgress {
  const AccountSetupProgress({this.steps = const {}, this.dismissed = false});
  final Map<AccountSetupStep, AccountSetupStatus> steps;
  final bool dismissed;
  AccountSetupStatus status(AccountSetupStep step) =>
      steps[step] ?? AccountSetupStatus.pending;
  int get completedCount => AccountSetupStep.values
      .where((step) => status(step) == AccountSetupStatus.completed)
      .length;
  bool get finished => AccountSetupStep.values.every(
    (step) => status(step) != AccountSetupStatus.pending,
  );
}

class AccountSetupService {
  AccountSetupService(this.pubkey) {
    if (!RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(pubkey)) {
      throw ArgumentError('A valid account is required');
    }
  }
  final String pubkey;
  String get _key => 'noscall_account_setup_v1_${pubkey.toLowerCase()}';

  Future<AccountSetupProgress> load() async {
    final raw = await PreferencesStore.shared.getString(_key);
    try {
      final data = raw == null
          ? <String, dynamic>{}
          : jsonDecode(raw) as Map<String, dynamic>;
      final steps = data['steps'] as Map? ?? {};
      return AccountSetupProgress(
        dismissed: data['dismissed'] == true,
        steps: {
          for (final step in AccountSetupStep.values)
            step: AccountSetupStatus.values.firstWhere(
              (status) => status.name == steps[step.name],
              orElse: () => AccountSetupStatus.pending,
            ),
        },
      );
    } catch (_) {
      return const AccountSetupProgress();
    }
  }

  Future<AccountSetupProgress> update({
    Map<AccountSetupStep, AccountSetupStatus> steps = const {},
    bool? dismissed,
  }) async {
    final previous = await load();
    final next = AccountSetupProgress(
      steps: {...previous.steps, ...steps},
      dismissed: dismissed ?? previous.dismissed,
    );
    final saved = await PreferencesStore.shared.setString(
      _key,
      jsonEncode({
        'steps': {
          for (final entry in next.steps.entries)
            entry.key.name: entry.value.name,
        },
        'dismissed': next.dismissed,
      }),
    );
    if (!saved) throw StateError('Setup progress could not be saved');
    return next;
  }
}
