import 'package:idb_shim/idb_shim.dart';

/// Abstract interface for basic database operations
abstract class DatabaseInterface {
  /// Get the database instance
  Database? get database;

  /// Check if the database is initialized
  bool get isInitialized;

  /// Initialize the database
  Future<void> init();

  /// Close the database connection
  Future<void> close();

  // Basic CRUD operations

  /// Create/Insert a record in the specified store
  Future<void> create(String storeName, Map<String, dynamic> data);

  /// Read a single record by key from the specified store
  Future<Map<String, dynamic>?> read(String storeName, String key);

  /// Read all records from the specified store
  Future<List<Map<String, dynamic>>> readAll(String storeName);

  /// Update a record in the specified store
  Future<void> update(String storeName, String key, Map<String, dynamic> data);

  /// Delete a record by key from the specified store
  Future<void> delete(String storeName, String key);

  /// Clear all records from the specified store
  Future<void> clear(String storeName);

  /// Count records in the specified store
  Future<int> count(String storeName, {KeyRange? keyRange});

  /// Query records from the specified store using a KeyRange filter
  Future<List<Map<String, dynamic>>> query(String storeName, {KeyRange? keyRange});
}
