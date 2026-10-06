import 'package:flutter_test/flutter_test.dart';
import 'package:idb_shim/idb_shim.dart';
import 'package:log_inspector/src/database/database_service.dart';
import 'package:log_inspector/src/logger_output/universal_logger_output.dart';
import 'package:log_inspector/src/models/session.dart';
import 'package:log_inspector/src/services/logs_service.dart';
import 'package:log_inspector/src/services/sessions_service.dart';

import '../mocks/mock_database_service.dart';

void main() {
  late _CountingDatabase database;
  late LogsService logs;
  late SessionsService sessions;
  late UniversalLoggerOutput output;

  setUp(() async {
    database = _CountingDatabase();
    logs = LogsService.createForTesting(database);
    sessions = SessionsService.createForTesting(database);
    output = UniversalLoggerOutput(
      databaseService: database,
      logsService: logs,
      sessionsService: sessions,
    );
    await output.init();
  });

  tearDown(() async => output.destroy());

  test(
    'session list and reader agree despite an old undercounted session',
    () async {
      final sessionId = output.currentSessionId;
      final record = (await sessions.getSession(
        sessionId,
      ))!.copyWith(logCount: 42);
      await database.update(
        DatabaseService.sessionsStoreName,
        sessionId,
        record.toMap(),
      );
      await logs.storeLogs(
        List.generate(12000, (index) => 'Entry $index'),
        sessionId,
      );

      final sessionPage = await output.getSessionsPaginated(0);
      final logPage = await output.readLogsPaginated(0, sessionId: sessionId);

      expect(sessionPage.sessions.single.logCount, 12000);
      expect(sessionPage.sessions.single.logCount, logPage.totalLogs);
      expect((await output.getAllSessions()).single.logCount, 12000);
      expect((await output.getSession(sessionId))!.logCount, 12000);
    },
  );

  test('session counts are scoped to their own stored entries', () async {
    final otherSession = LogSession(
      id: 'other-session',
      createdAt: DateTime.now(),
      lastActivityAt: DateTime.now(),
      logCount: 900,
    );
    await sessions.createSession(otherSession);
    await logs.storeLogs(['One', 'Two', 'Three'], output.currentSessionId);
    await logs.storeLogs(['Other entry'], otherSession.id);

    final result = await output.getAllSessions();
    expect(
      result
          .singleWhere((session) => session.id == output.currentSessionId)
          .logCount,
      3,
    );
    expect(
      result.singleWhere((session) => session.id == otherSession.id).logCount,
      1,
    );
  });

  test('a session with no stored entries has a zero count', () async {
    final session = (await sessions.getSession(
      output.currentSessionId,
    ))!.copyWith(logCount: 900);
    await database.update(
      DatabaseService.sessionsStoreName,
      session.id,
      session.toMap(),
    );

    expect((await output.getSession(session.id))!.logCount, 0);
    expect((await output.getSessionsPaginated(0)).sessions.single.logCount, 0);
    expect(await output.getSession('missing-session'), isNull);
  });

  test(
    'paginated session reads only count the sessions on the requested page',
    () async {
      final now = DateTime.now();
      for (var index = 1; index <= 3; index++) {
        await sessions.createSession(
          LogSession(
            id: 'saved-$index',
            createdAt: now.add(Duration(days: index)),
            lastActivityAt: now,
            logCount: 99,
          ),
        );
        await logs.storeLogs(['Entry $index'], 'saved-$index');
      }

      final page = await output.getSessionsPaginated(1, pageSize: 1);

      expect(page.totalSessions, 4);
      expect(page.sessions.single.id, 'saved-2');
      expect(page.sessions.single.logCount, 1);
      expect(database.countedSessions, ['saved-2']);
    },
  );
}

class _CountingDatabase extends MockDatabaseService {
  final countedSessions = <String>[];

  @override
  Future<int> count(String storeName, {KeyRange? keyRange}) {
    if (storeName == DatabaseService.logsStoreName && keyRange != null) {
      countedSessions.add(keyRange.lower.toString());
    }
    return super.count(storeName, keyRange: keyRange);
  }
}
