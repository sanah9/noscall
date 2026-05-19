import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/core/common/network/connect_subscription_queue.dart';
import 'package:noscall/core/common/network/connect_types.dart';

Requests request({
  int requestTime = 0,
  List<String> relays = const ['wss://relay.example.com'],
}) {
  return Requests(
    'request-id',
    List<String>.from(relays),
    requestTime,
    {},
    null,
    null,
    '["REQ","subscription-id"]',
    true,
  );
}

void main() {
  group('ConnectSubscriptionQueue', () {
    test('deduplicates waiting subscriptions per relay', () {
      final queue = ConnectSubscriptionQueue(maxInFlight: 2);

      queue.add('sub-1', 'wss://relay.example.com');
      queue.add('sub-1', 'wss://relay.example.com');

      expect(queue.waitingByRelay['wss://relay.example.com'], ['sub-1']);
    });

    test('takes next subscription when active count is below limit', () {
      final queue = ConnectSubscriptionQueue(maxInFlight: 2);
      const relay = 'wss://relay.example.com';
      final requests = <String, Requests>{
        'active-1$relay': request(requestTime: 100, relays: [relay]),
      };

      queue.add('sub-2', relay);

      expect(queue.takeNext(relay, requests), 'sub-2');
      expect(queue.waitingCount(relay), 0);
    });

    test('leaves waiting subscription when active count reaches limit', () {
      final queue = ConnectSubscriptionQueue(maxInFlight: 1);
      const relay = 'wss://relay.example.com';
      final requests = <String, Requests>{
        'active-1$relay': request(requestTime: 100, relays: [relay]),
      };

      queue.add('sub-2', relay);

      expect(queue.takeNext(relay, requests), isNull);
      expect(queue.waitingByRelay[relay], ['sub-2']);
    });
  });
}
