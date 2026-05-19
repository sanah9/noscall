import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/services.dart';

class ThreadPoolManager {
  Isolate? _databaseIsolate;
  Isolate? _algorithmIsolate;
  Isolate? _otherIsolate;
  SendPort? _databaseSendPort;
  SendPort? _algorithmSendPort;
  SendPort? _otherSendPort;
  final RootIsolateToken _rootIsolateToken;
  bool _isInitialized = false;

  /// singleton
  ThreadPoolManager._internal(this._rootIsolateToken);
  factory ThreadPoolManager() => sharedInstance;
  static final ThreadPoolManager sharedInstance =
      ThreadPoolManager._internal(RootIsolateToken.instance!);

  Future<void> initialize() async {
    if (_isInitialized) return;
    _databaseSendPort = await _createIsolate((sendPort) {
      _databaseIsolate = sendPort.isolate;
      return sendPort.sendPort;
    });
    _algorithmSendPort = await _createIsolate((sendPort) {
      _algorithmIsolate = sendPort.isolate;
      return sendPort.sendPort;
    });
    _otherSendPort = await _createIsolate((sendPort) {
      _otherIsolate = sendPort.isolate;
      return sendPort.sendPort;
    });
    _isInitialized = true;
  }

  Future<SendPort> _createIsolate(Function(IsolateConfig) isolateConfig) async {
    final receivePort = ReceivePort();
    final isolate = await Isolate.spawn(_isolateEntry, receivePort.sendPort);
    final sendPort = await receivePort.first as SendPort;
    isolateConfig(IsolateConfig(isolate, sendPort));
    return sendPort;
  }

  Future<dynamic> _runTask(
      Future<dynamic> Function() task, SendPort sendPort) async {
    final completer = Completer<dynamic>();
    final port = ReceivePort();
    sendPort.send([task, port.sendPort, _rootIsolateToken]);
    port.listen((message) {
      port.close(); // Close the port once the task is completed
      completer.complete(message);
    });
    return completer.future;
  }

  Future<dynamic> runDatabaseTask(Future<dynamic> Function() task) {
    return _runTask(task, _requireSendPort(_databaseSendPort, 'database'));
  }

  Future<dynamic> runAlgorithmTask(Future<dynamic> Function() task) {
    return _runTask(task, _requireSendPort(_algorithmSendPort, 'algorithm'));
  }

  Future<dynamic> runOtherTask(Future<dynamic> Function() task) {
    return _runTask(task, _requireSendPort(_otherSendPort, 'other'));
  }

  SendPort _requireSendPort(SendPort? sendPort, String name) {
    if (sendPort == null) {
      throw StateError('ThreadPoolManager $name isolate is not initialized');
    }
    return sendPort;
  }

  void dispose() {
    _databaseIsolate?.kill(priority: Isolate.immediate);
    _algorithmIsolate?.kill(priority: Isolate.immediate);
    _otherIsolate?.kill(priority: Isolate.immediate);
    _databaseIsolate = null;
    _algorithmIsolate = null;
    _otherIsolate = null;
    _databaseSendPort = null;
    _algorithmSendPort = null;
    _otherSendPort = null;
    _isInitialized = false;
  }
}

class IsolateConfig {
  Isolate isolate;
  SendPort sendPort;
  IsolateConfig(this.isolate, this.sendPort);
}

void _isolateEntry(SendPort sendPort) {
  final port = ReceivePort();
  sendPort.send(port.sendPort);
  port.listen((message) async {
    if (message is List && message.length == 3) {
      final task = message[0] as Future Function();
      final replyPort = message[1] as SendPort;
      final rootIsolateToken = message[2] as RootIsolateToken;
      try {
        // Attach root isolate token to the current isolate
        BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
        final result = await task();
        replyPort.send(result);
      } catch (e, stackTrace) {
        stderr.writeln('_isolateEntry Error: $e\n$stackTrace');
        replyPort.send("Error: $e");
      }
    }
  });
}
