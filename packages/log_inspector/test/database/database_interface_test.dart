import 'package:flutter_test/flutter_test.dart';
import 'package:idb_shim/idb_shim.dart';
import 'package:log_inspector/src/database/database_interface.dart';
import '../mocks/mock_database_service.dart';

void main() {
  group('DatabaseInterface', () {
    late DatabaseInterface mockDb;

    setUp(() {
      mockDb = MockDatabaseService();
    });

    test('should initialize properly', () async {
      expect(mockDb.isInitialized, isFalse);
      await mockDb.init();
      expect(mockDb.isInitialized, isTrue);
    });

    test('should create and retrieve records', () async {
      await mockDb.init();

      final testData = {
        'id': 'test-record',
        'name': 'Test Record',
        'value': 42,
      };

      await mockDb.create('test-store', testData);
      final retrievedRecord = await mockDb.read('test-store', 'test-record');

      expect(retrievedRecord?['id'], equals('test-record'));
      expect(retrievedRecord?['name'], equals('Test Record'));
      expect(retrievedRecord?['value'], equals(42));
    });

    test('should update records', () async {
      await mockDb.init();

      final testData = {
        'id': 'test-record',
        'name': 'Original Name',
        'value': 42,
      };

      await mockDb.create('test-store', testData);

      final updatedData = {
        'id': 'test-record',
        'name': 'Updated Name',
        'value': 100,
      };

      await mockDb.update('test-store', 'test-record', updatedData);
      final retrievedRecord = await mockDb.read('test-store', 'test-record');

      expect(retrievedRecord?['name'], equals('Updated Name'));
      expect(retrievedRecord?['value'], equals(100));
    });

    test('should delete records', () async {
      await mockDb.init();

      final testData = {
        'id': 'test-record',
        'name': 'Test Record',
      };

      await mockDb.create('test-store', testData);
      expect(await mockDb.read('test-store', 'test-record'), isNotNull);

      await mockDb.delete('test-store', 'test-record');
      expect(await mockDb.read('test-store', 'test-record'), isNull);
    });

    test('should read all records', () async {
      await mockDb.init();

      final testData1 = {'id': 'record1', 'name': 'Record 1'};
      final testData2 = {'id': 'record2', 'name': 'Record 2'};

      await mockDb.create('test-store', testData1);
      await mockDb.create('test-store', testData2);

      final allRecords = await mockDb.readAll('test-store');
      expect(allRecords.length, equals(2));
    });

    test('should count records', () async {
      await mockDb.init();

      final testData1 = {'id': 'record1', 'type': 'A'};
      final testData2 = {'id': 'record2', 'type': 'B'};
      final testData3 = {'id': 'record3', 'type': 'A'};

      await mockDb.create('test-store', testData1);
      await mockDb.create('test-store', testData2);
      await mockDb.create('test-store', testData3);

      final totalCount = await mockDb.count('test-store');
      expect(totalCount, equals(3));

      // Test with keyRange (mock will return total count for simplicity)
      final filteredCount = await mockDb.count('test-store', keyRange: KeyRange.only('record1'));
      expect(filteredCount, equals(3)); // Mock returns total count
    });

    test('should query records', () async {
      await mockDb.init();

      final testData1 = {'id': 'record1', 'type': 'A'};
      final testData2 = {'id': 'record2', 'type': 'B'};
      final testData3 = {'id': 'record3', 'type': 'A'};

      await mockDb.create('test-store', testData1);
      await mockDb.create('test-store', testData2);
      await mockDb.create('test-store', testData3);

      // Test querying all records
      final allRecords = await mockDb.query('test-store');
      expect(allRecords.length, equals(3));

      // Test querying with keyRange
      final filteredRecords = await mockDb.query('test-store', keyRange: KeyRange.only('record1'));
      expect(filteredRecords, isA<List<Map<String, dynamic>>>());
      expect(filteredRecords.length, equals(3)); // Mock returns all records for simplicity
    });

    test('should clear all records in a store', () async {
      await mockDb.init();

      await mockDb.create('test-store', {'id': 'record1', 'name': 'Record 1'});
      await mockDb.create('test-store', {'id': 'record2', 'name': 'Record 2'});

      final countBefore = await mockDb.count('test-store');
      expect(countBefore, equals(2));

      await mockDb.clear('test-store');

      final countAfter = await mockDb.count('test-store');
      expect(countAfter, equals(0));
    });

    test('should close properly', () async {
      await mockDb.init();
      expect(mockDb.isInitialized, isTrue);

      await mockDb.close();
      expect(mockDb.isInitialized, isFalse);
    });
  });
}
