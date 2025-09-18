import 'dart:async';
import 'package:isar/isar.dart';
import 'package:noscall/call/constant/call_type.dart';
import 'package:noscall/flutter_utils/datatime_extension.dart';
import 'package:uuid/uuid.dart';
import '../constants/call_enums.dart';
import '../models/call_entry.dart';
import '../models/call_log_group.dart';
import '../../core/common/database/db_isar.dart';

class CallHistoryManager {
  Isar get _isar => DBISAR.sharedInstance.isar;

  List<CallLogGroup> _callLogGroups = [];

  List<CallLogGroup> get callLogGroups => List.unmodifiable(_callLogGroups);

  final StreamController<List<CallLogGroup>> _dataChangeController = 
      StreamController<List<CallLogGroup>>.broadcast();

  get dataChangeController => _dataChangeController;

  Stream<List<CallLogGroup>> get dataChangeStream => _dataChangeController.stream;

  void _notifyDataChanged() {
    _dataChangeController.add(List.unmodifiable(_callLogGroups));
  }

  Future<void> initialize() async {
    try {
      _callLogGroups = await _isar.callLogGroups
          .where()
          .sortByLastCallTimeDesc()
          .findAll();

      for (final group in _callLogGroups) {
        await _loadCallEntriesForGroup(group);
      }

      _notifyDataChanged();
    } catch (e) {
      throw Exception('Failed to initialize call history: $e');
    }
  }

  Future<void> addCallRecord({
    required String callId,
    required String peerPubkey,
    required CallDirection direction,
    required CallType type,
    required CallStatus status,
    required DateTime startTime,
    Duration? duration,
  }) async {
    final callEntry = CallEntry(
      callId: callId,
      peerPubkey: peerPubkey,
      direction: direction,
      type: type,
      status: status,
      startTime: startTime,
      duration: duration,
    );

    await _addCallEntry(callEntry);
  }

  Future<void> deleteCallLogGroup(String groupId) async {
    try {
      final group = await _isar.callLogGroups
          .where()
          .groupIdEqualTo(groupId)
          .findFirst();

      _callLogGroups.removeWhere((group) => group.groupId == groupId);

      await _isar.writeTxn(() async {
        await _isar.callEntrys
            .where()
            .anyOf(group?.callEntryIds ?? [],
                (query, entryId) => query.callIdEqualTo(entryId))
            .deleteAll();
        await _isar.callLogGroups
            .where()
            .groupIdEqualTo(groupId)
            .deleteAll();
      });

      _notifyDataChanged();
    } catch (e) {
      throw Exception('Failed to delete CallLogGroup: $e');
    }
  }

  Future<void> deleteAllHistory() async {
    await _isar.callLogGroups.where().deleteAll();
    await _isar.callEntrys.where().deleteAll();
  }

  Future<void> _addCallEntry(CallEntry callEntry) async {
    await _isar.writeTxn(() async {
      await _isar.callEntrys.put(callEntry);
    });

    CallLogGroup? targetGroup;
    final firstGroup = _callLogGroups.firstOrNull;
    if (firstGroup != null) {
      if (_canMergeToGroup(callEntry, firstGroup)) {
        targetGroup = firstGroup;
      }
    }

    if (targetGroup != null) {
      await _mergeToCallLogGroup(callEntry, targetGroup);
    } else {
      final newGroup = CallLogGroup(
        groupId: const Uuid().v4(),
        callEntryIds: [callEntry.callId],
        peerPubkey: callEntry.peerPubkey,
        direction: callEntry.direction,
        type: callEntry.type,
        lastCallTime: callEntry.startTime,
        isConnected: callEntry.isConnected,
      );
      newGroup.callEntries = [callEntry];

      await _addCallLogGroup(newGroup);
    }
  }

  Future<void> _mergeToCallLogGroup(CallEntry callEntry, CallLogGroup group) async {
    group.callEntryIds = [
      callEntry.callId,
      ...group.callEntryIds,
    ];
    group.callEntries.add(callEntry);

    if (callEntry.startTime.isAfter(group.lastCallTime)) {
      group.lastCallTime = callEntry.startTime;
    }

    if (callEntry.status == CallStatus.completed) {
      group.isConnected = true;
    }

    await _isar.writeTxn(() async {
      await _isar.callLogGroups.put(group);
    });

    _notifyDataChanged();
  }

  Future<void> _addCallLogGroup(CallLogGroup group) async {
    _callLogGroups.add(group);

    _callLogGroups.sort((a, b) => b.lastCallTime.compareTo(a.lastCallTime));

    await _isar.writeTxn(() async {
      await _isar.callLogGroups.put(group);
    });

    _notifyDataChanged();
  }

  bool _canMergeToGroup(CallEntry callEntry, CallLogGroup group) {
    if (callEntry.peerPubkey != group.peerPubkey) return false;
    if (callEntry.direction != group.direction) return false;
    if (callEntry.type != group.type) return false;
    if (callEntry.isConnected != group.isConnected) return false;
    if (!callEntry.startTime.isSameDay(group.lastCallTime)) return false;

    return true;
  }

  Future<void> _loadCallEntriesForGroup(CallLogGroup group) async {
    final callEntries = <CallEntry>[];

    for (final callEntryId in group.callEntryIds) {
      final callEntry = await _isar.callEntrys
          .where()
          .callIdEqualTo(callEntryId)
          .findFirst();

      if (callEntry != null) {
        callEntries.add(callEntry);
      }
    }

    callEntries.sort((a, b) => a.startTime.compareTo(b.startTime));
    group.callEntries = callEntries;
  }

  void dispose() {
    _dataChangeController.close();
  }
}
