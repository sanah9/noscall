import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:noscall/call/constant/call_type.dart';
import 'package:noscall/flutter_utils/datatime_extension.dart';
import 'package:uuid/uuid.dart';
import '../constants/call_enums.dart';
import '../models/call_entry.dart';
import '../models/call_log_group.dart';
import '../../core/common/database/db_isar.dart';

const String _kUnreadMissedCallCountKey = 'unread_missed_call_count';

class CallHistoryManager {
  Isar get _isar => DBISAR.sharedInstance.isar;

  List<CallLogGroup> _callLogGroups = [];

  List<CallLogGroup> get callLogGroups => List.unmodifiable(_callLogGroups);

  final StreamController<List<CallLogGroup>> _dataChangeController = 
      StreamController<List<CallLogGroup>>.broadcast();

  get dataChangeController => _dataChangeController;

  Stream<List<CallLogGroup>> get dataChangeStream => _dataChangeController.stream;

  /// Unread missed call count for tab badge. Persisted; cleared when user opens Recent tab.
  final ValueNotifier<int> unreadMissedCountNotifier = ValueNotifier(0);
  SharedPreferences? _prefs;
  bool _unreadLoaded = false;

  Future<void> loadUnreadMissedCount() async {
    if (_unreadLoaded) return;
    _prefs ??= await SharedPreferences.getInstance();
    unreadMissedCountNotifier.value = _prefs!.getInt(_kUnreadMissedCallCountKey) ?? 0;
    _unreadLoaded = true;
  }

  Future<void> incrementUnreadMissed() async {
    _prefs ??= await SharedPreferences.getInstance();
    final n = unreadMissedCountNotifier.value + 1;
    unreadMissedCountNotifier.value = n;
    await _prefs!.setInt(_kUnreadMissedCallCountKey, n);
  }

  /// Clears the red dot in UI and persists 0. Call when user *leaves* Recent tab (switches to another tab).
  Future<void> clearUnreadMissed() async {
    unreadMissedCountNotifier.value = 0;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setInt(_kUnreadMissedCallCountKey, 0);
  }

  /// Only persists 0 so next app launch has no red dot. Does NOT change UI. Call when user *enters* Recent page.
  Future<void> persistUnreadCleared() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setInt(_kUnreadMissedCallCountKey, 0);
  }

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

  /// Returns true if a new record was added, false if callId already existed (e.g. duplicate from another relay).
  Future<bool> addCallRecord({
    required String callId,
    required String peerPubkey,
    required CallDirection direction,
    required CallType type,
    required CallStatus status,
    required DateTime startTime,
    Duration? duration,
  }) async {
    final existing = await _isar.callEntrys.where().callIdEqualTo(callId).findFirst();
    if (existing != null) return false;

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
    return true;
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
    _callLogGroups.clear();
    await _isar.writeTxn(() async {
      await _isar.callLogGroups.where().deleteAll();
      await _isar.callEntrys.where().deleteAll();
    });
    _notifyDataChanged();
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
