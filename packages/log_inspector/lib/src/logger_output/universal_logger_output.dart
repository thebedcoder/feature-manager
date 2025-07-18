import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:log_inspector/src/database/database_interface.dart';
import 'package:log_inspector/src/database/database_service.dart';
import 'package:log_inspector/src/services/logs_service.dart';
import 'package:log_inspector/src/services/sessions_service.dart';
import 'package:log_inspector/src/download/universal_download.dart';
import 'package:log_inspector/src/models/paginated_logs.dart';
import 'package:log_inspector/src/models/session.dart';
import 'package:logger/logger.dart';

/// Web implementation of UniversalLoggerOutput using IndexedDB with session support
class UniversalLoggerOutput extends LogOutput {
  UniversalLoggerOutput({
    this.shouldLog = true,
    this.localStorageKey = 'log_inspector_logs',
    this.logFileName = 'app_logs',
    DatabaseInterface? databaseService,
    LogsService? logsService,
    SessionsService? sessionsService,
  })  : _databaseService = databaseService ?? DatabaseService.instance,
        _logsService = logsService ?? LogsService.instance,
        _sessionsService = sessionsService ?? SessionsService.instance {
    _instance ??= this;
    _currentSessionId = _generateSessionId();
  }

  static UniversalLoggerOutput? _instance;
  static UniversalLoggerOutput get instance {
    if (_instance == null) {
      throw StateError(
        'No UniversalLoggerOutput instance registered. '
        'Call register() on your UniversalLoggerOutput instance first.',
      );
    }
    return _instance!;
  }

  final bool shouldLog;
  final String localStorageKey;
  final String logFileName;
  final DatabaseInterface _databaseService;
  final LogsService _logsService;
  final SessionsService _sessionsService;

  // Session management
  String _currentSessionId = '';

  /// Get the current session ID
  String get currentSessionId => _currentSessionId;

  final List<String> _webLogs = [];
  bool _isInitialized = false;

  /// Generate a unique session ID
  String _generateSessionId() {
    return 'session_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Create a new session (called when creating a new instance or explicitly)

  /// Create a session record in the database
  Future<void> _createSessionRecord() async {
    if (!_databaseService.isInitialized) return;

    try {
      final now = DateTime.now();
      final session = LogSession(
        id: _currentSessionId,
        createdAt: now,
        lastActivityAt: now,
        logCount: 0,
      );

      await _sessionsService.createSession(session);
      debugPrint('Created new session: $_currentSessionId');
    } catch (e) {
      debugPrint('Error creating session record: $e');
    }
  }

  @override
  Future<void> init() async {
    if (!shouldLog) return;

    try {
      // Initialize the database service
      await _databaseService.init();
      _isInitialized = true;

      // Load existing logs for current session
      await _loadLogs();

      // Create session record
      await _createSessionRecord();
      debugPrint('Logger initialized with session: $_currentSessionId');
    } catch (e) {
      debugPrint('Error initializing logger: $e');
      _isInitialized = false;
    }
  }

  Future<void> _loadLogs() async {
    if (!_databaseService.isInitialized) return;

    try {
      final logs = await _logsService.getLogsForSession(_currentSessionId);
      _webLogs.clear();
      _webLogs.addAll(logs);

      debugPrint('Loaded ${_webLogs.length} logs from database for session $_currentSessionId');
    } catch (e) {
      debugPrint('Error loading logs from database: $e');
    }
  }

  @override
  void output(OutputEvent event) {
    if (!shouldLog) return;

    // Console output
    event.lines.forEach(debugPrint);

    // Add logs to memory array
    _webLogs.addAll(event.lines);

    // Store in IndexedDB with session information
    _storeLogs(event.lines);

    // Update session activity
    _updateSessionActivity(event.lines.length);
  }

  Future<void> _storeLogs(List<String> newLogs) async {
    if (!_databaseService.isInitialized) return;

    try {
      await _logsService.storeLogs(newLogs, _currentSessionId);
    } catch (e) {
      debugPrint('Error storing logs to database: $e');
    }
  }

  /// Update session activity and log count
  Future<void> _updateSessionActivity(int newLogCount) async {
    if (!_databaseService.isInitialized) return;

    try {
      await _sessionsService.updateSessionActivity(_currentSessionId, newLogCount);
    } catch (e) {
      debugPrint('Error updating session activity: $e');
    }
  }

  @override
  Future<void> destroy() async {
    _webLogs.clear();
    _isInitialized = false;
  }

  /// Get the current logs content
  Future<String> getLogsContent() async {
    if (!_isInitialized) {
      await init();
    }

    if (_webLogs.isEmpty) {
      await _loadLogs();
    }

    return _webLogs.join('\n');
  }

  /// Read logs with pagination
  /// Returns a specific page of logs based on the page size
  Future<List<String>> readLogsPage(int page, {int pageSize = 100}) async {
    if (!_isInitialized) {
      await init();
    }

    if (_webLogs.isEmpty) {
      await _loadLogs();
    }

    if (page < 0) {
      throw ArgumentError('Page number must be non-negative');
    }

    final startIndex = page * pageSize;
    final endIndex = (startIndex + pageSize).clamp(0, _webLogs.length);

    if (startIndex >= _webLogs.length) {
      return <String>[];
    }

    return _webLogs.sublist(startIndex, endIndex);
  }

  /// Read logs page directly from database (more efficient for large datasets)
  /// This method doesn't load all logs into memory first
  Future<List<String>> readLogsPageFromDB(int page, {int pageSize = 100, String? sessionId}) async {
    if (!_isInitialized) {
      await init();
    }

    if (!_databaseService.isInitialized) {
      return <String>[];
    }

    if (page < 0) {
      throw ArgumentError('Page number must be non-negative');
    }

    final targetSessionId = sessionId ?? _currentSessionId;

    try {
      return await _logsService.getLogsPageForSession(targetSessionId, page, pageSize);
    } catch (e) {
      debugPrint('Error reading logs page from database: $e');
      // Fallback to in-memory pagination
      return await readLogsPage(page, pageSize: pageSize);
    }
  }

  /// Get total number of logs directly from database for a specific session
  Future<int> getTotalLogsCount({String? sessionId}) async {
    if (!_isInitialized) {
      await init();
    }

    if (!_databaseService.isInitialized) {
      return _webLogs.length;
    }

    final targetSessionId = sessionId ?? _currentSessionId;

    try {
      return await _logsService.getTotalLogsCountForSession(targetSessionId);
    } catch (e) {
      debugPrint('Error getting logs count from database: $e');
      return _webLogs.length;
    }
  }

  /// Get the total number of pages for pagination
  Future<int> getTotalPages({int pageSize = 100}) async {
    if (!_isInitialized) {
      await init();
    }

    if (_webLogs.isEmpty) {
      await _loadLogs();
    }

    if (pageSize <= 0) {
      throw ArgumentError('Page size must be positive');
    }

    return (_webLogs.length / pageSize).ceil();
  }

  /// Get paginated logs with metadata for a specific session
  Future<PaginatedLogs> readLogsPaginated(int page, {int pageSize = 100, String? sessionId}) async {
    if (!_isInitialized) {
      await init();
    }

    final targetSessionId = sessionId ?? _currentSessionId;

    // If requesting current session, use in-memory data
    if (targetSessionId == _currentSessionId) {
      if (_webLogs.isEmpty) {
        await _loadLogs();
      }

      final totalLogs = _webLogs.length;
      final totalPages = (totalLogs / pageSize).ceil();
      final logs = await readLogsPage(page, pageSize: pageSize);

      return PaginatedLogs(
        logs: logs,
        currentPage: page,
        pageSize: pageSize,
        totalLogs: totalLogs,
        totalPages: totalPages,
        hasNextPage: page < totalPages - 1,
        hasPreviousPage: page > 0,
      );
    } else {
      // For other sessions, use database directly
      return await readLogsPaginatedFromDB(page, pageSize: pageSize, sessionId: targetSessionId);
    }
  }

  /// Get paginated logs directly from IndexedDB with metadata for a specific session
  Future<PaginatedLogs> readLogsPaginatedFromDB(int page,
      {int pageSize = 100, String? sessionId}) async {
    if (!_isInitialized) {
      await init();
    }

    final targetSessionId = sessionId ?? _currentSessionId;
    final totalLogs = await getTotalLogsCount(sessionId: targetSessionId);
    final totalPages = (totalLogs / pageSize).ceil();
    final logs = await readLogsPageFromDB(page, pageSize: pageSize, sessionId: targetSessionId);

    return PaginatedLogs(
      logs: logs,
      currentPage: page,
      pageSize: pageSize,
      totalLogs: totalLogs,
      totalPages: totalPages,
      hasNextPage: page < totalPages - 1,
      hasPreviousPage: page > 0,
    );
  }

  /// Get the number of log files/sources
  Future<int> getLogFilesCount() async {
    if (!_isInitialized) {
      await init();
    }

    return _webLogs.isNotEmpty ? 1 : 0;
  }

  /// Get the total size of logs in bytes
  Future<int> getLogsSizeInBytes() async {
    if (!_isInitialized) {
      await init();
    }

    if (_webLogs.isEmpty) {
      await _loadLogs();
    }

    return utf8.encode(_webLogs.join('\n')).length;
  }

  /// Clear all logs for current session or all sessions
  Future<void> clearLogs({bool allSessions = false}) async {
    if (!_isInitialized) {
      await init();
    }

    _webLogs.clear();

    if (_databaseService.isInitialized) {
      try {
        if (allSessions) {
          // Clear all logs and sessions
          await _logsService.clearAllLogs();
          await _sessionsService.clearAllSessions();
          debugPrint('All database logs and sessions cleared');
        } else {
          // Clear only current session logs
          await _logsService.deleteLogsForSession(_currentSessionId);
          await _sessionsService.deleteSession(_currentSessionId);
          debugPrint('Database logs for session $_currentSessionId cleared');
        }
      } catch (e) {
        debugPrint('Error clearing database logs: $e');
      }
    }
  }

  /// Download logs using web download functionality
  Future<void> downloadLogs() async {
    if (!_isInitialized) {
      await init();
    }

    if (_webLogs.isEmpty) {
      await _loadLogs();
    }

    if (_webLogs.isEmpty) return;

    try {
      final content = _webLogs.join('\n');

      await UniversalDownload.downloadLogs(content);
    } catch (e) {
      debugPrint('Error downloading web logs: $e');
    }
  }

  /// Download logs with custom content and filename
  Future<void> downloadLogsWithContent(String content, String fileName) async {
    try {
      await UniversalDownload.downloadLogs(content, fileName);
    } catch (e) {
      debugPrint('Error downloading custom logs: $e');
    }
  }

  /// Check if logs exist
  Future<bool> hasLogs() async {
    return await getLogFilesCount() > 0;
  }

  /// Get all sessions from the database
  Future<List<LogSession>> getAllSessions() async {
    if (!_isInitialized) {
      await init();
    }

    if (!_databaseService.isInitialized) {
      return [];
    }

    try {
      return await _sessionsService.getAllSessions();
    } catch (e) {
      debugPrint('Error getting sessions from database: $e');
      return [];
    }
  }

  /// Get paginated sessions
  Future<PaginatedSessions> getSessionsPaginated(int page, {int pageSize = 20}) async {
    final allSessions = await getAllSessions();
    final totalSessions = allSessions.length;
    final totalPages = (totalSessions / pageSize).ceil();

    final startIndex = page * pageSize;
    final endIndex = (startIndex + pageSize).clamp(0, allSessions.length);

    final sessions = startIndex < allSessions.length
        ? allSessions.sublist(startIndex, endIndex)
        : <LogSession>[];

    return PaginatedSessions(
      sessions: sessions,
      currentPage: page,
      pageSize: pageSize,
      totalSessions: totalSessions,
      totalPages: totalPages,
      hasNextPage: page < totalPages - 1,
      hasPreviousPage: page > 0,
    );
  }

  /// Get session by ID
  Future<LogSession?> getSession(String sessionId) async {
    if (!_isInitialized) {
      await init();
    }

    if (!_databaseService.isInitialized) {
      return null;
    }

    try {
      return await _sessionsService.getSession(sessionId);
    } catch (e) {
      debugPrint('Error getting session from database: $e');
      return null;
    }
  }

  /// Delete a specific session and its logs
  Future<void> deleteSession(String sessionId) async {
    if (!_isInitialized) {
      await init();
    }

    if (!_databaseService.isInitialized) return;

    try {
      // Delete logs for this session
      await _logsService.deleteLogsForSession(sessionId);

      // Delete session record
      await _sessionsService.deleteSession(sessionId);

      debugPrint('Deleted session: $sessionId');
    } catch (e) {
      debugPrint('Error deleting session: $e');
    }
  }

  /// Get logs content for a specific session
  Future<String> getLogsContentForSession(String sessionId) async {
    if (!_isInitialized) {
      await init();
    }

    if (!_databaseService.isInitialized) {
      return '';
    }

    try {
      final logs = await _logsService.getLogsForSession(sessionId);
      return logs.join('\n');
    } catch (e) {
      debugPrint('Error getting logs content for session: $e');
      return '';
    }
  }
}
