import 'package:flutter_test/flutter_test.dart';
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

    test('should query records with filter', () async {
      await mockDb.init();
      
      final testData1 = {'id': 'record1', 'type': 'A', 'value': 10};
      final testData2 = {'id': 'record2', 'type': 'B', 'value': 20};
      final testData3 = {'id': 'record3', 'type': 'A', 'value': 30};
      
      await mockDb.create('test-store', testData1);
      await mockDb.create('test-store', testData2);
      await mockDb.create('test-store', testData3);
      
      final filteredRecords = await mockDb.query('test-store', (record) => record['type'] == 'A');
      expect(filteredRecords.length, equals(2));
    });

    test('should get paginated records', () async {
      await mockDb.init();
      
      // Create multiple records
      for (int i = 0; i < 15; i++) {
        await mockDb.create('test-store', {'id': 'record$i', 'index': i});
      }
      
      // Get first page
      final firstPage = await mockDb.getPage('test-store', 0, 5);
      expect(firstPage.length, equals(5));
      
      // Get second page
      final secondPage = await mockDb.getPage('test-store', 1, 5);
      expect(secondPage.length, equals(5));
      
      // Get last page
      final lastPage = await mockDb.getPage('test-store', 2, 5);
      expect(lastPage.length, equals(5));
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
      
      final filteredCount = await mockDb.count('test-store', filter: (record) => record['type'] == 'A');
      expect(filteredCount, equals(2));
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
