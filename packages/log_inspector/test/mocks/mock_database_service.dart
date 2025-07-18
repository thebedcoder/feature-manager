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
  Future<List<Map<String, dynamic>>> getPage(String storeName, int page, int pageSize,
      {bool Function(Map<String, dynamic>)? filter}) async {
    _ensureStoreExists(storeName);
    var records = _stores[storeName]!.values.toList();

    if (filter != null) {
      records = records.where(filter).toList();
    }

    final startIndex = page * pageSize;
    final endIndex = startIndex + pageSize;

    if (startIndex >= records.length) {
      return [];
    }

    return records.sublist(startIndex, endIndex.clamp(0, records.length));
  }

  @override
  Future<int> count(String storeName, {bool Function(Map<String, dynamic>)? filter}) async {
    _ensureStoreExists(storeName);
    var records = _stores[storeName]!.values.toList();

    if (filter != null) {
      records = records.where(filter).toList();
    }

    return records.length;
  }
}
