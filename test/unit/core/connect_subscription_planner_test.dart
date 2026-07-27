import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:noscall/core/common/network/connect_subscription_planner.dart';

void main() {
  test('uses valid explicit relays when provided', () {
    final planner = ConnectSubscriptionPlanner();
    final filters = [
      Filter(kinds: [1]),
    ];

    final plan = planner.plan(
      filters,
      explicitRelays: const [
        '',
        'https://not-a-relay.example.com',
        'ws://relay-1.example.com',
        'wss://relay-2.example.com',
      ],
      connectedRelays: const ['wss://fallback.example.com'],
    );

    expect(
      plan.filtersByRelay.keys,
      equals(['ws://relay-1.example.com', 'wss://relay-2.example.com']),
    );
    expect(plan.filtersByRelay['ws://relay-1.example.com'], same(filters));
  });

  test('falls back to connected relays when explicit relays are empty', () {
    final planner = ConnectSubscriptionPlanner();
    final filters = [
      Filter(kinds: [1]),
    ];

    final plan = planner.plan(
      filters,
      explicitRelays: const ['ftp://invalid.example.com'],
      connectedRelays: const [
        'wss://relay-1.example.com',
        'wss://relay-2.example.com',
      ],
    );

    expect(
      plan.filtersByRelay.keys,
      equals(['wss://relay-1.example.com', 'wss://relay-2.example.com']),
    );
  });

  test('returns empty plan when no relay is available', () {
    final planner = ConnectSubscriptionPlanner();

    final plan = planner.plan(
      [
        Filter(kinds: [1]),
      ],
      explicitRelays: const [],
      connectedRelays: const [],
    );

    expect(plan.isEmpty, isTrue);
  });
}
