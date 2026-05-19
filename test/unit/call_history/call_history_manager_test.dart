import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/call/constant/call_type.dart';
import 'package:noscall/call_history/constants/call_enums.dart';
import 'package:noscall/call_history/controller/call_history_manager.dart';
import 'package:noscall/call_history/models/call_entry.dart';
import 'package:noscall/call_history/models/call_log_group.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kUnreadMissedCallCountKey = 'unread_missed_call_count';

CallEntry entry({
  required String callId,
  required String peerPubkey,
  required CallDirection direction,
  required CallType type,
  required CallStatus status,
  required DateTime startTime,
}) {
  return CallEntry(
    callId: callId,
    peerPubkey: peerPubkey,
    direction: direction,
    type: type,
    status: status,
    startTime: startTime,
  );
}

CallLogGroup makeCallLogGroup({
  required String groupId,
  required List<String> callEntryIds,
  required String peerPubkey,
  required CallDirection direction,
  required CallType type,
  required DateTime lastCallTime,
  bool isConnected = false,
}) {
  return CallLogGroup(
    groupId: groupId,
    callEntryIds: callEntryIds,
    peerPubkey: peerPubkey,
    direction: direction,
    type: type,
    lastCallTime: lastCallTime,
    isConnected: isConnected,
  );
}

void main() {
  group('CallHistoryManager.canMergeToGroup', () {
    late CallHistoryManager manager;

    setUp(() {
      manager = CallHistoryManager();
    });

    tearDown(() {
      manager.dispose();
    });

    test(
        'returns true when same peer, direction, type, isConnected and same day',
        () {
      final g = makeCallLogGroup(
        groupId: 'g1',
        callEntryIds: ['c1'],
        peerPubkey: 'peer_a',
        direction: CallDirection.incoming,
        type: CallType.audio,
        lastCallTime: DateTime(2025, 2, 17, 10, 0),
        isConnected: true,
      );
      final e = entry(
        callId: 'c2',
        peerPubkey: 'peer_a',
        direction: CallDirection.incoming,
        type: CallType.audio,
        status: CallStatus.completed,
        startTime: DateTime(2025, 2, 17, 14, 0),
      );
      expect(manager.canMergeToGroup(e, g), isTrue);
    });

    test('returns false when peer differs', () {
      final g = makeCallLogGroup(
        groupId: 'g1',
        callEntryIds: ['c1'],
        peerPubkey: 'peer_a',
        direction: CallDirection.incoming,
        type: CallType.audio,
        lastCallTime: DateTime(2025, 2, 17, 10, 0),
      );
      final e = entry(
        callId: 'c2',
        peerPubkey: 'peer_b',
        direction: CallDirection.incoming,
        type: CallType.audio,
        status: CallStatus.cancelled,
        startTime: DateTime(2025, 2, 17, 14, 0),
      );
      expect(manager.canMergeToGroup(e, g), isFalse);
    });

    test('returns false when direction differs', () {
      final g = makeCallLogGroup(
        groupId: 'g1',
        callEntryIds: ['c1'],
        peerPubkey: 'peer_a',
        direction: CallDirection.incoming,
        type: CallType.audio,
        lastCallTime: DateTime(2025, 2, 17, 10, 0),
      );
      final e = entry(
        callId: 'c2',
        peerPubkey: 'peer_a',
        direction: CallDirection.outgoing,
        type: CallType.audio,
        status: CallStatus.completed,
        startTime: DateTime(2025, 2, 17, 14, 0),
      );
      expect(manager.canMergeToGroup(e, g), isFalse);
    });

    test('returns false when type differs', () {
      final g = makeCallLogGroup(
        groupId: 'g1',
        callEntryIds: ['c1'],
        peerPubkey: 'peer_a',
        direction: CallDirection.incoming,
        type: CallType.audio,
        lastCallTime: DateTime(2025, 2, 17, 10, 0),
      );
      final e = entry(
        callId: 'c2',
        peerPubkey: 'peer_a',
        direction: CallDirection.incoming,
        type: CallType.video,
        status: CallStatus.completed,
        startTime: DateTime(2025, 2, 17, 14, 0),
      );
      expect(manager.canMergeToGroup(e, g), isFalse);
    });

    test('returns false when isConnected differs (completed vs missed)', () {
      final g = makeCallLogGroup(
        groupId: 'g1',
        callEntryIds: ['c1'],
        peerPubkey: 'peer_a',
        direction: CallDirection.incoming,
        type: CallType.audio,
        lastCallTime: DateTime(2025, 2, 17, 10, 0),
        isConnected: true,
      );
      final e = entry(
        callId: 'c2',
        peerPubkey: 'peer_a',
        direction: CallDirection.incoming,
        type: CallType.audio,
        status: CallStatus.cancelled,
        startTime: DateTime(2025, 2, 17, 14, 0),
      );
      expect(manager.canMergeToGroup(e, g), isFalse);
    });

    test('returns false when different day', () {
      final g = makeCallLogGroup(
        groupId: 'g1',
        callEntryIds: ['c1'],
        peerPubkey: 'peer_a',
        direction: CallDirection.incoming,
        type: CallType.audio,
        lastCallTime: DateTime(2025, 2, 16, 23, 59),
      );
      final e = entry(
        callId: 'c2',
        peerPubkey: 'peer_a',
        direction: CallDirection.incoming,
        type: CallType.audio,
        status: CallStatus.completed,
        startTime: DateTime(2025, 2, 17, 0, 1),
      );
      expect(manager.canMergeToGroup(e, g), isFalse);
    });

    test('returns true when both missed (isConnected false) and same day', () {
      final g = makeCallLogGroup(
        groupId: 'g1',
        callEntryIds: ['c1'],
        peerPubkey: 'peer_a',
        direction: CallDirection.outgoing,
        type: CallType.audio,
        lastCallTime: DateTime(2025, 2, 17, 10, 0),
        isConnected: false,
      );
      final e = entry(
        callId: 'c2',
        peerPubkey: 'peer_a',
        direction: CallDirection.outgoing,
        type: CallType.audio,
        status: CallStatus.cancelled,
        startTime: DateTime(2025, 2, 17, 11, 0),
      );
      expect(manager.canMergeToGroup(e, g), isTrue);
    });
  });

  group('CallHistoryManager unread missed count', () {
    late CallHistoryManager manager;

    setUpAll(() {
      SharedPreferences.setMockInitialValues({});
    });

    setUp(() async {
      manager = CallHistoryManager();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kUnreadMissedCallCountKey);
    });

    tearDown(() {
      manager.dispose();
    });

    test('loadUnreadMissedCount loads 0 when prefs empty', () async {
      await manager.loadUnreadMissedCount();
      expect(manager.unreadMissedCountNotifier.value, 0);
    });

    test('incrementUnreadMissed increases notifier and persists', () async {
      await manager.loadUnreadMissedCount();
      await manager.incrementUnreadMissed();
      expect(manager.unreadMissedCountNotifier.value, 1);
      await manager.incrementUnreadMissed();
      expect(manager.unreadMissedCountNotifier.value, 2);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(_kUnreadMissedCallCountKey), 2);
    });

    test('clearUnreadMissed sets notifier to 0 and persists', () async {
      await manager.loadUnreadMissedCount();
      await manager.incrementUnreadMissed();
      await manager.incrementUnreadMissed();
      await manager.clearUnreadMissed();
      expect(manager.unreadMissedCountNotifier.value, 0);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(_kUnreadMissedCallCountKey), 0);
    });

    test('persistUnreadCleared only persists 0 without changing notifier',
        () async {
      await manager.loadUnreadMissedCount();
      await manager.incrementUnreadMissed();
      expect(manager.unreadMissedCountNotifier.value, 1);
      await manager.persistUnreadCleared();
      expect(manager.unreadMissedCountNotifier.value, 1);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(_kUnreadMissedCallCountKey), 0);
    });

    test('dispose is idempotent', () {
      manager.dispose();
      expect(manager.dispose, returnsNormally);
    });
  });
}
