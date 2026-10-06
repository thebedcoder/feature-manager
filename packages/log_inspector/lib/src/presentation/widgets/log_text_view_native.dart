import 'dart:math' as math;

import 'package:flutter/material.dart';

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
  final _horizontalController = ScrollController();
  String? _measuredText;
  TextStyle? _measuredStyle;
  TextScaler? _measuredScaler;
  double _textWidth = 0;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_reportScrollMetrics);
  }

  @override
  void didUpdateWidget(covariant LogTextView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController.removeListener(_reportScrollMetrics);
      widget.scrollController.addListener(_reportScrollMetrics);
    }
  }

  void _reportScrollMetrics() {
    if (!widget.scrollController.hasClients) return;
    final position = widget.scrollController.position;
    widget.onScrollMetrics(position.extentAfter, position.viewportDimension);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_reportScrollMetrics);
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium!.copyWith(
      fontFamily: 'RobotoMono',
      package: 'log_inspector',
      fontWeight: FontWeight.w400,
      height: 1.5,
    );
    final textScaler = MediaQuery.textScalerOf(context);
    final text = widget.textController.text;
    if (!widget.wrapLines &&
        (text != _measuredText || style != _measuredStyle || textScaler != _measuredScaler)) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
        textScaler: textScaler,
      )..layout();
      _textWidth = painter.width.ceilToDouble();
      painter.dispose();
      _measuredText = text;
      _measuredStyle = style;
      _measuredScaler = textScaler;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Leave space for the text padding and the caret so the longest line does not wrap.
        final width =
            widget.wrapLines
                ? constraints.maxWidth
                : math.max(constraints.maxWidth, _textWidth + 36);
        return Scrollbar(
          controller: widget.scrollController,
          notificationPredicate: (notification) => notification.metrics.axis == Axis.vertical,
          child: Scrollbar(
            controller: _horizontalController,
            thumbVisibility: width > constraints.maxWidth,
            notificationPredicate: (notification) => notification.metrics.axis == Axis.horizontal,
            child: SingleChildScrollView(
              controller: _horizontalController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: width,
                height: constraints.maxHeight,
                child: TextField(
                  controller: widget.textController,
                  scrollController: widget.scrollController,
                  readOnly: true,
                  showCursor: false,
                  expands: true,
                  maxLines: null,
                  textDirection: TextDirection.ltr,
                  textAlignVertical: TextAlignVertical.top,
                  style: style,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.fromLTRB(16, 16, 16, 24),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
