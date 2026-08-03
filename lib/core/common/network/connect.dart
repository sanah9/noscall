import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'package:nostr_core_dart/nostr.dart';

import 'package:noscall/core/common/utils/log_utils.dart';
import 'connect_auth_sender.dart';
import 'connect_auth_state.dart';
import 'connect_connection_manager.dart';
import 'connect_dependencies.dart';
import 'connect_event_processor.dart';
import 'connect_lifecycle.dart';
import 'connect_message_router.dart';
import 'connect_ok_handler.dart';
import 'connect_relay_sender.dart';
import 'connect_request_completion_handler.dart';
import 'connect_request_tracker.dart';
import 'connect_send_tracker.dart';
import 'connect_socket_registry.dart';
import 'connect_status_notifier.dart';
import 'connect_subscription_dispatcher.dart';
import 'connect_subscription_planner.dart';
import 'connect_subscription_queue.dart';
import 'connect_timeout_checker.dart';
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
  late final ConnectAuthSender _authSender = ConnectAuthSender(
    authState: _authState,
  );
  late final ConnectConnectionManager _connectionManager =
      ConnectConnectionManager(
        socketRegistry: _socketRegistry,
        reconnectionScheduler: _reconnectionScheduler,
        socketConnector: () => _socketConnector,
        hasNetworkConnectivity: _hasNetworkConnectivity,
        setConnectStatus: _setConnectStatus,
        handleMessage: _handleMessage,
        connectionTimeoutSeconds: connectionTimeout,
      );
  final ConnectEventProcessor _eventProcessor = ConnectEventProcessor();
  final ConnectLifecycle _lifecycle = ConnectLifecycle();
  final ConnectMessageRouter _messageRouter = ConnectMessageRouter();
  late final ConnectOkHandler _okHandler = ConnectOkHandler(
    authState: _authState,
    sendTracker: _sendTracker,
  );
  final ConnectRelaySender _relaySender = ConnectRelaySender();
  late final ConnectRequestCompletionHandler _requestCompletionHandler =
      ConnectRequestCompletionHandler(
        requestTracker: _requestTracker,
        authState: _authState,
      );
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
    await _connectionManager.resetConnection(force: force);
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
    await _connectionManager.connect(
      relay,
      relayKind: relayKind,
      isInitialized: _isInitialized,
    );
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
    await _connectionManager.closeConnects(relays, relayKind);
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
    await _connectionManager.closeConnect(relay);
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

  Future<void> _handleEvent(Event event, String relay) async {
    await _eventProcessor.handle(event, relay, requestTracker: _requestTracker);
  }

  Future<void> _handleEOSE(String eose, String relay, bool timeout) async {
    await _requestCompletionHandler.handleEose(
      eose,
      relay,
      timeout,
      closeSubscription: _closeSubscription,
    );
  }

  Future<void> _handleCLOSED(Closed closed, String relay) async {
    await _requestCompletionHandler.handleClosed(
      closed,
      relay,
      closeSubscription: _closeSubscription,
      sendAuth: _sendAuth,
    );
  }

  Future<void> _handleNotice(String notice, String relay) async {
    await _requestCompletionHandler.handleNotice(
      notice,
      relay,
      noticeCallBack: noticeCallBack,
      closeSubscription: _closeSubscription,
    );
  }

  Future<void> _handleOk(OKEvent ok, String relay) async {
    await _okHandler.handle(
      ok,
      relay,
      send: _sendToRelays,
      sendAuth: _sendAuth,
      completeRelayRequests: (relay) => _requestCompletionHandler
          .completeAllForRelay(relay, closeSubscription: _closeSubscription),
    );
  }

  void _handleAuth(Auth auth, String relay) {
    LogUtils.v(() => 'receive auth: ${auth.challenge}');
    _authState.registerChallenge(auth, relay);
  }

  Future<void> _sendAuth(String relay) async {
    await _authSender.sendAuth(relay, send: _sendToRelays);
  }
}
