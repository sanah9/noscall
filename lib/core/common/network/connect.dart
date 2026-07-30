import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'package:nostr_core_dart/nostr.dart';

import 'package:noscall/core/account/account.dart';
import 'package:noscall/core/common/utils/log_utils.dart';
import 'connect_auth_state.dart';
import 'connect_dependencies.dart';
import 'connect_lifecycle.dart';
import 'connect_message_router.dart';
import 'connect_relay_sender.dart';
import 'connect_request_tracker.dart';
import 'connect_send_tracker.dart';
import 'connect_socket_registry.dart';
import 'connect_status_notifier.dart';
import 'connect_subscription_dispatcher.dart';
import 'connect_subscription_planner.dart';
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

  /// sockets
  Map<String, ISocket> get webSockets => _socketRegistry.sockets;

  Map<String, Requests> get requestsMap => _requestTracker.requests;
  Map<String, Sends> get sendsMap => _sendTracker.sends;
  List<ConnectStatusCallBack> get connectStatusListeners =>
      _statusNotifier.listeners;
  // for timeout
  Timer? get timer => _lifecycle.timer;
  Map<String, AuthData> get auths => _authState.auths;

  Map<String, List<Future<bool>>> get eventCheckerFutures =>
      _requestTracker.eventChecks;

  Map<String, List<String>> get subscriptionsWaitingQueue =>
      _subscriptionQueue.waitingByRelay;

  final ConnectAuthState _authState = ConnectAuthState();
  final ConnectLifecycle _lifecycle = ConnectLifecycle();
  final ConnectMessageRouter _messageRouter = ConnectMessageRouter();
  final ConnectRelaySender _relaySender = ConnectRelaySender();
  final ConnectRequestTracker _requestTracker = ConnectRequestTracker();
  final ConnectSendTracker _sendTracker = ConnectSendTracker();
  final ConnectSocketRegistry _socketRegistry = ConnectSocketRegistry();
  final ConnectStatusNotifier _statusNotifier = ConnectStatusNotifier();
  final ConnectSubscriptionPlanner _subscriptionPlanner =
      ConnectSubscriptionPlanner();
  final ConnectSubscriptionQueue _subscriptionQueue = ConnectSubscriptionQueue(
    maxInFlight: maxSubscriptionsCount,
  );
  late final ConnectSubscriptionDispatcher _subscriptionDispatcher =
      ConnectSubscriptionDispatcher(
        requestTracker: _requestTracker,
        subscriptionQueue: _subscriptionQueue,
      );
  final ConnectTimeoutChecker _timeoutChecker = ConnectTimeoutChecker(
    timeoutSeconds: timeout,
  );
  final ReconnectionScheduler _reconnectionScheduler = ReconnectionScheduler();

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
    _lifecycle.startHeartbeat(
      onTimeoutCheck: _checkTimeout,
      onResetConnection: () => resetConnection(force: false),
    );
  }

  Future<void> resetConnection({bool force = true}) async {
    for (final relay in List<String>.from(_socketRegistry.relays)) {
      if (webSockets[relay]?.connectStatus != 3 && force) {
        _socketRegistry.setStatus(relay, 3);
        await _socketRegistry.socketFor(relay)?.close();
      }
      for (final relayKind in _socketRegistry.relayKindsFor(relay)) {
        connect(relay, relayKind: relayKind);
      }
    }
  }

  Future<void> listenConnectivity() async {
    await _lifecycle.listenConnectivity(
      _connectivity,
      onNetworkAvailable: () {
        _reconnectionScheduler.resetAll();
        resetConnection(force: false);
      },
    );
  }

  bool _hasNetworkConnectivity() {
    return _lifecycle.hasNetworkConnectivity;
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
    _socketRegistry.setStatus(relay, status);
    _statusNotifier.notify(relay, status, _socketRegistry.relayKindsFor(relay));
  }

  ConnectStatusListenerHandle addConnectStatusListener(
    ConnectStatusCallBack callBack,
  ) {
    return _statusNotifier.add(callBack);
  }

  void removeConnectStatusListener(ConnectStatusCallBack callBack) {
    _statusNotifier.remove(callBack);
  }

  List<String> relays({
    List<RelayKind> relayKinds = const [RelayKind.general],
  }) {
    return _socketRegistry.connectedRelays(relayKinds);
  }

  Future<void> connect(
    String relay, {
    RelayKind relayKind = RelayKind.general,
  }) async {
    LogUtils.v(() => 'connect to $relay, kind: ${relayKind.name}');
    if (relay.isEmpty) return;
    if (!_isInitialized) {
      LogUtils.w(
        () =>
            'Connect used before init(); continuing without lifecycle watchers.',
      );
    }

    final relayKinds = _socketRegistry.mergeRelayKind(relay, relayKind);

    if (_socketRegistry.isConnectingOrOpen(relay)) {
      return;
    }

    _reconnectionScheduler.resetRelay(relay);

    LogUtils.v(() => "connecting... $relay");
    _socketRegistry.markConnecting(relay, relayKinds);
    try {
      RelaySocket? socket;
      socket = await _connectWs(relay);
      if (socket != null) {
        socket.done.then((dynamic _) => _onDisconnected(relay, relayKind));
        _listenEvent(socket, relay, relayKind);
        _socketRegistry.markOpen(relay, socket, relayKinds);
        LogUtils.v(() => "$relay connection initialized");
        _setConnectStatus(relay, 1);
        _reconnectionScheduler.recordSuccess(relay);
      }
    } catch (_) {
      _onDisconnected(relay, relayKind);
    }
  }

  Future<bool> connectRelays(
    List<String> relays, {
    RelayKind relayKind = RelayKind.general,
  }) async {
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
      final relayKinds = _socketRegistry.removeRelayKind(relay, relayKind);
      if (_socketRegistry.contains(relay) && relayKinds.isEmpty) {
        await closeConnect(relay);
      }
    });
  }

  Future closeTempConnects(List<String> relays) async {
    await closeConnects(relays, RelayKind.temp);
  }

  Future closeAllConnects() async {
    await _lifecycle.stop();

    _reconnectionScheduler.cancelAll();

    await Future.forEach(List<String>.from(_socketRegistry.relays), (
      relay,
    ) async {
      await closeConnect(relay);
    });

    // Clear all state
    _sendTracker.clear();
    _requestTracker.clear();
    _authState.clear();
    _subscriptionQueue.clear();
    _isInitialized = false;
  }

  Future closeConnect(String relay) async {
    LogUtils.v(() => 'closeConnect ${webSockets[relay]?.socket}');
    final socket = _socketRegistry.remove(relay);

    _reconnectionScheduler.cancelRelay(relay);

    await socket?.close();
  }

  String addSubscription(
    List<Filter> filters, {
    EventCallBack? eventCallBack,
    EOSECallBack? eoseCallBack,
    List<String>? relays,
    List<RelayKind> relayKinds = const [RelayKind.general],
    bool closeSubscription = true,
  }) {
    final plan = _subscriptionPlanner.plan(
      filters,
      explicitRelays: relays,
      connectedRelays: this.relays(relayKinds: relayKinds),
    );
    if (plan.isEmpty) {
      eoseCallBack?.call('', OKEvent('', false, 'no relays connected'), '', []);
      return '';
    }
    return addSubscriptions(
      plan.filtersByRelay,
      eventCallBack: eventCallBack,
      eoseCallBack: eoseCallBack,
      closeSubscription: closeSubscription,
    );
  }

  String addSubscriptions(
    Map<String, List<Filter>> filters, {
    EventCallBack? eventCallBack,
    EOSECallBack? eoseCallBack,
    bool closeSubscription = true,
  }) {
    return _requestTracker.addSubscriptions(
      filters,
      eventCallBack: eventCallBack,
      eoseCallBack: eoseCallBack,
      closeSubscription: closeSubscription,
      onSubscription: (requestId, relay, subscriptionString) {
        _subscriptionDispatcher.enqueue(
          requestId,
          relay,
          requestsMap: requestsMap,
          send: _sendToRelays,
          onIdle: _logSubscriptionQueueState,
        );
        LogUtils.v(() => '$subscriptionString, $relay');
      },
    );
  }

  void _sendToRelays(String data, List<String> relays) {
    _send(data, toRelays: relays);
  }

  void _logSubscriptionQueueState(
    int sendingQueue,
    int waitingQueue,
    String relay,
  ) {
    LogUtils.v(
      () => 'sendingQueue: $sendingQueue, waitingQueue: $waitingQueue, $relay',
    );
  }

  Future _closeSubscription(String subscriptionId, String relay) async {
    LogUtils.v(() => 'send ${Close(subscriptionId).serialize()}, $relay');
    _subscriptionDispatcher.close(
      subscriptionId,
      relay,
      requestsMap: requestsMap,
      send: _sendToRelays,
      onIdle: _logSubscriptionQueueState,
    );
  }

  Future closeRequests(String requestId, {String? relay}) async {
    final targets = _requestTracker.closeTargets(
      requestId,
      relay: relay,
      connectedRelays: relays(),
    );
    for (final target in targets) {
      await _closeSubscription(target.subscriptionId, target.relay);
    }
  }

  /// send an event to relay/relays
  void sendEvent(
    Event event, {
    OKCallBack? sendCallBack,
    List<String>? toRelays,
    List<RelayKind> relayKinds = const [RelayKind.general, RelayKind.outbox],
  }) {
    String eventString = event.serialize();
    List<String> rs = (toRelays == null || toRelays.isEmpty)
        ? relays(relayKinds: relayKinds)
        : List.from(toRelays);
    LogUtils.v(
      () => 'send event toRelays: ${jsonEncode(rs)}, eventString: $eventString',
    );
    _sendTracker.trackEvent(
      eventId: event.id,
      eventString: eventString,
      relays: rs,
      okCallBack: sendCallBack,
    );
    _send(eventString, toRelays: rs);
  }

  void _send(
    String data, {
    List<String>? toRelays,
    String? eventId,
    String? subscriptionId,
  }) {
    _relaySender.send(
      data,
      socketRegistry: _socketRegistry,
      onOkFailure: (ok, relay) => _handleOk(ok, relay),
      onClosed: (closed, relay) => _handleCLOSED(closed, relay),
      toRelays: toRelays,
      eventId: eventId,
      subscriptionId: subscriptionId,
    );
  }

  Future<void> _handleMessage(String message, String relay) async {
    await _messageRouter.route(
      message,
      relay,
      onEvent: (event, relay) => _handleEvent(event, relay),
      onEose: (eose, relay, timeout) => _handleEOSE(eose, relay, timeout),
      onClosed: (closed, relay) => _handleCLOSED(closed, relay),
      onNotice: (notice, relay) => _handleNotice(notice, relay),
      onOk: (ok, relay) => _handleOk(ok, relay),
      onAuth: (auth, relay) => _handleAuth(auth, relay),
      onUnsupported: (message) {
        LogUtils.v(() => 'Received message not supported: $message');
      },
    );
  }

  Future<bool> _checkValidEvent(Event event, String relay) async {
    return _requestTracker.checkValidEvent(event, relay);
  }

  Future<void> _handleEvent(Event event, String relay) async {
    LogUtils.v(
      () =>
          'Received event, subscriptionId: ${event.subscriptionId}, ${event.toJson()}',
    );
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
      _requestTracker.trackEventCheck(event.subscriptionId!, relay, future);
    }
  }

  Future<void> _handleEOSE(String eose, String relay, bool timeout) async {
    LogUtils.v(() => 'receive EOSE: $eose, $relay, timeout: $timeout');
    String subscriptionId = _requestTracker.requestIdFromEose(eose);
    if (_requestTracker.containsSubscription(subscriptionId, relay)) {
      await _requestTracker.waitForEventChecks(subscriptionId, relay);
      _removeRequestsMapRelay(subscriptionId, relay, timeout);
    }
  }

  void _handleCLOSED(Closed closed, String relay) {
    LogUtils.v(() => 'receive closed: ${closed.serialize()}, $relay');
    String subscriptionId = closed.subscriptionId;
    if (_requestTracker.containsSubscription(subscriptionId, relay)) {
      // check auth
      if (Nip42.authRequired(closed.message)) {
        final subscriptionString = _requestTracker.subscriptionStringFor(
          subscriptionId,
          relay,
        );
        if (subscriptionString != null) {
          _authState.queueResend(relay, subscriptionString);
        }
        _sendAuth(relay);
        return;
      }
      _removeRequestsMapRelay(subscriptionId, relay, true);
    }
  }

  void _handleNotice(String notice, String relay) {
    LogUtils.v(() => 'receive notice: $notice, $relay');
    String n = jsonDecode(notice)[0];

    _removeRequestsForRelay(relay);

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
    final sendResult = _sendTracker.handleOk(ok, relay);
    final authEventString = sendResult.authRequiredEventString;
    if (authEventString != null) {
      _authState.queueResend(relay, authEventString);
      _sendAuth(relay);
      return;
    }
    final failedRelay = sendResult.failedRelayForRequests;
    if (failedRelay != null) {
      _removeRequestsForRelay(failedRelay);
    }
  }

  void _handleAuth(Auth auth, String relay) {
    LogUtils.v(() => 'receive auth: ${auth.challenge}');
    _authState.registerChallenge(auth, relay);
  }

  void _removeRequestsMapRelay(
    String subscriptionId,
    String removeRelay,
    bool error,
  ) {
    final closeSubscription = _requestTracker.completeRelay(
      subscriptionId,
      removeRelay,
      error,
    );
    if (closeSubscription) {
      _closeSubscription(subscriptionId, removeRelay);
    }
  }

  void _removeRequestsForRelay(String relay) {
    for (final subscriptionId in _requestTracker.subscriptionIdsForRelay(
      relay,
    )) {
      _removeRequestsMapRelay(subscriptionId, relay, true);
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
      Account.sharedInstance.currentPrivkey,
    );
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
      isRelayManaged: () => _socketRegistry.contains(relay),
      reconnect: () {
        connect(relay, relayKind: relayKind);
      },
    );
  }

  void _listenEvent(RelaySocket socket, String relay, RelayKind relayKind) {
    socket.listen(
      (message) async {
        await _handleMessage(message, relay);
      },
      onDone: () async {
        LogUtils.v(() => "connect aborted");
        await _reConnectToRelay(relay, relayKind);
      },
      onError: (e) async {
        LogUtils.v(() => 'Server error: $e');
        await _reConnectToRelay(relay, relayKind);
      },
    );
  }

  Future<RelaySocket?> _connectWs(String relay) async {
    try {
      _setConnectStatus(relay, 0);
      return await _connectWsSetting(relay);
    } catch (e) {
      LogUtils.v(() => "Error! can not connect WS connectWs $e relay:$relay");
      _setConnectStatus(relay, 3);

      final relayKind = _socketRegistry.firstPersistentKind(relay);
      if (relayKind != null && _socketRegistry.contains(relay)) {
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
