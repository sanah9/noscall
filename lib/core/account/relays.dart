import 'package:http/http.dart' as http;
import 'package:isar/isar.dart';

import '../common/config/config.dart';
import '../common/database/db_isar.dart';
import '../common/network/connect.dart';
import '../common/utils/log_utils.dart';
import 'account.dart';
import 'model/relayDB_isar.dart';

class Relays {
  /// singleton
  Relays._internal();
  factory Relays() => sharedInstance;
  static final Relays sharedInstance = Relays._internal();
  // ALL relays list
  Map<String, RelayDBISAR> relays = {};

  List<String> recommendGeneralRelays = [
    'wss://relay.0xchat.com',
    'wss://yabu.me',
    'wss://relay.siamstr.com',
    'wss://relay.damus.io',
    'wss://relay.nostr.band',
    'wss://nos.lol',
    'wss://nostr.wine',
    'wss://eden.nostr.land'
  ];

  List<String> recommendDMRelays = [
    'wss://auth.nostr1.com',
    'wss://relay.0xchat.com',
    'wss://inbox.nostr.wine',
  ];

  Future<void> init() async {
    await Config.sharedInstance.initConfig();
    List<RelayDBISAR> result = await _loadRelaysFromDB() ?? [];
    if (result.isNotEmpty) {
      relays = {for (var item in result) item.url: item};
    }
    connectGeneralRelays();
    connectDMRelays();
    connectInboxOutboxRelays();
  }

  Future<void> connectGeneralRelays() async {
    List<String> connectedGeneralRelays =
        Connect.sharedInstance.relays(relayKinds: [RelayKind.general]);
    List<String> generalRelays = Account.sharedInstance.me?.relayList ?? [];
    List<String> notInGeneralRelays =
        connectedGeneralRelays.where((relay) => !generalRelays.contains(relay)).toList();
    await Connect.sharedInstance.closeConnects(notInGeneralRelays, RelayKind.general);

    int updatedTime = Account.sharedInstance.me?.lastRelayListUpdatedTime ?? 0;
    if (updatedTime > 0 && generalRelays.isNotEmpty) {
      Connect.sharedInstance.connectRelays(generalRelays, relayKind: RelayKind.general);
    } else {
      // startup relays
      Connect.sharedInstance.connectRelays(recommendGeneralRelays, relayKind: RelayKind.general);
    }
  }

  Future<void> connectDMRelays() async {
    List<String> connectedDMRelays = Connect.sharedInstance.relays(relayKinds: [RelayKind.dm]);
    List<String> dmRelays = Account.sharedInstance.me?.dmRelayList ?? [];
    List<String> notInDMRelays =
        connectedDMRelays.where((relay) => !dmRelays.contains(relay)).toList();
    await Connect.sharedInstance.closeConnects(notInDMRelays, RelayKind.dm);

    Connect.sharedInstance.connectRelays(dmRelays, relayKind: RelayKind.dm);
  }

  Future<void> connectInboxOutboxRelays() async {
    List<String> connectedBoxRelays =
        Connect.sharedInstance.relays(relayKinds: [RelayKind.inbox, RelayKind.outbox]);
    List<String> inbox = Account.sharedInstance.me?.inboxRelayList ?? [];
    List<String> outbox = Account.sharedInstance.me?.outboxRelayList ?? [];
    var relays = [...inbox, ...outbox];
    List<String> notInRelays =
        connectedBoxRelays.where((relay) => !relays.contains(relay)).toList();
    await Connect.sharedInstance.closeConnects(notInRelays, RelayKind.inbox);
    await Connect.sharedInstance.closeConnects(notInRelays, RelayKind.outbox);
    Connect.sharedInstance.connectRelays(relays, relayKind: RelayKind.inbox);
    Connect.sharedInstance.connectRelays(relays, relayKind: RelayKind.outbox);
  }

  Future<List<RelayDBISAR>?> _loadRelaysFromDB() async {
    final isar = DBISAR.sharedInstance.isar;
    return isar.relayDBISARs.where().findAll();
  }

  Future<void> syncRelaysToDB({String? r}) async {
    if (r != null && relays[r] != null) {
      await DBISAR.sharedInstance.saveToDB(relays[r]!);
    } else {
      await Future.forEach(relays.values, (relay) async {
        await DBISAR.sharedInstance.saveToDB(relay);
      });
    }
  }

  Future<void> syncRelayToDB(RelayDBISAR db) async {
    await DBISAR.sharedInstance.saveToDB(db);
  }

  int getCommonMessageUntil(String relayURL) {
    return relays.containsKey(relayURL) ? relays[relayURL]!.commonMessagesUntil : 0;
  }

  int getCommonMessageSince(String relayURL) {
    return relays.containsKey(relayURL) ? relays[relayURL]!.commonMessagesSince : 0;
  }

  void setCommonMessageUntil(int updateTime, String relay) {
    int until = Relays.sharedInstance.getCommonMessageUntil(relay);
    if (!relays.containsKey(relay)) relays[relay] = RelayDBISAR(url: relay);
    relays[relay]!.commonMessagesUntil = updateTime > until ? updateTime : until;
  }

  static Future<RelayDBISAR?> getRelayDetailsFromDB(String relayURL) async {
    final isar = DBISAR.sharedInstance.isar;
    return isar.relayDBISARs.where().urlEqualTo(relayURL).findFirst();
  }

  static Future<RelayDBISAR?> getRelayDetails(String relayURL, {bool? refresh}) async {
    if (refresh != true) {
      RelayDBISAR? relayDB = await getRelayDetailsFromDB(relayURL);
      if (relayDB?.pubkey?.isNotEmpty == true) return relayDB;
    }

    var url = Uri.parse(relayURL).replace(scheme: 'https');
    var response = await http.get(url, headers: {'Accept': 'application/nostr+json'});

    if (response.statusCode == 200) {
      RelayDBISAR? relayDB = Relays.sharedInstance.relays.containsKey(relayURL)
          ? Relays.sharedInstance.relays[relayURL]
          : RelayDBISAR(url: relayURL);
      relayDB = RelayDBISAR.relayDBInfoFromJSON(response.body, relayDB!);
      await Relays.sharedInstance.syncRelayToDB(relayDB);
      return relayDB;
    } else {
      LogUtils.v(() => 'Request failed with status: ${response.statusCode}.');
      return null;
    }
  }
}
