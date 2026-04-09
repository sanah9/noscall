import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/contacts/services/favorite_contacts_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FavoriteContactsService', () {
    final service = FavoriteContactsService();

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await service.initialize();
    });

    test('starts empty without persisted data', () {
      expect(service.favoritePubkeys, isEmpty);
    });

    test('addFavorite persists contact', () async {
      await service.addFavorite('pubkey_a');
      await service.initialize();
      expect(service.isFavorite('pubkey_a'), isTrue);
    });

    test('toggleFavorite removes existing favorite', () async {
      await service.addFavorite('pubkey_b');
      await service.toggleFavorite('pubkey_b');
      expect(service.isFavorite('pubkey_b'), isFalse);
    });
  });
}
