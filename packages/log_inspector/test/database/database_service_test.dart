import 'package:flutter_test/flutter_test.dart';
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
  });
}
