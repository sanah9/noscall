import 'dart:async';
import 'dart:convert';
import 'package:noscall/core/call/contacts/contacts_isolate_event.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:isar/isar.dart';

import 'package:noscall/core/account/model/user_db_isar.dart';
import 'package:noscall/core/common/thread/thread_pool_manager.dart';
import 'package:noscall/core/call/contacts/contacts.dart';

part 'message_db_isar.g.dart';

enum MessageType { unknown, call, voice }

extension MessageDBISARExtensions on MessageDBISAR {
  MessageDBISAR withGrowableLevels() => this
    ..reportList = reportList?.toList()
    ..reactionEventIds = reactionEventIds?.toList()
    ..zapEventIds = zapEventIds?.toList();
}

@collection
class MessageDBISAR {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  String messageId; //event id

  String sender; // pubkey
  String receiver; // friend pubkey
  String groupId; // channel or group id
  String sessionId; // secret chat id
  int kind;
  String tags;
  String content; // content
  int createTime;
  bool read;
  String replyId;

  // additional,
  String decryptContent;
  String type;
  int? status; // 0 sending, 1 sent, 2 fail 3 recall

  List<String>? reportList; // hide message ids list, not save to DB

  String plaintEvent;

  /// add type
  int?
  chatType; // 0 private chat 1 group chat 2 channel chat 3 secret chat 4 relay group chat 5 ble channel chat 6 ble private chat
  String? subType; // subtype of template/system type

  /// add previewData
  String? previewData;

  /// add disappearing time
  int? expiration;

  /// add decryptSecret
  String? decryptSecret;
  String? decryptNonce;
  String? decryptAlgo;
  // actions
  List<String>? reactionEventIds;
  List<String>? zapEventIds;

  MessageDBISAR({
    this.messageId = '',
    this.sender = '',
    this.receiver = '',
    this.groupId = '',
    this.sessionId = '',
    this.kind = 0,
    this.tags = '',
    this.content = '',
    this.createTime = 0,
    this.read = false,
    this.replyId = '',
    this.decryptContent = '',
    this.type = 'text',
    this.status = 1,
    this.plaintEvent = '',
    this.chatType,
    this.subType,
    this.previewData,
    this.expiration,
    this.decryptSecret,
    this.decryptNonce,
    this.decryptAlgo,
    this.reactionEventIds,
    this.zapEventIds,
  });

  /// Copy with optional overrides. Used e.g. for marking read without duplicating all fields.
  MessageDBISAR copyWith({
    int? id,
    String? messageId,
    String? sender,
    String? receiver,
    String? groupId,
    String? sessionId,
    int? kind,
    String? tags,
    String? content,
    int? createTime,
    bool? read,
    String? replyId,
    String? decryptContent,
    String? type,
    int? status,
    List<String>? reportList,
    String? plaintEvent,
    int? chatType,
    String? subType,
    String? previewData,
    int? expiration,
    String? decryptSecret,
    String? decryptNonce,
    String? decryptAlgo,
    List<String>? reactionEventIds,
    List<String>? zapEventIds,
  }) {
    return MessageDBISAR(
        messageId: messageId ?? this.messageId,
        sender: sender ?? this.sender,
        receiver: receiver ?? this.receiver,
        groupId: groupId ?? this.groupId,
        sessionId: sessionId ?? this.sessionId,
        kind: kind ?? this.kind,
        tags: tags ?? this.tags,
        content: content ?? this.content,
        createTime: createTime ?? this.createTime,
        read: read ?? this.read,
        replyId: replyId ?? this.replyId,
        decryptContent: decryptContent ?? this.decryptContent,
        type: type ?? this.type,
        status: status ?? this.status,
        plaintEvent: plaintEvent ?? this.plaintEvent,
        chatType: chatType ?? this.chatType,
        subType: subType ?? this.subType,
        previewData: previewData ?? this.previewData,
        expiration: expiration ?? this.expiration,
        decryptSecret: decryptSecret ?? this.decryptSecret,
        decryptNonce: decryptNonce ?? this.decryptNonce,
        decryptAlgo: decryptAlgo ?? this.decryptAlgo,
        reactionEventIds: reactionEventIds ?? this.reactionEventIds,
        zapEventIds: zapEventIds ?? this.zapEventIds,
      )
      ..id = id ?? this.id
      ..reportList = reportList ?? this.reportList;
  }

  static MessageDBISAR fromMap(Map<String, Object?> map) {
    return _messageInfoFromMap(map);
  }

  static String messageTypeToString(MessageType type) {
    switch (type) {
      case MessageType.call:
        return 'call';
      case MessageType.voice:
        return 'voice';
      default:
        return 'unknown';
    }
  }

  static MessageType stringtoMessageType(String type) {
    switch (type) {
      case 'call':
        return MessageType.call;
      case 'voice':
        return MessageType.voice;
      default:
        return MessageType.unknown;
    }
  }

  static bool isImageBase64(String str) {
    const base64Pattern = r'^data:image\/[a-zA-Z0-9\+\-\.]+;base64,';
    if (RegExp(base64Pattern).hasMatch(str)) {
      final base64Data = str.split(',').last;
      return _isValidBase64(base64Data);
    }
    return false;
  }

  static bool _isValidBase64(String str) {
    final base64RegExp = RegExp(r'^[A-Za-z0-9+/]+={0,2}$');
    return base64RegExp.hasMatch(str);
  }

  static Future<Map<String, dynamic>> decodeContent(String content) async {
    var result = await ThreadPoolManager.sharedInstance.runOtherTask(
      () => _decodeContentInIsolate(content),
    );
    return result;
  }

  static Future<Map<String, dynamic>> _decodeContentInIsolate(
    String content,
  ) async {
    content = content.trim();
    try {
      Map<String, dynamic> map = jsonDecode(content) as Map<String, dynamic>;
      if (map.containsKey('contentType') && map.containsKey('content')) {
        String type = map['contentType'];
        if (type == 'call') return map;
        if (type == 'voice') {
          map['content'] ??= content;
          return map;
        }
      }
      if (map.containsKey('contentType') && map['contentType'] == 'voice') {
        map['content'] ??= content;
        return map;
      }
      return {'contentType': 'text', 'content': content};
    } catch (e) {
      return {
        'contentType': messageTypeToString(MessageType.unknown),
        'content': content,
      };
    }
  }

  static String getContent(MessageType type, String content, String? source) {
    if (source != null && source.isNotEmpty == true) return source;
    switch (type) {
      case MessageType.call:
        return '[You\'ve received a call via noscall!]';
      case MessageType.voice:
        try {
          final map = jsonDecode(content) as Map<String, dynamic>;
          final sec = (map['durationSeconds'] as num?)?.toInt() ?? 0;
          return 'Voice ${sec ~/ 60}:${(sec % 60).toString().padLeft(2, '0')}';
        } catch (_) {
          return 'Voice message';
        }
      default:
        return content;
    }
  }

  static String? getSubContent(MessageType type, String content) {
    switch (type) {
      case MessageType.call:
        return jsonEncode({
          'contentType': messageTypeToString(type),
          'content': content,
        });
      case MessageType.voice:
        return content;
      default:
        return null;
    }
  }

  /// Parses voice message payload from [decryptContent] or [content] JSON.
  /// Returns map with url, durationSeconds, mimeType or null.
  static Map<String, dynamic>? parseVoiceContent(String? jsonContent) {
    if (jsonContent == null || jsonContent.isEmpty) return null;
    try {
      final map = jsonDecode(jsonContent) as Map<String, dynamic>;
      if (map['contentType'] == 'voice' || map['url'] != null) {
        final peaks = map['waveformPeaks'];
        if (peaks is List) {
          map['waveformPeaks'] = peaks
              .map((e) => (e as num?)?.toInt() ?? 0)
              .where((v) => v > 0)
              .toList();
        }
        return map;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static String mimeTypeToTpyeString(String mimeType) {
    if (mimeType.startsWith('image/')) {
      return 'encryptedImage';
    } else if (mimeType.startsWith('audio/')) {
      return 'encryptedAudio';
    } else if (mimeType.startsWith('video/')) {
      return 'encryptedVideo';
    }
    return 'encryptedFile';
  }

  static Future<MessageDBISAR?> fromPrivateMessage(
    Event event,
    String receiver,
    String privkey, {
    int chatType = 0,
  }) async {
    EDMessage? message;
    if (event.kind == 44) {
      message = await Contacts.sharedInstance.decodeNip44Event(
        event,
        receiver,
        privkey,
      );
    } else if (event.kind == 4) {
      message = await Contacts.sharedInstance.decodeNip4Event(
        event,
        receiver,
        privkey,
      );
    } else if (event.kind == 14 || event.kind == 15) {
      message = await Contacts.sharedInstance.decodeKind14Event(
        event,
        receiver,
      );
    }
    if (message == null) return null;
    MessageDBISAR messageDB = MessageDBISAR(
      messageId: event.id,
      sender: message.sender,
      receiver: message.receiver,
      groupId: message.groupId ?? '',
      kind: event.kind,
      tags: jsonEncode(event.tags),
      content: message.content,
      createTime: event.createdAt,
      replyId: message.replyId,
      plaintEvent: jsonEncode(event),
      chatType: chatType,
      expiration: message.expiration == null
          ? null
          : int.parse(message.expiration!),
      decryptAlgo: message.algorithm,
      decryptNonce: message.nonce,
      decryptSecret: message.secret,
    );
    var map = await decodeContent(message.content);
    messageDB.decryptContent = map['content'];
    messageDB.type = map['contentType'];
    if (map['decryptSecret'] != null) {
      messageDB.decryptSecret = map['decryptSecret'];
    }
    if (message.mimeType != null) {
      messageDB.type = mimeTypeToTpyeString(message.mimeType!);
    }
    return messageDB;
  }

  static String? getNostrScheme(String content) {
    const regexNostr =
        r'((nostr:)?(npub|note|nprofile|nevent|nrelay|naddr)[0-9a-zA-Z]+)';
    final urlRegexp = RegExp(regexNostr);
    final match = urlRegexp.firstMatch(content);
    return match?.group(0);
  }
}

MessageDBISAR _messageInfoFromMap(Map<String, dynamic> map) {
  return MessageDBISAR(
    messageId: map['messageId'].toString(),
    sender: map['sender'].toString(),
    receiver: map['receiver'].toString(),
    groupId: map['groupId'].toString(),
    sessionId: map['sessionId'].toString(),
    kind: map['kind'],
    tags: map['tags'].toString(),
    content: map['content'].toString(),
    createTime: map['createTime'],
    read: map['read'],
    replyId: map['replyId'].toString(),
    decryptContent: map['decryptContent'].toString(),
    type: map['type'],
    status: map['status'],
    plaintEvent: map['plaintEvent'].toString(),
    chatType: map['chatType'],
    subType: map['subType']?.toString(),
    previewData: map['previewData']?.toString(),
    expiration: map['expiration'],
    decryptSecret: map['decryptSecret']?.toString(),
    reactionEventIds: UserDBISAR.decodeStringList(
      map['reactionEventIds'].toString(),
    ),
    zapEventIds: UserDBISAR.decodeStringList(map['zapEventIds'].toString()),
  );
}
