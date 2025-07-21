import 'package:log_inspector/src/logger_output/universal_logger_output.dart';
import 'package:log_inspector/src/services/logger_service/logger_service.dart';
import 'package:log_inspector/src/models/paginated_logs.dart';
import 'package:log_inspector/src/models/session.dart';

class LoggerServiceImpl implements LoggerService {
  LoggerServiceImpl({UniversalLoggerOutput? logger}) {
    if (logger != null) {
      _logger = logger;
    } else {
      _logger = UniversalLoggerOutput.instance;
    }
  }

  late final UniversalLoggerOutput _logger;

  @override
  Future<void> cleanLogs() => _logger.clearLogs();

  @override
  Future<void> downloadLogs() => _logger.downloadLogs();

  @override
  Future<PaginatedLogs> readLogsPaginated(int page, {int pageSize = 100}) {
    return _logger.readLogsPaginated(page, pageSize: pageSize);
  }

  @override
  Future<PaginatedSessions> getSessionsPaginated(int page, {int pageSize = 20}) {
    return _logger.getSessionsPaginated(page, pageSize: pageSize);
  }

  @override
  Future<void> deleteSession(String sessionId) => _logger.deleteSession(sessionId);

  @override
  String get currentSessionId => _logger.currentSessionId;

  @override
  Future<PaginatedLogs> readLogsPaginatedForSession(String sessionId, int page,
      {int pageSize = 100}) {
    return _logger.readLogsPaginated(page, pageSize: pageSize, sessionId: sessionId);
  }

  @override
  Future<void> downloadLogsForSession(String sessionId) async {
    final content = await _logger.getLogsContentForSession(sessionId);
    if (content.isNotEmpty) {
      // Use a modified download method that allows custom content
      await _logger.downloadLogsWithContent(content, 'session_${sessionId}_logs');
    }
  }

  @override
  Future<void> clearLogsForSession(String sessionId) async {
    if (sessionId == _logger.currentSessionId) {
      await _logger.clearLogs(allSessions: false);
    } else {
      await _logger.deleteSession(sessionId);
    }
  }
}
