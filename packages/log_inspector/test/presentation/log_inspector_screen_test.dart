import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:log_inspector/src/database/database_service.dart';
import 'package:log_inspector/src/logger_output/universal_logger_output.dart';
import 'package:log_inspector/src/presentation/log_inspector_screen.dart';
import 'package:log_inspector/src/services/logger_service/logger_service_impl.dart';
import 'package:log_inspector/src/services/logs_service.dart';
import 'package:log_inspector/src/services/sessions_service.dart';

import '../mocks/mock_database_service.dart';

void main() {
  for (final total in [1, 12000]) {
    testWidgets('session list and reader show the same $total stored entries', (
      tester,
    ) async {
      final database = MockDatabaseService();
      final logs = LogsService.createForTesting(database);
      final sessions = SessionsService.createForTesting(database);
      final output = UniversalLoggerOutput(
        databaseService: database,
        logsService: logs,
        sessionsService: sessions,
      );
      await output.init();
      addTearDown(output.destroy);
      final sessionId = output.currentSessionId;
      final session = (await sessions.getSession(
        sessionId,
      ))!.copyWith(logCount: 42);
      await database.update(
        DatabaseService.sessionsStoreName,
        sessionId,
        session.toMap(),
      );
      await logs.storeLogs(
        List.generate(total, (index) => 'Entry $index'),
        sessionId,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: LogInspectorScreen(
            loggerService: LoggerServiceImpl(logger: output),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final unit = total == 1 ? 'entry' : 'entries';
      expect(find.text('$total $unit'), findsOneWidget);
      expect(find.text('42 logs'), findsNothing);

      await tester.tap(find.text(sessionId));
      await tester.pumpAndSettle();

      final loaded = total.clamp(0, 100);
      expect(
        find.text('$loaded of $total $unit loaded · Oldest first'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
