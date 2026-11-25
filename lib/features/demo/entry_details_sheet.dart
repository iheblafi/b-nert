import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:material_ui/material_ui.dart';

import '../../core/design/app_theme.dart';
import '../../core/l10n/l10n.dart';
import '../times/domain/time_rules.dart';
import 'demo_data.dart';
import 'demo_ui.dart';

/// All fields of one entry, as a bottom sheet (spec F5 detail).
Future<void> showEntryDetails(
  BuildContext context,
  TimeRecord e,
  TimeRules rules,
) {
  final l = context.l10n;
  final totals = e.totals(rules);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.sheet)),
    ),
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final pill = entryPill(ctx, e);
      Widget row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 130,
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(child: Text(value, style: theme.textTheme.bodyLarge)),
          ],
        ),
      );
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(Gap.l, 0, Gap.l, Gap.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(e.project.name, style: theme.textTheme.titleLarge),
              const SizedBox(height: 2),
              Text(
                e.project.number,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (pill != null) ...[const SizedBox(height: Gap.s), pill],
              const SizedBox(height: Gap.m),
              const Divider(),
              row(
                l.fieldDate,
                DateFormat.yMMMMEEEEd(localeTag(ctx)).format(e.time.start),
              ),
              row(l.fieldStart, timeOf(e.time.start)),
              row(l.fieldEnd, timeOf(e.time.end)),
              row(l.breakLabel, '${e.time.breakMinutes} ${l.minutesUnit}'),
              row(l.fieldWorking, '${hm(totals.working)} ${l.hoursUnit}'),
              if (totals.night > 0)
                row(l.nightLabel, '${hm(totals.night)} ${l.hoursUnit}'),
              if (totals.sunday > 0)
                row(l.fieldSunday, '${hm(totals.sunday)} ${l.hoursUnit}'),
              if (totals.holiday > 0)
                row(l.fieldHoliday, '${hm(totals.holiday)} ${l.hoursUnit}'),
              if (e.activity.isNotEmpty) row(l.fieldActivity, e.activity),
              if (e.subproject case final s?) row(l.fieldSubproject, s),
              if (e.workPlace case final w?)
                row(l.fieldWorkPlace, workPlaceLabel(ctx, w)),
              if (e.holidayState case final s?) row(l.fieldHolidayState, s),
              if (e.location case final s?) row(l.fieldLocation, s),
              row(l.fieldCreatedIn, e.createdInApp ? 'App' : 'Web'),
              if (e.remarks != null) row(l.fieldRemarks, e.remarks!),
              const SizedBox(height: Gap.l),
              FilledButton.icon(
                onPressed: e.locked
                    ? null
                    : () {
                        Navigator.pop(ctx);
                        context.push('/entry/edit', extra: e);
                      },
                icon: Icon(e.locked ? Icons.lock_rounded : Icons.edit_rounded),
                label: Text(e.locked ? l.entryClosed : l.edit),
              ),
            ],
          ),
        ),
      );
    },
  );
}
