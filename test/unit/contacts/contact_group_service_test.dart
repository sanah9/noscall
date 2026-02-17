import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/contacts/models/contact_group_isar.dart';
import 'package:noscall/contacts/services/contact_group_service.dart';

void main() {
  group('ContactGroupService.newMemberPubKeysToAdd', () {
    test('returns empty list when contactPubKeys is empty', () {
      expect(
        ContactGroupService.newMemberPubKeysToAdd([], {'a', 'b'}),
        isEmpty,
      );
    });

    test('returns all when existingPubKeys is empty', () {
      expect(
        ContactGroupService.newMemberPubKeysToAdd(['p1', 'p2'], {}),
        ['p1', 'p2'],
      );
    });

    test('returns only pubkeys not in existingPubKeys', () {
      expect(
        ContactGroupService.newMemberPubKeysToAdd(
          ['p1', 'p2', 'p3'],
          {'p2'},
        ),
        ['p1', 'p3'],
      );
    });

    test('returns empty when all contactPubKeys already exist', () {
      expect(
        ContactGroupService.newMemberPubKeysToAdd(
          ['p1', 'p2'],
          {'p1', 'p2'},
        ),
        isEmpty,
      );
    });

    test('keeps duplicate pubkeys in contactPubKeys when all are new', () {
      expect(
        ContactGroupService.newMemberPubKeysToAdd(
          ['p1', 'p1', 'p2'],
          {},
        ),
        ['p1', 'p1', 'p2'],
      );
    });

    test('preserves order of contactPubKeys', () {
      expect(
        ContactGroupService.newMemberPubKeysToAdd(
          ['c', 'a', 'b'],
          {'a'},
        ),
        ['c', 'b'],
      );
    });
  });

  group('ContactGroup (model used by service)', () {
    test('create with empty name uses Untitled', () {
      final g = ContactGroup.create(name: '');
      expect(g.name, 'Untitled');
      expect(g.createTime, greaterThan(0));
      expect(g.updateTime, greaterThan(0));
    });

    test('create with non-empty name uses that name', () {
      final g = ContactGroup.create(name: 'My Group');
      expect(g.name, 'My Group');
    });

    test('updateName updates name and updateTime', () {
      final g = ContactGroup.create(name: 'Old');
      final tBefore = g.updateTime;
      g.updateName('New');
      expect(g.name, 'New');
      expect(g.updateTime, greaterThanOrEqualTo(tBefore));
    });
  });
}
