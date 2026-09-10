import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/onboarding/onboarding_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OnboardingService', () {
    final service = OnboardingService();

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await service.initialize();
    });

    test('loads incomplete by default', () {
      expect(service.isCompleted, isFalse);
    });

    test('persists completion', () async {
      await service.complete();

      expect(service.isCompleted, isTrue);

      await service.initialize();
      expect(service.isCompleted, isTrue);
    });

    test('resets completion', () async {
      await service.complete();
      await service.reset();

      expect(service.isCompleted, isFalse);

      await service.initialize();
      expect(service.isCompleted, isFalse);
    });
  });
}
