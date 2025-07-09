import 'universal_logger_output.dart';

abstract class LoggerService {
  /// Downloads logs as a file.
  Future<void> downloadLogs();

  /// Reads logs from storage.
  Future<String> readLogs();

  /// Cleans up old logs.
  Future<void> cleanLogs();

  /// Gets the number of log files.
  Future<int> getLogFilesCount();

  /// Gets the total size of logs in bytes.
  Future<int> getLogsSizeInBytes();
}

class LoggerServiceImpl implements LoggerService {
  LoggerServiceImpl({UniversalLoggerOutput? loggerOutput}) {
    if (loggerOutput != null) {
      _loggerOutput = loggerOutput;
    } else if (UniversalLoggerOutput.instanceOrNull != null) {
      _loggerOutput = UniversalLoggerOutput.instance;
    } else {
      throw StateError(
        'No UniversalLoggerOutput instance available. Either:\n'
        '1. Pass one explicitly: LoggerServiceImpl(loggerOutput: myOutput)\n'
        '2. Register a global instance: myOutput.register()'
      );
    }
  }

  late final UniversalLoggerOutput _loggerOutput;

  @override
  Future<void> cleanLogs() async {
    await _loggerOutput.clearLogs();
  }

  @override
  Future<void> downloadLogs() async {
    await _loggerOutput.downloadLogs();
  }

  @override
  Future<String> readLogs() async {
    return await _loggerOutput.getLogsContent();
  }

  @override
  Future<int> getLogFilesCount() async {
    return await _loggerOutput.getLogFilesCount();
  }

  @override
  Future<int> getLogsSizeInBytes() async {
    return await _loggerOutput.getLogsSizeInBytes();
  }
}
