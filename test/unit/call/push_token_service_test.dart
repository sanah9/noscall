import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/call/push_token_service.dart';
import 'package:noscall/core/account/account.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakePushTokenApiClient implements PushTokenApiClient {
  String? registeredToken;
  String? unregisteredDeviceId;

  @override
  Future<PushTokenRegistration?> registerDevice(
    PushTokenRegistrationRequest request,
  ) async {
    registeredToken = request.token;
    return const PushTokenRegistration(
      deviceRegistrationId: 'device-1',
      callbackUrl: 'https://push.example.com/callback/device-1',
    );
  }

  @override
  Future<bool> unregisterDevice(String deviceRegistrationId) async {
    unregisteredDeviceId = deviceRegistrationId;
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PushTokenService', () {
    final service = PushTokenService();
    late FakePushTokenApiClient apiClient;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      apiClient = FakePushTokenApiClient();
      PushTokenService.setTestOverrides(apiClient: apiClient);
      Account.sharedInstance.currentPubkey =
          '79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798';
      await service.clearVoIPToken();
    });

    tearDown(() {
      PushTokenService.clearTestOverrides();
      Account.sharedInstance.currentPubkey = '';
    });

    test('should upload when token has not been registered', () async {
      final shouldUpload = await service.shouldUploadVoIPToken('token_1');
      expect(shouldUpload, isTrue);
    });

    test('uploadVoIPToken persists callback registration metadata', () async {
      final uploaded = await service.uploadVoIPToken('token_2');

      expect(uploaded, isTrue);
      expect(apiClient.registeredToken, 'token_2');
      expect(await service.getLastUploadedToken(), 'token_2');
      final registration = await service.getCurrentRegistration();
      expect(registration?.deviceRegistrationId, 'device-1');
      expect(
        registration?.callbackUrl,
        'https://push.example.com/callback/device-1',
      );
    });

    test('unregisterCurrentDevice calls server and clears persisted metadata',
        () async {
      await service.uploadVoIPToken('token_3');
      final ok = await service.unregisterCurrentDevice();

      expect(ok, isTrue);
      expect(apiClient.unregisteredDeviceId, 'device-1');
      expect(await service.getLastUploadedToken(), isNull);
      expect(await service.getCurrentRegistration(), isNull);
    });

    test('clearVoIPToken removes local registration metadata', () async {
      await service.uploadVoIPToken('token_4');
      await service.clearVoIPToken();

      expect(await service.getLastUploadedToken(), isNull);
      expect(await service.getCurrentRegistration(), isNull);
    });
  });
}
