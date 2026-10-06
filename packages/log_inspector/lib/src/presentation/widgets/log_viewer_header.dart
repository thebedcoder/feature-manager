import 'package:flutter/material.dart';

class LogViewerHeader extends StatelessWidget {
  const LogViewerHeader({
    super.key,
    required this.sessionId,
    required this.loadedCount,
    required this.totalCount,
    required this.wrapLines,
    required this.onToggleWrap,
  });

  final String sessionId;
  final int loadedCount;
  final int totalCount;
  final bool wrapLines;
  final VoidCallback onToggleWrap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Tooltip(
                  message: sessionId,
                  child: Text(
                    sessionId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$loadedCount of $totalCount '
                  '${totalCount == 1 ? 'entry' : 'entries'} loaded · Oldest first',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: wrapLines ? 'Disable line wrapping' : 'Wrap lines',
            isSelected: wrapLines,
            onPressed: onToggleWrap,
            icon: const Icon(Icons.wrap_text),
          ),
        ],
      ),
    );
  }
}
