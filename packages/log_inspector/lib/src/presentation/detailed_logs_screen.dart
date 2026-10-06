import 'package:flutter/material.dart';
import 'package:log_inspector/src/presentation/widgets/log_text_view.dart';
import 'package:log_inspector/src/presentation/widgets/log_viewer_header.dart';
import 'package:log_inspector/src/services/logger_service/logger_service.dart';
import 'package:log_inspector/src/services/logger_service/logger_service_impl.dart';

class DetailedLogsScreen extends StatefulWidget {
  const DetailedLogsScreen({super.key, this.sessionId, this.loggerService});

  /// Optional session ID to view logs for a specific session.
  /// If null, defaults to the current session.
  final String? sessionId;

  /// Overrides the default logger service, for example in tests.
  final LoggerService? loggerService;

  @override
  State<DetailedLogsScreen> createState() => _DetailedLogsScreenState();
}

class _DetailedLogsScreenState extends State<DetailedLogsScreen> {
  static const _pageSize = 100;
  static final _ansiEscape = RegExp(r'\x1B\[[0-?]*[ -/]*[@-~]');

  late LoggerService _loggerService;
  final _scrollController = ScrollController();
  final _textController = TextEditingController();
  final List<String> _logs = [];
  int _currentPage = 0;
  int _totalLogs = 0;
  int _loadRequestId = 0;
  int _transcriptRevision = 0;
  bool _hasNextPage = false;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _loadFailed = false;
  bool _loadMoreFailed = false;
  bool _isDownloading = false;
  bool _isClearing = false;
  bool _wrapLines = false;

  String get _targetSessionId => widget.sessionId ?? _loggerService.currentSessionId;

  @override
  void initState() {
    super.initState();
    _loggerService = widget.loggerService ?? LoggerServiceImpl();
    _loadLogs();
  }

  @override
  void didUpdateWidget(covariant DetailedLogsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessionId != widget.sessionId ||
        oldWidget.loggerService != widget.loggerService) {
      _loggerService = widget.loggerService ?? LoggerServiceImpl();
      _logs.clear();
      _textController.clear();
      _totalLogs = 0;
      _hasNextPage = false;
      _loadLogs();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs({bool append = false}) async {
    if (append && (_isLoading || _isLoadingMore || _isClearing || !_hasNextPage)) return;

    final requestId = ++_loadRequestId;
    final page = append ? _currentPage + 1 : 0;
    setState(() {
      if (append) {
        _isLoadingMore = true;
        _loadMoreFailed = false;
      } else {
        _isLoading = true;
        _isLoadingMore = false;
        _loadFailed = false;
        _loadMoreFailed = false;
      }
    });

    try {
      final result =
          widget.sessionId == null
              ? await _loggerService.readLogsPaginated(page, pageSize: _pageSize)
              : await _loggerService.readLogsPaginatedForSession(
                _targetSessionId,
                page,
                pageSize: _pageSize,
              );
      if (!mounted || requestId != _loadRequestId) return;

      if (result.logs.isEmpty && result.totalLogs > (append ? _logs.length : 0)) {
        throw StateError('The requested page of logs is unavailable.');
      }

      if (!append && _scrollController.hasClients) _scrollController.jumpTo(0);
      final pageText = result.logs.map((log) => log.replaceAll(_ansiEscape, '')).join('\n');
      final text =
          append && _logs.isNotEmpty
              ? '${_textController.text}${result.logs.isEmpty ? '' : '\n$pageText'}'
              : pageText;
      _textController.value = TextEditingValue(
        text: text,
        selection: append ? _textController.selection : const TextSelection.collapsed(offset: 0),
      );
      setState(() {
        if (!append) {
          _logs.clear();
          _transcriptRevision++;
        }
        _logs.addAll(result.logs);
        _currentPage = page;
        _totalLogs = result.totalLogs;
        _hasNextPage = result.hasNextPage && result.logs.isNotEmpty;
        _isLoading = false;
        _isLoadingMore = false;
      });
      _checkViewportAfterLayout();
    } catch (error) {
      if (!mounted || requestId != _loadRequestId) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _loadFailed = !append;
        _loadMoreFailed = append;
      });
      if (!append && _logs.isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not refresh logs. Try again.')));
      }
    }
  }

  void _loadMoreIfNeeded() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    _loadMoreForViewport(position.extentAfter, position.viewportDimension);
  }

  void _loadMoreForViewport(double extentAfter, double viewportDimension) {
    if (_loadFailed || _loadMoreFailed) return;
    final threshold = viewportDimension.clamp(400.0, 1200.0);
    if (extentAfter < threshold) _loadLogs(append: true);
  }

  void _checkViewportAfterLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadMoreIfNeeded();
    });
  }

  Future<void> _downloadLogs() async {
    setState(() => _isDownloading = true);
    try {
      if (widget.sessionId == null) {
        await _loggerService.downloadLogs();
      } else {
        await _loggerService.downloadLogsForSession(_targetSessionId);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Logs download triggered.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not download logs: $error')));
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _clearLogs() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear logs?'),
            content: const Text(
              'This will delete all logs in this session. This cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Clear'),
              ),
            ],
          ),
    );
    if (!mounted || confirmed != true) return;

    setState(() {
      _isClearing = true;
      _isLoadingMore = false;
      _loadRequestId++;
    });
    try {
      if (widget.sessionId == null) {
        await _loggerService.cleanLogs();
      } else {
        await _loggerService.clearLogsForSession(_targetSessionId);
      }
      if (!mounted) return;
      await _loadLogs();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not clear logs: $error')));
    } finally {
      if (mounted) {
        setState(() => _isClearing = false);
        _checkViewportAfterLayout();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final parentTheme = Theme.of(context);
    final colors = ColorScheme.fromSeed(
      seedColor: parentTheme.colorScheme.primary,
      surface: Colors.white,
    );
    final theme = ThemeData.from(
      colorScheme: colors,
      textTheme: parentTheme.textTheme.apply(
        bodyColor: colors.onSurface,
        displayColor: colors.onSurface,
      ),
      useMaterial3: parentTheme.useMaterial3,
    );
    final busy = _isLoading || _isClearing;

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: colors.surface,
          surfaceTintColor: colors.surface,
          title: Text(widget.sessionId == null ? 'Current session logs' : 'Session logs'),
          actions: [
            IconButton(
              tooltip: 'Download logs',
              icon:
                  _isDownloading
                      ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.download_outlined),
              onPressed: busy || _isDownloading || _logs.isEmpty ? null : _downloadLogs,
            ),
            IconButton(
              tooltip: 'Clear logs',
              icon: const Icon(Icons.delete_outline),
              onPressed: busy || _isDownloading || _logs.isEmpty ? null : _clearLogs,
            ),
            IconButton(
              tooltip: 'Refresh logs',
              icon: const Icon(Icons.refresh),
              onPressed: busy ? null : _loadLogs,
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              LogViewerHeader(
                sessionId: _targetSessionId,
                loadedCount: _logs.length,
                totalCount: _totalLogs,
                wrapLines: _wrapLines,
                onToggleWrap: () => setState(() => _wrapLines = !_wrapLines),
              ),
              SizedBox(height: 2, child: busy ? const LinearProgressIndicator() : null),
              Expanded(
                child:
                    _logs.isEmpty
                        ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _loadFailed ? Icons.error_outline : Icons.subject,
                                  size: 40,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _isLoading
                                      ? 'Loading logs…'
                                      : _loadFailed
                                      ? 'Could not load logs'
                                      : 'No logs in this session',
                                  style: theme.textTheme.titleMedium,
                                ),
                                if (_loadFailed)
                                  TextButton.icon(
                                    onPressed: _loadLogs,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Retry'),
                                  ),
                              ],
                            ),
                          ),
                        )
                        : NotificationListener<ScrollMetricsNotification>(
                          onNotification: (_) {
                            _checkViewportAfterLayout();
                            return false;
                          },
                          child: LogTextView(
                            key: ValueKey(_transcriptRevision),
                            textController: _textController,
                            scrollController: _scrollController,
                            wrapLines: _wrapLines,
                            onScrollMetrics: _loadMoreForViewport,
                          ),
                        ),
              ),
              if (_hasNextPage)
                SizedBox(
                  height: 48,
                  child: Center(
                    child:
                        _isLoadingMore
                            ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : TextButton.icon(
                              onPressed: busy ? null : () => _loadLogs(append: true),
                              icon: Icon(_loadMoreFailed ? Icons.refresh : Icons.expand_more),
                              label: Text(
                                _loadMoreFailed ? 'Could not load more. Retry' : 'Load more',
                              ),
                            ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
