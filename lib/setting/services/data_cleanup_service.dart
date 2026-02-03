import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:noscall/call_history/controller/call_history_manager.dart';
import 'package:noscall/core/common/network/eventCache.dart';

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
      return const DataCleanupResult(
        success: true,
        message: 'Cache cleared.',
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
      final deleted = await callHistoryManager.deleteCallHistoryOlderThan(before);
      await EventCache.sharedInstance.loadAllEventsFromDB();
      return DataCleanupResult(
        success: true,
        message: deleted > 0
            ? 'Cleared $deleted call record(s) and expired event cache.'
            : 'No old call records; expired event cache cleaned.',
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
