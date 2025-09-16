import 'dart:async';

import 'package:isar/isar.dart';
import 'package:nostr/nostr.dart';

import '../../account/account.dart';
import '../../common/database/db_isar.dart';
import '../../common/network/connect.dart';
import 'model/messageDB_isar.dart';

typedef MessageActionsCallBack = void Function(MessageDBISAR);
typedef MessagesDeleteCallBack = void Function(List<MessageDBISAR>);

class Messages {
  /// singleton
  Messages._internal();
  factory Messages() => sharedInstance;
  static final Messages sharedInstance = Messages._internal();

  static const int maxReportCount = 3;

  String pubkey = '';
  String privkey = '';
  String messageRequestsId = '';
  String messagesActionsRequestsId = '';
  MessageActionsCallBack? actionsCallBack;
  MessagesDeleteCallBack? deleteCallBack;

  late Completer<void> contactMessageCompleter;

  Future<void> init() async {
    privkey = Account.sharedInstance.currentPrivkey;
    pubkey = Account.sharedInstance.currentPubkey;

    contactMessageCompleter = Completer<void>();
  }

  Future<void> closeMessagesActionsRequests() async {
    if (messagesActionsRequestsId.isNotEmpty) {
      await Connect.sharedInstance.closeRequests(messagesActionsRequestsId);
    }
  }

  Future<MessageDBISAR?> loadMessageDBFromDB(String messageId) async {
    List<MessageDBISAR> result = loadMessagesFromCache(messageIds: [messageId]);
    if (result.isNotEmpty) return result.first.withGrowableLevels();
    final isar = DBISAR.sharedInstance.isar;
    var queryBuilder = isar.messageDBISARs.where().messageIdEqualTo(messageId);
    final message = await queryBuilder.findFirst();
    return message?.withGrowableLevels();
  }

  Future<List<MessageDBISAR>> loadMessageDBFromDBWithMsgIds(List<String> messageIds) async {
    List<MessageDBISAR> cacheMsg = loadMessagesFromCache(messageIds: messageIds);
    List<MessageDBISAR> dbMsg = [];
    if (cacheMsg.length != messageIds.length) {
      final isar = DBISAR.sharedInstance.isar;
      var queryBuilder = isar.messageDBISARs.where().anyOf(messageIds, (q, messageId) => q.messageIdEqualTo(messageId));
      dbMsg = await queryBuilder.findAll();
    }
    return [...cacheMsg, ...dbMsg].map((e) => e.withGrowableLevels()).toList();
  }

  static List<MessageDBISAR> loadMessagesFromCache({
    String? receiver,
    String? groupId,
    String? sessionId,
    List<MessageType> messageTypes = const [],
    int? until,
    List<String>? messageIds,
    bool? hasPreviewData,
  }) {
    final Map<Type, List<dynamic>> buffers = DBISAR.sharedInstance.getBuffers();
    List<MessageDBISAR> result = [];
    for (MessageDBISAR message in buffers[MessageDBISAR]?.toList() ?? []) {
      bool query = true;
      if (messageIds != null && messageIds.isNotEmpty && !messageIds.contains(message.messageId)) {
        query = false;
      }
      if (query && receiver != null) {
        query = (message.sender == receiver &&
                message.receiver == Account.sharedInstance.currentPubkey) ||
            (message.sender == Account.sharedInstance.currentPubkey &&
                message.receiver == receiver);
      }
      if (query && groupId != null) {
        query = message.groupId == groupId;
      }
      if (query && sessionId != null) {
        query = message.sessionId == sessionId;
      }
      if (query && messageTypes.isNotEmpty) {
        query = messageTypes.any((messageType) => message.type == MessageDBISAR.messageTypeToString(messageType));
      }
      if (query && hasPreviewData != null) {
        query = hasPreviewData ? message.previewData != null : message.previewData == null;
      }
      if (query && until != null) {
        query = message.createTime < until;
      }
      if (query) result.add(message);
    }
    return result;
  }

  static Future<Map> loadMessagesFromDB({
    String? receiver,
    String? groupId,
    String? sessionId,
    List<MessageType> messageTypes = const [],
    int? until,
    int? since,
    int? limit,
    bool? hasPreviewData,
    String? decryptContentLike,
  }) async {
    assert(until == null || since == null, 'unsupported filter');

    final isar = DBISAR.sharedInstance.isar;

    final whereBuilder = isar.messageDBISARs.filter();

    QueryBuilder<MessageDBISAR, MessageDBISAR, QAfterFilterCondition> qb =
        whereBuilder.messageIdIsNotEmpty();

    qb = qb
        .optional(receiver != null, (q) => q.group((qq) => qq
                .group((qq) => qq
                    .senderEqualTo(receiver!)
                    .receiverEqualTo(Account.sharedInstance.currentPubkey)
                    .sessionIdIsEmpty())
                .or()
                .group((qq) => qq
                    .senderEqualTo(Account.sharedInstance.currentPubkey)
                    .receiverEqualTo(receiver!)
                    .sessionIdIsEmpty())))
        .optional(sessionId != null, (q) => q.sessionIdEqualTo(sessionId!))
        .optional(groupId != null, (q) => q.groupIdEqualTo(groupId!))
        .optional(messageTypes.isNotEmpty, (q) => q.anyOf(messageTypes,
            (qq, mt) => qq.typeEqualTo(MessageDBISAR.messageTypeToString(mt))))
        .optional(decryptContentLike != null,
            (q) => q.decryptContentContains(decryptContentLike!, caseSensitive: false))
        .optional(hasPreviewData != null, (q) =>
            hasPreviewData! ? q.previewDataIsNotNull() : q.previewDataIsNull())
        .optional(until != null, (q) => q.createTimeLessThan(until!))
        .optional(since != null, (q) => q.createTimeGreaterThan(since!));

    final sortedBuilder = since != null ? qb.sortByCreateTime() : qb.sortByCreateTimeDesc();

    var messages = await sortedBuilder.findAll();
    if (limit != null && messages.length > limit) {
      messages = messages.take(limit).toList();
    }

    int theLastTime = 0;
    List<MessageDBISAR> result = loadMessagesFromCache(
      receiver: receiver,
      groupId: groupId,
      sessionId: sessionId,
      messageTypes: messageTypes,
      until: until,
      hasPreviewData: hasPreviewData
    );
    for (var message in messages) {
      message = message.withGrowableLevels();
      theLastTime = message.createTime > theLastTime ? message.createTime : theLastTime;
      result.add(message);
    }
    return {'theLastTime': theLastTime, 'messages': result};
  }

  static Future<Map> searchPrivateMessagesFromDB(String? chatId, String orignalSearchTxt) async {
    final isar = DBISAR.sharedInstance.isar;
    List<MessageDBISAR> messages;
    if (chatId == null) {
      messages = await isar.messageDBISARs
          .filter()
          .senderIsNotEmpty()
          .receiverIsNotEmpty()
          .decryptContentContains(orignalSearchTxt, caseSensitive: false)
          .findAll();
    } else {
      messages = await isar.messageDBISARs
          .filter()
          .group((q) => q
              .group((q) => q
                  .senderEqualTo(chatId)
                  .and()
                  .receiverEqualTo(Account.sharedInstance.currentPubkey))
              .or()
              .group((q) => q
                  .senderEqualTo(Account.sharedInstance.currentPubkey)
                  .and()
                  .receiverEqualTo(chatId)))
          .and()
          .decryptContentContains(orignalSearchTxt, caseSensitive: false)
          .findAll();
    }
    int theLastTime = 0;
    for (var message in messages) {
      theLastTime = message.createTime > theLastTime ? message.createTime : theLastTime;
    }
    return {'theLastTime': theLastTime, 'messages': messages};
  }

  static Future<void> saveMessageToDB(MessageDBISAR message) async {
    await DBISAR.sharedInstance.saveToDB(message);
  }

  static deleteMessagesFromDB({List<String>? messageIds, bool notify = true}) async {
    if (messageIds != null) {
      final isar = DBISAR.sharedInstance.isar;
      var queryBuilder = isar.messageDBISARs.where();
      final messages = await queryBuilder
          .anyOf(messageIds, (q, messageId) => q.messageIdEqualTo(messageId))
          .findAll();
      await isar.writeTxn(() async {
        isar.messageDBISARs
            .where()
            .anyOf(messageIds, (q, messageId) => q.messageIdEqualTo(messageId))
            .deleteAll();
      });
      if (notify) {
        Messages.sharedInstance.deleteCallBack?.call(messages);
      }
    }
  }

  static deleteGroupMessagesFromDB(String? groupId) async {
    if (groupId != null) {
      final isar = DBISAR.sharedInstance.isar;
      await isar.writeTxn(() async {
        isar.messageDBISARs.filter().groupIdEqualTo(groupId).deleteAll();
      });
    }
  }

  static deleteSingleChatMessagesFromDB(String sender, String receiver) async {
    final isar = DBISAR.sharedInstance.isar;
    await isar.writeTxn(() async {
      isar.messageDBISARs
          .filter()
          .senderEqualTo(sender)
          .receiverEqualTo(receiver)
          .chatTypeEqualTo(0)
          .deleteAll();
    });
  }

  static List<ProfileMention> decodeProfileMention(String content) {
    return Nip27.decodeProfileMention(content);
  }

  static String encodeProfileMention(List<ProfileMention> mentions, String content) {
    return Nip27.encodeProfileMention(mentions, content);
  }
}
