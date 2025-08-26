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
      // Use the test constructor to inject the mock database
      sessionsService = SessionsService.createForTesting(mockDatabase);
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

      await sessionsService.createSession(session);

      // Verify session was created by retrieving it
      final retrievedSession = await sessionsService.getSession('test-session');
      expect(retrievedSession, isNotNull);
      expect(retrievedSession!.id, equals('test-session'));
      expect(retrievedSession.logCount, equals(0));
    });

    test('should get all sessions', () async {
      final session1 = LogSession(
        id: 'session-1',
        createdAt: DateTime.now(),
        lastActivityAt: DateTime.now(),
        logCount: 5,
      );

      final session2 = LogSession(
        id: 'session-2',
        createdAt: DateTime.now(),
        lastActivityAt: DateTime.now(),
        logCount: 10,
      );

      await sessionsService.createSession(session1);
      await sessionsService.createSession(session2);

      final allSessions = await sessionsService.getAllSessions();
      expect(allSessions.length, equals(2));
      expect(allSessions.map((s) => s.id), contains('session-1'));
      expect(allSessions.map((s) => s.id), contains('session-2'));
    });

    test('should get session by ID', () async {
      final session = LogSession(
        id: 'test-session',
        createdAt: DateTime.now(),
        lastActivityAt: DateTime.now(),
        logCount: 5,
      );

      await sessionsService.createSession(session);

      final retrievedSession = await sessionsService.getSession('test-session');
      expect(retrievedSession, isNotNull);
      expect(retrievedSession!.id, equals('test-session'));
      expect(retrievedSession.logCount, equals(5));
    });

    test('should return null for non-existent session', () async {
      final session = await sessionsService.getSession('non-existent');
      expect(session, isNull);
    });

    test('should update session activity', () async {
      final session = LogSession(
        id: 'test-session',
        createdAt: DateTime.now(),
        lastActivityAt: DateTime.now(),
        logCount: 5,
      );

      await sessionsService.createSession(session);

      // Update session activity
      await sessionsService.updateSessionActivity('test-session', 3);

      final updatedSession = await sessionsService.getSession('test-session');
      expect(updatedSession, isNotNull);
      expect(updatedSession!.logCount, equals(8)); // 5 + 3
    });

    test('should delete session', () async {
      final session = LogSession(
        id: 'test-session',
        createdAt: DateTime.now(),
        lastActivityAt: DateTime.now(),
        logCount: 5,
      );

      await sessionsService.createSession(session);

      // Verify session exists
      expect(await sessionsService.getSession('test-session'), isNotNull);

      // Delete session
      await sessionsService.deleteSession('test-session');

      // Verify session is deleted
      expect(await sessionsService.getSession('test-session'), isNull);
    });

    test('should clear all sessions', () async {
      final session1 = LogSession(
        id: 'session-1',
        createdAt: DateTime.now(),
        lastActivityAt: DateTime.now(),
        logCount: 5,
      );

      final session2 = LogSession(
        id: 'session-2',
        createdAt: DateTime.now(),
        lastActivityAt: DateTime.now(),
        logCount: 10,
      );

      await sessionsService.createSession(session1);
      await sessionsService.createSession(session2);

      // Verify sessions exist
      expect(await sessionsService.getAllSessions(), hasLength(2));

      // Clear all sessions
      await sessionsService.clearAllSessions();

      // Verify all sessions are cleared
      expect(await sessionsService.getAllSessions(), isEmpty);
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
      // Compare DateTime values with tolerance for precision differences
      expect(restoredSession.createdAt.difference(session.createdAt).inMilliseconds.abs(), lessThan(1000));
      expect(restoredSession.lastActivityAt.difference(session.lastActivityAt).inMilliseconds.abs(), lessThan(1000));
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

    test('should handle invalid session data gracefully', () async {
      // Create a session with invalid data in the database
      await mockDatabase.create('sessions', {
        'id': 'invalid-session',
        'createdAt': 'invalid-date', // Invalid date format
        'lastActivityAt': DateTime.now().millisecondsSinceEpoch,
        'logCount': 5,
      });

      // Should return null for invalid session
      final session = await sessionsService.getSession('invalid-session');
      expect(session, isNull);

      // Should skip invalid sessions when getting all sessions
      final allSessions = await sessionsService.getAllSessions();
      expect(allSessions.where((s) => s.id == 'invalid-session'), isEmpty);
    });
  });
}
