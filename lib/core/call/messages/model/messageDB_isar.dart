import 'dart:async';
import 'dart:convert';
import 'package:noscall/core/call/contacts/contacts+isolateEvent.dart';
import 'package:nostr/nostr.dart';
import 'package:isar/isar.dart';

import '../../../account/model/userDB_isar.dart';
import '../../../common/thread/threadPoolManager.dart';
import '../../contacts/contacts.dart';

part 'messageDB_isar.g.dart';

enum MessageType {
  unknown,
  call,
}

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
  int? chatType; // 0 private chat 1 group chat 2 channel chat 3 secret chat 4 relay group chat 5 ble channel chat 6 ble private chat
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

  static MessageDBISAR fromMap(Map<String, Object?> map) {
    return _messageInfoFromMap(map);
  }

  static String messageTypeToString(MessageType type) {
    switch (type) {
      case MessageType.call:
        return 'call';
      default:
        return 'unknown';
    }
  }

  static MessageType stringtoMessageType(String type) {
    switch (type) {
      case 'call':
        return MessageType.call;
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
    var result =
        await ThreadPoolManager.sharedInstance.runOtherTask(() => _decodeContentInIsolate(content));
    return result;
  }

  static Future<Map<String, dynamic>> _decodeContentInIsolate(String content) async {
    content = content.trim();
    try {
      Map<String, dynamic> map = jsonDecode(content);
      if (map.containsKey('contentType') && map.containsKey('content')) {
        String type = map['contentType'];
        if (type == 'call') return map;
      }
      return {'contentType': 'text', 'content': content};
    } catch (e) {
      return {'contentType': messageTypeToString(MessageType.unknown), 'content': content};
    }
  }

  static String getContent(MessageType type, String content, String? source) {
    if (source != null && source.isNotEmpty == true) return source;
    switch (type) {
      case MessageType.call:
        return '[You\'ve received a call via noscall!]';
      default:
        return content;
    }
  }

  static String? getSubContent(MessageType type, String content) {
    switch (type) {
      case MessageType.call:
        return jsonEncode({'contentType': messageTypeToString(type), 'content': content});
      default:
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

  static Future<MessageDBISAR?> fromPrivateMessage(Event event, String receiver, String privkey,
      {int chatType = 0}) async {
    EDMessage? message;
    if (event.kind == 44) {
      message = await Contacts.sharedInstance.decodeNip44Event(event, receiver, privkey);
    } else if (event.kind == 14 || event.kind == 15) {
      message = await Contacts.sharedInstance.decodeKind14Event(event, receiver);
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
        expiration: message.expiration == null ? null : int.parse(message.expiration!),
        decryptAlgo: message.algorithm,
        decryptNonce: message.nonce,
        decryptSecret: message.secret);
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
    const regexNostr = r'((nostr:)?(npub|note|nprofile|nevent|nrelay|naddr)[0-9a-zA-Z]+)';
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
    reactionEventIds: UserDBISAR.decodeStringList(map['reactionEventIds'].toString()),
    zapEventIds: UserDBISAR.decodeStringList(map['zapEventIds'].toString()),
  );
}
