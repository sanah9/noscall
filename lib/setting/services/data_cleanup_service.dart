import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:noscall/call_history/controller/call_history_manager.dart';
import 'package:noscall/core/call/messages/messages.dart';
import 'package:noscall/core/call/messages/model/messageDB_isar.dart';
import 'package:noscall/core/call/messages/voice_cache_manager.dart';
import 'package:noscall/core/common/network/event_cache.dart';

/// Result of a cleanup operation.
class DataCleanupResult {
  final bool success;
  final String message;
  final int? entriesDeleted;

  const DataCleanupResult({
    required this.success,
    required this.message,
    this.entriesDeleted,
  });
}

/// Service for clearing app cache and old data.
class DataCleanupService {
  DataCleanupService._();
  static final DataCleanupService _instance = DataCleanupService._();
  static DataCleanupService get instance => _instance;

  /// Clears image cache (CachedNetworkImage / DefaultCacheManager).
  Future<DataCleanupResult> clearCache() async {
    try {
      await DefaultCacheManager().emptyCache();
      await VoiceCacheManager.instance.clearAllCache();
      return const DataCleanupResult(
        success: true,
        message: 'Image and voice cache cleared.',
      );
    } catch (e) {
      return DataCleanupResult(
        success: false,
        message: 'Failed to clear cache: $e',
      );
    }
  }

  /// Clears old data: call history older than [days] and expired event cache.
  /// Returns number of call history entries deleted.
  Future<DataCleanupResult> clearOldData({
    required int days,
    required CallHistoryManager callHistoryManager,
  }) async {
    try {
      final before = DateTime.now().subtract(Duration(days: days));
      final deleted =
          await callHistoryManager.deleteCallHistoryOlderThan(before);
      await EventCache.sharedInstance.loadAllEventsFromDB();
      final cutoffSeconds = before.millisecondsSinceEpoch ~/ 1000;
      final voiceResult = await Messages.loadMessagesFromDB(
        messageTypes: const [MessageType.voice],
        until: cutoffSeconds,
      );
      final oldVoiceMessages =
          (voiceResult['messages'] as List<MessageDBISAR>?) ?? const [];
      await VoiceCacheManager.instance
          .deleteCacheForMessages(oldVoiceMessages.map((m) => m.messageId));
      return DataCleanupResult(
        success: true,
        message: deleted > 0
            ? 'Cleared $deleted call record(s), expired event cache, and old voice cache.'
            : 'No old call records; expired event cache and old voice cache cleaned.',
        entriesDeleted: deleted,
      );
    } catch (e) {
      return DataCleanupResult(
        success: false,
        message: 'Failed to clear old data: $e',
      );
    }
  }
}
