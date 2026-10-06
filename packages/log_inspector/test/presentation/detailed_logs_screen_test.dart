import 'dart:async';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:log_inspector/src/models/paginated_logs.dart';
import 'package:log_inspector/src/presentation/detailed_logs_screen.dart';
import 'package:log_inspector/src/services/logger_service/logger_service.dart';

void main() {
  late _TestLoggerService service;

  setUp(() => service = _TestLoggerService());

  Future<void> showReader(WidgetTester tester, {String? sessionId}) async {
    await tester.pumpWidget(
      MaterialApp(home: DetailedLogsScreen(sessionId: sessionId, loggerService: service)),
    );
    await tester.pumpAndSettle();
  }

  ScrollController controller(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField)).scrollController!;

  testWidgets('keeps the transcript, scroll position and selection while the next page loads', (
    tester,
  ) async {
    final nextPage = Completer<PaginatedLogs>();
    service.onRead = (page) => page == 1 ? nextPage.future : Future.value(service.result(page));
    await showReader(tester);

    final scrollController = controller(tester);
    final position = scrollController.position;
    final textElement = tester.element(find.byType(TextField));
    final textController = tester.widget<TextField>(find.byType(TextField)).controller!;
    final selection = TextSelection(
      baseOffset: textController.text.indexOf('Message 90'),
      extentOffset: textController.text.indexOf('Message 94'),
    );
    textController.selection = selection;
    scrollController.jumpTo(position.maxScrollExtent - 100);
    final offset = scrollController.offset;
    await tester.pump();

    expect(service.requestedPages, [0, 1]);
    expect(scrollController.position, same(position));
    expect(tester.element(find.byType(TextField)), same(textElement));
    expect(scrollController.offset, offset);

    nextPage.complete(service.result(1));
    await tester.pumpAndSettle();

    expect(scrollController.position, same(position));
    expect(scrollController.offset, offset);
    expect(find.text('200 of 250 entries loaded · Oldest first'), findsOneWidget);
    expect(textController.selection, selection);
    expect(textController.text, service.logs.take(200).join('\n'));
  });

  testWidgets('refresh restores the transcript from the first page', (tester) async {
    await showReader(tester, sessionId: 'saved-session');
    final scrollController = controller(tester);
    scrollController.jumpTo(scrollController.position.maxScrollExtent - 100);
    await tester.pumpAndSettle();
    expect(service.requestedPages, [0, 1]);

    await tester.tap(find.byTooltip('Refresh logs'));
    await tester.pumpAndSettle();

    expect(service.requestedPages, [0, 1, 0]);
    expect(service.requestedSessions, everyElement('saved-session'));
    expect(scrollController.offset, 0);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      startsWith('Message 1\n'),
    );
    expect(find.text('100 of 250 entries loaded · Oldest first'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      service.logs.take(100).join('\n'),
    );
  });

  testWidgets('retries a failed page without skipping entries', (tester) async {
    var failNextPage = true;
    service.onRead = (page) async {
      if (page == 1 && failNextPage) throw StateError('Temporary read failure');
      return service.result(page);
    };
    await showReader(tester);
    final scrollController = controller(tester);
    scrollController.jumpTo(scrollController.position.maxScrollExtent - 100);
    await tester.pumpAndSettle();
    expect(service.requestedPages, [0, 1]);
    expect(scrollController.offset, greaterThan(0));

    failNextPage = false;
    await tester.tap(find.text('Could not load more. Retry'));
    await tester.pumpAndSettle();

    expect(service.requestedPages, [0, 1, 1]);
    expect(find.text('200 of 250 entries loaded · Oldest first'), findsOneWidget);
  });

  testWidgets('ignores an old page response after refreshing', (tester) async {
    final nextPage = Completer<PaginatedLogs>();
    service.onRead = (page) => page == 1 ? nextPage.future : Future.value(service.result(page));
    await showReader(tester);
    final scrollController = controller(tester);
    scrollController.jumpTo(scrollController.position.maxScrollExtent - 100);
    await tester.pump();

    await tester.tap(find.byTooltip('Refresh logs'));
    await tester.pumpAndSettle();
    nextPage.complete(service.result(1));
    await tester.pumpAndSettle();

    expect(service.requestedPages, [0, 1, 0]);
    expect(find.text('100 of 250 entries loaded · Oldest first'), findsOneWidget);
    expect(scrollController.offset, 0);
  });

  testWidgets('offers retry when the final page returns no entries despite its count', (
    tester,
  ) async {
    service.logs = service.logs.take(200).toList();
    service.onRead = (page) async {
      if (page == 0) return service.result(page);
      return const PaginatedLogs(
        logs: [],
        currentPage: 1,
        pageSize: 100,
        totalLogs: 200,
        totalPages: 2,
        hasNextPage: false,
        hasPreviousPage: true,
      );
    };
    await showReader(tester);
    final scrollController = controller(tester);
    scrollController.jumpTo(scrollController.position.maxScrollExtent - 100);
    await tester.pumpAndSettle();

    service.onRead = null;
    await tester.tap(find.text('Could not load more. Retry'));
    await tester.pumpAndSettle();
    expect(service.requestedPages, [0, 1, 1]);
    expect(find.text('200 of 200 entries loaded · Oldest first'), findsOneWidget);
  });

  testWidgets('loads another page when the first page does not fill the viewport', (tester) async {
    service.logs = List.generate(5, (index) => 'Message ${index + 1}');
    service.resultPageSize = 2;
    await showReader(tester);

    expect(service.requestedPages, [0, 1, 2]);
    expect(find.text('5 of 5 entries loaded · Oldest first'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      endsWith('Message 5'),
    );
  });

  testWidgets('can retry an initial load failure', (tester) async {
    service.onRead = (_) => Future.error(StateError('Unavailable'));
    await showReader(tester);
    expect(find.text('Could not load logs'), findsOneWidget);

    service.onRead = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      startsWith('Message 1\n'),
    );
    expect(service.requestedPages, [0, 0]);
  });

  testWidgets('finishing a load after leaving the screen is safe', (tester) async {
    final response = Completer<PaginatedLogs>();
    service.onRead = (_) => response.future;
    await tester.pumpWidget(MaterialApp(home: DetailedLogsScreen(loggerService: service)));
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    response.complete(service.result(0));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('downloading keeps the reader mounted at the same position', (tester) async {
    service.download = Completer<void>();
    await showReader(tester);
    final scrollController = controller(tester);
    scrollController.jumpTo(500);
    await tester.pumpAndSettle();
    final position = scrollController.position;

    await tester.tap(find.byTooltip('Download logs'));
    await tester.pump();
    expect(scrollController.position, same(position));
    expect(scrollController.offset, 500);

    service.download!.complete();
    await tester.pumpAndSettle();
    expect(scrollController.offset, 500);
  });

  testWidgets('clear reloads page zero and shows an empty session', (tester) async {
    await showReader(tester, sessionId: 'saved-session');
    final scrollController = controller(tester);
    scrollController.jumpTo(scrollController.position.maxScrollExtent - 100);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Clear logs'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    expect(service.clearedSession, 'saved-session');
    expect(service.requestedPages, [0, 1, 0]);
    expect(find.text('No logs in this session'), findsOneWidget);
    expect(find.text('0 of 0 entries loaded · Oldest first'), findsOneWidget);
  });

  testWidgets('shows complete large entries in a single read-only transcript', (tester) async {
    final content = '${'A long diagnostic message. ' * 1000}THE END';
    service.logs = ['Session started', content, 'Session finished'];
    await showReader(tester);

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, service.logs.join('\n'));
    expect(field.readOnly, isTrue);
    final horizontal =
        tester.widget<SingleChildScrollView>(find.byType(SingleChildScrollView)).controller!;
    expect(horizontal.position.maxScrollExtent, greaterThan(0));
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('dragging across entries copies multiple lines without ANSI codes', (tester) async {
    service.logs = ['\x1B[31mFirst entry\x1B[0m\n  payload: value', 'Second entry', 'Third entry'];
    await showReader(tester);
    final field = tester.widget<TextField>(find.byType(TextField));
    final textController = field.controller!;
    const plainText = 'First entry\n  payload: value\nSecond entry\nThird entry';
    expect(textController.text, plainText);

    String? copiedText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (
      call,
    ) async {
      if (call.method == 'Clipboard.setData') {
        copiedText = (call.arguments as Map)['text'] as String;
      }
      return null;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    final RenderEditable editable =
        tester.state<EditableTextState>(find.byType(EditableText)).renderEditable;
    Offset caretPosition(int offset) =>
        editable.localToGlobal(editable.getLocalRectForCaret(TextPosition(offset: offset)).center);
    const start = 6;
    final end = plainText.indexOf('\nThird entry');
    final gesture = await tester.startGesture(caretPosition(start), kind: PointerDeviceKind.mouse);
    await tester.pump();
    await gesture.moveTo(caretPosition(end));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(textController.selection.textInside(plainText), plainText.substring(start, end));

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(copiedText, 'entry\n  payload: value\nSecond entry');
  });

  testWidgets('line wrapping can be toggled without changing text or selection', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    service.logs = ['┌${'─' * 119}', 'A complete message'];
    await showReader(tester);
    final field = tester.widget<TextField>(find.byType(TextField));
    final horizontal =
        tester.widget<SingleChildScrollView>(find.byType(SingleChildScrollView)).controller!;
    const selection = TextSelection(baseOffset: 0, extentOffset: 12);
    field.controller!.selection = selection;
    expect(horizontal.position.maxScrollExtent, greaterThan(0));
    horizontal.jumpTo(100);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Wrap lines'));
    await tester.pumpAndSettle();
    expect(horizontal.position.maxScrollExtent, 0);
    expect(field.controller!.text, service.logs.join('\n'));
    expect(field.controller!.selection, selection);

    await tester.tap(find.byTooltip('Disable line wrapping'));
    await tester.pumpAndSettle();
    expect(horizontal.position.maxScrollExtent, greaterThan(0));
    expect(field.controller!.selection, selection);
  });

  testWidgets('reader stays white and readable in a narrow dark app with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    service.logs = ['A log message that wraps across multiple lines on a narrow screen.'];
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        builder:
            (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(2)),
              child: child!,
            ),
        home: DetailedLogsScreen(sessionId: 'a-long-session-identifier', loggerService: service),
      ),
    );
    await tester.pumpAndSettle();
    final readerTheme = Theme.of(tester.element(find.byType(TextField)));
    expect(readerTheme.colorScheme.surface, Colors.white);
    expect(readerTheme.brightness, Brightness.light);
    expect(
      tester.widget<TextField>(find.byType(TextField)).style!.color,
      readerTheme.colorScheme.onSurface,
    );
    expect(tester.takeException(), isNull);
  });
}

class _TestLoggerService extends Fake implements LoggerService {
  List<String> logs = List.generate(250, (index) => 'Message ${index + 1}');
  final requestedPages = <int>[];
  final requestedSessions = <String?>[];
  int resultPageSize = 100;
  Future<PaginatedLogs> Function(int page)? onRead;
  Completer<void>? download;
  String? clearedSession;

  @override
  String get currentSessionId => 'current-session';

  PaginatedLogs result(int page) {
    final totalPages = (logs.length / resultPageSize).ceil();
    return PaginatedLogs(
      logs: logs.skip(page * resultPageSize).take(resultPageSize).toList(),
      currentPage: page,
      pageSize: resultPageSize,
      totalLogs: logs.length,
      totalPages: totalPages,
      hasNextPage: page < totalPages - 1,
      hasPreviousPage: page > 0,
    );
  }

  Future<PaginatedLogs> _read(int page, String? sessionId) async {
    requestedPages.add(page);
    requestedSessions.add(sessionId);
    return onRead == null ? result(page) : await onRead!(page);
  }

  @override
  Future<PaginatedLogs> readLogsPaginated(int page, {int pageSize = 100}) => _read(page, null);

  @override
  Future<PaginatedLogs> readLogsPaginatedForSession(
    String sessionId,
    int page, {
    int pageSize = 100,
  }) => _read(page, sessionId);

  @override
  Future<void> downloadLogs() async => await download?.future;

  @override
  Future<void> clearLogsForSession(String sessionId) async {
    clearedSession = sessionId;
    logs = [];
  }
}
