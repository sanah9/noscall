import 'dart:async';

import 'package:nostr_core_dart/nostr.dart';

import 'package:noscall/core/common/thread/thread_pool_manager.dart';
import 'package:noscall/core/common/utils/log_utils.dart';

typedef NostrMessageDeserializer = Future<Message> Function(String message);
typedef UnsupportedMessageHandler = void Function(String message);

class ConnectMessageRouter {
  ConnectMessageRouter({NostrMessageDeserializer? deserializeMessage})
    : _deserializeMessage = deserializeMessage ?? _deserializeOnWorker;

  final NostrMessageDeserializer _deserializeMessage;

  Future<void> route(
    String message,
    String relay, {
    required FutureOr<void> Function(Event event, String relay) onEvent,
    required FutureOr<void> Function(String eose, String relay, bool timeout)
    onEose,
    required FutureOr<void> Function(Closed closed, String relay) onClosed,
    required FutureOr<void> Function(String notice, String relay) onNotice,
    required FutureOr<void> Function(OKEvent ok, String relay) onOk,
    required FutureOr<void> Function(Auth auth, String relay) onAuth,
    UnsupportedMessageHandler? onUnsupported,
  }) async {
    final nostrMessage = await _deserializeMessage(message);
    switch (nostrMessage.type) {
      case 'EVENT':
        await onEvent(nostrMessage.message, relay);
        break;
      case 'EOSE':
        await onEose(nostrMessage.message, relay, false);
        break;
      case 'CLOSED':
        await onClosed(nostrMessage.message, relay);
        break;
      case 'NOTICE':
      case 'NOTIFY':
        await onNotice(nostrMessage.message, relay);
        break;
      case 'OK':
        await onOk(nostrMessage.message, relay);
        break;
      case 'AUTH':
        await onAuth(nostrMessage.message, relay);
        break;
      default:
        if (onUnsupported != null) {
          onUnsupported(message);
        } else {
          LogUtils.v(() => 'Received message not supported: $message');
        }
        break;
    }
  }

  static Future<Message> _deserializeOnWorker(String message) async {
    final nostrMessage = await ThreadPoolManager.sharedInstance.runOtherTask(
      () => Message.deserialize(message),
    );
    return nostrMessage as Message;
  }
}
