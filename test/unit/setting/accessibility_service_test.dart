import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/setting/services/accessibility_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AccessibilityService', () {
    final service = AccessibilityService();

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await service.initialize();
    });

    test('default text scale factor is null', () {
      expect(service.textScaleFactor, isNull);
    });

    test('persists text scale factor', () async {
      await service.setTextScaleFactor(1.2);
      await service.initialize();
      expect(service.textScaleFactor, 1.2);
    });

    test('removes persisted text scale factor when set to null', () async {
      await service.setTextScaleFactor(1.3);
      await service.setTextScaleFactor(null);
      await service.initialize();
      expect(service.textScaleFactor, isNull);
    });
  });
}
