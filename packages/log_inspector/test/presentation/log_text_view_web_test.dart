@TestOn('browser')
library;

import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:log_inspector/src/presentation/widgets/log_text_view.dart';
import 'package:web/web.dart' as web;

void main() {
  late TextEditingController textController;
  late ScrollController scrollController;
  late _TestViewRegistry registry;

  setUp(() {
    registry = _TestViewRegistry();
    ui_web.debugOverridePlatformViewRegistry(registry);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform_views,
      registry.handleMethodCall,
    );
    textController = TextEditingController(text: List.generate(200, (i) => 'Log $i').join('\n'));
    scrollController = ScrollController();
  });

  tearDown(() {
    ui_web.debugOverridePlatformViewRegistry(null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform_views,
      null,
    );
    textController.dispose();
    scrollController.dispose();
  });

  Future<void> showReader(
    WidgetTester tester, {
    bool wrapLines = false,
    void Function(double, double)? onScrollMetrics,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: LogTextView(
          textController: textController,
          scrollController: scrollController,
          wrapLines: wrapLines,
          onScrollMetrics: onScrollMetrics ?? (_, _) {},
        ),
      ),
    ),
  );

  testWidgets('large transcripts use native text without a Flutter editable layout', (
    tester,
  ) async {
    textController.text = '${'Large log payload. ' * 550000}\nLAST ENTRY';
    await showReader(tester);
    final element = registry.elements.values.single;

    expect(find.byType(EditableText), findsNothing);
    expect(element.readOnly, isTrue);
    expect(element.value, textController.text);
    expect(element.wrap, 'off');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('appending preserves native scroll and a backwards multiline selection', (
    tester,
  ) async {
    await showReader(tester);
    final element = registry.elements.values.single;
    element.style.height = '240px';
    web.document.body!.append(element);
    addTearDown(() => element.remove());

    element
      ..setSelectionRange(20, 80, 'backward')
      ..dispatchEvent(web.Event('select'))
      ..scrollTop = 500;
    expect(textController.selection, const TextSelection(baseOffset: 80, extentOffset: 20));
    textController.value = textController.value.copyWith(text: '${textController.text}\nNext page');

    expect(element.scrollTop, 500);
    expect(element.selectionStart, 20);
    expect(element.selectionEnd, 80);
    expect(element.selectionDirection, 'backward');
    expect(element.value, endsWith('\nNext page'));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('selection stays visible inside Flutter browser selection styles', (tester) async {
    await showReader(tester);
    final element = registry.elements.values.single;
    final host = web.document.createElement('flutter-view')
      ..setAttribute('style', 'user-select: none');
    final engineStyle =
        web.HTMLStyleElement()
          ..textContent = 'flutter-view textarea::selection { background-color: transparent; }';
    web.document.head!.append(engineStyle);
    web.document.body!.append(host);
    host.append(element);
    addTearDown(() {
      host.remove();
      engineStyle.remove();
    });

    final selectionStyle = web.window.getComputedStyle(element, '::selection');
    expect(selectionStyle.backgroundColor, isNot('rgba(0, 0, 0, 0)'));
    expect(selectionStyle.color, isNot(selectionStyle.backgroundColor));
    expect(web.window.getComputedStyle(element).userSelect, 'text');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('wrapping keeps the same text area and selection', (tester) async {
    await showReader(tester);
    final element = registry.elements.values.single;
    element
      ..setSelectionRange(20, 80)
      ..dispatchEvent(web.Event('select'));

    await showReader(tester, wrapLines: true);
    expect(registry.elements.values.single, element);
    expect(element.wrap, 'soft');
    expect(element.selectionStart, 20);
    expect(element.selectionEnd, 80);
    expect(element.value, textController.text);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('leaving the reader disconnects text and selection listeners', (tester) async {
    await showReader(tester);
    final element = registry.elements.values.single;
    final originalText = element.value;
    await tester.pumpWidget(const SizedBox());
    textController.text = 'Different session';
    element
      ..setSelectionRange(20, 80)
      ..dispatchEvent(web.Event('select'));

    expect(element.value, originalText);
    expect(textController.selection.isValid, isFalse);
    expect(tester.takeException(), isNull);
  });
}

class _TestViewRegistry extends ui_web.PlatformViewRegistry {
  final elements = <int, web.HTMLTextAreaElement>{};

  @override
  Object getViewById(int viewId) => elements[viewId]!;

  Future<void> handleMethodCall(MethodCall call) async {
    if (call.method == 'create') {
      final arguments = call.arguments as Map;
      elements[arguments['id'] as int] = web.HTMLTextAreaElement();
    } else if (call.method == 'dispose') {
      elements.remove(call.arguments as int);
    }
  }
}
