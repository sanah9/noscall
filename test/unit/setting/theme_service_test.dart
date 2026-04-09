import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/setting/services/theme_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeService', () {
    final service = ThemeService();

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await service.initialize();
    });

    test('loads defaults when no persisted values', () async {
      expect(service.themeModeNotifier.value, ThemeModeOption.system);
      expect(service.seedColorValueNotifier.value, kDefaultSeedColorValue);
    });

    test('persists and loads theme mode', () async {
      await service.setThemeMode(ThemeModeOption.dark);
      final loaded = await service.getThemeMode();
      expect(loaded, ThemeModeOption.dark);
    });

    test('persists and loads seed color value', () async {
      await service.setSeedColorValue(0xFF1976D2);
      final loaded = await service.getSeedColorValue();
      expect(loaded, 0xFF1976D2);
    });
  });
}
