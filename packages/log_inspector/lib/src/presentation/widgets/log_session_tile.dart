import 'package:flutter/material.dart';
import 'package:log_inspector/src/models/session.dart';
import 'package:log_inspector/src/utils/extensions/date_time_extension.dart';

enum _SessionAction { view, download, delete }

class LogSessionTile extends StatelessWidget {
  const LogSessionTile({
    super.key,
    required this.session,
    required this.isCurrentSession,
    required this.onView,
    required this.onDownload,
    this.onDelete,
  });

  final LogSession session;
  final bool isCurrentSession;
  final VoidCallback onView;
  final VoidCallback onDownload;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final secondaryStyle = theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      title: Row(
        children: [
          Expanded(
            child: Tooltip(
              message: '${session.id}\nCreated: ${session.createdAt.formatDateTime()}',
              child: Text(
                session.id,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
          ),
          if (isCurrentSession)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text('Active', style: secondaryStyle),
            ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Wrap(
          spacing: 16,
          runSpacing: 4,
          children: [
            Text(
              '${session.logCount} ${session.logCount == 1 ? 'entry' : 'entries'}',
              style: secondaryStyle,
            ),
            Text('Last activity ${session.lastActivityAt.formatDateTime()}', style: secondaryStyle),
          ],
        ),
      ),
      trailing: PopupMenuButton<_SessionAction>(
        tooltip: 'Session actions',
        icon: Icon(Icons.more_horiz, color: colors.onSurfaceVariant),
        color: colors.surface,
        surfaceTintColor: colors.surface,
        onSelected: (action) {
          switch (action) {
            case _SessionAction.view:
              onView();
            case _SessionAction.download:
              onDownload();
            case _SessionAction.delete:
              onDelete?.call();
          }
        },
        itemBuilder:
            (context) => [
              const PopupMenuItem(
                value: _SessionAction.view,
                child: Row(
                  children: [
                    Icon(Icons.subject_outlined, size: 18),
                    SizedBox(width: 12),
                    Text('View logs'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: _SessionAction.download,
                child: Row(
                  children: [
                    Icon(Icons.download_outlined, size: 18),
                    SizedBox(width: 12),
                    Text('Download'),
                  ],
                ),
              ),
              if (onDelete != null)
                PopupMenuItem(
                  value: _SessionAction.delete,
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: colors.error),
                      const SizedBox(width: 12),
                      Text('Delete', style: TextStyle(color: colors.error)),
                    ],
                  ),
                ),
            ],
      ),
      onTap: onView,
    );
  }
}
