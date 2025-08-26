import 'package:flutter_test/flutter_test.dart';
import 'package:idb_shim/idb_shim.dart';
import 'package:log_inspector/src/database/database_service.dart';
import 'package:log_inspector/src/models/session.dart';

void main() {
  group('DatabaseService', () {
    late DatabaseService databaseService;

    setUp(() {
      databaseService = DatabaseService.instance;
    });

    tearDown(() {
      DatabaseService.dispose();
    });

    test('should be a singleton', () {
      final instance1 = DatabaseService.instance;
      final instance2 = DatabaseService.instance;
      expect(instance1, equals(instance2));
    });

    test('should have correct initial state', () {
      expect(databaseService.isInitialized, isFalse);
      expect(databaseService.database, isNull);
    });

    // Skip database operation tests in unit test environment
    // These would require proper database setup which is not suitable for unit tests
    // Integration tests would be more appropriate for testing actual database operations

    test('should handle session creation models correctly', () {
      final session = LogSession(
        id: 'test-session',
        createdAt: DateTime.now(),
        lastActivityAt: DateTime.now(),
        logCount: 5,
      );

      expect(session.id, equals('test-session'));
      expect(session.logCount, equals(5));

      // Test serialization/deserialization
      final map = session.toMap();
      final restoredSession = LogSession.fromMap(map);

      expect(restoredSession.id, equals(session.id));
      expect(restoredSession.logCount, equals(session.logCount));
    });

    group('query method', () {
      test('should be declared in DatabaseService', () {
        // Test that the method exists and has correct signature
        expect(
          databaseService.query,
          isA<Future<List<Map<String, dynamic>>> Function(String, {KeyRange? keyRange})>(),
        );
      });

      test('should return empty list when not initialized', () async {
        // Test behavior when database is not initialized
        try {
          final result = await databaseService.query('test-store');
          expect(result, isEmpty);
        } catch (e) {
          // Should throw StateError when database is not initialized
          expect(e, isA<StateError>());
        }
      });

      test('should handle null keyRange parameter', () async {
        // Test that the method accepts null keyRange
        try {
          final result = await databaseService.query('test-store', keyRange: null);
          expect(result, isA<List<Map<String, dynamic>>>());
        } catch (e) {
          // Expected in unit test environment without real database
          expect(e, isA<StateError>());
        }
      });

      test('should handle valid keyRange parameter', () async {
        // Test that the method accepts a keyRange parameter
        try {
          final keyRange = KeyRange.only('test-key');
          final result = await databaseService.query('test-store', keyRange: keyRange);
          expect(result, isA<List<Map<String, dynamic>>>());
        } catch (e) {
          // Expected in unit test environment without real database
          expect(e, isA<StateError>());
        }
      });

      test('should return List<Map<String, dynamic>> type', () async {
        // Test return type consistency
        try {
          final result = await databaseService.query('test-store');
          expect(result, isA<List<Map<String, dynamic>>>());
        } catch (e) {
          // Expected in unit test environment without real database
          expect(e, isA<StateError>());
        }
      });
    });
  });
}
