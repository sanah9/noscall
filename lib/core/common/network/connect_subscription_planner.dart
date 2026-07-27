import 'package:nostr_core_dart/nostr.dart';

class ConnectSubscriptionPlan {
  const ConnectSubscriptionPlan(this.filtersByRelay);

  final Map<String, List<Filter>> filtersByRelay;

  bool get isEmpty => filtersByRelay.isEmpty;
}

class ConnectSubscriptionPlanner {
  ConnectSubscriptionPlan plan(
    List<Filter> filters, {
    List<String>? explicitRelays,
    required List<String> connectedRelays,
  }) {
    final validExplicitRelays = _validExplicitRelays(explicitRelays);
    final targetRelays = validExplicitRelays.isNotEmpty
        ? validExplicitRelays
        : connectedRelays;

    return ConnectSubscriptionPlan({
      for (final relay in targetRelays) relay: filters,
    });
  }

  List<String> _validExplicitRelays(List<String>? relays) {
    if (relays == null) return const [];
    return relays.where(_isValidRelayUrl).toList();
  }

  bool _isValidRelayUrl(String relay) {
    return relay.isNotEmpty &&
        (relay.startsWith('ws://') || relay.startsWith('wss://'));
  }
}
