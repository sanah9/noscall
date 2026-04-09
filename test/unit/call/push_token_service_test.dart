import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/call/push_token_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PushTokenService', () {
    final service = PushTokenService();

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await service.clearVoIPToken();
    });

    test('should upload when token has not been seen', () async {
      final shouldUpload = await service.shouldUploadVoIPToken('token_1');
      expect(shouldUpload, isTrue);
    });

    test('uploadVoIPToken marks token as uploaded for change detection', () async {
      await service.uploadVoIPToken('token_2');
      final lastToken = await service.getLastUploadedToken();
      expect(lastToken, 'token_2');
    });

    test('clearVoIPToken removes persisted token', () async {
      await service.uploadVoIPToken('token_3');
      await service.clearVoIPToken();
      final lastToken = await service.getLastUploadedToken();
      expect(lastToken, isNull);
    });
  });
}
