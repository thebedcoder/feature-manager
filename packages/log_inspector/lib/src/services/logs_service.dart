import 'package:log_inspector/src/database/database_interface.dart';
import 'package:log_inspector/src/database/database_service.dart';

/// Service for managing logs
class LogsService {
  LogsService._();

  static LogsService? _instance;
  static LogsService get instance {
    _instance ??= LogsService._();
    return _instance!;
  }

  final DatabaseInterface _database = DatabaseService.instance;

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
    final records = await (_database as DatabaseService).queryBySessionId(sessionId);

    final logs = <String>[];
    for (final record in records) {
      if (record['log'] != null) {
        logs.add(record['log'].toString());
      }
    }

    return logs;
  }

  /// Get paginated logs for a specific session
  Future<List<String>> getLogsPageForSession(String sessionId, int page, int pageSize) async {
    final records = await (_database as DatabaseService).getPageBySessionId(
      sessionId, 
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
  Future<int> getTotalLogsCountForSession(String sessionId) async {
    return await (_database as DatabaseService).countBySessionId(sessionId);
  }

  /// Delete all logs for a specific session
  Future<void> deleteLogsForSession(String sessionId) async {
    // Get all logs for the session first
    final records = await _database.query(
      DatabaseService.logsStoreName, 
      (record) => record['sessionId'] == sessionId,
    );

    // Delete each log record
    for (final record in records) {
      if (record['id'] != null) {
        await _database.delete(DatabaseService.logsStoreName, record['id'].toString());
      }
    }
  }

  /// Clear all logs
  Future<void> clearAllLogs() async {
    await _database.clear(DatabaseService.logsStoreName);
  }

  /// Get total logs count across all sessions
  Future<int> getTotalLogsCount() async {
    return await _database.count(DatabaseService.logsStoreName);
  }

  /// Get logs by timestamp range for a specific session
  Future<List<String>> getLogsForSessionByTimeRange(
    String sessionId, 
    DateTime startTime, 
    DateTime endTime,
  ) async {
    final startTimestamp = startTime.millisecondsSinceEpoch;
    final endTimestamp = endTime.millisecondsSinceEpoch;

    final records = await _database.query(
      DatabaseService.logsStoreName, 
      (record) => 
        record['sessionId'] == sessionId &&
        record['timestamp'] != null &&
        record['timestamp'] >= startTimestamp &&
        record['timestamp'] <= endTimestamp,
    );

    final logs = <String>[];
    for (final record in records) {
      if (record['log'] != null) {
        logs.add(record['log'].toString());
      }
    }

    return logs;
  }

  /// Search logs by content for a specific session
  Future<List<String>> searchLogsForSession(String sessionId, String searchTerm) async {
    final records = await _database.query(
      DatabaseService.logsStoreName, 
      (record) => 
        record['sessionId'] == sessionId &&
        record['log'] != null &&
        record['log'].toString().toLowerCase().contains(searchTerm.toLowerCase()),
    );

    final logs = <String>[];
    for (final record in records) {
      if (record['log'] != null) {
        logs.add(record['log'].toString());
      }
    }

    return logs;
  }

  /// Dispose the singleton instance
  static void dispose() {
    _instance = null;
  }
}
