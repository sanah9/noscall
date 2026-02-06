import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local contact remarks keyed by pubkey. Stored in SharedPreferences.
class ContactRemarkService {
  ContactRemarkService._internal();
  factory ContactRemarkService() => _instance;
  static final ContactRemarkService _instance =
      ContactRemarkService._internal();

  static const String _keyRemarks = 'noscall_contact_remarks';

  final ValueNotifier<Map<String, String>> _remarksNotifier =
      ValueNotifier<Map<String, String>>({});

  ValueNotifier<Map<String, String>> get remarksNotifier => _remarksNotifier;
  Map<String, String> get remarks => Map.unmodifiable(_remarksNotifier.value);

  String? getRemark(String pubkey) => _remarksNotifier.value[pubkey];

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_keyRemarks);
      if (json == null || json.isEmpty) {
        _remarksNotifier.value = {};
        return;
      }
      final map = jsonDecode(json) as Map<String, dynamic>?;
      _remarksNotifier.value = map?.map(
            (k, v) => MapEntry(k, v?.toString() ?? ''),
          ) ??
          {};
    } catch (e) {
      if (kDebugMode) {
        print('ContactRemarkService init error: $e');
      }
      _remarksNotifier.value = {};
    }
  }

  Future<void> _save(Map<String, String> map) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyRemarks, jsonEncode(map));
      _remarksNotifier.value = Map.from(map);
    } catch (_) {}
  }

  Future<void> setRemark(String pubkey, String remark) async {
    final next = Map<String, String>.from(_remarksNotifier.value);
    final trimmed = remark.trim();
    if (trimmed.isEmpty) {
      next.remove(pubkey);
    } else {
      next[pubkey] = trimmed;
    }
    await _save(next);
  }

  Future<void> removeRemark(String pubkey) async {
    final next = Map<String, String>.from(_remarksNotifier.value);
    next.remove(pubkey);
    await _save(next);
  }

  void dispose() {
    _remarksNotifier.dispose();
  }
}
