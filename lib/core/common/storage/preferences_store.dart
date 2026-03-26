import 'package:noscall/core/common/utils/log_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around SharedPreferences to centralize error handling.
class PreferencesStore {
  PreferencesStore._internal();
  static final PreferencesStore shared = PreferencesStore._internal();

  Future<String?> getString(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (e, stack) {
      LogUtils.e(() => 'PreferencesStore.getString($key) failed: $e, $stack');
      return null;
    }
  }

  Future<bool?> getBool(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(key);
    } catch (e, stack) {
      LogUtils.e(() => 'PreferencesStore.getBool($key) failed: $e, $stack');
      return null;
    }
  }

  Future<int?> getInt(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(key);
    } catch (e, stack) {
      LogUtils.e(() => 'PreferencesStore.getInt($key) failed: $e, $stack');
      return null;
    }
  }

  Future<double?> getDouble(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble(key);
    } catch (e, stack) {
      LogUtils.e(() => 'PreferencesStore.getDouble($key) failed: $e, $stack');
      return null;
    }
  }

  Future<bool> setString(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.setString(key, value);
    } catch (e, stack) {
      LogUtils.e(() => 'PreferencesStore.setString($key) failed: $e, $stack');
      return false;
    }
  }

  Future<bool> setBool(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.setBool(key, value);
    } catch (e, stack) {
      LogUtils.e(() => 'PreferencesStore.setBool($key) failed: $e, $stack');
      return false;
    }
  }

  Future<bool> setInt(String key, int value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.setInt(key, value);
    } catch (e, stack) {
      LogUtils.e(() => 'PreferencesStore.setInt($key) failed: $e, $stack');
      return false;
    }
  }

  Future<bool> setDouble(String key, double value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.setDouble(key, value);
    } catch (e, stack) {
      LogUtils.e(() => 'PreferencesStore.setDouble($key) failed: $e, $stack');
      return false;
    }
  }

  Future<bool> remove(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.remove(key);
    } catch (e, stack) {
      LogUtils.e(() => 'PreferencesStore.remove($key) failed: $e, $stack');
      return false;
    }
  }
}
