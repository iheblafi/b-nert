import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:material_ui/material_ui.dart';

import '../../app/shell/main_page.dart';
import '../../core/design/app_theme.dart';
import '../../core/design/motion.dart';
import '../../core/l10n/l10n.dart';
import '../demo/demo_data.dart';
import '../demo/demo_mode.dart';
import '../demo/demo_ui.dart';

/// Notification list (F10). Sample data until sprint 3.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final data = ref.watch(demoDataProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Flexible(
              child: Text(l.notifications, overflow: TextOverflow.ellipsis),
            ),
            if (data != null) ...[
              const SizedBox(width: Gap.s),
              const DemoBadge(),
            ],
          ],
        ),
      ),
      body: data == null || data.notifications.isEmpty
          ? EmptyState(
              icon: Icons.notifications_none_rounded,
              title: l.notificationsEmptyTitle,
              body: l.notificationsEmptyBody,
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(Gap.m, Gap.s, Gap.m, Gap.xl),
              children: [
                for (final n in data.notifications)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Gap.s),
                    child: SoftCard(
                      padding: EdgeInsets.zero,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: Gap.m,
                          vertical: 6,
                        ),
                        onTap: Haptics.selection,
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _color(
                              context,
                              n.kind,
                            ).withValues(alpha: 0.14),
                          ),
                          child: Icon(
                            _icon(n.kind),
                            color: _color(context, n.kind),
                          ),
                        ),
                        title: Text(
                          n.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: n.unread
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            Text(n.body),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat(
                                'd. MMM, HH:mm',
                                localeTag(context),
                              ).format(n.at),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        trailing: n.unread
                            ? Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: theme.colorScheme.primary,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  static IconData _icon(NotificationKind k) => switch (k) {
    NotificationKind.missingEntry => Icons.edit_calendar_rounded,
    NotificationKind.approved => Icons.check_circle_rounded,
    NotificationKind.rejected => Icons.cancel_rounded,
    NotificationKind.request => Icons.mark_email_unread_rounded,
  };

  static Color _color(BuildContext context, NotificationKind k) => switch (k) {
    NotificationKind.missingEntry => statusColor(context, DayStatus.missing),
    NotificationKind.approved => statusColor(context, DayStatus.complete),
    NotificationKind.rejected => Theme.of(context).colorScheme.error,
    NotificationKind.request => Theme.of(context).colorScheme.primary,
  };
}
