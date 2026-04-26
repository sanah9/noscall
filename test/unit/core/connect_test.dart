import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/core/common/network/connect.dart';

import '../../helpers/test_setup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await Connect.sharedInstance.closeAllConnects();
    Connect.clearTestOverrides();
  });

  tearDown(() async {
    await Connect.sharedInstance.closeAllConnects();
    Connect.clearTestOverrides();
  });

  test('Connect stays idle until init is called', () {
    final connect = Connect.sharedInstance;

    expect(connect.isInitialized, isFalse);
    expect(connect.timer, isNull);
  });

  test('Connect.init starts lifecycle watchers explicitly', () async {
    final connect = Connect.sharedInstance;
    Connect.setTestOverrides(
      connectivity: TestSetup.connectivity(
        initialResults: const [ConnectivityResult.wifi],
      ),
      socketConnector: TestSetup.socketConnector(),
    );

    await connect.init();

    expect(connect.isInitialized, isTrue);
    expect(connect.timer, isNotNull);
  });

  test('Connect uses injected socket connector instead of real websocket',
      () async {
    final connect = Connect.sharedInstance;
    final fakeConnector = FakeRelaySocketConnector();
    Connect.setTestOverrides(
      connectivity: TestSetup.connectivity(
        initialResults: const [ConnectivityResult.wifi],
      ),
      socketConnector: fakeConnector,
    );

    await connect.init();
    await connect.connect('wss://relay.example.com');

    expect(fakeConnector.connectedRelays, contains('wss://relay.example.com'));
    expect(
      connect.webSockets['wss://relay.example.com']?.connectStatus,
      equals(1),
    );
  });
}
