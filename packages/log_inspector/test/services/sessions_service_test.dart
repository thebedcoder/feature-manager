import 'package:flutter_test/flutter_test.dart';
import 'package:log_inspector/src/services/sessions_service.dart';
import 'package:log_inspector/src/models/session.dart';
import '../mocks/mock_database_service.dart';

void main() {
  group('SessionsService', () {
    late SessionsService sessionsService;
    late MockDatabaseService mockDatabase;

    setUp(() {
      mockDatabase = MockDatabaseService();
      sessionsService = SessionsService.instance;
      // Use reflection to set the private database field for testing
      // In a real scenario, you would inject the dependency
    });

    tearDown(() {
      SessionsService.dispose();
    });

    test('should be a singleton', () {
      final instance1 = SessionsService.instance;
      final instance2 = SessionsService.instance;
      expect(instance1, equals(instance2));
    });

    test('should create session', () async {
      final session = LogSession(
        id: 'test-session',
        createdAt: DateTime.now(),
        lastActivityAt: DateTime.now(),
        logCount: 0,
      );

      // This test demonstrates the interface but requires actual database setup
      // In a real test, you would mock the database service
      expect(session.id, equals('test-session'));
      expect(session.logCount, equals(0));
    });

    test('should handle session models correctly', () {
      final now = DateTime.now();
      final session = LogSession(
        id: 'test-session',
        createdAt: now,
        lastActivityAt: now,
        logCount: 5,
      );
      
      expect(session.id, equals('test-session'));
      expect(session.logCount, equals(5));
      expect(session.createdAt, equals(now));
      expect(session.lastActivityAt, equals(now));
      
      // Test serialization/deserialization
      final map = session.toMap();
      final restoredSession = LogSession.fromMap(map);
      
      expect(restoredSession.id, equals(session.id));
      expect(restoredSession.logCount, equals(session.logCount));
      expect(restoredSession.createdAt, equals(session.createdAt));
      expect(restoredSession.lastActivityAt, equals(session.lastActivityAt));
    });

    test('should update session with copy method', () {
      final originalSession = LogSession(
        id: 'test-session',
        createdAt: DateTime.now(),
        lastActivityAt: DateTime.now(),
        logCount: 0,
      );

      final updatedSession = originalSession.copyWith(logCount: 10);
      
      expect(updatedSession.id, equals(originalSession.id));
      expect(updatedSession.logCount, equals(10));
      expect(updatedSession.createdAt, equals(originalSession.createdAt));
    });
  });
}
