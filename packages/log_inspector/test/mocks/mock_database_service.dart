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
    final key = data['id']?.toString() ?? 
        '${DateTime.now().millisecondsSinceEpoch}_${_stores[storeName]!.length}';
    final recordWithId = Map<String, dynamic>.from(data);
    recordWithId['id'] = key;
    _stores[storeName]![key] = recordWithId;
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

    // Filter by keyRange if provided
    if (keyRange != null) {
      final key = keyRange.lower.toString();
      // Check if this is a sessionId filter or record ID filter
      if (records.isNotEmpty && records.first.containsKey('sessionId')) {
        // This is likely a sessionId filter
        records = records.where((record) => record['sessionId'] == key).toList();
      } else {
        // This is likely a record ID filter - return total count for backward compatibility
        return records.length;
      }
    }

    return records.length;
  }

  @override
  Future<List<Map<String, dynamic>>> query(String storeName, {KeyRange? keyRange}) async {
    _ensureStoreExists(storeName);
    var records = _stores[storeName]!.values.toList();

    // Filter by keyRange if provided
    if (keyRange != null) {
      final key = keyRange.lower.toString();
      // Check if this is a sessionId filter or record ID filter
      if (records.isNotEmpty && records.first.containsKey('sessionId')) {
        // This is likely a sessionId filter
        records = records.where((record) => record['sessionId'] == key).toList();
      } else {
        // This is likely a record ID filter - return all records for backward compatibility
        return records;
      }
    }

    return records;
  }

  @override
  Future<List<Map<String, dynamic>>> getPageByKeyRange(
    KeyRange keyRange,
    int page,
    int pageSize,
  ) async {
    // Simple mock implementation for pagination
    final allRecords = await query('logs', keyRange: keyRange);
    
    if (page < 0 || pageSize <= 0) {
      return [];
    }

    final startIndex = page * pageSize;
    final endIndex = (startIndex + pageSize).clamp(0, allRecords.length);

    if (startIndex >= allRecords.length) {
      return [];
    }

    return allRecords.sublist(startIndex, endIndex);
  }
}
