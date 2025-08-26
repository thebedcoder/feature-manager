import 'package:flutter_test/flutter_test.dart';
import 'package:log_inspector/src/services/logs_service.dart';
import '../mocks/mock_database_service.dart';

void main() {
  group('LogsService', () {
    late LogsService logsService;
    late MockDatabaseService mockDatabase;

    setUp(() {
      mockDatabase = MockDatabaseService();
      // Use the test constructor to inject the mock database
      logsService = LogsService.createForTesting(mockDatabase);
    });

    tearDown(() {
      LogsService.dispose();
    });

    test('should be a singleton', () {
      final instance1 = LogsService.instance;
      final instance2 = LogsService.instance;
      expect(instance1, equals(instance2));
    });

    test('should store logs correctly', () async {
      final testLogs = ['Log 1', 'Log 2', 'Log 3'];
      final sessionId = 'test-session';

      await logsService.storeLogs(testLogs, sessionId);

      // Verify logs were stored by retrieving them
      final storedLogs = await logsService.getLogsForSession(sessionId);
      expect(storedLogs.length, equals(3));
      expect(storedLogs, contains('Log 1'));
      expect(storedLogs, contains('Log 2'));
      expect(storedLogs, contains('Log 3'));
    });

    test('should get logs for specific session', () async {
      // Store logs for two different sessions
      await logsService.storeLogs(['Log A1', 'Log A2'], 'session-A');
      await logsService.storeLogs(['Log B1', 'Log B2', 'Log B3'], 'session-B');

      // Get logs for session A
      final sessionALogs = await logsService.getLogsForSession('session-A');
      expect(sessionALogs.length, equals(2));
      expect(sessionALogs, contains('Log A1'));
      expect(sessionALogs, contains('Log A2'));

      // Get logs for session B
      final sessionBLogs = await logsService.getLogsForSession('session-B');
      expect(sessionBLogs.length, equals(3));
      expect(sessionBLogs, contains('Log B1'));
      expect(sessionBLogs, contains('Log B2'));
      expect(sessionBLogs, contains('Log B3'));
    });

    test('should get paginated logs for session', () async {
      // Store 25 logs for a session
      final logs = List.generate(25, (i) => 'Log ${i + 1}');
      final sessionId = 'pagination-test';
      await logsService.storeLogs(logs, sessionId);

      // Get first page (10 items)
      final page0Logs = await logsService.getLogsPageForSession(sessionId, 0, 10);
      expect(page0Logs.length, equals(10));
      expect(page0Logs.first, equals('Log 1'));
      expect(page0Logs.last, equals('Log 10'));

      // Get second page (10 items)
      final page1Logs = await logsService.getLogsPageForSession(sessionId, 1, 10);
      expect(page1Logs.length, equals(10));
      expect(page1Logs.first, equals('Log 11'));
      expect(page1Logs.last, equals('Log 20'));

      // Get third page (5 items)
      final page2Logs = await logsService.getLogsPageForSession(sessionId, 2, 10);
      expect(page2Logs.length, equals(5));
      expect(page2Logs.first, equals('Log 21'));
      expect(page2Logs.last, equals('Log 25'));
    });

    test('should get total logs count for session', () async {
      final sessionId = 'count-test';
      await logsService.storeLogs(['Log 1', 'Log 2', 'Log 3'], sessionId);

      final count = await logsService.getTotalLogsCountForSession(sessionId);
      expect(count, equals(3));
    });

    test('should delete logs for specific session', () async {
      // Store logs for two sessions
      await logsService.storeLogs(['Log A1', 'Log A2'], 'session-A');
      await logsService.storeLogs(['Log B1', 'Log B2'], 'session-B');

      // Verify both sessions have logs
      expect(await logsService.getLogsForSession('session-A'), hasLength(2));
      expect(await logsService.getLogsForSession('session-B'), hasLength(2));

      // Delete logs for session A
      await logsService.deleteLogsForSession('session-A');

      // Verify session A logs are deleted but session B remains
      expect(await logsService.getLogsForSession('session-A'), hasLength(0));
      expect(await logsService.getLogsForSession('session-B'), hasLength(2));
    });

    test('should clear all logs', () async {
      // Store logs for multiple sessions
      await logsService.storeLogs(['Log 1'], 'session-1');
      await logsService.storeLogs(['Log 2'], 'session-2');

      // Verify logs exist
      expect(await logsService.getLogsForSession('session-1'), hasLength(1));
      expect(await logsService.getLogsForSession('session-2'), hasLength(1));

      // Clear all logs
      await logsService.clearAllLogs();

      // Verify all logs are cleared
      expect(await logsService.getLogsForSession('session-1'), hasLength(0));
      expect(await logsService.getLogsForSession('session-2'), hasLength(0));
    });

    test('should handle empty logs list', () async {
      final sessionId = 'empty-test';
      await logsService.storeLogs([], sessionId);

      final logs = await logsService.getLogsForSession(sessionId);
      expect(logs, isEmpty);
    });

    test('should handle non-existent session', () async {
      final logs = await logsService.getLogsForSession('non-existent');
      expect(logs, isEmpty);

      final count = await logsService.getTotalLogsCountForSession('non-existent');
      expect(count, equals(0));
    });
  });
}
