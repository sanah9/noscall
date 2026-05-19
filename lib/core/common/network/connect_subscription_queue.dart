import 'connect_types.dart';

class ConnectSubscriptionQueue {
  ConnectSubscriptionQueue({required this.maxInFlight});

  final int maxInFlight;
  final Map<String, List<String>> waitingByRelay = {};

  void add(String subscriptionId, String relay) {
    final waitingQueue = waitingByRelay[relay] ?? [];
    if (!waitingQueue.contains(subscriptionId)) {
      waitingQueue.add(subscriptionId);
      waitingByRelay[relay] = waitingQueue;
    }
  }

  int activeCount(String relay, Map<String, Requests> requestsMap) {
    var count = 0;
    for (final key in requestsMap.keys) {
      final request = requestsMap[key];
      if (key.contains(relay) &&
          request != null &&
          request.relays.contains(relay) &&
          request.requestTime > 0) {
        count += 1;
      }
    }
    return count;
  }

  int waitingCount(String relay) {
    return waitingByRelay[relay]?.length ?? 0;
  }

  String? takeNext(String relay, Map<String, Requests> requestsMap) {
    if (activeCount(relay, requestsMap) >= maxInFlight) {
      return null;
    }

    final waitingQueue = waitingByRelay[relay];
    if (waitingQueue == null || waitingQueue.isEmpty) {
      return null;
    }

    return waitingQueue.removeAt(0);
  }

  void clear() {
    waitingByRelay.clear();
  }
}
