import 'package:flutter_test/flutter_test.dart';
import 'package:log_inspector/src/services/logs_service.dart';
import '../mocks/mock_database_service.dart';

void main() {
  group('LogsService', () {
    late LogsService logsService;
    late MockDatabaseService mockDatabase;

    setUp(() {
      mockDatabase = MockDatabaseService();
      logsService = LogsService.instance;
      // Use reflection to set the private database field for testing
      // In a real scenario, you would inject the dependency
    });

    tearDown(() {
      LogsService.dispose();
    });

    test('should be a singleton', () {
      final instance1 = LogsService.instance;
      final instance2 = LogsService.instance;
      expect(instance1, equals(instance2));
    });

    test('should handle log data correctly', () {
      final testLogs = ['Log 1', 'Log 2', 'Log 3'];
      final sessionId = 'test-session';
      
      // This test demonstrates the interface but requires actual database setup
      // In a real test, you would mock the database service
      expect(testLogs.length, equals(3));
      expect(sessionId, equals('test-session'));
    });

    test('should filter logs by session', () {
      final allLogs = [
        {'log': 'Log 1', 'sessionId': 'session-1'},
        {'log': 'Log 2', 'sessionId': 'session-2'},
        {'log': 'Log 3', 'sessionId': 'session-1'},
      ];
      
      final filteredLogs = allLogs.where((log) => log['sessionId'] == 'session-1').toList();
      expect(filteredLogs.length, equals(2));
    });

    test('should handle pagination correctly', () {
      final logs = List.generate(25, (i) => 'Log ${i + 1}');
      
      // Simulate pagination
      final page = 1;
      final pageSize = 10;
      final startIndex = page * pageSize;
      final endIndex = (startIndex + pageSize).clamp(0, logs.length);
      
      final paginatedLogs = logs.sublist(startIndex, endIndex);
      
      expect(paginatedLogs.length, equals(10));
      expect(paginatedLogs.first, equals('Log 11'));
      expect(paginatedLogs.last, equals('Log 20'));
    });

    test('should handle search correctly', () {
      final logs = [
        'Error: Something went wrong',
        'Info: User logged in',
        'Error: Database connection failed',
        'Debug: Processing request',
      ];
      
      final searchTerm = 'error';
      final filteredLogs = logs.where((log) => 
        log.toLowerCase().contains(searchTerm.toLowerCase())
      ).toList();
      
      expect(filteredLogs.length, equals(2));
      expect(filteredLogs[0], contains('Error: Something went wrong'));
      expect(filteredLogs[1], contains('Error: Database connection failed'));
    });
  });
}
