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

/// "Abwesenheit": balances (F6), my requests (F7), team (F8).
/// Sample data until sprint 4.
class AbsenceScreen extends ConsumerWidget {
  const AbsenceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final data = ref.watch(demoDataProvider);
    if (data == null) {
      return MainPage(
        title: l.navAbsence,
        body: EmptyState(
          icon: Icons.beach_access_rounded,
          title: l.absenceEmptyTitle,
          body: l.absenceEmptyBody,
        ),
      );
    }
    final requests = [...data.absences]
      ..sort((a, b) => b.from.compareTo(a.from));
    return MainPage(
      title: l.navAbsence,
      demo: true,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Gap.m, Gap.s, Gap.m, 120),
        children: [
          _LeaveCard(b: data.balances),
          const SizedBox(height: Gap.m),
          PressScale(
            child: FilledButton.icon(
              key: const Key('newRequest'),
              onPressed: () {
                Haptics.tap();
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(l.comingSoon)));
              },
              icon: const Icon(Icons.add_rounded),
              label: Text(l.newRequest),
            ),
          ),
          const SizedBox(height: Gap.l),
          _Section(l.myRequests),
          SoftCard(
            padding: const EdgeInsets.symmetric(vertical: Gap.xs),
            child: Column(
              children: [for (final a in requests) _RequestTile(a: a)],
            ),
          ),
          const SizedBox(height: Gap.l),
          _Section(l.teamAbsences),
          SoftCard(
            padding: const EdgeInsets.symmetric(vertical: Gap.xs),
            child: Column(
              children: [for (final c in data.colleagues) _ColleagueTile(c: c)],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(Gap.s, 0, Gap.s, Gap.s),
    child: Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

String _days(double d) => d == d.roundToDouble()
    ? d.toStringAsFixed(0)
    : d.toStringAsFixed(1).replaceAll('.', ',');

/// Leave balance as one segmented bar: taken, planned, requested,
/// available, each labelled in the legend.
class _LeaveCard extends StatelessWidget {
  const _LeaveCard({required this.b});

  final DemoBalances b;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final parts = [
      (l.taken, b.taken, scheme.primary),
      (l.planned, b.planned, scheme.primary.withValues(alpha: 0.6)),
      (l.requested, b.pending, statusColor(context, DayStatus.incomplete)),
      (l.available, b.available, scheme.surfaceContainerHighest),
    ];
    return SoftCard(
      key: const Key('leaveCard'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.beach_access_rounded, color: scheme.primary),
              const SizedBox(width: Gap.s),
              Text(l.vacationTitle, style: theme.textTheme.titleMedium),
              const Spacer(),
              Text(
                '${DateTime.now().year}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: Gap.m),
          Wrap(
            spacing: Gap.s,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              Text(
                _days(b.available),
                style: theme.textTheme.displaySmall?.copyWith(
                  fontSize: 40,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${l.daysUnit} ${l.available}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Gap.m),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  for (var i = 0; i < parts.length; i++)
                    if (parts[i].$2 > 0)
                      Expanded(
                        flex: (parts[i].$2 * 10).round(),
                        child: Container(
                          margin: EdgeInsets.only(
                            right: i == parts.length - 1 ? 0 : 2,
                          ),
                          color: parts[i].$3,
                        ),
                      ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Gap.m),
          Wrap(
            spacing: Gap.m,
            runSpacing: Gap.s,
            children: [
              for (final p in parts)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: p.$3,
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${p.$1} ${_days(p.$2)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: Gap.m),
          Container(
            padding: const EdgeInsets.all(Gap.s + 4),
            decoration: BoxDecoration(
              color: statusColor(
                context,
                DayStatus.incomplete,
              ).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(Radii.field),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.hourglass_bottom_rounded,
                  size: 18,
                  color: statusColor(context, DayStatus.incomplete),
                ),
                const SizedBox(width: Gap.s),
                Expanded(
                  child: Text(
                    '${l.carryOver} ${_days(b.carryOver)} ${l.daysUnit} · ${l.expiresOn} ${dateShort(context, b.carryOverExpiry)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({required this.a});

  final AbsenceRecord a;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fmt = DateFormat('d. MMM', localeTag(context));
    final (label, color, icon) = switch (a.status) {
      RequestStatus.pending => (
        l.reqPending,
        statusColor(context, DayStatus.incomplete),
        Icons.hourglass_top_rounded,
      ),
      RequestStatus.approved => (
        l.reqApproved,
        statusColor(context, DayStatus.complete),
        Icons.check_circle_rounded,
      ),
      RequestStatus.rejected => (
        l.reqRejected,
        scheme.error,
        Icons.cancel_rounded,
      ),
      RequestStatus.cancelled => (
        l.reqCancelled,
        scheme.onSurfaceVariant,
        Icons.remove_circle_rounded,
      ),
    };
    final range = a.from == a.to
        ? fmt.format(a.from)
        : '${fmt.format(a.from)} – ${fmt.format(a.to)}';
    return ListTile(
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: scheme.primary.withValues(alpha: 0.1),
        ),
        child: Icon(absenceIcon(a.type), color: scheme.primary, size: 22),
      ),
      title: Text(absenceTypeLabel(context, a.type)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$range · ${_days(a.days)} ${a.days == 1 ? l.dayUnit : l.daysUnit}',
          ),
          const SizedBox(height: 6),
          StatusPill(label: label, color: color, icon: icon),
        ],
      ),
    );
  }
}

class _ColleagueTile extends StatelessWidget {
  const _ColleagueTile({required this.c});

  final DemoColleagueAbsence c;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('EEE d. MMM', localeTag(context));
    final range = c.from == c.to
        ? fmt.format(c.from)
        : '${fmt.format(c.from)} – ${fmt.format(c.to)}';
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.secondaryContainer,
        child: Text(
          c.initials,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSecondaryContainer,
          ),
        ),
      ),
      title: Text(c.name),
      subtitle: Text(range),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            absenceIcon(c.type),
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            absenceTypeLabel(context, c.type),
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
