import 'package:idb_shim/idb_shim.dart';
import 'package:log_inspector/src/database/database_interface.dart';

/// Mock database service for testing
class MockDatabaseService implements DatabaseInterface {
  bool _isInitialized = false;
  final Map<String, Map<String, Map<String, dynamic>>> _stores = {};

  @override
  Database? get database => null;

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<void> init() async {
    _isInitialized = true;
  }

  @override
  Future<void> close() async {
    _isInitialized = false;
  }

  void _ensureStoreExists(String storeName) {
    _stores[storeName] ??= {};
  }

  @override
  Future<void> create(String storeName, Map<String, dynamic> data) async {
    _ensureStoreExists(storeName);
    final key = data['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
    _stores[storeName]![key] = Map.from(data);
  }

  @override
  Future<Map<String, dynamic>?> read(String storeName, String key) async {
    _ensureStoreExists(storeName);
    return _stores[storeName]![key];
  }

  @override
  Future<List<Map<String, dynamic>>> readAll(String storeName) async {
    _ensureStoreExists(storeName);
    return _stores[storeName]!.values.toList();
  }

  @override
  Future<void> update(String storeName, String key, Map<String, dynamic> data) async {
    _ensureStoreExists(storeName);
    _stores[storeName]![key] = Map.from(data);
  }

  @override
  Future<void> delete(String storeName, String key) async {
    _ensureStoreExists(storeName);
    _stores[storeName]!.remove(key);
  }

  @override
  Future<void> clear(String storeName) async {
    _ensureStoreExists(storeName);
    _stores[storeName]!.clear();
  }

  @override
  Future<int> count(String storeName, {KeyRange? keyRange}) async {
    _ensureStoreExists(storeName);
    var records = _stores[storeName]!.values.toList();

    // Simple implementation - keyRange filtering would be more complex in reality
    if (keyRange != null) {
      // For mock purposes, we'll just return the total count
      // In a real implementation, this would filter based on the keyRange
    }

    return records.length;
  }

  @override
  Future<List<Map<String, dynamic>>> query(String storeName, {KeyRange? keyRange}) async {
    _ensureStoreExists(storeName);
    var records = _stores[storeName]!.values.toList();

    // Simple implementation - keyRange filtering would be more complex in reality
    if (keyRange != null) {
      // For mock purposes, we'll simulate filtering
      // In a real implementation, this would filter based on the keyRange
      // For testing, we'll return all records
    }

    return records;
  }
}
