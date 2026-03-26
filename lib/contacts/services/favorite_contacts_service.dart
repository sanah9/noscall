import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:noscall/core/common/storage/preferences_store.dart';
import 'package:noscall/core/common/utils/log_utils.dart';

class FavoriteContactsService {
  FavoriteContactsService._internal();
  factory FavoriteContactsService() => _instance;
  static final FavoriteContactsService _instance = FavoriteContactsService._internal();

  static const String _keyFavorites = 'noscall_favorite_contact_pubkeys';
  final PreferencesStore _prefs = PreferencesStore.shared;

  final ValueNotifier<Set<String>> favoritePubkeysNotifier =
      ValueNotifier<Set<String>>({});

  Set<String> get favoritePubkeys => favoritePubkeysNotifier.value;

  bool isFavorite(String pubkey) => favoritePubkeys.contains(pubkey);

  Future<void> initialize() async {
    final json = await _prefs.getString(_keyFavorites);
    if (json == null || json.isEmpty) {
      favoritePubkeysNotifier.value = {};
      return;
    }
    try {
      final list = jsonDecode(json) as List<dynamic>?;
      favoritePubkeysNotifier.value =
          (list ?? []).map((e) => e.toString()).toSet();
    } catch (e, stack) {
      LogUtils.e(() => 'FavoriteContactsService.initialize failed: $e, $stack');
      favoritePubkeysNotifier.value = {};
    }
  }

  Future<void> _save(Set<String> set) async {
    final ok = await _prefs.setString(_keyFavorites, jsonEncode(set.toList()));
    if (ok) {
      favoritePubkeysNotifier.value = Set.from(set);
    } else {
      LogUtils.w(() => 'FavoriteContactsService._save failed');
    }
  }

  Future<void> addFavorite(String pubkey) async {
    final next = Set<String>.from(favoritePubkeys)..add(pubkey);
    await _save(next);
  }

  Future<void> removeFavorite(String pubkey) async {
    final next = Set<String>.from(favoritePubkeys)..remove(pubkey);
    await _save(next);
  }

  Future<void> toggleFavorite(String pubkey) async {
    if (isFavorite(pubkey)) {
      await removeFavorite(pubkey);
    } else {
      await addFavorite(pubkey);
    }
  }

  void dispose() {
    favoritePubkeysNotifier.dispose();
  }
}
