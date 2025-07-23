import 'package:flutter/foundation.dart';
import 'package:idb_shim/idb_browser.dart';
import 'package:idb_sqflite/idb_sqflite.dart';
import 'package:log_inspector/src/database/database_interface.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

/// Basic database service singleton for managing IndexedDB/SQLite operations
class DatabaseService implements DatabaseInterface {
  DatabaseService._();

  static DatabaseService? _instance;
  static DatabaseService get instance {
    _instance ??= DatabaseService._();
    return _instance!;
  }

  // Database configuration
  static const String _dbName = 'LogInspectorDB';
  static const String logsStoreName = 'logs';
  static const String sessionsStoreName = 'sessions';
  static const int _dbVersion = 1;

  Database? _database;
  bool _isInitialized = false;

  /// Execute a transaction against a store and return its result.
  Future<T> _transaction<T>(
    String storeName,
    String mode,
    Future<T> Function(ObjectStore store) action,
  ) async {
    await _ensureInitialized();
    final txn = _database!.transaction(storeName, mode);
    final store = txn.objectStore(storeName);
    final result = await action(store);
    await txn.completed;
    return result;
  }

  /// Get the database instance
  @override
  Database? get database => _database;

  /// Check if the database is initialized
  @override
  bool get isInitialized => _isInitialized;

  /// Initialize the database
  @override
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      IdbFactory factory;

      if (kIsWeb) {
        factory = getIdbFactory()!;
      } else {
        factory = getIdbFactorySqflite(sqflite.databaseFactory);
      }

      _database = await factory.open(_dbName, version: _dbVersion,
          onUpgradeNeeded: (VersionChangeEvent event) {
        final db = event.database;

        // Create logs store with sessionId index
        final logsStore = db.createObjectStore(logsStoreName, keyPath: 'id', autoIncrement: true);
        logsStore.createIndex('sessionId', 'sessionId', unique: false);

        // Create sessions store
        db.createObjectStore(sessionsStoreName, keyPath: 'id');
      });

      _isInitialized = true;
      debugPrint('Database initialized successfully');
    } catch (e) {
      debugPrint('Error initializing database: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  /// Close the database connection
  @override
  Future<void> close() async {
    if (_database != null) {
      _database!.close();
      _database = null;
    }
    _isInitialized = false;
    debugPrint('Database closed');
  }

  /// Dispose the singleton instance
  static void dispose() {
    _instance?.close();
    _instance = null;
  }

  // Basic CRUD operations

  /// Create/Insert a record in the specified store
  @override
  Future<void> create(String storeName, Map<String, dynamic> data) async {
    await _transaction<void>(
      storeName,
      'readwrite',
      (store) => store.add(data),
    );
    if (kDebugMode) debugPrint('Created record in $storeName');
  }

  /// Read a single record by key from the specified store
  @override
  Future<Map<String, dynamic>?> read(String storeName, String key) async {
    final obj = await _transaction<Object?>(
      storeName,
      'readonly',
      (store) => store.getObject(key),
    );
    return obj is Map<String, dynamic> ? obj : null;
  }

  /// Read all records from the specified store
  @override
  Future<List<Map<String, dynamic>>> readAll(String storeName) async {
    final all = await _transaction<List<Object?>>(
      storeName,
      'readonly',
      (store) => store.getAll(),
    );
    return all.whereType<Map<String, dynamic>>().toList();
  }

  /// Update a record in the specified store
  @override
  Future<void> update(String storeName, String key, Map<String, dynamic> data) async {
    await _transaction<void>(
      storeName,
      'readwrite',
      (store) async {
        final keyPath = store.keyPath;
        if (keyPath is String) {
          data[keyPath] = key;
        }
        await store.put(data);
      },
    );
    if (kDebugMode) debugPrint('Updated record in $storeName');
  }

  /// Delete a record by key from the specified store
  @override
  Future<void> delete(String storeName, String key) async {
    await _transaction<void>(
      storeName,
      'readwrite',
      (store) => store.delete(key),
    );
    if (kDebugMode) debugPrint('Deleted record from $storeName');
  }

  /// Clear all records from the specified store
  @override
  Future<void> clear(String storeName) async {
    await _transaction<void>(
      storeName,
      'readwrite',
      (store) => store.clear(),
    );
    if (kDebugMode) debugPrint('Cleared all records from $storeName');
  }

  /// Query records from the specified store using a KeyRange filter
  @override
  Future<List<Map<String, dynamic>>> query(String storeName, {KeyRange? keyRange}) async {
    await _ensureInitialized();

    try {
      return await _transaction<List<Map<String, dynamic>>>(
        storeName,
        'readonly',
        (store) async {
          final index = store.index('sessionId');

          final all = await index.getAll(keyRange);
          return all.whereType<Map<String, dynamic>>().toList();
        },
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Error querying records from $storeName: $e');
      return [];
    }
  }

  /// Get paginated records by sessionId using index
  Future<List<Map<String, dynamic>>> getPageByKeyRange(
    KeyRange keyRange,
    int page,
    int pageSize,
  ) async {
    await _ensureInitialized();

    if (page < 0) {
      throw ArgumentError('Page number must be non-negative');
    }

    if (pageSize <= 0) {
      throw ArgumentError('Page size must be positive');
    }

    try {
      final offset = page * pageSize;

      return await _transaction<List<Map<String, dynamic>>>(
        logsStoreName,
        'readonly',
        (store) async {
          final index = store.index('sessionId');
          final records = <Map<String, dynamic>>[];

          // Open cursor with key range - don't use autoAdvance for manual control
          final cursorStream = index.openCursor(range: keyRange);

          bool hasAdvanced = false;
          int collected = 0;

          await for (final cursor in cursorStream) {
            // Skip to the desired page on first iteration
            if (!hasAdvanced && offset > 0) {
              cursor.advance(offset);
              hasAdvanced = true;
              continue;
            }

            // Collect records for this page
            if (collected < pageSize) {
              final value = cursor.value;
              if (value is Map<String, dynamic>) {
                records.add(value);
                collected++;
              }

              if (collected < pageSize) {
                cursor.next();
              } else {
                break; // We have enough records, exit the loop
              }
            } else {
              break; // We have enough records
            }
          }

          return records;
        },
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Error getting page by sessionId: $e');
      return [];
    }
  }

  /// Count records in the specified store
  @override
  Future<int> count(String storeName, {KeyRange? keyRange}) async {
    await _ensureInitialized();

    try {
      return _transaction<int>(
        storeName,
        'readonly',
        (store) {
          if (keyRange == null) {
            return store.count();
          }
          final index = store.index('sessionId');
          return index.count(keyRange);
        },
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Error counting records in $storeName: $e');
      return 0;
    }
  }

  /// Ensure database is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await init();
    }
    if (_database == null) {
      throw StateError('Database is not initialized');
    }
  }
}
