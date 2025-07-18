import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:idb_shim/idb_browser.dart';
import 'package:idb_sqflite/idb_sqflite.dart';
import 'package:log_inspector/src/download/universal_download.dart';
import 'package:log_inspector/src/models/paginated_logs.dart';
import 'package:log_inspector/src/models/session.dart';
import 'package:logger/logger.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

/// Web implementation of UniversalLoggerOutput using IndexedDB with session support
class UniversalLoggerOutput extends LogOutput {
  UniversalLoggerOutput({
    this.shouldLog = true,
    this.localStorageKey = 'log_inspector_logs',
    this.logFileName = 'app_logs',
  }) {
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

  // Session management
  String _currentSessionId = '';

  /// Get the current session ID
  String get currentSessionId => _currentSessionId;

  // IndexedDB-specific properties
  static const String _dbName = 'LogInspectorDB';
  static const String _logsStoreName = 'logs';
  static const String _sessionsStoreName = 'sessions';
  static const int _dbVersion = 2; // Incremented for schema change

  Database? _database;
  final List<String> _webLogs = [];
  bool _isInitialized = false;

  /// Generate a unique session ID
  String _generateSessionId() {
    return 'session_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  /// Create a new session (called when creating a new instance or explicitly)

  /// Create a session record in the database
  Future<void> _createSessionRecord() async {
    if (_database == null || !_isInitialized) return;

    try {
      final transaction = _database!.transaction(_sessionsStoreName, 'readwrite');
      final store = transaction.objectStore(_sessionsStoreName);

      final now = DateTime.now();
      await store.add({
        'id': _currentSessionId,
        'createdAt': now.millisecondsSinceEpoch,
        'lastActivityAt': now.millisecondsSinceEpoch,
        'logCount': 0,
      });

      await transaction.completed;
      debugPrint('Created new session: $_currentSessionId');
    } catch (e) {
      debugPrint('Error creating session record: $e');
    }
  }

  @override
  Future<void> init() async {
    if (!shouldLog) return;

    try {
      IdbFactory factory;

      if (kIsWeb) {
        factory = getIdbFactory()!;
      } else {
        // Initialize sqflite database factory for non-web platforms
        // This ensures the underlying sqflite database factory is properly initialized
        factory = getIdbFactorySqflite(sqflite.databaseFactory);
      }

      _database = await factory.open(_dbName, version: _dbVersion,
          onUpgradeNeeded: (VersionChangeEvent event) {
        final db = event.database;

        // Create logs store
        if (!db.objectStoreNames.contains(_logsStoreName)) {
          db.createObjectStore(_logsStoreName, keyPath: 'id', autoIncrement: true);
        }

        // Create sessions store
        if (!db.objectStoreNames.contains(_sessionsStoreName)) {
          db.createObjectStore(_sessionsStoreName, keyPath: 'id');
        }
      });

      _isInitialized = true;

      // Load existing logs for current session
      await _loadLogs();

      // Create session record
      await _createSessionRecord();
      debugPrint('IndexedDB logger initialized with session: $_currentSessionId');
    } catch (e) {
      debugPrint('Error initializing IndexedDB logger: $e');
      _isInitialized = false;
    }
  }

  Future<void> _loadLogs() async {
    if (_database == null) return;

    try {
      final transaction = _database!.transaction(_logsStoreName, 'readonly');
      final store = transaction.objectStore(_logsStoreName);
      final request = store.getAll();
      final results = await request;

      _webLogs.clear();
      for (final item in results) {
        if (item is Map && item['log'] != null && item['sessionId'] == _currentSessionId) {
          _webLogs.add(item['log'].toString());
        }
      }

      debugPrint('Loaded ${_webLogs.length} logs from IndexedDB for session $_currentSessionId');
    } catch (e) {
      debugPrint('Error loading logs from IndexedDB: $e');
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
    if (_database == null || !_isInitialized) return;

    try {
      final transaction = _database!.transaction(_logsStoreName, 'readwrite');
      final store = transaction.objectStore(_logsStoreName);

      for (final log in newLogs) {
        await store.add({
          'log': log,
          'sessionId': _currentSessionId,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      }

      await transaction.completed;
    } catch (e) {
      debugPrint('Error storing logs to IndexedDB: $e');
    }
  }

  /// Update session activity and log count
  Future<void> _updateSessionActivity(int newLogCount) async {
    if (_database == null || !_isInitialized) return;

    try {
      final transaction = _database!.transaction(_sessionsStoreName, 'readwrite');
      final store = transaction.objectStore(_sessionsStoreName);

      final sessionData = await store.getObject(_currentSessionId);
      if (sessionData != null && sessionData is Map) {
        final updatedSession = Map<String, dynamic>.from(sessionData);
        updatedSession['lastActivityAt'] = DateTime.now().millisecondsSinceEpoch;
        updatedSession['logCount'] = (updatedSession['logCount'] as int) + newLogCount;

        await store.put(updatedSession);
      }

      await transaction.completed;
    } catch (e) {
      debugPrint('Error updating session activity: $e');
    }
  }

  @override
  Future<void> destroy() async {
    _webLogs.clear();
    if (_database != null) {
      _database!.close();
      _database = null;
    }
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

  /// Read logs page directly from IndexedDB (more efficient for large datasets)
  /// This method doesn't load all logs into memory first
  Future<List<String>> readLogsPageFromDB(int page, {int pageSize = 100, String? sessionId}) async {
    if (!_isInitialized) {
      await init();
    }

    if (_database == null) {
      return <String>[];
    }

    if (page < 0) {
      throw ArgumentError('Page number must be non-negative');
    }

    final targetSessionId = sessionId ?? _currentSessionId;

    try {
      final transaction = _database!.transaction(_logsStoreName, 'readonly');
      final store = transaction.objectStore(_logsStoreName);

      // Use cursor to efficiently skip and read only the needed logs
      final List<String> logs = [];
      int skipCount = page * pageSize;
      int readCount = 0;

      await for (final cursor in store.openCursor()) {
        final value = cursor.value;
        if (value is Map && value['log'] != null && value['sessionId'] == targetSessionId) {
          if (skipCount > 0) {
            skipCount--;
            cursor.next();
            continue;
          }

          if (readCount >= pageSize) {
            break;
          }

          logs.add(value['log'].toString());
          readCount++;
        }

        cursor.next();
      }

      return logs;
    } catch (e) {
      debugPrint('Error reading logs page from IndexedDB: $e');
      // Fallback to in-memory pagination
      return await readLogsPage(page, pageSize: pageSize);
    }
  }

  /// Get total number of logs directly from IndexedDB for a specific session
  Future<int> getTotalLogsCount({String? sessionId}) async {
    if (!_isInitialized) {
      await init();
    }

    if (_database == null) {
      return _webLogs.length;
    }

    final targetSessionId = sessionId ?? _currentSessionId;

    try {
      final transaction = _database!.transaction(_logsStoreName, 'readonly');
      final store = transaction.objectStore(_logsStoreName);

      // Count logs for specific session
      int count = 0;
      await for (final cursor in store.openCursor()) {
        final value = cursor.value;
        if (value is Map && value['log'] != null && value['sessionId'] == targetSessionId) {
          count++;
        }
        cursor.next();
      }

      return count;
    } catch (e) {
      debugPrint('Error getting logs count from IndexedDB: $e');
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

    if (_database != null) {
      try {
        if (allSessions) {
          // Clear all logs and sessions
          final logsTransaction = _database!.transaction(_logsStoreName, 'readwrite');
          final logsStore = logsTransaction.objectStore(_logsStoreName);
          await logsStore.clear();
          await logsTransaction.completed;

          final sessionsTransaction = _database!.transaction(_sessionsStoreName, 'readwrite');
          final sessionsStore = sessionsTransaction.objectStore(_sessionsStoreName);
          await sessionsStore.clear();
          await sessionsTransaction.completed;

          debugPrint('All IndexedDB logs and sessions cleared');
        } else {
          // Clear only current session logs
          final transaction = _database!.transaction(_logsStoreName, 'readwrite');
          final store = transaction.objectStore(_logsStoreName);

          // Delete logs for current session
          await for (final cursor in store.openCursor()) {
            final value = cursor.value;
            if (value is Map && value['sessionId'] == _currentSessionId) {
              cursor.delete();
            }
            cursor.next();
          }

          await transaction.completed;

          // Also remove the session record
          final sessionTransaction = _database!.transaction(_sessionsStoreName, 'readwrite');
          final sessionStore = sessionTransaction.objectStore(_sessionsStoreName);
          await sessionStore.delete(_currentSessionId);
          await sessionTransaction.completed;

          debugPrint('IndexedDB logs for session $_currentSessionId cleared');
        }
      } catch (e) {
        debugPrint('Error clearing IndexedDB logs: $e');
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

    if (_database == null) {
      return [];
    }

    try {
      final transaction = _database!.transaction(_sessionsStoreName, 'readonly');
      final store = transaction.objectStore(_sessionsStoreName);
      final request = store.getAll();
      final results = await request;

      final sessions = <LogSession>[];
      for (final item in results) {
        if (item is Map<String, dynamic>) {
          try {
            sessions.add(LogSession.fromMap(item));
          } catch (e) {
            debugPrint('Error parsing session: $e');
          }
        }
      }

      // Sort by creation date (newest first)
      sessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return sessions;
    } catch (e) {
      debugPrint('Error getting sessions from IndexedDB: $e');
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

    if (_database == null) {
      return null;
    }

    try {
      final transaction = _database!.transaction(_sessionsStoreName, 'readonly');
      final store = transaction.objectStore(_sessionsStoreName);
      final result = await store.getObject(sessionId);

      if (result != null && result is Map<String, dynamic>) {
        return LogSession.fromMap(result);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting session from IndexedDB: $e');
      return null;
    }
  }

  /// Delete a specific session and its logs
  Future<void> deleteSession(String sessionId) async {
    if (!_isInitialized) {
      await init();
    }

    if (_database == null) return;

    try {
      // Delete logs for this session
      final logsTransaction = _database!.transaction(_logsStoreName, 'readwrite');
      final logsStore = logsTransaction.objectStore(_logsStoreName);

      await for (final cursor in logsStore.openCursor()) {
        final value = cursor.value;
        if (value is Map && value['sessionId'] == sessionId) {
          cursor.delete();
        }
        cursor.next();
      }

      await logsTransaction.completed;

      // Delete session record
      final sessionTransaction = _database!.transaction(_sessionsStoreName, 'readwrite');
      final sessionStore = sessionTransaction.objectStore(_sessionsStoreName);
      await sessionStore.delete(sessionId);
      await sessionTransaction.completed;

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

    if (_database == null) {
      return '';
    }

    try {
      final transaction = _database!.transaction(_logsStoreName, 'readonly');
      final store = transaction.objectStore(_logsStoreName);
      final logs = <String>[];

      await for (final cursor in store.openCursor()) {
        final value = cursor.value;
        if (value is Map && value['log'] != null && value['sessionId'] == sessionId) {
          logs.add(value['log'].toString());
        }
        cursor.next();
      }

      return logs.join('\n');
    } catch (e) {
      debugPrint('Error getting logs content for session: $e');
      return '';
    }
  }
}
