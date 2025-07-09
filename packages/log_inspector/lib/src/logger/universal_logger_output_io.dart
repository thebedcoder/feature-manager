import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';

/// Mobile/Desktop implementation of UniversalLoggerOutput
class UniversalLoggerOutput extends LogOutput {
  UniversalLoggerOutput({
    this.shouldLog = true,
    this.localStorageKey = 'log_inspector_logs',
    this.logFileName = 'app_logs',
  }) {
    _instance ??= this;
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

  // Mobile/Desktop-specific storage
  List<String> _mobileLogs = [];
  File? _logFile;

  @override
  Future<void> init() async {
    if (!shouldLog) return;
    _mobileLogs = [];

    try {
      // Initialize log file
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory(path.join(directory.path, 'logs'));
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      _logFile = File(path.join(logDir.path, '$logFileName.log'));

      // Read existing logs from file if it exists
      if (await _logFile!.exists()) {
        final content = await _logFile!.readAsString();
        if (content.isNotEmpty) {
          _mobileLogs = content.split('\n').where((line) => line.trim().isNotEmpty).toList();
        }
      }

      debugPrint('Mobile/Desktop logger initialized with file: ${_logFile!.path}');
      debugPrint('Existing logs count: ${_mobileLogs.length}');
    } catch (e) {
      debugPrint('Error initializing file logger: $e');
      debugPrint('Falling back to in-memory logging');
      _logFile = null;
    }
  }

  @override
  void output(OutputEvent event) {
    if (!shouldLog) return;

    // Console output
    event.lines.forEach(debugPrint);

    // Store in memory
    _mobileLogs.addAll(event.lines);

    // Write to file if available
    if (_logFile != null) {
      _writeToFile(event.lines);
    } else {
      // Try to initialize if not done yet
      _ensureInitialized().then((_) {
        if (_logFile != null) {
          _writeToFile(event.lines);
        }
      });
    }
  }

  Future<void> _ensureInitialized() async {
    if (_logFile != null) return; // Already initialized

    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory(path.join(directory.path, 'logs'));
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      _logFile = File(path.join(logDir.path, '$logFileName.log'));
      debugPrint('Logger initialized lazily with file: ${_logFile!.path}');
    } catch (e) {
      debugPrint('Error in lazy initialization: $e');
    }
  }

  Future<void> _writeToFile(List<String> lines) async {
    try {
      final logEntries =
          lines.map((line) => '${DateTime.now().toIso8601String()} | $line').join('\n');

      await _logFile!.writeAsString(
        '$logEntries\n',
        mode: FileMode.append,
      );
    } catch (e) {
      debugPrint('Error writing to log file: $e');
    }
  }

  @override
  Future<void> destroy() async {
    _mobileLogs.clear();
  }

  /// Get the current logs content
  Future<String> getLogsContent() async {
    debugPrint('Getting logs content...');
    debugPrint('In-memory logs count: ${_mobileLogs.length}');
    debugPrint('Log file: ${_logFile?.path}');

    // Ensure we're initialized
    await _ensureInitialized();

    // Try to read from file first if available
    if (_logFile != null && await _logFile!.exists()) {
      try {
        final content = await _logFile!.readAsString();
        debugPrint('File content length: ${content.length}');
        if (content.isNotEmpty) {
          return content;
        }
      } catch (e) {
        debugPrint('Error reading log file: $e');
      }
    }

    // Fallback to in-memory logs
    if (_mobileLogs.isEmpty) {
      final statusMessage = 'No logs available.\n\n'
          'Storage: ${_logFile != null ? 'File-based (${_logFile!.path})' : 'In-memory'}\n'
          'Note: Logs are ${_logFile != null ? 'persistently stored in files' : 'stored in memory only'}\n'
          'File exists: ${_logFile != null ? await _logFile!.exists() : 'N/A'}';
      return statusMessage;
    }

    final memoryContent = _mobileLogs.join('\n');
    debugPrint('Returning in-memory content, length: ${memoryContent.length}');
    return memoryContent;
  }

  /// Get the number of log files/sources
  Future<int> getLogFilesCount() async {
    if (_logFile != null && await _logFile!.exists()) {
      return 1;
    }
    return _mobileLogs.isNotEmpty ? 1 : 0;
  }

  /// Get the total size of logs in bytes
  Future<int> getLogsSizeInBytes() async {
    // Try to get file size first
    if (_logFile != null && await _logFile!.exists()) {
      try {
        final stat = await _logFile!.stat();
        return stat.size;
      } catch (e) {
        debugPrint('Error getting file size: $e');
      }
    }

    // Fallback to in-memory calculation
    if (_mobileLogs.isEmpty) return 0;
    return utf8.encode(_mobileLogs.join('\n')).length;
  }

  /// Clear all logs
  Future<void> clearLogs() async {
    _mobileLogs.clear();

    // Clear file if it exists
    if (_logFile != null && await _logFile!.exists()) {
      try {
        await _logFile!.delete();
        debugPrint('Log file deleted: ${_logFile!.path}');
      } catch (e) {
        debugPrint('Error deleting log file: $e');
      }
    }

    debugPrint('Mobile logs cleared');
  }

  /// Download logs (prepare for sharing on mobile/desktop)
  Future<void> downloadLogs() async {
    if (_logFile != null && await _logFile!.exists()) {
      SharePlus.instance.share(
        ShareParams(
          files: [XFile(_logFile!.path)],
        ),
      );
    }
  }

  /// Check if logs exist
  Future<bool> hasLogs() async {
    return await getLogFilesCount() > 0;
  }
}
