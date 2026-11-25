import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:material_ui/material_ui.dart';

import '../../../core/design/app_theme.dart';
import '../../../core/design/motion.dart';
import '../../../core/design/state_views.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/l10n/l10n.dart';
import '../../auth/state/session.dart';
import '../../demo/demo_mode.dart';
import '../../demo/demo_ui.dart';
import '../../times/domain/german_holidays.dart';
import '../../times/domain/german_time.dart';
import '../../times/domain/time_rules.dart';
import '../../times/model/overview_data.dart';
import '../../times/model/records.dart';
import '../../times/state/overview_provider.dart';
import '../../user_context/model/company_settings.dart';
import '../data/entry_options_repository.dart';
import '../model/entry_draft.dart';

const _tabular = [FontFeature.tabularFigures()];

/// Saving waits for the client (task c3, R-BE-1). Until then the form
/// checks everything and says that nothing was sent.
const savingEnabled = false;

const stateNames = {
  'BW': 'Baden-Württemberg',
  'BY': 'Bayern',
  'BE': 'Berlin',
  'BB': 'Brandenburg',
  'HB': 'Bremen',
  'HH': 'Hamburg',
  'HE': 'Hessen',
  'MV': 'Mecklenburg-Vorpommern',
  'NI': 'Niedersachsen',
  'NW': 'Nordrhein-Westfalen',
  'RP': 'Rheinland-Pfalz',
  'SL': 'Saarland',
  'SN': 'Sachsen',
  'ST': 'Sachsen-Anhalt',
  'SH': 'Schleswig-Holstein',
  'TH': 'Thüringen',
};

/// "Neuer Eintrag" / "Eintrag bearbeiten" (F3). [day] preselects the date
/// for a new entry; [entry] is the entry to edit.
class EntryFormScreen extends ConsumerStatefulWidget {
  const EntryFormScreen({this.day, this.entry, super.key});

  final DateTime? day;
  final TimeRecord? entry;

  @override
  ConsumerState<EntryFormScreen> createState() => _EntryFormScreenState();
}

class _EntryFormScreenState extends ConsumerState<EntryFormScreen> {
  EntryDraft? _draft;
  bool _matched = false;
  bool _showErrors = false;
  final _location = TextEditingController();
  final _remarks = TextEditingController();

  @override
  void dispose() {
    _location.dispose();
    _remarks.dispose();
    super.dispose();
  }

  EntryDraft _initial(CompanySettings s, DateTime today) {
    final e = widget.entry;
    if (e != null) {
      _location.text = e.location ?? '';
      _remarks.text = e.remarks ?? '';
      final stored = e.stored;
      return EntryDraft(
        id: e.id,
        projectId: e.project.id,
        day: e.day,
        start: (hour: e.time.start.hour, minute: e.time.start.minute),
        end: (hour: e.time.end.hour, minute: e.time.end.minute),
        breakMinutes: e.time.breakMinutes,
        night: stored?.night,
        sunday: stored?.sunday,
        holiday: stored?.holiday,
        workPlace: e.workPlace,
        holidayState: e.holidayState,
        location: e.location ?? '',
        remarks: e.remarks ?? '',
      );
    }
    return EntryDraft(
      day: GermanTime.startOfDay(widget.day ?? today),
      start: s.defaultStartTime,
      end: s.defaultEndTime,
    );
  }

  /// Ids for project, sub-project and activity of an edited entry: the
  /// entry carries names, the pickers ids.
  void _matchOptions(EntryOptions o) {
    final e = widget.entry;
    if (_matched || e == null || _draft == null) return;
    _matched = true;
    var d = _draft!;
    if (d.projectId == null) {
      final p = o.projects.where((p) => p.number == e.project.number).first;
      d = d.copyWith(projectId: p.id);
    }
    final sub = o
        .subprojectsOf(d.projectId)
        .where((s) => s.name == e.subproject)
        .firstOrNull;
    final act = o.activities.where((a) => a.name == e.activity).firstOrNull;
    _draft = d.copyWith(subprojectId: () => sub?.id, activityId: () => act?.id);
  }

  void _update(EntryDraft d) {
    Haptics.selection();
    setState(() => _draft = d);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final session = ref.watch(sessionProvider);
    final settings = session is SignedIn
        ? session.context.settings
        : const CompanySettings();
    final demo = ref.watch(demoDataProvider);
    final DateTime today = demo?.today ?? ref.watch(germanTodayProvider);
    final draft = _draft ??= _initial(settings, today);
    final OverviewData? overview =
        demo ??
        (session is SignedIn
            ? ref.watch(overviewProvider(monthKey(draft.day))).value
            : null);
    final options = ref.watch(entryOptionsProvider);
    final locked = widget.entry?.locked ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry == null ? l.newEntry : l.entryEditTitle),
      ),
      body: switch (options) {
        AsyncValue(:final value?) => Builder(
          builder: (context) {
            _matchOptions(value);
            return _Form(
              draft: _draft!,
              options: value,
              settings: settings,
              check: checkDraft(
                _draft!,
                settings: settings,
                now: demo != null
                    ? GermanTime.wall(ref.watch(demoNowProvider)())
                    : GermanTime.fromInstant(DateTime.now()),
                overview: overview,
                locked: locked,
              ),
              locked: locked,
              showErrors: _showErrors,
              location: _location,
              remarks: _remarks,
              onChanged: _update,
              onSave: _save,
            );
          },
        ),
        AsyncValue(:final error?) => ErrorView(
          failure: AppFailure.from(error),
          onRetry: () => ref.invalidate(entryOptionsProvider),
        ),
        _ => const LoadingView(),
      },
    );
  }

  Future<void> _save(EntryCheck check) async {
    final l = context.l10n;
    if (!check.canSave) {
      Haptics.error();
      setState(() => _showErrors = true);
      return;
    }
    // savingEnabled is false until c3 is answered: nothing is sent.
    Haptics.success();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('notSavedDialog'),
        icon: const Icon(Icons.cloud_off_rounded),
        title: Text(l.entryCompleteTitle),
        content: Text(l.entryNotSent),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(ctx), child: Text(l.ok)),
        ],
      ),
    );
  }
}

class _Form extends StatelessWidget {
  const _Form({
    required this.draft,
    required this.options,
    required this.settings,
    required this.check,
    required this.locked,
    required this.showErrors,
    required this.location,
    required this.remarks,
    required this.onChanged,
    required this.onSave,
  });

  final EntryDraft draft;
  final EntryOptions options;
  final CompanySettings settings;
  final EntryCheck check;
  final bool locked;
  final bool showErrors;
  final TextEditingController location;
  final TextEditingController remarks;
  final ValueChanged<EntryDraft> onChanged;
  final Future<void> Function(EntryCheck) onSave;

  String? _error(BuildContext context, EntryField f) {
    final e = check.errors[f];
    if (e == null) return null;
    // Wrong times, overlaps and locks are shown at once; a missing project
    // only after the first save attempt.
    if (!showErrors && f == EntryField.project) return null;
    return errorText(context, e);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final subs = options.subprojectsOf(draft.projectId);
    final project = options.projects
        .where((p) => p.id == draft.projectId)
        .firstOrNull;
    final details = <Widget>[
      if (settings.workPlaceMode != WorkPlaceMode.off) ...[
        _Label(l.fieldWorkPlace),
        SegmentedButton<WorkPlace?>(
          key: const Key('workPlace'),
          showSelectedIcon: false,
          emptySelectionAllowed: true,
          segments: [
            for (final w in WorkPlace.values)
              ButtonSegment(value: w, label: Text(workPlaceLabel(context, w))),
          ],
          selected: {if (draft.workPlace != null) draft.workPlace},
          onSelectionChanged: locked
              ? null
              : (s) => onChanged(
                  draft.copyWith(workPlace: () => s.isEmpty ? null : s.first),
                ),
        ),
        const SizedBox(height: Gap.m),
      ],
      if (settings.showHolidayState) ...[
        DropdownButtonFormField<String?>(
          key: const Key('holidayState'),
          initialValue: draft.holidayState,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l.fieldHolidayState,
            helperText: l.holidayStateHint,
            helperMaxLines: 3,
          ),
          items: [
            DropdownMenuItem(value: null, child: Text(l.ownLocation)),
            for (final s in federalStates)
              DropdownMenuItem(value: s, child: Text(stateNames[s]!)),
          ],
          onChanged: locked
              ? null
              : (v) => onChanged(draft.copyWith(holidayState: () => v)),
        ),
        const SizedBox(height: Gap.m),
      ],
      TextField(
        key: const Key('location'),
        controller: location,
        enabled: !locked,
        decoration: InputDecoration(labelText: l.fieldLocation),
        textInputAction: TextInputAction.next,
        onChanged: (v) => onChanged(draft.copyWith(location: v)),
      ),
      const SizedBox(height: Gap.m),
      TextField(
        key: const Key('remarks'),
        controller: remarks,
        enabled: !locked,
        minLines: 2,
        maxLines: 5,
        decoration: InputDecoration(labelText: l.fieldRemarks),
        onChanged: (v) => onChanged(draft.copyWith(remarks: v)),
      ),
    ];

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(Gap.m, Gap.s, Gap.m, Gap.xl),
              children: [
                _Banner(
                  key: const Key('savingOff'),
                  icon: locked
                      ? Icons.lock_rounded
                      : Icons.info_outline_rounded,
                  text: locked
                      ? l.errLocked
                      : savingEnabled
                      ? ''
                      : l.entrySavingOff,
                ),
                const SizedBox(height: Gap.m),
                _PickerField(
                  key: const Key('project'),
                  label: l.fieldProject,
                  value: project?.label,
                  placeholder: l.chooseProject,
                  error: _error(context, EntryField.project),
                  icon: Icons.work_outline_rounded,
                  onTap: locked
                      ? null
                      : () async {
                          final id = await _pickProject(
                            context,
                            options.projects,
                          );
                          if (id != null && id != draft.projectId) {
                            onChanged(
                              draft.copyWith(
                                projectId: id,
                                subprojectId: () => null,
                              ),
                            );
                          }
                        },
                ),
                if (settings.showSubproject && subs.isNotEmpty) ...[
                  const SizedBox(height: Gap.m),
                  DropdownButtonFormField<String?>(
                    key: const Key('subproject'),
                    initialValue: draft.subprojectId,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: l.fieldSubproject),
                    items: [
                      DropdownMenuItem(value: null, child: Text(l.noneOption)),
                      for (final s in subs)
                        DropdownMenuItem(value: s.id, child: Text(s.name)),
                    ],
                    onChanged: locked
                        ? null
                        : (v) =>
                              onChanged(draft.copyWith(subprojectId: () => v)),
                  ),
                ],
                if (settings.showActivity && options.activities.isNotEmpty) ...[
                  const SizedBox(height: Gap.m),
                  DropdownButtonFormField<String?>(
                    key: const Key('activity'),
                    initialValue: draft.activityId,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: l.fieldActivity),
                    items: [
                      DropdownMenuItem(value: null, child: Text(l.noneOption)),
                      for (final a in options.activities)
                        DropdownMenuItem(value: a.id, child: Text(a.name)),
                    ],
                    onChanged: locked
                        ? null
                        : (v) => onChanged(draft.copyWith(activityId: () => v)),
                  ),
                ],
                const SizedBox(height: Gap.m),
                _PickerField(
                  key: const Key('date'),
                  label: l.fieldDate,
                  value: DateFormat.yMMMMEEEEd(localeTag(context))
                      .format(draft.day),
                  error: _error(context, EntryField.date),
                  icon: Icons.calendar_today_rounded,
                  onTap: locked
                      ? null
                      : () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: draft.day,
                            firstDate: DateTime.utc(draft.day.year - 2),
                            lastDate: DateTime.utc(draft.day.year + 1, 12, 31),
                          );
                          if (d != null) {
                            onChanged(
                              draft.copyWith(
                                day: DateTime.utc(d.year, d.month, d.day),
                              ),
                            );
                          }
                        },
                ),
                const SizedBox(height: Gap.m),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _PickerField(
                        key: const Key('start'),
                        label: l.fieldStart,
                        value: _clock(draft.start),
                        icon: Icons.login_rounded,
                        onTap: locked
                            ? null
                            : () async {
                                final t = await _pickTime(context, draft.start);
                                if (t != null) {
                                  onChanged(draft.copyWith(start: t));
                                }
                              },
                      ),
                    ),
                    const SizedBox(width: Gap.m),
                    Expanded(
                      child: _PickerField(
                        key: const Key('end'),
                        label: draft.endsNextDay
                            ? '${l.fieldEnd} (${l.nextDay})'
                            : l.fieldEnd,
                        value: _clock(draft.end),
                        error: _error(context, EntryField.end),
                        icon: Icons.logout_rounded,
                        onTap: locked
                            ? null
                            : () async {
                                final t = await _pickTime(context, draft.end);
                                if (t != null) {
                                  onChanged(draft.copyWith(end: t));
                                }
                              },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Gap.m),
                _BreakField(
                  minutes: draft.breakMinutes,
                  suggested: check.suggestedBreak,
                  error: _error(context, EntryField.breakMinutes),
                  enabled: !locked,
                  onChanged: (m) => onChanged(draft.copyWith(breakMinutes: m)),
                ),
                const SizedBox(height: Gap.m),
                _Totals(
                  draft: draft,
                  check: check,
                  surcharges: settings.showSurchargeTimes,
                  enabled: !locked,
                  errorFor: (f) => _error(context, f),
                  onChanged: onChanged,
                ),
                if (check.warnings.isNotEmpty) ...[
                  const SizedBox(height: Gap.m),
                  _Warnings(warnings: check.warnings, settings: settings),
                ],
                if (!check.comparedWithOthers) ...[
                  const SizedBox(height: Gap.s),
                  Text(
                    l.notComparedNote,
                    key: const Key('notCompared'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (settings.furtherDetails != FurtherDetailsMode.hidden) ...[
                  const SizedBox(height: Gap.m),
                  if (settings.furtherDetails == FurtherDetailsMode.open) ...[
                    _Label(l.furtherDetails),
                    ...details,
                  ] else
                    Theme(
                      data: theme.copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        key: const Key('furtherDetails'),
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: const EdgeInsets.only(top: Gap.s),
                        title: Text(l.furtherDetails),
                        children: details,
                      ),
                    ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.m, Gap.s, Gap.m, Gap.m),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('saveEntry'),
                onPressed: locked ? null : () => onSave(check),
                icon: const Icon(Icons.check_rounded),
                label: Text(l.save),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String errorText(BuildContext context, EntryError e) {
  final l = context.l10n;
  return switch (e) {
    EntryError.noProject => l.errNoProject,
    EntryError.endNotAfterStart => l.errEndNotAfterStart,
    EntryError.longerThan24h => l.errLongerThan24h,
    EntryError.breakLongerThanEntry => l.errBreakTooLong,
    EntryError.surchargeAboveWorking => l.errSurchargeAboveWorking,
    EntryError.overlap => l.errOverlap,
    EntryError.absenceBlocks => l.errAbsenceBlocks,
    EntryError.locked => l.errLocked,
  };
}

String _clock(ClockTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

Future<ClockTime?> _pickTime(BuildContext context, ClockTime t) async {
  final picked = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(hour: t.hour, minute: t.minute),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
      child: child!,
    ),
  );
  return picked == null ? null : (hour: picked.hour, minute: picked.minute);
}

Future<String?> _pickProject(
  BuildContext context,
  List<ProjectOption> projects,
) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (ctx) => _ProjectSheet(projects: projects),
);

class _ProjectSheet extends StatefulWidget {
  const _ProjectSheet({required this.projects});

  final List<ProjectOption> projects;

  @override
  State<_ProjectSheet> createState() => _ProjectSheetState();
}

class _ProjectSheetState extends State<_ProjectSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final q = _query.toLowerCase();
    final shown = widget.projects
        .where((p) => q.isEmpty || p.label.toLowerCase().contains(q))
        .toList();
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (context, scroll) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.m, 0, Gap.m, Gap.s),
            child: TextField(
              key: const Key('projectSearch'),
              autofocus: widget.projects.length > 8,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: l.searchProjects,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: scroll,
              itemCount: shown.length,
              itemBuilder: (context, i) => ListTile(
                minTileHeight: 56,
                title: Text(shown[i].name),
                subtitle: shown[i].number.isEmpty
                    ? null
                    : Text(shown[i].number),
                onTap: () => Navigator.pop(context, shown[i].id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Gap.s),
    child: Text(text, style: Theme.of(context).textTheme.titleSmall),
  );
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.text, super.key});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(Gap.m),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(Radii.card),
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.onSecondaryContainer),
          const SizedBox(width: Gap.m),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSecondaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

/// A read-only field that opens a picker.
class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.placeholder,
    this.error,
    super.key,
  });

  final String label;
  final String? value;
  final String? placeholder;
  final String? error;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.field),
      child: InputDecorator(
        isEmpty: value == null,
        decoration: InputDecoration(
          labelText: label,
          hintText: placeholder,
          errorText: error,
          errorMaxLines: 3,
          enabled: onTap != null,
          suffixIcon: Icon(icon),
        ),
        child: value == null
            ? null
            : Text(
                value!,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontFeatures: _tabular,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
      ),
    );
  }
}

class _BreakField extends StatelessWidget {
  const _BreakField({
    required this.minutes,
    required this.suggested,
    required this.error,
    required this.enabled,
    required this.onChanged,
  });

  final int minutes;
  final int suggested;
  final String? error;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    return InputDecorator(
      decoration: InputDecoration(
        labelText: l.breakLabel,
        errorText: error,
        errorMaxLines: 3,
        enabled: enabled,
        contentPadding: const EdgeInsets.fromLTRB(Gap.m, Gap.s, Gap.s, Gap.s),
      ),
      child: Row(
        children: [
          IconButton.filledTonal(
            key: const Key('breakMinus'),
            tooltip: '− 5 ${l.minutesUnit}',
            onPressed: enabled && minutes >= 5
                ? () => onChanged(minutes - 5)
                : null,
            icon: const Icon(Icons.remove_rounded),
          ),
          Expanded(
            child: Text(
              '$minutes ${l.minutesUnit}',
              key: const Key('breakValue'),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontFeatures: _tabular,
              ),
            ),
          ),
          IconButton.filledTonal(
            key: const Key('breakPlus'),
            tooltip: '+ 5 ${l.minutesUnit}',
            onPressed: enabled ? () => onChanged(minutes + 5) : null,
            icon: const Icon(Icons.add_rounded),
          ),
          if (suggested > 0 && suggested != minutes) ...[
            const SizedBox(width: Gap.s),
            ActionChip(
              key: const Key('suggestedBreak'),
              label: Text('$suggested ${l.minutesUnit}'),
              avatar: const Icon(Icons.auto_awesome_rounded, size: 18),
              tooltip: l.suggestedBreak,
              onPressed: enabled ? () => onChanged(suggested) : null,
            ),
          ],
        ],
      ),
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({
    required this.draft,
    required this.check,
    required this.surcharges,
    required this.enabled,
    required this.errorFor,
    required this.onChanged,
  });

  final EntryDraft draft;
  final EntryCheck check;
  final bool surcharges;
  final bool enabled;
  final String? Function(EntryField) errorFor;
  final ValueChanged<EntryDraft> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final t = check.totals;
    Widget stat(String label, int minutes, {Key? key}) => Expanded(
      child: Column(
        key: key,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            hm(minutes),
            style: theme.textTheme.titleLarge?.copyWith(fontFeatures: _tabular),
          ),
        ],
      ),
    );

    Widget surcharge(
      EntryField field,
      String label,
      int value,
      int? typed,
      EntryDraft Function(int? Function()) set,
    ) {
      final error = errorFor(field);
      return ListTile(
        key: Key('surcharge-${field.name}'),
        contentPadding: EdgeInsets.zero,
        minTileHeight: 48,
        enabled: enabled,
        title: Text(label),
        subtitle: Text(
          error ?? (typed == null ? l.calculated : l.typedByHand),
          style: error == null
              ? null
              : TextStyle(color: theme.colorScheme.error),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              hm(value),
              style: theme.textTheme.titleMedium?.copyWith(
                fontFeatures: _tabular,
              ),
            ),
            if (typed != null)
              IconButton(
                tooltip: l.calculated,
                onPressed: enabled ? () => onChanged(set(() => null)) : null,
                icon: const Icon(Icons.restart_alt_rounded),
              ),
          ],
        ),
        onTap: enabled
            ? () async {
                final m = await _askMinutes(context, label, value);
                if (m != null) onChanged(set(() => m));
              }
            : null,
      );
    }

    return SoftCard(
      key: const Key('entryTotals'),
      child: Column(
        children: [
          Row(
            children: [
              stat(l.fieldWorking, t.working, key: const Key('totalWorking')),
              stat(l.totalLabel, t.total),
            ],
          ),
          if (surcharges) ...[
            const SizedBox(height: Gap.s),
            const Divider(),
            surcharge(
              EntryField.night,
              l.nightLabel,
              t.night,
              draft.night,
              (v) => draft.copyWith(night: v),
            ),
            surcharge(
              EntryField.sunday,
              l.fieldSunday,
              t.sunday,
              draft.sunday,
              (v) => draft.copyWith(sunday: v),
            ),
            surcharge(
              EntryField.holiday,
              l.fieldHoliday,
              t.holiday,
              draft.holiday,
              (v) => draft.copyWith(holiday: v),
            ),
          ],
        ],
      ),
    );
  }
}

Future<int?> _askMinutes(BuildContext context, String label, int value) {
  final l = context.l10n;
  final c = TextEditingController(text: '$value');
  return showDialog<int>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(label),
      content: TextField(
        key: const Key('minutesInput'),
        controller: c,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(suffixText: l.minutesUnit),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, int.tryParse(c.text.trim())),
          child: Text(l.ok),
        ),
      ],
    ),
  ).whenComplete(c.dispose);
}

class _Warnings extends StatelessWidget {
  const _Warnings({required this.warnings, required this.settings});

  final List<EntryWarning> warnings;
  final CompanySettings settings;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final color = statusColor(context, DayStatus.incomplete);
    String text(EntryWarning w) => switch (w) {
      BreakTooShort(:final required) => l.warnBreakTooShort(required),
      LongDay(:final limitHours) => l.warnLongDay(limitHours),
      RestTooShort(:final rest, :final required) => l.warnRestTooShort(
        hm(rest),
        hm(required),
      ),
      OnAbsenceDay(:final type) => l.warnAbsenceDay(
        absenceTypeLabel(context, type),
      ),
      NeedsApproval() => l.warnNeedsApproval(settings.maxDelayHours ?? 0),
    };
    return SoftCard(
      key: const Key('entryWarnings'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.warningsTitle, style: theme.textTheme.titleSmall),
          const SizedBox(height: Gap.s),
          for (final w in warnings)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, size: 20, color: color),
                  const SizedBox(width: Gap.s),
                  Expanded(
                    child: Text(text(w), style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
