import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/core/account/model/userDB_isar.dart';
import 'package:noscall/call/ice_server_manager.dart';

/// Test helper utilities
class TestHelpers {
  /// Create a test user
  static UserDBISAR createTestUser({
    String? pubKey,
    String? name,
    String? nickName,
  }) {
    return UserDBISAR(
      pubKey: pubKey ?? 'test_pubkey_${DateTime.now().millisecondsSinceEpoch}',
      name: name ?? 'Test User',
      nickName: nickName,
      lastUpdatedTime: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      lastFriendsListUpdatedTime: 0,
      lastBlockListUpdatedTime: 0,
      lastRelayListUpdatedTime: 0,
      lastFollowingListUpdatedTime: 0,
      lastDMRelayListUpdatedTime: 0,
    );
  }

  /// Wait for async operations to complete
  static Future<void> waitForAsync(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  /// Wait for network requests to complete
  static Future<void> waitForNetwork(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
  }

  /// Create a valid Relay URL
  static String createValidRelayUrl({String? host}) {
    return 'wss://${host ?? 'test.relay.com'}';
  }

  /// Create an invalid Relay URL
  static String createInvalidRelayUrl() {
    return 'invalid-url';
  }

  /// Create a test ICE server model
  static ICEServerModel createTestIceServer({
    String? url,
  }) {
    return ICEServerModel(
      url: url ?? 'stun:stun.test.com:3478',
    );
  }

  /// Create a valid STUN server URL
  static String createValidStunUrl({String? host, int? port}) {
    return 'stun:${host ?? 'stun.test.com'}:${port ?? 3478}';
  }

  /// Create a valid TURN server URL
  static String createValidTurnUrl({
    String? username,
    String? password,
    String? host,
    int? port,
  }) {
    return 'turn:${username ?? 'testuser'}:${password ?? 'testpass'}@${host ?? 'turn.test.com'}:${port ?? 3478}';
  }

  /// Create an invalid ICE server URL
  static String createInvalidIceServerUrl() {
    return 'invalid-ice-url';
  }
}
