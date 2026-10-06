import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:idb_shim/idb_shim.dart';
import 'package:log_inspector/src/database/database_service.dart';
import 'package:log_inspector/src/logger_output/universal_logger_output.dart';
import 'package:log_inspector/src/models/session.dart';
import 'package:log_inspector/src/services/logs_service.dart';
import 'package:log_inspector/src/services/sessions_service.dart';

import '../mocks/mock_database_service.dart';

void main() {
  late _CleanupDatabase database;
  late LogsService logs;
  late SessionsService sessions;
  late UniversalLoggerOutput output;

  setUp(() {
    database = _CleanupDatabase();
    logs = LogsService.createForTesting(database);
    sessions = SessionsService.createForTesting(database);
    output = UniversalLoggerOutput(
      databaseService: database,
      logsService: logs,
      sessionsService: sessions,
    );
  });

  tearDown(() => output.destroy());

  Future<void> saveHistory(
    String id, {
    int cachedCount = 0,
    List<String> entries = const [],
  }) async {
    await sessions.createSession(
      LogSession(
        id: id,
        createdAt: DateTime(2025),
        lastActivityAt: DateTime(2025),
        logCount: cachedCount,
      ),
    );
    await logs.storeLogs(entries, id);
  }

  test('initialization deletes empty history and preserves the empty active session', () async {
    await saveHistory('empty-history');
    await saveHistory('outdated-count', cachedCount: 900);

    await output.init();

    expect(await sessions.getSession('empty-history'), isNull);
    expect(await sessions.getSession('outdated-count'), isNull);
    expect((await sessions.getSession(output.currentSessionId))!.logCount, 0);
    expect((await output.getSessionsPaginated(0)).totalSessions, 1);
  });

  test('stored entries survive cleanup even when the cached count is zero', () async {
    await saveHistory('saved-history', entries: ['Saved message', 'Stack trace']);
    await saveHistory('blank-entry', entries: ['']);

    await output.init();

    expect(await sessions.getSession('saved-history'), isNotNull);
    expect(await sessions.getSession('blank-entry'), isNotNull);
    expect(await logs.getLogsForSession('saved-history'), ['Saved message', 'Stack trace']);
    expect(await logs.getLogsForSession('blank-entry'), ['']);
    expect((await output.getSession('saved-history'))!.logCount, 2);
  });

  test('pagination totals exclude all historical sessions removed at startup', () async {
    for (var index = 0; index < 5; index++) {
      await saveHistory('empty-$index');
    }
    for (var index = 0; index < 3; index++) {
      await saveHistory('saved-$index', entries: ['Entry $index']);
    }

    await output.init();
    final first = await output.getSessionsPaginated(0, pageSize: 2);
    final second = await output.getSessionsPaginated(1, pageSize: 2);

    expect(first.totalSessions, 4);
    expect(first.totalPages, 2);
    expect(first.hasNextPage, isTrue);
    expect(second.hasNextPage, isFalse);
    expect(
      [...first.sessions, ...second.sessions].map((session) => session.id),
      unorderedEquals([output.currentSessionId, 'saved-0', 'saved-1', 'saved-2']),
    );
  });

  test('a failed entry count preserves that session and cleanup continues', () async {
    await saveHistory('unreadable-history', entries: ['Keep this entry']);
    await saveHistory('empty-history');
    database.countFailure = 'unreadable-history';

    await output.init();

    expect(await sessions.getSession('unreadable-history'), isNotNull);
    expect(await logs.getLogsForSession('unreadable-history'), ['Keep this entry']);
    expect(await sessions.getSession('empty-history'), isNull);
    expect(await output.getSession(output.currentSessionId), isNotNull);
    expect(database.initializations, 1);
  });

  test('a failed deletion does not prevent cleanup of other empty sessions', () async {
    await saveHistory('undeletable-history');
    await saveHistory('empty-history');
    database.deleteFailure = 'undeletable-history';

    await output.init();

    expect(await sessions.getSession('undeletable-history'), isNotNull);
    expect(await sessions.getSession('empty-history'), isNull);
    expect(await output.getSession(output.currentSessionId), isNotNull);
    expect(database.initializations, 1);
  });

  test('unavailable session history does not prevent logger initialization', () async {
    await saveHistory('empty-history');
    database.failReadingSessions = true;

    await output.init();

    expect(await sessions.getSession('empty-history'), isNotNull);
    expect(await output.getSession(output.currentSessionId), isNotNull);
    expect(database.initializations, 1);
  });

  test('concurrent session reads wait for startup cleanup to finish', () async {
    await saveHistory('empty-history');
    database.cleanupStarted = Completer<void>();
    database.continueCleanup = Completer<void>();

    final initialization = output.init();
    await database.cleanupStarted!.future;
    expect(output.init(), same(initialization));
    var readCompleted = false;
    final page = output.getSessionsPaginated(0).then((result) {
      readCompleted = true;
      return result;
    });
    await Future<void>.delayed(Duration.zero);
    expect(readCompleted, isFalse);

    database.continueCleanup!.complete();
    await initialization;
    expect((await page).sessions.single.id, output.currentSessionId);
    expect(database.initializations, 1);
  });
}

class _CleanupDatabase extends MockDatabaseService {
  int initializations = 0;
  String? countFailure;
  String? deleteFailure;
  bool failReadingSessions = false;
  Completer<void>? cleanupStarted;
  Completer<void>? continueCleanup;

  @override
  Future<void> init() async {
    initializations++;
    await super.init();
  }

  @override
  Future<List<Map<String, dynamic>>> readAll(String storeName) {
    if (storeName == DatabaseService.sessionsStoreName && failReadingSessions) {
      throw StateError('Session history is unavailable');
    }
    return super.readAll(storeName);
  }

  @override
  Future<int> count(String storeName, {KeyRange? keyRange}) async {
    if (storeName == DatabaseService.logsStoreName) {
      if (keyRange?.lower == countFailure && countFailure != null) {
        throw StateError('Entry count is unavailable');
      }
      if (keyRange?.lower == 'empty-history' && continueCleanup != null) {
        if (!cleanupStarted!.isCompleted) cleanupStarted!.complete();
        await continueCleanup!.future;
      }
    }
    return super.count(storeName, keyRange: keyRange);
  }

  @override
  Future<void> delete(String storeName, String key) {
    if (storeName == DatabaseService.sessionsStoreName && key == deleteFailure) {
      throw StateError('Session deletion is unavailable');
    }
    return super.delete(storeName, key);
  }
}
