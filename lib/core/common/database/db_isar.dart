import 'dart:async';
import 'dart:io';

import 'package:isar/isar.dart';
import 'package:noscall/call_history/models/call_entry.dart';
import 'package:noscall/call_history/models/call_log_group.dart';
import 'package:path_provider/path_provider.dart';

import '../../account/model/relayDB_isar.dart';
import '../../account/model/userDB_isar.dart';
import '../config/configDB_isar.dart';
import '../network/eventDB_isar.dart';
import '../utils/log_utils.dart';

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
    UserDBISARSchema,
    RelayDBISARSchema,
    ConfigDBISARSchema,
    EventDBISARSchema,
    CallEntrySchema,
    CallLogGroupSchema,
  ];

  // Store encryption key after first open so subsequent opens re-use it.
  static String? _sharedEncKey;

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
    Directory directory = isOS ? await getLibraryDirectory() : await getApplicationDocumentsDirectory();
    return directory.path;
  }

  /// Get full database file path
  Future<String> _getDatabaseFilePath(String pubkey, {String? circleId}) async {
    final dbName = _getDatabaseName(pubkey, circleId: circleId);
    final dbDir = await _getDatabaseDirectory();
    return '$dbDir/$dbName.isar';
  }

  Future open(String pubkey, {String? circleId, String? dbPath, String? encryptionKey}) async {
    final dbName = _getDatabaseName(pubkey, circleId: circleId);
    dbPath ??= await _getDatabaseDirectory();
    LogUtils.v(() => 'DBISAR open: $dbPath, pubkey: $pubkey, circleId: $circleId');

    // Store current circle ID
    _currentCircleId = circleId;

    // Persist encryption key if provided.
    if (encryptionKey != null) {
      _sharedEncKey = encryptionKey;
    }

    final String key = encryptionKey ?? _sharedEncKey ?? pubkey;
    isar = await Isar.open(
      schemas,
      directory: dbPath,
      name: dbName,
    );
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
    for (var object in objects) {
      await saveToDB(object);
    }
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
      for (var type in typeMap.keys) {
        await _saveTOISAR(typeMap[type]!, type);
      }
    });
  }

  Future<void> _saveTOISAR(List<dynamic> objects, Type type) async {
    String typeName = type.toString().replaceAll('?', '');
    IsarCollection? collection = isar.getCollectionByNameInternal(typeName);
    if (collection != null) {
      await collection.putAll(objects);
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
