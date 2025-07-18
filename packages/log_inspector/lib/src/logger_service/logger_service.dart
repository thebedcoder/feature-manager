import 'package:log_inspector/src/models/paginated_logs.dart';
import 'package:log_inspector/src/models/session.dart';

abstract class LoggerService {
  /// Downloads logs as a file.
  Future<void> downloadLogs();

  /// Reads logs from storage.
  Future<String> readLogs();

  /// Reads paginated logs with metadata.
  Future<PaginatedLogs> readLogsPaginated(int page, {int pageSize = 4});

  /// Cleans up old logs.
  Future<void> cleanLogs();

  /// Gets the number of log files.
  Future<int> getLogFilesCount();

  /// Gets the total size of logs in bytes.
  Future<int> getLogsSizeInBytes();

  // Session-related methods
  /// Gets all sessions.
  Future<List<LogSession>> getAllSessions();

  /// Gets paginated sessions.
  Future<PaginatedSessions> getSessionsPaginated(int page, {int pageSize = 20});

  /// Gets a specific session by ID.
  Future<LogSession?> getSession(String sessionId);

  /// Deletes a specific session and its logs.
  Future<void> deleteSession(String sessionId);

  /// Gets the current session ID.
  String get currentSessionId;

  /// Reads logs for a specific session.
  Future<String> readLogsForSession(String sessionId);

  /// Reads paginated logs for a specific session.
  Future<PaginatedLogs> readLogsPaginatedForSession(String sessionId, int page,
      {int pageSize = 100});

  /// Downloads logs for a specific session.
  Future<void> downloadLogsForSession(String sessionId);

  /// Clears logs for a specific session.
  Future<void> clearLogsForSession(String sessionId);
}
