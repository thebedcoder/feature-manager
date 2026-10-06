import 'dart:async';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class LogTextView extends StatefulWidget {
  const LogTextView({
    super.key,
    required this.textController,
    required this.scrollController,
    required this.wrapLines,
    required this.onScrollMetrics,
  });

  final TextEditingController textController;
  final ScrollController scrollController;
  final bool wrapLines;
  final void Function(double extentAfter, double viewportDimension) onScrollMetrics;

  @override
  State<LogTextView> createState() => _LogTextViewState();
}

class _LogTextViewState extends State<LogTextView> {
  static bool _fontRegistered = false;

  web.HTMLTextAreaElement? _element;
  web.HTMLStyleElement? _selectionStyle;
  web.ResizeObserver? _resizeObserver;
  StreamSubscription<web.Event>? _scrollSubscription;
  StreamSubscription<web.Event>? _selectionSubscription;
  int? _animationFrame;
  bool _updatingSelection = false;
  String _renderedText = '';

  @override
  void initState() {
    super.initState();
    widget.textController.addListener(_updateText);
    if (!_fontRegistered) {
      final assetUrl = ui_web.assetManager.getAssetUrl(
        'packages/log_inspector/assets/fonts/RobotoMono.ttf',
      );
      web.document.fonts.add(
        web.FontFace(
          'LogInspectorRobotoMono',
          'url("$assetUrl")'.toJS,
          web.FontFaceDescriptors(display: 'swap'),
        ),
      );
      _fontRegistered = true;
    }
  }

  @override
  void didUpdateWidget(covariant LogTextView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.textController != widget.textController) {
      oldWidget.textController.removeListener(_updateText);
      widget.textController.addListener(_updateText);
      _updateText();
    }
  }

  @override
  void dispose() {
    widget.textController.removeListener(_updateText);
    _scrollSubscription?.cancel();
    _selectionSubscription?.cancel();
    _resizeObserver?.disconnect();
    _selectionStyle?.remove();
    if (_animationFrame case final frame?) web.window.cancelAnimationFrame(frame);
    _element = null;
    super.dispose();
  }

  void _createElement(Object element) {
    final textArea = element as web.HTMLTextAreaElement;
    _element = textArea;
    textArea
      ..readOnly = true
      ..spellcheck = false
      ..classList.add('log-inspector-transcript')
      ..setAttribute('aria-label', 'Session log text')
      ..setAttribute('autocomplete', 'off');
    // Flutter hides native textarea selection; restore it only for this transcript.
    _selectionStyle =
        web.HTMLStyleElement()
          ..textContent = '''
textarea.log-inspector-transcript::selection {
  background-color: var(--log-inspector-selection-background);
  color: var(--log-inspector-selection-foreground);
}
''';
    web.document.head!.append(_selectionStyle!);
    _scrollSubscription = textArea.onScroll.listen((_) => _scheduleMetrics());
    _selectionSubscription = textArea.onSelect.listen((_) {
      final start = textArea.selectionStart;
      final end = textArea.selectionEnd;
      final backwards = textArea.selectionDirection == 'backward';
      _updatingSelection = true;
      widget.textController.selection = TextSelection(
        baseOffset: backwards ? end : start,
        extentOffset: backwards ? start : end,
      );
      _updatingSelection = false;
    });
    _resizeObserver = web.ResizeObserver(
      ((JSArray<web.ResizeObserverEntry> _, web.ResizeObserver _) => _scheduleMetrics()).toJS,
    )..observe(textArea);
    _updateStyle();
    _updateText();
  }

  void _updateText() {
    final element = _element;
    if (element == null || _updatingSelection) return;
    final value = widget.textController.value;
    final top = element.scrollTop;
    final left = element.scrollLeft;
    final textChanged = _renderedText != value.text;
    if (textChanged) {
      element.value = value.text;
      _renderedText = value.text;
    }
    if (value.selection.isValid) {
      element.setSelectionRange(
        value.selection.start,
        value.selection.end,
        value.selection.baseOffset > value.selection.extentOffset ? 'backward' : 'forward',
      );
    }
    element
      ..scrollTop = top
      ..scrollLeft = left;
    if (textChanged) _scheduleMetrics();
  }

  void _updateStyle() {
    final element = _element;
    if (element == null) return;
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyMedium!;
    final fontSize = MediaQuery.textScalerOf(context).scale(style.fontSize!);
    String cssColor(Color color) => '#${color.toARGB32().toRadixString(16).substring(2)}';
    element.wrap = widget.wrapLines ? 'soft' : 'off';
    element.style
      ..width = '100%'
      ..height = '100%'
      ..boxSizing = 'border-box'
      ..margin = '0'
      ..padding = '16px 16px 24px'
      ..border = '0'
      ..outline = 'none'
      ..resize = 'none'
      ..backgroundColor = cssColor(theme.colorScheme.surface)
      ..color = cssColor(theme.colorScheme.onSurface)
      ..fontFamily = 'LogInspectorRobotoMono, monospace'
      ..fontSize = '${fontSize}px'
      ..fontWeight = '400'
      ..lineHeight = '1.5'
      ..direction = 'ltr'
      ..cursor = 'text'
      ..userSelect = 'text'
      ..setProperty('-webkit-user-select', 'text')
      ..setProperty(
        '--log-inspector-selection-background',
        cssColor(theme.colorScheme.primaryContainer),
      )
      ..setProperty(
        '--log-inspector-selection-foreground',
        cssColor(theme.colorScheme.onPrimaryContainer),
      )
      ..setProperty('overscroll-behavior', 'contain')
      ..pointerEvents = (ModalRoute.of(context)?.isCurrent ?? true) ? 'auto' : 'none';
    _scheduleMetrics();
  }

  void _scheduleMetrics() {
    if (_animationFrame != null) return;
    _animationFrame = web.window.requestAnimationFrame(
      (double _) {
        _animationFrame = null;
        final element = _element;
        if (!mounted || element == null || !element.isConnected || element.clientHeight == 0) {
          return;
        }
        widget.onScrollMetrics(
          element.scrollHeight - element.clientHeight - element.scrollTop,
          element.clientHeight.toDouble(),
        );
      }.toJS,
    );
  }

  @override
  Widget build(BuildContext context) {
    _updateStyle();
    return HtmlElementView.fromTagName(tagName: 'textarea', onElementCreated: _createElement);
  }
}
