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
import '../demo/entry_details_sheet.dart';

enum _Filter { all, open, closed, invoiced, notCounted }

/// "Protokoll" (F5): all own entries, newest first, with status filters
/// and the total for the filter. Sample data until b14 is connected.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  _Filter _filter = _Filter.all;

  bool _matches(TimeRecord e) => switch (_filter) {
    _Filter.all => true,
    _Filter.open => e.status == EntryStatus.open && e.counts,
    _Filter.closed => e.status == EntryStatus.closed,
    _Filter.invoiced => e.status == EntryStatus.invoiced,
    _Filter.notCounted => !e.counts,
  };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final data = ref.watch(demoDataProvider);
    if (data == null) {
      return MainPage(
        title: l.navHistory,
        body: EmptyState(
          icon: Icons.history_rounded,
          title: l.historyEmptyTitle,
          body: l.historyEmptyBody,
        ),
      );
    }
    final theme = Theme.of(context);
    final entries = data.entries.where(_matches).toList()
      ..sort((a, b) => b.time.start.compareTo(a.time.start));
    final total = entries
        .where((e) => e.counts)
        .fold(0, (s, e) => s + e.totals(DemoData.demoRules).working);
    final labels = {
      _Filter.all: l.historyAll,
      _Filter.open: l.entryOpen,
      _Filter.closed: l.entryClosed,
      _Filter.invoiced: l.entryInvoiced,
      _Filter.notCounted: l.delayRejected,
    };
    final monthFmt = DateFormat.yMMMM(localeTag(context));
    final items = <Widget>[];
    String? month;
    for (final e in entries) {
      final m = monthFmt.format(e.time.start);
      if (m != month) {
        month = m;
        items.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.s, Gap.m, Gap.s, Gap.s),
            child: Text(
              m.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      }
      items.add(_HistoryRow(entry: e));
    }
    return MainPage(
      title: l.navHistory,
      demo: true,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Gap.m),
              child: Row(
                children: [
                  for (final f in _Filter.values)
                    Padding(
                      padding: const EdgeInsets.only(right: Gap.s),
                      child: ChoiceChip(
                        key: Key('filter-${f.name}'),
                        label: Text(labels[f]!),
                        selected: _filter == f,
                        showCheckmark: false,
                        onSelected: (_) {
                          Haptics.selection();
                          setState(() => _filter = f);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Gap.m, Gap.m, Gap.m, 0),
              child: SoftCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${entries.length} ${l.entriesCount}',
                            key: const Key('historyCount'),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            '${hm(total)} ${l.hoursUnit}',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.summarize_rounded,
                      size: 32,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(Gap.m, 0, Gap.m, 120),
            sliver: items.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(Gap.xl),
                      child: Text(
                        l.noEntriesFilter,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : SliverList.list(children: items),
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry});

  final TimeRecord entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final pill = entryPill(context, entry);
    final working = entry.totals(DemoData.demoRules).working;
    final tag = localeTag(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.s),
      child: SoftCard(
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: () {
            Haptics.selection();
            showEntryDetails(context, entry, DemoData.demoRules);
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 50,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        DateFormat.E(tag)
                            .format(entry.time.start)
                            .replaceAll('.', ''),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.primary,
                        ),
                      ),
                      Text(
                        '${entry.time.start.day}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: scheme.primary,
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
                        entry.project.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${timeOf(entry.time.start)} – ${timeOf(entry.time.end)} · ${entry.activity}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (pill != null) ...[const SizedBox(height: 6), pill],
                    ],
                  ),
                ),
                const SizedBox(width: Gap.s),
                Text(
                  hm(working),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: entry.counts ? null : scheme.onSurfaceVariant,
                    decoration: entry.counts
                        ? null
                        : TextDecoration.lineThrough,
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
