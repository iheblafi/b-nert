import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:material_ui/material_ui.dart';

import '../../app/shell/main_page.dart';
import '../../core/design/app_theme.dart';
import '../../core/design/motion.dart';
import '../../core/design/state_views.dart';
import '../../core/errors/app_failure.dart';
import '../../core/l10n/l10n.dart';
import '../auth/state/session.dart';
import '../demo/demo_data.dart';
import '../demo/demo_mode.dart';
import '../demo/demo_ui.dart';
import '../demo/entry_details_sheet.dart';
import '../user_context/model/user_context.dart';
import 'data/overview_rows.dart' show isoDay;
import 'domain/german_time.dart';
import 'domain/time_rules.dart';
import 'state/overview_provider.dart';

const _tabular = [FontFeature.tabularFigures()];

/// "Zeiten": greeting, then day, week and month (F2). Shows the user's
/// own entries from the backend, or sample data while that is switched on.
class TimesScreen extends ConsumerStatefulWidget {
  const TimesScreen({this.now, super.key});

  /// For tests; the device clock otherwise.
  final DateTime Function()? now;

  @override
  ConsumerState<TimesScreen> createState() => _TimesScreenState();
}

class _TimesScreenState extends ConsumerState<TimesScreen> {
  int _view = 0;
  DateTime? _selected;

  void _select(DateTime day, {int? view}) {
    Haptics.selection();
    setState(() {
      _selected = GermanTime.startOfDay(day);
      if (view != null) _view = view;
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final ctx = session is SignedIn ? session.context : null;
    final demo = ref.watch(demoDataProvider);
    final l = context.l10n;
    final now = (widget.now ?? DateTime.now)();
    final DateTime today = demo?.today ?? ref.watch(germanTodayProvider);
    final selected = _selected ?? today;
    final key = monthKey(selected);
    final live = demo == null && ctx != null
        ? ref.watch(overviewProvider(key))
        : null;
    final OverviewData? data = demo ?? live?.value;

    Future<void> refresh() async {
      if (live == null) return;
      try {
        final _ = await ref.refresh(overviewProvider(key).future);
      } on Object {
        // Shown by the notice; the old figures stay.
      }
    }

    final Widget content;
    if (data == null && live != null && live.hasError) {
      content = SliverFillRemaining(
        hasScrollBody: false,
        child: ErrorView(
          failure: AppFailure.from(live.error!),
          onRetry: () => ref.invalidate(overviewProvider(key)),
        ),
      );
    } else if (data == null && live != null) {
      content = const SliverFillRemaining(
        hasScrollBody: false,
        child: LoadingView(key: Key('overviewLoading')),
      );
    } else if (data == null) {
      content = SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyState(
          icon: Icons.schedule_rounded,
          title: l.timesEmptyTitle,
          body: l.timesEmptyBody,
        ),
      );
    } else {
      content = SliverMainAxisGroup(
        slivers: [
          if (live != null && live.hasError)
            SliverToBoxAdapter(
              child: _Notice(
                key: const Key('overviewStale'),
                icon: Icons.cloud_off_rounded,
                text: data.loadedAt == null
                    ? l.overviewStale
                    : '${l.overviewStale} ${l.asOf}: ${timeOf(data.loadedAt!)}',
              ),
            ),
          if (data.incomplete.isNotEmpty)
            SliverToBoxAdapter(
              child: _Notice(
                key: const Key('overviewIncomplete'),
                icon: Icons.info_outline_rounded,
                text: l.overviewIncomplete,
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Gap.m, Gap.m, Gap.m, 0),
              child: SegmentedButton<int>(
                key: const Key('timesView'),
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: 0, label: Text(l.tabDay)),
                  ButtonSegment(value: 1, label: Text(l.tabWeek)),
                  ButtonSegment(value: 2, label: Text(l.tabMonth)),
                ],
                selected: {_view},
                onSelectionChanged: (s) {
                  Haptics.selection();
                  setState(() => _view = s.first);
                },
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(Gap.m, Gap.m, Gap.m, 120),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: switch (_view) {
                      0 => _DayView(
                        key: const ValueKey('day'),
                        data: data,
                        day: selected,
                        onSelect: _select,
                      ),
                      1 => _WeekView(
                        key: const ValueKey('week'),
                        data: data,
                        day: selected,
                        onSelect: _select,
                      ),
                      _ => _MonthView(
                        key: const ValueKey('month'),
                        data: data,
                        day: selected,
                        onSelect: _select,
                      ),
                    },
                  ),
                  if (live != null) ...[
                    const SizedBox(height: Gap.m),
                    Text(
                      data.expected.assumed
                          ? l.targetAssumed
                          : l.targetProvisional,
                      key: const Key('targetNote'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: refresh,
          notificationPredicate: (_) => live != null,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _Greeting(ctx: ctx, now: now, demo: demo != null),
              ),
              content,
            ],
          ),
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text, super.key});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.m, Gap.m, Gap.m, 0),
      child: SoftCard(
        child: Row(
          children: [
            Icon(icon, size: 20, color: muted),
            const SizedBox(width: Gap.s),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.ctx, required this.now, required this.demo});

  final UserContext? ctx;
  final DateTime now;
  final bool demo;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final h = now.hour;
    final hello = h >= 5 && h < 11
        ? l.greetingMorning
        : h >= 18 || h < 5
        ? l.greetingEvening
        : l.greetingDay;
    final name = ctx?.firstName?.trim();
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.l, Gap.m, Gap.s, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: Gap.s,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      DateFormat.MMMMEEEEd(localeTag(context)).format(now),
                      key: const Key('todayDate'),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    if (demo) const DemoBadge(),
                  ],
                ),
                const SizedBox(height: Gap.xs),
                Text(
                  name == null || name.isEmpty ? hello : '$hello, $name',
                  key: const Key('greeting'),
                  style: theme.textTheme.headlineMedium,
                ),
              ],
            ),
          ),
          const BellButton(),
        ],
      ),
    );
  }
}

// --- Day ---------------------------------------------------------------

class _DayView extends StatelessWidget {
  const _DayView({
    required this.data,
    required this.day,
    required this.onSelect,
    super.key,
  });

  final OverviewData data;
  final DateTime day;
  final void Function(DateTime, {int? view}) onSelect;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final entries = data.entriesOn(day);
    final status = data.statusOf(day);
    final holiday = data.holidays[day];
    final absence = data.absenceOn(day);
    final children = <Widget>[];
    for (var i = 0; i < entries.length; i++) {
      if (i > 0) {
        final gap = GermanTime.minutesBetween(
          entries[i - 1].time.end,
          entries[i].time.start,
        );
        if (gap > 0) children.add(_GapRow(minutes: gap));
      }
      children.add(_EntryCard(entry: entries[i], rules: data.rules));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _WeekStrip(data: data, day: day, onSelect: onSelect),
        const SizedBox(height: Gap.m),
        _DaySummary(data: data, day: day),
        if (holiday != null || absence != null) ...[
          const SizedBox(height: Gap.m),
          _InfoCard(
            icon: holiday != null
                ? statusIcon(DayStatus.holiday)
                : absenceIcon(absence!.type),
            color: statusColor(
              context,
              holiday != null ? DayStatus.holiday : DayStatus.absent,
            ),
            title: holiday ?? absenceTypeLabel(context, absence!.type),
            body: holiday != null ? l.statusHoliday : (absence!.note ?? ''),
          ),
        ],
        if (status == DayStatus.missing) ...[
          const SizedBox(height: Gap.m),
          SoftCard(
            key: const Key('missingDay'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.edit_calendar_rounded,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: Gap.m),
                    Expanded(
                      child: Text(
                        l.missingTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Gap.s),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 44),
                    ),
                    onPressed: () =>
                        context.push('/entry/new?date=${isoDay(day)}'),
                    child: Text(l.missingAction),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (children.isNotEmpty) ...[
          const SizedBox(height: Gap.m),
          ...children,
        ],
        if (data.overtime case final overtime?) ...[
          const SizedBox(height: Gap.m),
          _OvertimeCard(overtime: overtime),
        ],
      ],
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.data,
    required this.day,
    required this.onSelect,
  });

  final OverviewData data;
  final DateTime day;
  final void Function(DateTime, {int? view}) onSelect;

  @override
  Widget build(BuildContext context) {
    final monday = GermanTime.addDays(day, -(day.weekday - 1));
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fmt = DateFormat.E(localeTag(context));
    return Row(
      children: [
        _Arrow(
          icon: Icons.chevron_left_rounded,
          onTap: () => onSelect(GermanTime.addDays(day, -7)),
        ),
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Builder(
              builder: (context) {
                final d = GermanTime.addDays(monday, i);
                final selected = d == day;
                final isToday = d == data.today;
                final status = data.statusOf(d);
                final showDot =
                    status != DayStatus.future && status != DayStatus.weekend;
                return Semantics(
                  button: true,
                  selected: selected,
                  label:
                      '${DateFormat.MMMMEEEEd(localeTag(context)).format(d)}, ${statusLabel(context, status)}',
                  excludeSemantics: true,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => onSelect(d),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? scheme.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: isToday && !selected
                            ? Border.all(color: scheme.primary, width: 1.4)
                            : null,
                      ),
                      child: Column(
                        children: [
                          Text(
                            fmt.format(d).replaceAll('.', ''),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: selected
                                  ? scheme.onPrimary
                                  : scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${d.day}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: selected
                                  ? scheme.onPrimary
                                  : scheme.onSurface,
                              fontFeatures: _tabular,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: !showDot
                                  ? Colors.transparent
                                  : selected
                                  ? scheme.onPrimary
                                  : statusColor(context, status),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        _Arrow(
          icon: Icons.chevron_right_rounded,
          onTap: () => onSelect(GermanTime.addDays(day, 7)),
        ),
      ],
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: icon == Icons.chevron_left_rounded
        ? MaterialLocalizations.of(context).previousPageTooltip
        : MaterialLocalizations.of(context).nextPageTooltip,
    // 48 x 48: the minimum touch target.
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints.tightFor(width: 48, height: 48),
    onPressed: onTap,
    icon: Icon(icon),
  );
}

class _DaySummary extends StatelessWidget {
  const _DaySummary({required this.data, required this.day});

  final OverviewData data;
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final worked = data.workedOn(day);
    final expected = data.expectedOn(day);
    final status = data.statusOf(day);
    final check = data.checkOn(day);
    final night = data.nightOn(day);
    final color = statusColor(context, status);
    return SoftCard(
      key: const Key('daySummary'),
      child: Column(
        children: [
          Row(
            children: [
              ProgressRing(
                size: 100,
                value: expected == 0 ? (worked > 0 ? 1 : 0) : worked / expected,
                color: status == DayStatus.missing
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      hm(worked),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontFeatures: _tabular,
                      ),
                    ),
                    Text(
                      l.worked,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Gap.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat.MMMMEEEEd(localeTag(context)).format(day),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: Gap.s),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        StatusPill(
                          label: statusLabel(context, status),
                          color: color,
                          icon: statusIcon(status),
                        ),
                        if (!check.compliant)
                          StatusPill(
                            key: const Key('breakWarning'),
                            label: l.breakTooShort,
                            color: statusColor(context, DayStatus.incomplete),
                            icon: Icons.free_breakfast_rounded,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Gap.m),
          const Divider(),
          const SizedBox(height: Gap.s),
          Row(
            children: [
              Expanded(
                child: _Stat(label: l.target, value: hm(expected)),
              ),
              Expanded(
                child: _Stat(
                  label: l.breakLabel,
                  value: check.compliant
                      ? hm(check.totalBreak)
                      : '${hm(check.totalBreak)} / ${hm(check.requiredBreak)}',
                ),
              ),
              Expanded(
                child: _Stat(label: l.nightLabel, value: hm(night)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(fontFeatures: _tabular),
        ),
      ],
    );
  }
}

class _GapRow extends StatelessWidget {
  const _GapRow({required this.minutes});

  final int minutes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: Gap.l),
      child: Row(
        children: [
          Icon(Icons.free_breakfast_outlined, size: 16, color: muted),
          const SizedBox(width: Gap.s),
          Text(
            '${context.l10n.breakLabel} ${hm(minutes)}',
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
          const SizedBox(width: Gap.s),
          Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
        ],
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry, required this.rules});

  final TimeRecord entry;
  final TimeRules rules;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final totals = entry.totals(rules);
    final pill = entryPill(context, entry);
    final accent = !entry.counts
        ? statusColor(context, DayStatus.incomplete)
        : entry.locked
        ? scheme.outline
        : scheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.s),
      child: SoftCard(
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: () {
            Haptics.selection();
            showEntryDetails(context, entry, rules);
          },
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 5, color: accent),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(Gap.m, 14, Gap.m, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.project.name,
                          style: theme.textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${entry.project.number} · ${entry.activity}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: Gap.s),
                        Wrap(
                          spacing: 2,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 15,
                              color: scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${timeOf(entry.time.start)} – ${timeOf(entry.time.end)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontFeatures: _tabular,
                              ),
                            ),
                            if (entry.time.breakMinutes > 0) ...[
                              const SizedBox(width: Gap.s + 2),
                              Icon(
                                Icons.free_breakfast_outlined,
                                size: 15,
                                color: scheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${entry.time.breakMinutes}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (pill != null) ...[
                          const SizedBox(height: Gap.s),
                          pill,
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: Gap.m),
                  child: Center(
                    child: Text(
                      hm(totals.working),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontFeatures: _tabular,
                        color: entry.counts ? null : scheme.onSurfaceVariant,
                        decoration: entry.counts
                            ? null
                            : TextDecoration.lineThrough,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SoftCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: Gap.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                if (body.isNotEmpty)
                  Text(
                    body,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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

class _OvertimeCard extends StatelessWidget {
  const _OvertimeCard({required this.overtime});

  final OvertimeSummary overtime;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(Gap.l),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.card),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navy, AppColors.brand],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.overtimeTitle,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${overtime.minutes >= 0 ? '+' : ''}${hm(overtime.minutes)} ${l.hoursUnit}',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontFeatures: _tabular,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${l.asOf}: ${dateShort(context, overtime.asOf)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.trending_up_rounded,
            color: AppColors.mint,
            size: 36,
          ),
        ],
      ),
    );
  }
}

// --- Week --------------------------------------------------------------

int isoWeek(DateTime d) {
  final thursday = GermanTime.addDays(d, 4 - d.weekday);
  final jan1 = DateTime.utc(thursday.year);
  return thursday.difference(jan1).inDays ~/ 7 + 1;
}

class _WeekView extends StatelessWidget {
  const _WeekView({
    required this.data,
    required this.day,
    required this.onSelect,
    super.key,
  });

  final OverviewData data;
  final DateTime day;
  final void Function(DateTime, {int? view}) onSelect;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final monday = GermanTime.addDays(day, -(day.weekday - 1));
    final days = [for (var i = 0; i < 7; i++) GermanTime.addDays(monday, i)];
    final worked = days.map(data.workedOn).toList();
    final expected = days.map(data.expectedOn).toList();
    final totalWorked = worked.fold(0, (a, b) => a + b);
    final totalExpected = expected.fold(0, (a, b) => a + b);
    final fmt = DateFormat('d. MMM', localeTag(context));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _Arrow(
                    icon: Icons.chevron_left_rounded,
                    onTap: () => onSelect(GermanTime.addDays(day, -7)),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '${l.weekShort} ${isoWeek(monday)}',
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          '${fmt.format(days.first)} – ${fmt.format(days.last)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _Arrow(
                    icon: Icons.chevron_right_rounded,
                    onTap: () => onSelect(GermanTime.addDays(day, 7)),
                  ),
                ],
              ),
              const SizedBox(height: Gap.m),
              Wrap(
                spacing: Gap.s,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  Text(
                    hm(totalWorked),
                    key: const Key('weekTotal'),
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontSize: 34,
                      fontFeatures: _tabular,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '${l.ofTarget} ${hm(totalExpected)} ${l.hoursUnit}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Gap.m),
              _WeekChart(
                days: days,
                worked: worked,
                expected: expected,
                selected: days.indexOf(day),
                onTap: (i) => onSelect(days[i]),
              ),
              const SizedBox(height: Gap.s),
              Row(
                children: [
                  _LegendBar(color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(l.worked, style: theme.textTheme.bodySmall),
                  const SizedBox(width: Gap.l),
                  _LegendTarget(color: theme.colorScheme.onSurface),
                  const SizedBox(width: 6),
                  Text(l.target, style: theme.textTheme.bodySmall),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: Gap.m),
        SoftCard(
          padding: const EdgeInsets.symmetric(vertical: Gap.xs),
          child: Column(
            children: [
              for (var i = 0; i < 7; i++)
                ListTile(
                  dense: true,
                  onTap: () => onSelect(days[i], view: 0),
                  title: Text(
                    DateFormat.MMMMEEEEd(localeTag(context)).format(days[i]),
                  ),
                  subtitle: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: StatusPill(
                        label: statusLabel(context, data.statusOf(days[i])),
                        color: statusColor(context, data.statusOf(days[i])),
                        icon: statusIcon(data.statusOf(days[i])),
                      ),
                    ),
                  ),
                  trailing: Text(
                    '${hm(worked[i])} / ${hm(expected[i])}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFeatures: _tabular,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendBar extends StatelessWidget {
  const _LegendBar({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(2),
    ),
  );
}

class _LegendTarget extends StatelessWidget {
  const _LegendTarget({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) =>
      Container(width: 14, height: 2, color: color.withValues(alpha: 0.6));
}

/// One bar per day (worked), a thin marker for the target. Tap a bar to
/// select the day; only the selected bar carries its value label.
class _WeekChart extends StatelessWidget {
  const _WeekChart({
    required this.days,
    required this.worked,
    required this.expected,
    required this.selected,
    required this.onTap,
  });

  final List<DateTime> days;
  final List<int> worked;
  final List<int> expected;
  final int selected;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat.E(localeTag(context));
    return Semantics(
      label: [
        for (var i = 0; i < 7; i++)
          '${fmt.format(days[i])} ${hm(worked[i])} / ${hm(expected[i])}',
      ].join(', '),
      child: LayoutBuilder(
        builder: (context, box) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) => onTap(
            (d.localPosition.dx / (box.maxWidth / 7)).floor().clamp(0, 6),
          ),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, grow, _) => CustomPaint(
              size: Size(box.maxWidth, 190),
              painter: _WeekChartPainter(
                worked: worked,
                expected: expected,
                labels: [
                  for (final d in days) fmt.format(d).replaceAll('.', ''),
                ],
                selected: selected,
                grow: grow,
                bar: theme.colorScheme.primary,
                target: theme.colorScheme.onSurface,
                grid: theme.colorScheme.outlineVariant,
                text: theme.colorScheme.onSurfaceVariant,
                strong: theme.colorScheme.onSurface,
                fontFamily: theme.textTheme.bodySmall?.fontFamily,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WeekChartPainter extends CustomPainter {
  _WeekChartPainter({
    required this.worked,
    required this.expected,
    required this.labels,
    required this.selected,
    required this.grow,
    required this.bar,
    required this.target,
    required this.grid,
    required this.text,
    required this.strong,
    required this.fontFamily,
  });

  final List<int> worked;
  final List<int> expected;
  final List<String> labels;
  final int selected;
  final double grow;
  final Color bar;
  final Color target;
  final Color grid;
  final Color text;
  final Color strong;
  final String? fontFamily;

  void _text(
    Canvas c,
    String s,
    Offset at,
    Color color,
    double size, {
    FontWeight weight = FontWeight.w500,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: weight,
          fontFamily: fontFamily,
          fontFeatures: _tabular,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, at - Offset(tp.width / 2, 0));
  }

  @override
  void paint(Canvas canvas, Size size) {
    const labelH = 22.0;
    const topPad = 20.0;
    final chartH = size.height - labelH - topPad;
    final maxV = math
        .max(600, [...worked, ...expected].reduce(math.max))
        .toDouble();
    double y(num v) => topPad + chartH - chartH * v / maxV;
    final slot = size.width / 7;
    final barW = math.min(26.0, slot * 0.46);

    // Recessive grid: baseline and the 8 h line.
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    canvas
      ..drawLine(Offset(0, y(0)), Offset(size.width, y(0)), gridPaint)
      ..drawLine(Offset(0, y(480)), Offset(size.width, y(480)), gridPaint);

    for (var i = 0; i < 7; i++) {
      final cx = slot * i + slot / 2;
      final v = worked[i] * grow;
      final isSel = i == selected;
      if (v > 0) {
        final rect = RRect.fromRectAndCorners(
          Rect.fromLTRB(cx - barW / 2, y(v), cx + barW / 2, y(0)),
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
        );
        canvas.drawRRect(
          rect,
          Paint()..color = isSel ? bar : bar.withValues(alpha: 0.45),
        );
      }
      if (expected[i] > 0) {
        final ty = y(expected[i]);
        canvas.drawLine(
          Offset(cx - barW / 2 - 4, ty),
          Offset(cx + barW / 2 + 4, ty),
          Paint()
            ..color = target.withValues(alpha: 0.6)
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round,
        );
      }
      if (isSel && worked[i] > 0) {
        _text(
          canvas,
          hm(worked[i]),
          Offset(cx, y(v) - 18),
          strong,
          12,
          weight: FontWeight.w700,
        );
      }
      _text(
        canvas,
        labels[i],
        Offset(cx, size.height - labelH + 6),
        isSel ? strong : text,
        11,
        weight: isSel ? FontWeight.w700 : FontWeight.w500,
      );
    }
  }

  @override
  bool shouldRepaint(_WeekChartPainter old) =>
      old.grow != grow || old.selected != selected || old.worked != worked;
}

// --- Month -------------------------------------------------------------

class _MonthView extends StatelessWidget {
  const _MonthView({
    required this.data,
    required this.day,
    required this.onSelect,
    super.key,
  });

  final OverviewData data;
  final DateTime day;
  final void Function(DateTime, {int? view}) onSelect;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final first = DateTime.utc(day.year, day.month);
    final daysInMonth = DateTime.utc(day.year, day.month + 1, 0).day;
    final lead = first.weekday - 1;
    final cells = lead + daysInMonth;
    final rows = (cells / 7).ceil();
    final monthDays = [
      for (var i = 1; i <= daysInMonth; i++)
        DateTime.utc(day.year, day.month, i),
    ];
    final worked = monthDays.fold(0, (s, d) => s + data.workedOn(d));
    final expected = monthDays
        .where((d) => !d.isAfter(data.today))
        .fold(0, (s, d) => s + data.expectedOn(d));
    final weekdayFmt = DateFormat.E(localeTag(context));
    final legend = [
      DayStatus.complete,
      DayStatus.incomplete,
      DayStatus.missing,
      DayStatus.absent,
      DayStatus.holiday,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SoftCard(
          child: Column(
            children: [
              Row(
                children: [
                  _Arrow(
                    icon: Icons.chevron_left_rounded,
                    onTap: () =>
                        onSelect(DateTime.utc(day.year, day.month - 1)),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          DateFormat.yMMMM(localeTag(context)).format(first),
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          '${hm(worked)} ${l.ofTarget} ${hm(expected)} ${l.hoursUnit}',
                          key: const Key('monthTotal'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontFeatures: _tabular,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _Arrow(
                    icon: Icons.chevron_right_rounded,
                    onTap: () =>
                        onSelect(DateTime.utc(day.year, day.month + 1)),
                  ),
                ],
              ),
              const SizedBox(height: Gap.m),
              Row(
                children: [
                  for (var i = 0; i < 7; i++)
                    Expanded(
                      child: Center(
                        child: Text(
                          weekdayFmt
                              .format(DateTime.utc(2026, 11, 23 + i))
                              .replaceAll('.', ''),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: Gap.xs),
              for (var r = 0; r < rows; r++)
                Row(
                  children: [
                    for (var c = 0; c < 7; c++)
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            final n = r * 7 + c - lead + 1;
                            if (n < 1 || n > daysInMonth) {
                              return const SizedBox(height: 48);
                            }
                            final d = DateTime.utc(day.year, day.month, n);
                            final status = data.statusOf(d);
                            final isSel = d == day;
                            final isToday = d == data.today;
                            final showDot =
                                status != DayStatus.future &&
                                status != DayStatus.weekend;
                            return Semantics(
                              button: true,
                              label:
                                  '${DateFormat.MMMMEEEEd(localeTag(context)).format(d)}, ${statusLabel(context, status)}',
                              excludeSemantics: true,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => onSelect(d, view: 0),
                                child: Container(
                                  height: 48,
                                  margin: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: isSel
                                        ? scheme.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(14),
                                    border: isToday && !isSel
                                        ? Border.all(color: scheme.primary)
                                        : null,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '$n',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              fontFeatures: _tabular,
                                              fontWeight: FontWeight.w600,
                                              color: isSel
                                                  ? scheme.onPrimary
                                                  : status == DayStatus.weekend
                                                  ? scheme.onSurfaceVariant
                                                  : scheme.onSurface,
                                            ),
                                      ),
                                      const SizedBox(height: 3),
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: !showDot
                                              ? Colors.transparent
                                              : isSel
                                              ? scheme.onPrimary
                                              : statusColor(context, status),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: Gap.m),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final s in legend)
              StatusPill(
                label: statusLabel(context, s),
                color: statusColor(context, s),
                icon: statusIcon(s),
              ),
          ],
        ),
      ],
    );
  }
}
