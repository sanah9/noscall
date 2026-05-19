import 'connect_types.dart';

class ConnectStatusNotifier {
  final List<ConnectStatusCallBack> listeners = [];

  ConnectStatusListenerHandle add(ConnectStatusCallBack callBack) {
    if (!listeners.contains(callBack)) {
      listeners.add(callBack);
    }
    return ConnectStatusListenerHandle(callBack, remove);
  }

  void remove(ConnectStatusCallBack callBack) {
    listeners.remove(callBack);
  }

  void notify(String relay, int status, List<RelayKind> relayKinds) {
    for (final callBack in listeners) {
      callBack(relay, status, relayKinds);
    }
  }
}
