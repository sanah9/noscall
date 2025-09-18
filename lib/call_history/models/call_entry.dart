import 'package:isar/isar.dart';
import 'package:noscall/call/constant/call_type.dart';
import '../constants/call_enums.dart';

part 'call_entry.g.dart';

@collection
class CallEntry {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  String callId;

  String peerPubkey;

  @Enumerated(EnumType.value, 'value')
  CallDirection direction;

  @Enumerated(EnumType.value, 'value')
  CallType type;

  @Enumerated(EnumType.value, 'value')
  CallStatus status;

  DateTime startTime;

  @ignore
  Duration? duration;

  int get durationSeconds => duration?.inSeconds ?? 0;

  set durationSeconds(int seconds) {
    duration = seconds > 0 ? Duration(seconds: seconds) : null;
  }

  @ignore
  bool get isConnected => status == CallStatus.completed;

  CallEntry({
    required this.callId,
    required this.peerPubkey,
    required this.direction,
    required this.type,
    required this.status,
    required this.startTime,
    this.duration,
  });
}
