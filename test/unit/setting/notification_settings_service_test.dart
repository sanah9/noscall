import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/setting/services/notification_settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationSettingsService', () {
    final service = NotificationSettingsService();

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await service.initialize();
    });

    test('loads defaults when values are missing', () {
      expect(service.notificationsEnabled, isTrue);
      expect(service.notificationSound, isTrue);
      expect(service.doNotDisturb, isFalse);
    });

    test('persists notifications enabled', () async {
      await service.setNotificationsEnabled(false);
      await service.initialize();
      expect(service.notificationsEnabled, isFalse);
    });

    test('persists do not disturb', () async {
      await service.setDoNotDisturb(true);
      await service.initialize();
      expect(service.doNotDisturb, isTrue);
    });
  });
}
