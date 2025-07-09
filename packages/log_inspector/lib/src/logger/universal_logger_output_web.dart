import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Web implementation of UniversalLoggerOutput
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

  // Web-specific storage
  List<String> _webLogs = [];

  @override
  Future<void> init() async {
    if (!shouldLog) return;
    _webLogs = [];
    // Clear existing logs on init if needed
    // html.window.localStorage.remove(localStorageKey);
  }

  @override
  void output(OutputEvent event) {
    if (!shouldLog) return;

    // Console output
    event.lines.forEach(debugPrint);

    // Add logs to memory array
    _webLogs.addAll(event.lines);

    // Store in localStorage
    html.window.localStorage[localStorageKey] = jsonEncode(_webLogs);
  }

  @override
  Future<void> destroy() async {
    _webLogs.clear();
  }

  /// Get the current logs content
  Future<String> getLogsContent() async {
    final logs = html.window.localStorage[localStorageKey];
    if (logs == null) return '';

    try {
      final List<dynamic> logsList = jsonDecode(logs);
      return logsList.join('\n');
    } catch (e) {
      // If JSON decode fails, treat as raw string
      return logs;
    }
  }

  /// Get the number of log files/sources
  Future<int> getLogFilesCount() async {
    final logs = html.window.localStorage[localStorageKey];
    return logs != null ? 1 : 0;
  }

  /// Get the total size of logs in bytes
  Future<int> getLogsSizeInBytes() async {
    final logs = html.window.localStorage[localStorageKey];
    if (logs == null) return 0;
    return utf8.encode(logs).length;
  }

  /// Clear all logs
  Future<void> clearLogs() async {
    _webLogs.clear();
    html.window.localStorage.remove(localStorageKey);
  }

  /// Download logs
  Future<void> downloadLogs() async {
    final logs = html.window.localStorage[localStorageKey];
    if (logs == null) return;

    try {
      final content = jsonDecode(logs).join('\n');
      final blob = html.Blob([content], 'text/plain', 'native');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', '${logFileName}_${DateTime.now().millisecondsSinceEpoch}.txt')
        ..click();
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      debugPrint('Error downloading web logs: $e');
    }
  }

  /// Check if logs exist
  Future<bool> hasLogs() async {
    return await getLogFilesCount() > 0;
  }
}
