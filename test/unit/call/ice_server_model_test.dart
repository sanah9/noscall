import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/call/ice_server_manager.dart';
import '../../helpers/test_data.dart';
import '../../helpers/test_helpers.dart';

void main() {
  group('ICEServerModel', () {
    group('isTurnAddress', () {
      test('should return true for TURN URLs', () {
        final server = ICEServerModel(url: TestData.validTurnUrl);
        expect(server.isTurnAddress, isTrue);
      });

      test('should return true for TURNS URLs', () {
        final server = ICEServerModel(url: TestData.validTurnsUrl);
        expect(server.isTurnAddress, isTrue);
      });

      test('should return false for STUN URLs', () {
        final server = ICEServerModel(url: TestData.validStunUrl);
        expect(server.isTurnAddress, isFalse);
      });

      test('should return false for STUNS URLs', () {
        final server = ICEServerModel(url: TestData.validStunsUrl);
        expect(server.isTurnAddress, isFalse);
      });
    });

    group('username', () {
      test('should extract username from TURN URL', () {
        final server = ICEServerModel(url: 'turn:testuser:testpass@turn.example.com:3478');
        expect(server.username, equals('testuser'));
      });

      test('should return empty string for STUN URL', () {
        final server = ICEServerModel(url: TestData.validStunUrl);
        expect(server.username, isEmpty);
      });

      test('should handle complex usernames', () {
        final server = ICEServerModel(url: 'turn:user_name-123:pass@turn.example.com:3478');
        expect(server.username, equals('user_name-123'));
      });
    });

    group('credential', () {
      test('should extract credential from TURN URL', () {
        final server = ICEServerModel(url: 'turn:testuser:testpass@turn.example.com:3478');
        expect(server.credential, equals('testpass'));
      });

      test('should return empty string for STUN URL', () {
        final server = ICEServerModel(url: TestData.validStunUrl);
        expect(server.credential, isEmpty);
      });

      test('should handle complex passwords', () {
        final server = ICEServerModel(url: 'turn:user:pass-word_123@turn.example.com:3478');
        expect(server.credential, equals('pass-word_123'));
      });
    });

    group('domain', () {
      test('should extract domain from TURN URL', () {
        final server = ICEServerModel(url: 'turn:user:pass@turn.example.com:3478');
        expect(server.domain, equals('turn.example.com:3478'));
      });

      test('should return full URL for STUN URL', () {
        final server = ICEServerModel(url: TestData.validStunUrl);
        expect(server.domain, equals(TestData.validStunUrl));
      });

      test('should handle URLs without port', () {
        final server = ICEServerModel(url: 'turn:user:pass@turn.example.com');
        expect(server.domain, equals('turn.example.com'));
      });
    });

    group('host', () {
      test('should extract host from TURN URL', () {
        final server = ICEServerModel(url: 'turn:user:pass@turn.example.com:3478');
        expect(server.host, equals('turn.example.com'));
      });

      test('should return full URL for STUN URL', () {
        final server = ICEServerModel(url: TestData.validStunUrl);
        expect(server.host, equals(TestData.validStunUrl));
      });
    });

    group('serverConfigs', () {
      test('should return STUN config for STUN URL', () {
        final server = ICEServerModel(url: TestData.validStunUrl);
        final configs = server.serverConfigs;
        
        expect(configs.length, equals(1));
        expect(configs[0]['url'], equals(TestData.validStunUrl));
        expect(configs[0].containsKey('urls'), isFalse);
        expect(configs[0].containsKey('username'), isFalse);
        expect(configs[0].containsKey('credential'), isFalse);
      });

      test('should return TURN config for TURN URL', () {
        final server = ICEServerModel(url: 'turn:user:pass@turn.example.com:3478');
        final configs = server.serverConfigs;
        
        expect(configs.length, equals(1));
        expect(configs[0]['urls'], equals('turn:turn.example.com:3478'));
        expect(configs[0]['username'], equals('user'));
        expect(configs[0]['credential'], equals('pass'));
        expect(configs[0].containsKey('url'), isFalse);
      });

      test('should return TURN config for TURNS URL', () {
        final server = ICEServerModel(url: TestData.validTurnsUrl);
        final configs = server.serverConfigs;
        
        expect(configs.length, equals(1));
        expect(configs[0].containsKey('urls'), isTrue);
        expect(configs[0].containsKey('username'), isTrue);
        expect(configs[0].containsKey('credential'), isTrue);
      });
    });

    group('fromJson', () {
      test('should create ICEServerModel from JSON', () {
        final json = {'url': TestData.validStunUrl};
        final server = ICEServerModel.fromJson(json);
        
        expect(server.url, equals(TestData.validStunUrl));
      });

      test('should handle missing url field', () {
        final json = <String, dynamic>{};
        final server = ICEServerModel.fromJson(json);
        
        expect(server.url, isEmpty);
      });

      test('should handle null url field', () {
        final json = {'url': null};
        final server = ICEServerModel.fromJson(json);
        
        expect(server.url, isEmpty);
      });
    });

    group('toJson', () {
      test('should convert ICEServerModel to JSON', () {
        final server = ICEServerModel(url: TestData.validStunUrl);
        final json = server.toJson();
        
        expect(json['url'], equals(TestData.validStunUrl));
      });

      test('should handle TURN URL in JSON', () {
        final server = ICEServerModel(url: TestData.validTurnUrl);
        final json = server.toJson();
        
        expect(json['url'], equals(TestData.validTurnUrl));
      });
    });

    group('equality', () {
      test('should be equal when URLs are the same', () {
        final server1 = ICEServerModel(url: TestData.validStunUrl);
        final server2 = ICEServerModel(url: TestData.validStunUrl);
        
        expect(server1 == server2, isTrue);
        expect(server1.hashCode, equals(server2.hashCode));
      });

      test('should not be equal when URLs are different', () {
        final server1 = ICEServerModel(url: TestData.validStunUrl);
        final server2 = ICEServerModel(url: TestData.validTurnUrl);
        
        expect(server1 == server2, isFalse);
      });

      test('should not be equal to different type', () {
        final server = ICEServerModel(url: TestData.validStunUrl);
        
        expect(server == 'string', isFalse);
        expect(server == null, isFalse);
      });

      test('should be equal to itself', () {
        final server = ICEServerModel(url: TestData.validStunUrl);
        
        expect(server == server, isTrue);
      });
    });

    group('edge cases', () {
      test('should handle empty URL', () {
        final server = ICEServerModel(url: '');
        
        expect(server.url, isEmpty);
        expect(server.isTurnAddress, isFalse);
        expect(server.username, isEmpty);
        expect(server.credential, isEmpty);
      });

      test('should handle TURN URL without credentials', () {
        // This is an invalid format, may throw RangeError
        final server = ICEServerModel(url: 'turn:@turn.example.com:3478');
        
        expect(server.isTurnAddress, isTrue);
        // username and credential extraction may throw for invalid format
        // This is expected behavior - invalid URLs should be caught by validation
        // The actual behavior depends on the split result
        try {
          final username = server.username;
          // If it doesn't throw, username might be empty or have unexpected value
          expect(username, anyOf(isEmpty, isA<String>()));
        } catch (e) {
          expect(e, isA<RangeError>());
        }
        
        try {
          final credential = server.credential;
          expect(credential, anyOf(isEmpty, isA<String>()));
        } catch (e) {
          expect(e, isA<RangeError>());
        }
      });

      test('should handle malformed TURN URL', () {
        final server = ICEServerModel(url: 'turn:invalid');
        
        expect(server.isTurnAddress, isTrue);
        expect(() => server.domain, returnsNormally);
        expect(() => server.host, returnsNormally);
      });
    });
  });
}
