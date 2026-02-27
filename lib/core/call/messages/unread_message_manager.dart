import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:noscall/core/account/account.dart';

/// Manages unread *voice* message IDs per account (pubkey-scoped).
///
/// - Stores voice message IDs in SharedPreferences under a key namespaced by pubkey.
/// - Provides APIs to get total unread count, add/remove IDs, and query read state by ID.
class VoiceUnreadManager {
  VoiceUnreadManager._();
  static final VoiceUnreadManager instance = VoiceUnreadManager._();

  /// Notifier for total unread voice message count.
  final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);

  SharedPreferences? _prefs;

  /// In-memory cache of unread voice message IDs for current account.
  final Set<String> _unreadIds = <String>{};

  /// Initialize from persistent storage for the current account.
  /// Call once after `Account.sharedInstance.currentPubkey` is ready.
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    final key = _keyForCurrentUser();
    if (key == null) {
      _unreadIds.clear();
      unreadCountNotifier.value = 0;
      return;
    }
    final stored = _prefs!.getStringList(key) ?? const <String>[];
    _unreadIds
      ..clear()
      ..addAll(stored);
    unreadCountNotifier.value = _unreadIds.length;
  }

  /// Returns total unread voice message count (size of the ID set).
  int get totalUnread => _unreadIds.length;

  /// Returns a snapshot of all unread voice message IDs.
  List<String> get unreadIds => List.unmodifiable(_unreadIds);

  /// Returns `true` if the given message ID is currently considered *read*.
  /// A message is read iff it's not in the unread ID set.
  bool isRead(String messageId) {
    if (messageId.isEmpty) return true;
    return !_unreadIds.contains(messageId);
  }

  /// Returns `true` if the given message ID is currently considered *unread*.
  bool isUnread(String messageId) {
    if (messageId.isEmpty) return false;
    return _unreadIds.contains(messageId);
  }

  /// Adds a voice message ID to the unread set and persists the change.
  Future<void> addUnread(String messageId) async {
    if (messageId.isEmpty) return;
    final added = _unreadIds.add(messageId);
    if (!added) return;
    unreadCountNotifier.value = _unreadIds.length;
    await _persist();
  }

  /// Removes a voice message ID from the unread set and persists the change.
  Future<void> removeUnread(String messageId) async {
    if (messageId.isEmpty) return;
    final removed = _unreadIds.remove(messageId);
    if (!removed) return;
    unreadCountNotifier.value = _unreadIds.length;
    await _persist();
  }

  /// Clears all unread voice message IDs for current account and persists the change.
  Future<void> clearAll() async {
    if (_unreadIds.isEmpty) return;
    _unreadIds.clear();
    unreadCountNotifier.value = 0;
    await _persist();
  }

  String? _keyForCurrentUser() {
    final pubkey = Account.sharedInstance.currentPubkey;
    if (pubkey.isEmpty) return null;
    return 'voice_unread_message_ids_$pubkey';
  }

  Future<void> _persist() async {
    final key = _keyForCurrentUser();
    if (key == null) return;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setStringList(key, _unreadIds.toList());
  }
}


