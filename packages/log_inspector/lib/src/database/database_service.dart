import 'package:flutter/foundation.dart';
import 'package:idb_shim/idb_browser.dart';
import 'package:idb_shim/idb.dart';
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
        // Initialize sqflite database factory for non-web platforms
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
    // Ensure the key is present
    data[(_database!.transaction(storeName, 'readwrite').objectStore(storeName).keyPath)
        as String] = key;
    await _transaction<void>(
      storeName,
      'readwrite',
      (store) => store.put(data),
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

  /// Query records with a filter function
  @override
  Future<List<Map<String, dynamic>>> query(
    String storeName,
    bool Function(Map<String, dynamic>) filter,
  ) async {
    await _ensureInitialized();

    try {
      final transaction = _database!.transaction(storeName, 'readonly');
      final store = transaction.objectStore(storeName);
      final records = <Map<String, dynamic>>[];

      await for (final cursor in store.openCursor()) {
        final value = cursor.value;
        if (value is Map<String, dynamic> && filter(value)) {
          records.add(value);
        }
        cursor.next();
      }

      return records;
    } catch (e) {
      debugPrint('Error querying records from $storeName: $e');
      return [];
    }
  }

  /// Efficiently query records by sessionId using index
  Future<List<Map<String, dynamic>>> queryBySessionId(String sessionId) async {
    await _ensureInitialized();

    try {
      final transaction = _database!.transaction(logsStoreName, 'readonly');
      final store = transaction.objectStore(logsStoreName);
      final index = store.index('sessionId');

      final records = <Map<String, dynamic>>[];
      final keyRange = KeyRange.only(sessionId);

      // Use index cursor for efficient filtering
      await for (final cursor in index.openCursor(range: keyRange)) {
        final value = cursor.value;
        if (value is Map<String, dynamic>) {
          records.add(value);
        }
        cursor.next();
      }

      return records;
    } catch (e) {
      debugPrint('Error querying records by sessionId: $e');
      return [];
    }
  }

  /// Count records by sessionId using index
  Future<int> countBySessionId(String sessionId) async {
    await _ensureInitialized();

    try {
      final transaction = _database!.transaction(logsStoreName, 'readonly');
      final store = transaction.objectStore(logsStoreName);
      final index = store.index('sessionId');

      final keyRange = KeyRange.only(sessionId);
      return await index.count(keyRange);
    } catch (e) {
      debugPrint('Error counting records by sessionId: $e');
      return 0;
    }
  }

  /// Get paginated records by sessionId using index
  Future<List<Map<String, dynamic>>> getPageBySessionId(
    String sessionId,
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
      final keyRange = KeyRange.only(sessionId);
      final offset = page * pageSize;

      // Use the same pattern as the existing pagination code
      return await _transaction<List<Map<String, dynamic>>>(
        logsStoreName,
        'readonly',
        (store) async {
          final index = store.index('sessionId');
          final records = <Map<String, dynamic>>[];
          
          // Get first cursor with key range
          final cursorStream = index.openCursor(range: keyRange);
          final cursor = await cursorStream.first;
          
          // Skip to the desired page using cursor.advance() - much more efficient!
          if (offset > 0) {
            cursor.advance(offset);
          }

          int collected = 0;
          // Collect records for this page
          while (collected < pageSize) {
            final value = cursor.value;
            if (value is Map<String, dynamic>) {
              records.add(value);
              collected++;
            } else {
              break; // No more records
            }
            
            if (collected < pageSize) {
              cursor.next();
            }
          }
          
          return records;
        },
      );
    } catch (e) {
      debugPrint('Error getting page by sessionId: $e');
      return [];
    }
  }

  /// Get paginated records from the specified store
  @override
  Future<List<Map<String, dynamic>>> getPage(String storeName, int page, int pageSize,
      {bool Function(Map<String, dynamic>)? filter}) async {
    await _ensureInitialized();

    if (page < 0) {
      throw ArgumentError('Page number must be non-negative');
    }

    if (pageSize <= 0) {
      throw ArgumentError('Page size must be positive');
    }

    try {
      final transaction = _database!.transaction(storeName, 'readonly');
      final store = transaction.objectStore(storeName);

      final List<Map<String, dynamic>> records = [];
      final offset = page * pageSize;

      // If no filter is provided, use more efficient approach
      if (filter == null) {
        return await _transaction<List<Map<String, dynamic>>>(
          storeName,
          'readonly',
          (store) async {
            final List<Map<String, dynamic>> records = [];
            final cursor = await store.openCursor().first;
            cursor.advance(page * pageSize);
            int collected = 0;
            while (collected < pageSize) {
              final v = cursor.value;
              if (v is Map<String, dynamic>) {
                records.add(v);
                collected++;
              }
              cursor.next();
            }
            return records;
          },
        );
      } else {
        // When filter is provided, we need to iterate through all records
        // but we can still optimize by tracking filtered count
        int filteredCount = 0;
        int collected = 0;

        await for (final cursor in store.openCursor()) {
          final value = cursor.value;
          if (value is Map<String, dynamic>) {
            final matchesFilter = filter(value);

            if (matchesFilter) {
              // Skip records until we reach the offset
              if (filteredCount < offset) {
                filteredCount++;
                cursor.next();
                continue;
              }

              // Collect records for this page
              records.add(value);
              collected++;

              if (collected >= pageSize) {
                break;
              }
            }
          }
          cursor.next();
        }
      }

      return records;
    } catch (e) {
      debugPrint('Error reading page from $storeName: $e');
      return [];
    }
  }

  /// Count records in the specified store
  @override
  Future<int> count(String storeName, {bool Function(Map<String, dynamic>)? filter}) async {
    await _ensureInitialized();

    try {
      final transaction = _database!.transaction(storeName, 'readonly');
      final store = transaction.objectStore(storeName);

      if (filter == null) {
        return await _transaction<int>(
          storeName,
          'readonly',
          (store) => store.count(),
        );
      }

      int count = 0;
      await for (final cursor in store.openCursor()) {
        final value = cursor.value;
        if (value is Map<String, dynamic>) {
          final matchesFilter = filter(value);
          if (matchesFilter) {
            count++;
          }
        }
        cursor.next();
      }

      return count;
    } catch (e) {
      debugPrint('Error counting records in $storeName: $e');
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
