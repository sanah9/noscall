import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/core/account/model/user_db_isar.dart';

void main() {
  group('UserDBISAR', () {
    test('fromMap does not import legacy sensitive fields', () {
      final user = UserDBISAR.fromMap({
        'pubKey':
            '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
        'encryptedPrivKey': 'encrypted',
        'defaultPassword': 'legacy-password',
        'clientPrivateKey': 'legacy-client-key',
        'name': 'Alice',
        'nickName': 'alice',
        'mainRelay': '',
        'dns': '',
        'lnurl': '',
        'badges': '',
        'gender': '',
        'area': '',
        'about': '',
        'picture': '',
        'banner': '',
        'friendsList': '',
        'blockedList': '[]',
        'followingList': '[]',
        'followersList': '[]',
        'relayList': '[]',
        'dmRelayList': '[]',
        'aliasPubkey': '',
        'mute': false,
        'lastUpdatedTime': 0,
      });

      expect(user.defaultPassword, isEmpty);
      expect(user.clientPrivateKey, isNull);
    });
  });
}
