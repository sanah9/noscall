import 'dart:async';
import 'dart:io';

import 'package:isar/isar.dart';
import 'package:noscall/call_history/models/call_entry.dart';
import 'package:noscall/call_history/models/call_log_group.dart';
import 'package:noscall/call_payments/infrastructure/call_payment_isar.dart';
import 'package:noscall/contacts/models/contact_group_isar.dart';
import 'package:noscall/core/call/messages/model/message_db_isar.dart';
import 'package:path_provider/path_provider.dart';

import 'package:noscall/core/account/model/relay_db_isar.dart';
import 'package:noscall/core/account/model/user_db_isar.dart';
import 'package:noscall/core/common/network/event_db_isar.dart';
import 'package:noscall/core/common/utils/log_utils.dart';
import 'package:noscall/wallet/infrastructure/database/wallet_configuration_isar.dart';

class DBISAR {
  static final DBISAR sharedInstance = DBISAR._internal();
  DBISAR._internal();
  factory DBISAR() => sharedInstance;

  late Isar isar;

  final Map<Type, List<dynamic>> _buffers = {};

  Timer? _timer;

  // Track current circle ID for this database instance
  String? _currentCircleId;

  List<CollectionSchema<dynamic>> schemas = [
    MessageDBISARSchema,
    UserDBISARSchema,
    RelayDBISARSchema,
    EventDBISARSchema,
    CallEntrySchema,
    CallLogGroupSchema,
    ContactGroupSchema,
    ContactGroupMemberSchema,
    CashuWalletConfigurationRecordSchema,
    CashuMintConfigurationRecordSchema,
    CashuTokenSendOperationRecordSchema,
    CashuLightningReceiveQuoteOperationRecordSchema,
    CashuLightningPayQuoteOperationRecordSchema,
    CallPaymentPolicyRecordSchema,
    CallPaymentSessionRecordSchema,
    CallPaymentInstallmentRecordSchema,
  ];

  /// Generate database name for given pubkey and optional circleId
  String _getDatabaseName(String pubkey, {String? circleId}) {
    if (circleId != null) {
      return '$pubkey-$circleId';
    }
    return pubkey;
  }

  /// Get database directory path
  Future<String> _getDatabaseDirectory() async {
    bool isOS = Platform.isIOS || Platform.isMacOS;
    Directory directory = isOS
        ? await getLibraryDirectory()
        : await getApplicationDocumentsDirectory();
    return directory.path;
  }

  /// Get full database file path
  Future<String> _getDatabaseFilePath(String pubkey, {String? circleId}) async {
    final dbName = _getDatabaseName(pubkey, circleId: circleId);
    final dbDir = await _getDatabaseDirectory();
    return '$dbDir/$dbName.isar';
  }

  Future open(String pubkey, {String? circleId, String? dbPath}) async {
    final dbName = _getDatabaseName(pubkey, circleId: circleId);
    dbPath ??= await _getDatabaseDirectory();
    LogUtils.v(
      () => 'DBISAR open: $dbPath, pubkey: $pubkey, circleId: $circleId',
    );

    // Store current circle ID
    _currentCircleId = circleId;

    isar = await Isar.open(schemas, directory: dbPath, name: dbName);
  }

  /// Check if database exists
  /// [pubkey] The user's public key
  /// [circleId] Optional circle ID, if null checks the main database
  /// Returns true if database file exists
  Future<bool> exists(String pubkey, {String? circleId}) async {
    try {
      final dbPath = await _getDatabaseFilePath(pubkey, circleId: circleId);
      final dbFile = File(dbPath);
      return await dbFile.exists();
    } catch (e) {
      LogUtils.e(() => 'Failed to check database existence: $e');
      return false;
    }
  }

  /// Delete an entire database instance by pubkey and circleId
  /// [pubkey] The user's public key
  /// [circleId] Optional circle ID, if null deletes the main database
  /// Returns true if deletion was successful
  Future<bool> delete(String pubkey, {String? circleId}) async {
    try {
      final dbName = _getDatabaseName(pubkey, circleId: circleId);
      if (isar.isOpen && isar.name == dbName) {
        isar.close();
        LogUtils.v(() => 'Closed database instance: $dbName');
      }

      // Delete the database file
      final dbPath = await _getDatabaseFilePath(pubkey, circleId: circleId);
      final dbFile = File(dbPath);

      if (await dbFile.exists()) {
        await dbFile.delete();
        LogUtils.v(() => 'Successfully deleted database file: $dbPath');
      }

      // Also delete associated files (like .lock files)
      final lockFile = File('$dbPath.lock');
      if (await lockFile.exists()) {
        await lockFile.delete();
        LogUtils.v(() => 'Successfully deleted lock file: $dbPath.lock');
      }

      // Delete any other associated files (.tmp, etc.)
      final tmpFile = File('$dbPath.tmp');
      if (await tmpFile.exists()) {
        await tmpFile.delete();
        LogUtils.v(() => 'Successfully deleted tmp file: $dbPath.tmp');
      }

      return true;
    } catch (e) {
      LogUtils.e(() => 'Failed to delete database: $e');
      return false;
    }
  }

  Map<Type, List<dynamic>> getBuffers() {
    return Map.from(_buffers);
  }

  Future<void> saveObjectsToDB<T>(List<T> objects) async {
    if (objects.isEmpty) return;

    final type = T;
    if (!_buffers.containsKey(type)) {
      _buffers[type] = <T>[];
    }

    // Batch add all objects to the buffer
    _buffers[type]!.addAll(objects);

    // Cancel any existing timer and set a new one for batch save
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 200), () async {
      await _putAll();
    });
  }

  Future<void> saveToDB<T>(T object) async {
    final type = T;
    if (!_buffers.containsKey(type)) {
      _buffers[type] = <T>[];
    }
    _buffers[type]!.add(object);

    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 200), () async {
      await _putAll();
    });
  }

  Future<void> _putAll() async {
    _timer?.cancel();
    _timer = null;

    if (_buffers.isEmpty) return;

    final Map<Type, List<dynamic>> typeMap = Map.from(_buffers);
    _buffers.clear();

    await isar.writeTxn(() async {
      for (final entry in typeMap.entries) {
        await _saveTypedObjects(entry.key, entry.value);
      }
    });
  }

  Future<void> _saveTypedObjects(Type type, List<dynamic> objects) async {
    if (type == MessageDBISAR) {
      await isar.messageDBISARs.putAll(objects.cast<MessageDBISAR>());
    } else if (type == UserDBISAR) {
      await isar.userDBISARs.putAll(objects.cast<UserDBISAR>());
    } else if (type == RelayDBISAR) {
      await isar.relayDBISARs.putAll(objects.cast<RelayDBISAR>());
    } else if (type == EventDBISAR) {
      await isar.eventDBISARs.putAll(objects.cast<EventDBISAR>());
    } else if (type == CallEntry) {
      await isar.callEntrys.putAll(objects.cast<CallEntry>());
    } else if (type == CallLogGroup) {
      await isar.callLogGroups.putAll(objects.cast<CallLogGroup>());
    } else if (type == ContactGroup) {
      await isar.contactGroups.putAll(objects.cast<ContactGroup>());
    } else if (type == ContactGroupMember) {
      await isar.contactGroupMembers.putAll(objects.cast<ContactGroupMember>());
    } else if (type == CashuWalletConfigurationRecord) {
      await isar.cashuWalletConfigurationRecords.putAll(
        objects.cast<CashuWalletConfigurationRecord>(),
      );
    } else if (type == CashuMintConfigurationRecord) {
      await isar.cashuMintConfigurationRecords.putAll(
        objects.cast<CashuMintConfigurationRecord>(),
      );
    } else if (type == CashuTokenSendOperationRecord) {
      await isar.cashuTokenSendOperationRecords.putAll(
        objects.cast<CashuTokenSendOperationRecord>(),
      );
    } else if (type == CashuLightningReceiveQuoteOperationRecord) {
      await isar.cashuLightningReceiveQuoteOperationRecords.putAll(
        objects.cast<CashuLightningReceiveQuoteOperationRecord>(),
      );
    } else if (type == CashuLightningPayQuoteOperationRecord) {
      await isar.cashuLightningPayQuoteOperationRecords.putAll(
        objects.cast<CashuLightningPayQuoteOperationRecord>(),
      );
    } else if (type == CallPaymentPolicyRecord) {
      await isar.callPaymentPolicyRecords.putAll(
        objects.cast<CallPaymentPolicyRecord>(),
      );
    } else if (type == CallPaymentSessionRecord) {
      await isar.callPaymentSessionRecords.putAll(
        objects.cast<CallPaymentSessionRecord>(),
      );
    } else if (type == CallPaymentInstallmentRecord) {
      await isar.callPaymentInstallmentRecords.putAll(
        objects.cast<CallPaymentInstallmentRecord>(),
      );
    } else {
      LogUtils.w(() => 'DBISAR: unsupported buffered type $type');
    }
  }

  /// Get current circle ID for this database instance
  /// Returns null if no circle is active (using main database)
  String? get currentCircleId => _currentCircleId;

  Future<void> closeDatabase() async {
    _buffers.clear();
    _timer?.cancel();
    _timer = null;
    _currentCircleId = null;
    if (isar.isOpen) isar.close();
  }
}
