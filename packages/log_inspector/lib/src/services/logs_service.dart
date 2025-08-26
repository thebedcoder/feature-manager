import 'package:idb_shim/idb.dart';
import 'package:log_inspector/src/database/database_interface.dart';
import 'package:log_inspector/src/database/database_service.dart';
import 'package:flutter/foundation.dart';

/// Service for managing logs
class LogsService {
  LogsService._([DatabaseInterface? database]) : _database = database ?? DatabaseService.instance;

  static LogsService? _instance;
  static LogsService get instance {
    _instance ??= LogsService._();
    return _instance!;
  }

  /// Create a test instance with a mock database
  /// This should only be used for testing
  @visibleForTesting
  static LogsService createForTesting(DatabaseInterface database) {
    return LogsService._(database);
  }

  final DatabaseInterface _database;

  /// Store logs in the database
  Future<void> storeLogs(List<String> logs, String sessionId) async {
    for (final log in logs) {
      await _database.create(DatabaseService.logsStoreName, {
        'log': log,
        'sessionId': sessionId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  /// Get all logs for a specific session
  Future<List<String>> getLogsForSession(String sessionId) async {
    final records = await _database.query(DatabaseService.logsStoreName,
        keyRange: KeyRange.only(sessionId));

    final logs = <String>[];
    for (final record in records) {
      if (record['log'] != null) {
        logs.add(record['log'].toString());
      }
    }

    return logs;
  }

  /// Get paginated logs for a specific session
  Future<List<String>> getLogsPageForSession(
      String sessionId, int page, int pageSize) async {
    final records = await _database.getPageByKeyRange(
      KeyRange.only(sessionId),
      page,
      pageSize,
    );

    final logs = <String>[];
    for (final record in records) {
      if (record['log'] != null) {
        logs.add(record['log'].toString());
      }
    }

    return logs;
  }

  /// Get total number of logs for a specific session
  Future<int> getTotalLogsCountForSession(String sessionId) {
    return _database.count(DatabaseService.logsStoreName,
        keyRange: KeyRange.only(sessionId));
  }

  /// Delete all logs for a specific session
  Future<void> deleteLogsForSession(String sessionId) async {
    final records = await _database.query(DatabaseService.logsStoreName,
        keyRange: KeyRange.only(sessionId));

    // Delete each log record
    for (final record in records) {
      if (record['id'] != null) {
        await _database.delete(
            DatabaseService.logsStoreName, record['id'].toString());
      }
    }
  }

  /// Clear all logs
  Future<void> clearAllLogs() async {
    await _database.clear(DatabaseService.logsStoreName);
  }

  /// Dispose the singleton instance
  static void dispose() {
    _instance = null;
  }
}
