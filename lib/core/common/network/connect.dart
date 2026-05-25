import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'package:nostr_core_dart/nostr.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:noscall/core/account/account.dart';
import 'package:noscall/core/common/thread/thread_pool_manager.dart';
import 'package:noscall/core/common/utils/log_utils.dart';
import 'connect_auth_state.dart';
import 'connect_dependencies.dart';
import 'connect_status_notifier.dart';
import 'connect_subscription_queue.dart';
import 'connect_timeout_checker.dart';
import 'event_cache.dart';
import 'reconnection_scheduler.dart';

import 'connect_types.dart';

export 'connect_types.dart';

class Connect {
  Connect._internal()
      : _connectivity = DefaultConnectConnectivity(),
        _socketConnector = const DefaultRelaySocketConnector();
  factory Connect() => sharedInstance;
  static final Connect sharedInstance = Connect._internal();

  ConnectConnectivity _connectivity;
  RelaySocketConnector _socketConnector;
  bool _isInitialized = false;

  static void setTestOverrides({
    ConnectConnectivity? connectivity,
    RelaySocketConnector? socketConnector,
  }) {
    sharedInstance.configureDependencies(
      connectivity: connectivity,
      socketConnector: socketConnector,
    );
  }

  static void clearTestOverrides() {
    sharedInstance.configureDependencies(
      connectivity: DefaultConnectConnectivity(),
      socketConnector: const DefaultRelaySocketConnector(),
    );
  }

  static const int timeout = 10;
  static const int connectionTimeout = 10;
  static const int maxSubscriptionsCount = 15;

  NoticeCallBack? noticeCallBack;
  StreamSubscription? _connectivitySubscription;

  /// sockets
  Map<String, ISocket> webSockets = {};

  // subscriptionId+relay, Requests
  Map<String, Requests> requestsMap = {};
  // send event callback
  Map<String, Sends> sendsMap = {};
  List<ConnectStatusCallBack> get connectStatusListeners =>
      _statusNotifier.listeners;
  // for timeout
  Timer? timer;
  Map<String, AuthData> get auths => _authState.auths;

  Map<String, List<Future<bool>>> eventCheckerFutures = {};

  Map<String, List<String>> get subscriptionsWaitingQueue =>
      _subscriptionQueue.waitingByRelay;

  final ConnectAuthState _authState = ConnectAuthState();
  final ConnectStatusNotifier _statusNotifier = ConnectStatusNotifier();
  final ConnectSubscriptionQueue _subscriptionQueue =
      ConnectSubscriptionQueue(maxInFlight: maxSubscriptionsCount);
  final ConnectTimeoutChecker _timeoutChecker =
      ConnectTimeoutChecker(timeoutSeconds: timeout);
  final ReconnectionScheduler _reconnectionScheduler = ReconnectionScheduler();
  ConnectivityResult? _currentConnectivity;

  bool get isInitialized => _isInitialized;

  void configureDependencies({
    ConnectConnectivity? connectivity,
    RelaySocketConnector? socketConnector,
  }) {
    _connectivity = connectivity ?? _connectivity;
    _socketConnector = socketConnector ?? _socketConnector;
  }

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;
    startHeartBeat();
    await listenConnectivity();
  }

  void startHeartBeat() {
    if (timer == null || timer!.isActive == false) {
      timer = Timer.periodic(const Duration(seconds: 5), (Timer t) {
        _checkTimeout();
      });
    }
    resetConnection(force: false);
  }

  Future<void> resetConnection({bool force = true}) async {
    for (var relay in webSockets.keys) {
      if (webSockets[relay]?.connectStatus != 3 && force) {
        webSockets[relay]?.connectStatus = 3;
        await webSockets[relay]?.socket?.close();
      }
      for (var relayKind in webSockets[relay]?.relayKinds ?? []) {
        connect(relay, relayKind: relayKind);
      }
    }
  }

  Future<void> listenConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _currentConnectivity = results.isNotEmpty ? results.first : null;

    _connectivitySubscription ??= _connectivity.onConnectivityChanged
        .listen((List<ConnectivityResult> results) async {
      _currentConnectivity = results.isNotEmpty ? results.first : null;
      if (results.any((result) => result != ConnectivityResult.none)) {
        _reconnectionScheduler.resetAll();
        resetConnection(force: false);
      }
    });
  }

  bool _hasNetworkConnectivity() {
    return _currentConnectivity != null &&
        _currentConnectivity != ConnectivityResult.none;
  }

  // void _stopCheckTimeOut() {
  //   if (timer != null && timer!.isActive) {
  //     timer!.cancel();
  //   }
  // }

  void _checkTimeout() {
    _timeoutChecker.check(
      sendsMap: sendsMap,
      requestsMap: requestsMap,
      onOkTimeout: (ok, relay) => _handleOk(ok, relay),
      onRequestTimeout: (eose, relay) => _handleEOSE(eose, relay, true),
    );
  }

  void _setConnectStatus(String relay, int status) {
    webSockets[relay]?.connectStatus = status;
    _statusNotifier.notify(
      relay,
      status,
      webSockets[relay]?.relayKinds ?? [],
    );
  }

  ConnectStatusListenerHandle addConnectStatusListener(
      ConnectStatusCallBack callBack) {
    return _statusNotifier.add(callBack);
  }

  void removeConnectStatusListener(ConnectStatusCallBack callBack) {
    _statusNotifier.remove(callBack);
  }

  List<String> relays(
      {List<RelayKind> relayKinds = const [RelayKind.general]}) {
    List<String> result = [];
    for (var relay in webSockets.keys) {
      if (webSockets[relay]?.connectStatus == 1 &&
          webSockets[relay]!.relayKinds.any((e) => relayKinds.contains(e))) {
        result.add(relay);
      }
    }
    return result;
  }

  Future<void> connect(String relay,
      {RelayKind relayKind = RelayKind.general}) async {
    LogUtils.v(() => 'connect to $relay, kind: ${relayKind.name}');
    if (relay.isEmpty) return;
    if (!_isInitialized) {
      LogUtils.w(() =>
          'Connect used before init(); continuing without lifecycle watchers.');
    }

    List<RelayKind> relayKinds = webSockets[relay]?.relayKinds ?? [relayKind];
    if (!relayKinds.contains(relayKind)) {
      relayKinds.add(relayKind);
    }
    webSockets[relay]?.relayKinds = relayKinds;

    if (webSockets[relay]?.connectStatus == 0 ||
        webSockets[relay]?.connectStatus == 1) {
      return;
    }

    _reconnectionScheduler.resetRelay(relay);

    LogUtils.v(() => "connecting... $relay");
    webSockets[relay] = ISocket(null, 0, relayKinds);
    try {
      RelaySocket? socket;
      socket = await _connectWs(relay);
      if (socket != null) {
        socket.done.then((dynamic _) => _onDisconnected(relay, relayKind));
        _listenEvent(socket, relay, relayKind);
        webSockets[relay] = ISocket(socket, 1, relayKinds);
        LogUtils.v(() => "$relay connection initialized");
        _setConnectStatus(relay, 1);
        _reconnectionScheduler.recordSuccess(relay);
      }
    } catch (_) {
      _onDisconnected(relay, relayKind);
    }
  }

  Future<bool> connectRelays(List<String> relays,
      {RelayKind relayKind = RelayKind.general}) async {
    final completer = Completer<bool>();
    if (relays.isEmpty && !completer.isCompleted) completer.complete(true);
    if (relayKind == RelayKind.temp) {
      // timeout for temp relays
      Timer(const Duration(seconds: 10), () {
        if (!completer.isCompleted) {
          completer.complete(false);
          closeConnects(relays, relayKind);
        }
      });
    }
    for (String relay in relays) {
      connect(relay, relayKind: relayKind).then((value) {
        if (!completer.isCompleted) completer.complete(true);
      });
    }
    return completer.future;
  }

  Future closeConnects(List<String> relays, RelayKind relayKind) async {
    await Future.forEach(relays, (relay) async {
      webSockets[relay]
          ?.relayKinds
          .removeWhere((e) => (e == RelayKind.temp || e == relayKind));
      if (webSockets[relay]?.relayKinds.isEmpty == true) {
        await closeConnect(relay);
      }
    });
  }

  Future closeTempConnects(List<String> relays) async {
    await closeConnects(relays, RelayKind.temp);
  }

  Future closeAllConnects() async {
    // Cancel heartbeat timer
    timer?.cancel();
    timer = null;

    // Cancel connectivity subscription
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;

    _reconnectionScheduler.cancelAll();

    await Future.forEach(List.from(webSockets.keys), (relay) async {
      await closeConnect(relay);
    });

    // Clear all state
    sendsMap.clear();
    requestsMap.clear();
    _authState.clear();
    eventCheckerFutures.clear();
    _subscriptionQueue.clear();
    _currentConnectivity = null;
    _isInitialized = false;
  }

  Future closeConnect(String relay) async {
    LogUtils.v(() => 'closeConnect ${webSockets[relay]?.socket}');
    final socket = webSockets[relay]?.socket;

    webSockets.remove(relay);

    _reconnectionScheduler.cancelRelay(relay);

    await socket?.close();
  }

  String addSubscription(List<Filter> filters,
      {EventCallBack? eventCallBack,
      EOSECallBack? eoseCallBack,
      List<String>? relays,
      List<RelayKind> relayKinds = const [RelayKind.general],
      bool closeSubscription = true}) {
    Map<String, List<Filter>> result = {};
    List<String> rs = [];
    if (relays != null) {
      rs = List.from(relays
          .where((relay) =>
              relay.isNotEmpty &&
              (relay.startsWith('ws://') || relay.startsWith('wss://')))
          .toList());
    }
    List<String> subscriptionRelays = rs.isNotEmpty == true
        ? rs
        : Connect.sharedInstance.relays(relayKinds: relayKinds);
    if (subscriptionRelays.isEmpty) {
      eoseCallBack?.call('', OKEvent('', false, 'no relays connected'), '', []);
      return '';
    }
    for (var relay in subscriptionRelays) {
      result[relay] = filters;
    }
    return addSubscriptions(result,
        eventCallBack: eventCallBack,
        eoseCallBack: eoseCallBack,
        closeSubscription: closeSubscription);
  }

  String addSubscriptions(Map<String, List<Filter>> filters,
      {EventCallBack? eventCallBack,
      EOSECallBack? eoseCallBack,
      bool closeSubscription = true}) {
    /// Create a subscription message request with one or many filters
    String requestsId = generate64RandomHexChars();
    for (String relay in filters.keys) {
      Request requestWithFilter = Request(requestsId, filters[relay]!);
      String subscriptionString = requestWithFilter.serialize();

      /// add request to request map
      Requests requests = Requests(requestsId, filters.keys.toList(), 0, {},
          eventCallBack, eoseCallBack, subscriptionString, closeSubscription);
      requests.subscriptions[relay] = requestWithFilter.subscriptionId;
      requestsMap[requestWithFilter.subscriptionId + relay] = requests;

      /// Send a request message to the WebSocket server
      _addSubscriptionToQueue(requestsId, relay);

      LogUtils.v(() => '$subscriptionString, $relay');
    }
    return requestsId;
  }

  void _addSubscriptionToQueue(String subscriptionId, String relay) {
    _subscriptionQueue.add(subscriptionId, relay);
    _sendSubscription(relay);
  }

  void _sendSubscription(String relay) {
    final subscriptionId = _subscriptionQueue.takeNext(relay, requestsMap);
    if (subscriptionId != null) {
      var request = requestsMap[subscriptionId + relay];
      if (request != null) {
        requestsMap[subscriptionId + relay]!.requestTime =
            DateTime.now().millisecondsSinceEpoch;
        _send(request.subscriptionString, toRelays: [relay]);
      }
    } else {
      final sendingQueue = _subscriptionQueue.activeCount(relay, requestsMap);
      final waitingQueue = _subscriptionQueue.waitingCount(relay);
      LogUtils.v(() =>
          'sendingQueue: $sendingQueue, waitingQueue: $waitingQueue, $relay');
    }
  }

  Future _closeSubscription(String subscriptionId, String relay) async {
    LogUtils.v(() => 'send ${Close(subscriptionId).serialize()}, $relay');
    if (subscriptionId.isNotEmpty) {
      _send(Close(subscriptionId).serialize(), toRelays: [relay]);
      // remove the mapping
      requestsMap.remove(subscriptionId + relay);
      _sendSubscription(relay);
    }
  }

  Future closeRequests(String requestId, {String? relay}) async {
    Iterable<String> requestsMapKeys = List<String>.from(requestsMap.keys);
    for (var key in requestsMapKeys) {
      var requests = requestsMap[key];
      if (requests!.requestId == requestId) {
        if (relay != null) {
          if (requests.subscriptions[relay] != null) {
            await _closeSubscription(requests.subscriptions[relay]!, relay);
          }
        } else {
          for (var relay in relays()) {
            if (requests.subscriptions[relay] != null) {
              await _closeSubscription(requests.subscriptions[relay]!, relay);
            }
          }
        }
        return;
      }
    }
  }

  /// send an event to relay/relays
  void sendEvent(Event event,
      {OKCallBack? sendCallBack,
      List<String>? toRelays,
      List<RelayKind> relayKinds = const [
        RelayKind.general,
        RelayKind.outbox,
      ]}) {
    String eventString = event.serialize();
    List<String> rs = (toRelays == null || toRelays.isEmpty)
        ? relays(relayKinds: relayKinds)
        : List.from(toRelays);
    LogUtils.v(() =>
        'send event toRelays: ${jsonEncode(rs)}, eventString: $eventString');
    Sends sends = Sends(
        generate64RandomHexChars(),
        rs,
        DateTime.now().millisecondsSinceEpoch,
        event.id,
        sendCallBack,
        eventString);
    sendsMap[event.id] = sends;
    _send(eventString, toRelays: rs);
  }

  void _send(String data,
      {List<String>? toRelays, String? eventId, String? subscriptionId}) {
    if (toRelays != null && toRelays.isNotEmpty) {
      toRelays = Set.from(toRelays).cast<String>().toList();
      for (var relay in toRelays) {
        if (webSockets.containsKey(relay)) {
          var socket = webSockets[relay]?.socket;
          if (webSockets[relay]?.connectStatus == 1 && socket != null) {
            socket.add(data);
          } else if (eventId != null) {
            _handleOk(OKEvent(eventId, false, 'not connect to relay'), relay);
          } else if (subscriptionId != null) {
            _handleCLOSED(Closed(subscriptionId), relay);
          }
        } else if (eventId != null) {
          _handleOk(OKEvent(eventId, false, 'not connect to relay'), relay);
        } else if (subscriptionId != null) {
          _handleCLOSED(Closed(subscriptionId), relay);
        }
      }
    } else {
      webSockets.forEach((url, socket) {
        if (webSockets[url]?.connectStatus == 1 && socket.socket != null) {
          socket.socket?.add(data);
        } else if (eventId != null) {
          _handleOk(OKEvent(eventId, false, 'not connect to relay'), url);
        } else if (subscriptionId != null) {
          _handleCLOSED(Closed(subscriptionId), url);
        }
      });
    }
  }

  static Future<Message> _deserializeMessage(String message) async {
    return await Message.deserialize(message);
  }

  Future<void> _handleMessage(String message, String relay) async {
    var m = await ThreadPoolManager.sharedInstance
        .runOtherTask(() => _deserializeMessage(message));
    switch (m.type) {
      case "EVENT":
        _handleEvent(m.message, relay);
        break;
      case "EOSE":
        _handleEOSE(m.message, relay, false);
        break;
      case "CLOSED":
        _handleCLOSED(m.message, relay);
        break;
      case "NOTICE":
      case "NOTIFY":
        _handleNotice(m.message, relay);
        break;
      case "OK":
        _handleOk(m.message, relay);
        break;
      case "AUTH":
        _handleAuth(m.message, relay);
        break;
      default:
        LogUtils.v(() => 'Received message not supported: $message');
        break;
    }
  }

  Future<bool> _checkValidEvent(Event event, String relay) async {
    String? subscriptionId = event.subscriptionId;
    if (subscriptionId != null) {
      String requestsMapKey = subscriptionId + relay;
      if (subscriptionId.isNotEmpty &&
          requestsMap.containsKey(requestsMapKey)) {
        // reset requestTime
        requestsMap[requestsMapKey]!.requestTime =
            DateTime.now().millisecondsSinceEpoch;
        EventCallBack? callBack = requestsMap[requestsMapKey]!.eventCallBack;
        if (callBack != null) {
          EventCache.sharedInstance.receiveEvent(event, relay);
          // check sign
          if (await event.isValid() == false) {
            return false;
          }
          callBack(event, relay);
          return true;
        }
      }
    }
    return false;
  }

  Future<void> _handleEvent(Event event, String relay) async {
    LogUtils.v(() =>
        'Received event, subscriptionId: ${event.subscriptionId}, ${event.toJson()}');
    if (EventCache.sharedInstance.cacheIds.contains(event.id)) {
      return;
    }
    // ignore the expired event
    if (Nip40.expired(event)) {
      EventCache.sharedInstance.receiveEvent(event, relay);
      return;
    }

    Future<bool> future = _checkValidEvent(event, relay);
    if (event.subscriptionId != null && event.subscriptionId!.isNotEmpty) {
      eventCheckerFutures[event.subscriptionId! + relay] ??= [];
      eventCheckerFutures[event.subscriptionId! + relay]?.add(future);
    }
  }

  Future<void> _handleEOSE(String eose, String relay, bool timeout) async {
    LogUtils.v(() => 'receive EOSE: $eose, $relay, timeout: $timeout');
    String subscriptionId = jsonDecode(eose)[0];
    String requestsMapKey = subscriptionId + relay;
    if (subscriptionId.isNotEmpty && requestsMap.containsKey(requestsMapKey)) {
      if (eventCheckerFutures.containsKey(requestsMapKey)) {
        await Future.wait(eventCheckerFutures[requestsMapKey]!);
        eventCheckerFutures.remove(requestsMapKey);
      }
      _removeRequestsMapRelay(subscriptionId, relay, timeout);
    }
  }

  void _handleCLOSED(Closed closed, String relay) {
    LogUtils.v(() => 'receive closed: ${closed.serialize()}, $relay');
    String subscriptionId = closed.subscriptionId;
    String requestsMapKey = subscriptionId + relay;
    if (subscriptionId.isNotEmpty && requestsMap.containsKey(requestsMapKey)) {
      // check auth
      if (Nip42.authRequired(closed.message)) {
        String subscriptionString =
            requestsMap[requestsMapKey]!.subscriptionString;
        _authState.queueResend(relay, subscriptionString);
        _sendAuth(relay);
        return;
      }
      _removeRequestsMapRelay(subscriptionId, relay, true);
    }
  }

  void _handleNotice(String notice, String relay) {
    LogUtils.v(() => 'receive notice: $notice, $relay');
    String n = jsonDecode(notice)[0];

    List<String> requestsMapKeys =
        requestsMap.keys.where((element) => element.contains(relay)).toList();
    for (var requestsMapKey in requestsMapKeys) {
      _removeRequestsMapRelay(
          requestsMapKey.replaceAll(relay, ''), relay, true);
    }

    noticeCallBack?.call(n, relay);
  }

  Future<void> _handleOk(OKEvent ok, String relay) async {
    LogUtils.v(() => 'receive ok: ${ok.serialize()}, $relay');
    // check auth response
    if (_authState.isAuthResponse(ok, relay)) {
      for (var data in _authState.completeAuthResponse(ok, relay)) {
        LogUtils.v(() => 're-send: $data');
        _send(data, toRelays: [relay]);
      }
      return;
    }
    if (sendsMap.containsKey(ok.eventId)) {
      // check need auth
      if (!ok.status && Nip42.authRequired(ok.message)) {
        String eventString = sendsMap[ok.eventId]!.eventString;
        _authState.queueResend(relay, eventString);
        _sendAuth(relay);
        return;
      }
      // callback
      if (sendsMap[ok.eventId]!.okCallBack != null) {
        var relays = sendsMap[ok.eventId]!.relays;
        relays.remove(relay);
        if (ok.status || relays.isEmpty) {
          sendsMap[ok.eventId]!.okCallBack!(ok, relay);
          sendsMap.remove(ok.eventId);
        } else if (!ok.status && ok.eventId.isEmpty) {
          List<String> requestsMapKeys = requestsMap.keys
              .where((element) => element.contains(relay))
              .toList();
          for (var requestsMapKey in requestsMapKeys) {
            _removeRequestsMapRelay(
                requestsMapKey.replaceAll(relay, ''), relay, true);
          }
        }
      } else {
        var relays = sendsMap[ok.eventId]!.relays;
        relays.remove(relay);
        if (relays.isEmpty) sendsMap.remove(ok.eventId);
      }
    }
  }

  void _handleAuth(Auth auth, String relay) {
    LogUtils.v(() => 'receive auth: ${auth.challenge}');
    _authState.registerChallenge(auth, relay);
  }

  void _removeRequestsMapRelay(
      String subscriptionId, String removeRelay, bool error) {
    var requestsMapKey = subscriptionId + removeRelay;
    var request = requestsMap[requestsMapKey];
    if (request == null) return;
    request.relays.remove(removeRelay);
    // remove others relay
    for (var r in requestsMap.values) {
      if (r.requestId == request.requestId) {
        r.relays.remove(removeRelay);
      }
    }
    // all relays have EOSE
    EOSECallBack? callBack = request.eoseCallBack;
    OKEvent ok = OKEvent(subscriptionId, !error, '');
    if (callBack != null) {
      callBack(subscriptionId, ok, removeRelay, request.relays);
    }
    requestsMap[requestsMapKey]?.eoseCallBack = null;
    if (request.closeSubscription) {
      _closeSubscription(subscriptionId, removeRelay);
    }
  }

  Future<void> _sendAuth(String relay) async {
    String? challenge = _authState.challengeFor(relay);
    if (challenge == null || challenge.isEmpty) return;
    if (!_authState.markSending(relay)) return;
    Event event = await Nip42.encode(
        challenge,
        relay,
        Account.sharedInstance.currentPubkey,
        Account.sharedInstance.currentPrivkey);
    var authJson = Nip42.authString(event);
    _authState.markSent(relay, event.id);
    LogUtils.v(() => 'send auth: $authJson');
    _send(authJson, toRelays: [relay]);
  }

  Future<void> _reConnectToRelay(String relay, RelayKind relayKind) async {
    _setConnectStatus(relay, 3);

    _reconnectionScheduler.schedule(
      relay: relay,
      hasNetworkConnectivity: _hasNetworkConnectivity(),
      isRelayManaged: () => webSockets.containsKey(relay),
      reconnect: () {
        connect(relay, relayKind: relayKind);
      },
    );
  }

  void _listenEvent(RelaySocket socket, String relay, RelayKind relayKind) {
    socket.listen((message) async {
      await _handleMessage(message, relay);
    }, onDone: () async {
      LogUtils.v(() => "connect aborted");
      await _reConnectToRelay(relay, relayKind);
    }, onError: (e) async {
      LogUtils.v(() => 'Server error: $e');
      await _reConnectToRelay(relay, relayKind);
    });
  }

  Future<RelaySocket?> _connectWs(String relay) async {
    try {
      _setConnectStatus(relay, 0);
      return await _connectWsSetting(relay);
    } catch (e) {
      LogUtils.v(() => "Error! can not connect WS connectWs $e relay:$relay");
      _setConnectStatus(relay, 3);

      List<RelayKind>? relayKinds = webSockets[relay]?.relayKinds;
      bool hasNonTempKind =
          relayKinds?.any((kind) => kind != RelayKind.temp) ?? false;
      if (hasNonTempKind && webSockets.containsKey(relay)) {
        final relayKind = relayKinds?.firstWhere(
              (kind) => kind != RelayKind.temp,
              orElse: () => RelayKind.general,
            ) ??
            RelayKind.general;
        _reConnectToRelay(relay, relayKind);
      }
      return null;
    }
  }

  Future<RelaySocket> _connectWsSetting(String relay) async {
    try {
      return await _socketConnector.connect(
        relay,
        timeout: const Duration(seconds: connectionTimeout),
      );
    } on TimeoutException catch (e) {
      LogUtils.v(() => 'WebSocket connection timeout for $relay');
      throw TimeoutException(e.message, e.duration);
    }
  }

  Future<void> _onDisconnected(String relay, RelayKind relayKind) async {
    LogUtils.v(() => "_onDisconnected");
    return await _reConnectToRelay(relay, relayKind);
  }
}
