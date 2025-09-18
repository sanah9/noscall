import 'package:isar/isar.dart';
import 'package:noscall/call/constant/call_type.dart';
import '../constants/call_enums.dart';
import 'call_entry.dart';

part 'call_log_group.g.dart';

@collection
class CallLogGroup {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  String groupId;

  List<String> callEntryIds;

  String peerPubkey;

  @Enumerated(EnumType.value, 'value')
  CallDirection direction;

  @Enumerated(EnumType.value, 'value')
  CallType type;

  DateTime lastCallTime;

  bool isConnected;

  @ignore
  int get callCount => callEntryIds.length;

  CallLogGroup({
    required this.groupId,
    required this.callEntryIds,
    required this.peerPubkey,
    required this.direction,
    required this.type,
    required this.lastCallTime,
    this.isConnected = false,
  });

  @ignore
  List<CallEntry> callEntries = [];
}
