import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteContactsService {
  FavoriteContactsService._internal();
  factory FavoriteContactsService() => _instance;
  static final FavoriteContactsService _instance = FavoriteContactsService._internal();

  static const String _keyFavorites = 'noscall_favorite_contact_pubkeys';

  final ValueNotifier<Set<String>> favoritePubkeysNotifier =
      ValueNotifier<Set<String>>({});

  Set<String> get favoritePubkeys => favoritePubkeysNotifier.value;

  bool isFavorite(String pubkey) => favoritePubkeys.contains(pubkey);

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keyFavorites);
    if (json == null || json.isEmpty) {
      favoritePubkeysNotifier.value = {};
      return;
    }
    try {
      final list = jsonDecode(json) as List<dynamic>?;
      favoritePubkeysNotifier.value =
          (list ?? []).map((e) => e.toString()).toSet();
    } catch (_) {
      favoritePubkeysNotifier.value = {};
    }
  }

  Future<void> _save(Set<String> set) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyFavorites, jsonEncode(set.toList()));
      favoritePubkeysNotifier.value = Set.from(set);
    } catch (_) {}
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
