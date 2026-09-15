import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/onboarding/account_setup_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'persists progress and distinguishes skipped steps from completed ones',
    () async {
      final service = AccountSetupService('a' * 64);
      expect((await service.load()).finished, isFalse);
      await service.update(
        steps: {
          AccountSetupStep.profile: AccountSetupStatus.completed,
          AccountSetupStep.backup: AccountSetupStatus.skipped,
        },
      );
      await service.update(dismissed: true);
      final reloaded = await AccountSetupService('a' * 64).load();
      expect(reloaded.completedCount, 1);
      expect(reloaded.dismissed, isTrue);
      expect(
        reloaded.status(AccountSetupStep.backup),
        AccountSetupStatus.skipped,
      );
      expect(reloaded.finished, isFalse);
      expect((await AccountSetupService('b' * 64).load()).completedCount, 0);
    },
  );

  test('resuming a skipped step preserves other progress', () async {
    final service = AccountSetupService('a' * 64);
    await service.update(
      steps: {
        for (final s in AccountSetupStep.values) s: AccountSetupStatus.skipped,
      },
    );
    final updated = await service.update(
      steps: {AccountSetupStep.backup: AccountSetupStatus.completed},
    );
    expect(updated.finished, isTrue);
    expect(updated.completedCount, 1);
    expect(
      updated.status(AccountSetupStep.contact),
      AccountSetupStatus.skipped,
    );
  });

  test(
    'recovers safely from corrupt progress and rejects missing account',
    () async {
      SharedPreferences.setMockInitialValues({
        'noscall_account_setup_v1_${'a' * 64}': '{bad',
      });
      expect((await AccountSetupService('a' * 64).load()).completedCount, 0);
      expect(() => AccountSetupService(''), throwsArgumentError);
    },
  );
}
