import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:noscall/call/ice_server_manager.dart';
import '../../helpers/test_data.dart';
import '../../helpers/test_helpers.dart';

void main() {
  // Initialize Flutter binding for SharedPreferences
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('ICEServerManager', () {
    late ICEServerManager manager;

    setUpAll(() async {
      // Initialize SharedPreferences with empty values for testing
      SharedPreferences.setMockInitialValues({});
    });

    setUp(() {
      manager = ICEServerManager.shared;
    });

    tearDownAll(() async {
      // Clear any saved preferences after all tests
      try {
        await ICEServerManager.shared.clearCustomServers();
      } catch (e) {
        // Ignore errors during cleanup
      }
    });

    group('defaultICEServers', () {
      test('should return list of default ICE servers', () {
        final servers = manager.defaultICEServers;

        expect(servers, isNotEmpty);
        expect(servers.first, isA<ICEServerModel>());
      });

      test('should contain valid ICE server URLs', () {
        final servers = manager.defaultICEServers;
        
        for (final server in servers) {
          expect(server.url, isNotEmpty);
          expect(server.url, contains(':'));
        }
      });
    });

    group('getICEServers', () {
      test('should return default servers when no custom servers saved', () async {
        // Arrange: Ensure no custom servers are saved
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('noscall_custom_ice_servers');
        
        // Act
        final servers = await manager.getICEServers();
        
        // Assert
        expect(servers, isNotEmpty);
        expect(servers.length, equals(manager.defaultICEServers.length));
        expect(servers.first.url, equals(manager.defaultICEServers.first.url));
      });

      test('should return custom servers when available', () async {
        // Arrange: Clear and save custom servers
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('noscall_custom_ice_servers');
        
        final customServers = [
          TestHelpers.createTestIceServer(url: TestData.validStunUrl),
          TestHelpers.createTestIceServer(url: TestData.validTurnUrl),
        ];
        final saveSuccess = await manager.saveCustomServers(customServers);
        expect(saveSuccess, isTrue);
        
        // Act
        final servers = await manager.getICEServers();
        
        // Assert
        expect(servers.length, equals(2));
        expect(servers[0].url, equals(TestData.validStunUrl));
        expect(servers[1].url, equals(TestData.validTurnUrl));
        
        // Cleanup
        await prefs.remove('noscall_custom_ice_servers');
      });
    });

    group('loadCustomServers', () {
      test('should return empty list when no saved servers', () async {
        // Arrange: Clear any saved servers
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('noscall_custom_ice_servers');
        
        // Act
        final servers = await manager.loadCustomServers();
        
        // Assert
        expect(servers, isEmpty);
      });

      test('should load saved servers from SharedPreferences', () async {
        // Arrange: Clear and save servers
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('noscall_custom_ice_servers');
        
        final savedServers = [
          TestHelpers.createTestIceServer(url: TestData.validStunUrl),
          TestHelpers.createTestIceServer(url: TestData.validTurnUrl),
        ];
        await manager.saveCustomServers(savedServers);
        
        // Act
        final loadedServers = await manager.loadCustomServers();
        
        // Assert
        expect(loadedServers.length, equals(2));
        expect(loadedServers[0].url, equals(TestData.validStunUrl));
        expect(loadedServers[1].url, equals(TestData.validTurnUrl));
        
        // Cleanup
        await prefs.remove('noscall_custom_ice_servers');
      });

      test('should handle invalid JSON gracefully', () async {
        // Arrange: Set invalid JSON
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('noscall_custom_ice_servers', 'invalid json');
        
        // Act
        final servers = await manager.loadCustomServers();
        
        // Assert: Should return empty list, not throw
        expect(servers, isEmpty);
        
        // Cleanup
        await prefs.remove('noscall_custom_ice_servers');
      });

      test('should handle null value gracefully', () async {
        // Arrange: Clear the key
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('noscall_custom_ice_servers');
        
        // Act
        final servers = await manager.loadCustomServers();
        
        // Assert
        expect(servers, isEmpty);
      });
    });

    group('saveCustomServers', () {
      test('should save servers to SharedPreferences', () async {
        // Arrange: Clear first
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('noscall_custom_ice_servers');
        
        final servers = [
          TestHelpers.createTestIceServer(url: TestData.validStunUrl),
          TestHelpers.createTestIceServer(url: TestData.validTurnUrl),
        ];
        
        // Act
        final success = await manager.saveCustomServers(servers);
        
        // Assert
        expect(success, isTrue);
        
        // Verify by loading
        final loadedServers = await manager.loadCustomServers();
        expect(loadedServers.length, equals(2));
        expect(loadedServers[0].url, equals(TestData.validStunUrl));
        expect(loadedServers[1].url, equals(TestData.validTurnUrl));
        
        // Cleanup
        await prefs.remove('noscall_custom_ice_servers');
      });

      test('should overwrite existing servers', () async {
        // Arrange: Clear and save initial servers
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('noscall_custom_ice_servers');
        
        final initialServers = [
          TestHelpers.createTestIceServer(url: TestData.validStunUrl),
        ];
        await manager.saveCustomServers(initialServers);
        
        // Act: Save different servers
        final newServers = [
          TestHelpers.createTestIceServer(url: TestData.validTurnUrl),
        ];
        final success = await manager.saveCustomServers(newServers);
        
        // Assert
        expect(success, isTrue);
        final loadedServers = await manager.loadCustomServers();
        expect(loadedServers.length, equals(1));
        expect(loadedServers[0].url, equals(TestData.validTurnUrl));
        
        // Cleanup
        await prefs.remove('noscall_custom_ice_servers');
      });
    });

    group('clearCustomServers', () {
      test('should remove saved servers from SharedPreferences', () async {
        // Arrange: Clear and save servers
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('noscall_custom_ice_servers');
        
        final servers = [
          TestHelpers.createTestIceServer(url: TestData.validStunUrl),
        ];
        await manager.saveCustomServers(servers);
        
        // Verify servers are saved
        final beforeClear = await manager.loadCustomServers();
        expect(beforeClear, isNotEmpty);
        
        // Act
        final success = await manager.clearCustomServers();
        
        // Assert
        expect(success, isTrue);
        final afterClear = await manager.loadCustomServers();
        expect(afterClear, isEmpty);
      });
    });
  });
}
