import 'package:log_inspector/src/database/database_interface.dart';
import 'package:log_inspector/src/database/database_service.dart';
import 'package:log_inspector/src/models/session.dart';

/// Service for managing log sessions
class SessionsService {
  SessionsService._();

  static SessionsService? _instance;
  static SessionsService get instance {
    _instance ??= SessionsService._();
    return _instance!;
  }

  final DatabaseInterface _database = DatabaseService.instance;

  /// Create a new session record
  Future<void> createSession(LogSession session) async {
    await _database.create(DatabaseService.sessionsStoreName, session.toMap());
  }

  /// Get all sessions from the database
  Future<List<LogSession>> getAllSessions() async {
    final records = await _database.readAll(DatabaseService.sessionsStoreName);

    final sessions = <LogSession>[];
    for (final record in records) {
      try {
        sessions.add(LogSession.fromMap(record));
      } catch (e) {
        // Skip invalid records
        continue;
      }
    }

    // Sort by creation date (newest first)
    sessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sessions;
  }

  /// Get session by ID
  Future<LogSession?> getSession(String sessionId) async {
    final record = await _database.read(DatabaseService.sessionsStoreName, sessionId);

    if (record != null) {
      try {
        return LogSession.fromMap(record);
      } catch (e) {
        // Return null if session data is invalid
        return null;
      }
    }

    return null;
  }

  /// Update session activity and log count
  Future<void> updateSessionActivity(String sessionId, int additionalLogCount) async {
    final existingRecord = await _database.read(DatabaseService.sessionsStoreName, sessionId);

    if (existingRecord != null) {
      final updatedSession = Map<String, dynamic>.from(existingRecord);
      updatedSession['lastActivityAt'] = DateTime.now().millisecondsSinceEpoch;
      updatedSession['logCount'] = (updatedSession['logCount'] as int) + additionalLogCount;

      await _database.update(DatabaseService.sessionsStoreName, sessionId, updatedSession);
    }
  }

  /// Delete a session
  Future<void> deleteSession(String sessionId) async {
    await _database.delete(DatabaseService.sessionsStoreName, sessionId);
  }

  /// Clear all sessions
  Future<void> clearAllSessions() async {
    await _database.clear(DatabaseService.sessionsStoreName);
  }

  /// Dispose the singleton instance
  static void dispose() {
    _instance = null;
  }
}
