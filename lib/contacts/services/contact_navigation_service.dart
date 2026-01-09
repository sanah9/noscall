import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage persistent state for contact navigation
/// Only saves group ID. If no group ID is saved, defaults to "All Contacts" page.
class ContactNavigationService {
  static final ContactNavigationService sharedInstance = ContactNavigationService._internal();
  ContactNavigationService._internal();
  factory ContactNavigationService() => sharedInstance;

  static const String _lastGroupIdKey = 'noscall_contact_last_group_id';

  /// Save the last visited group ID
  Future<void> saveLastGroupId(int groupId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastGroupIdKey, groupId);
    } catch (e) {
      // Silently fail - navigation state is not critical
    }
  }

  /// Clear the saved group ID (when on "All Contacts" or group list page)
  Future<void> clearLastGroupId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastGroupIdKey);
    } catch (e) {
      // Silently fail - navigation state is not critical
    }
  }

  /// Get the last visited group ID
  /// Returns null if no saved state (defaults to "All Contacts" page)
  Future<int?> getLastGroupId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_lastGroupIdKey);
    } catch (e) {
      return null;
    }
  }
}

