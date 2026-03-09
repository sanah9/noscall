import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:noscall/core/call/messages/model/messageDB_isar.dart';
import 'package:noscall/voice_messages/send_voice_message_page.dart';
import 'package:noscall/voice_messages/voice_message_detail_page.dart';

/// Voice message routes.
List<RouteBase> get voiceRoutes => [
      GoRoute(
        path: '/voice-message-detail',
        name: 'voice-message-detail',
        builder: (context, state) {
          final params = state.extra as Map? ?? {};
          final message = params['message'] as MessageDBISAR?;
          if (message == null) {
            return const Scaffold(
              body: Center(child: Text('Message not found')),
            );
          }
          return VoiceMessageDetailPage(message: message);
        },
      ),
      GoRoute(
        path: '/send-voice-message',
        name: 'send-voice-message',
        builder: (context, state) {
          final params = state.extra as Map? ?? {};
          final receiverPubkey = params['receiverPubkey'] as String? ?? '';
          return SendVoiceMessagePage(receiverPubkey: receiverPubkey);
        },
      ),
    ];
