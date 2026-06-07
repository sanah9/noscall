import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/call/push_token_service.dart';
import 'package:noscall/core/account/account.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakePushTokenApiClient implements PushTokenApiClient {
  String? registeredToken;
  String? registeredTokenType;
  String? unregisteredDeviceId;
  final List<String> unregisteredDeviceIds = [];

  @override
  Future<PushTokenRegistration?> registerDevice(
    PushTokenRegistrationRequest request,
  ) async {
    registeredToken = request.token;
    registeredTokenType = request.tokenType;
    return PushTokenRegistration(
      deviceRegistrationId: 'device-${request.tokenType}',
      callbackUrl:
          'https://push.example.com/callback/device-${request.tokenType}',
    );
  }

  @override
  Future<bool> unregisterDevice(String deviceRegistrationId) async {
    unregisteredDeviceId = deviceRegistrationId;
    unregisteredDeviceIds.add(deviceRegistrationId);
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
      await service.clearStandardAPNsToken();
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
      expect(apiClient.registeredTokenType, 'apns_voip');
      expect(await service.getLastUploadedToken(), 'token_2');
      final registration = await service.getCurrentRegistration();
      expect(registration?.deviceRegistrationId, 'device-apns_voip');
      expect(
        registration?.callbackUrl,
        'https://push.example.com/callback/device-apns_voip',
      );
    });

    test('uploadStandardAPNsToken persists separate APNs registration metadata',
        () async {
      await service.uploadVoIPToken('voip_token');
      final uploaded = await service.uploadStandardAPNsToken('standard_token');

      expect(uploaded, isTrue);
      expect(apiClient.registeredToken, 'standard_token');
      expect(apiClient.registeredTokenType, 'apns');
      expect(await service.getLastUploadedToken(), 'voip_token');
      expect(
          await service.getLastUploadedStandardAPNsToken(), 'standard_token');

      final voipRegistration = await service.getCurrentRegistration();
      expect(voipRegistration?.deviceRegistrationId, 'device-apns_voip');

      final standardRegistration = await service.getStandardAPNsRegistration();
      expect(standardRegistration?.deviceRegistrationId, 'device-apns');
      expect(
        standardRegistration?.callbackUrl,
        'https://push.example.com/callback/device-apns',
      );
    });

    test('unregisterCurrentDevice calls server and clears persisted metadata',
        () async {
      await service.uploadVoIPToken('token_3');
      final ok = await service.unregisterCurrentDevice();

      expect(ok, isTrue);
      expect(apiClient.unregisteredDeviceId, 'device-apns_voip');
      expect(await service.getLastUploadedToken(), isNull);
      expect(await service.getCurrentRegistration(), isNull);
    });

    test('unregisterCurrentDevice clears standard APNs metadata', () async {
      await service.uploadVoIPToken('token_3');
      await service.uploadStandardAPNsToken('standard_token_3');
      final ok = await service.unregisterCurrentDevice();

      expect(ok, isTrue);
      expect(apiClient.unregisteredDeviceIds, contains('device-apns_voip'));
      expect(apiClient.unregisteredDeviceIds, contains('device-apns'));
      expect(await service.getLastUploadedToken(), isNull);
      expect(await service.getCurrentRegistration(), isNull);
      expect(await service.getLastUploadedStandardAPNsToken(), isNull);
      expect(await service.getStandardAPNsRegistration(), isNull);
    });

    test('clearVoIPToken removes local registration metadata', () async {
      await service.uploadVoIPToken('token_4');
      await service.clearVoIPToken();

      expect(await service.getLastUploadedToken(), isNull);
      expect(await service.getCurrentRegistration(), isNull);
    });
  });
}
