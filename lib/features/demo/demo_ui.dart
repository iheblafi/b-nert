import 'dart:math' as math;

import 'package:intl/intl.dart' show DateFormat;
import 'package:material_ui/material_ui.dart';

import '../../core/design/app_theme.dart';
import '../../core/l10n/l10n.dart';
import 'demo_data.dart';

/// "7:30" for 450 minutes; negative with a minus sign.
String hm(int minutes) {
  final sign = minutes < 0 ? '-' : '';
  final m = minutes.abs();
  return '$sign${m ~/ 60}:${(m % 60).toString().padLeft(2, '0')}';
}

String localeTag(BuildContext context) =>
    Localizations.localeOf(context).toLanguageTag();

String dateShort(BuildContext context, DateTime d) =>
    DateFormat('dd.MM.yyyy', localeTag(context)).format(d);

String timeOf(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// Small pill so sample data is never mistaken for real data.
class DemoBadge extends StatelessWidget {
  const DemoBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      key: const Key('demoBadge'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.mint.withValues(alpha: dark ? 0.18 : 0.28),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        context.l10n.demoBadge,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: dark ? AppColors.mint : const Color(0xFF1B5E3A),
        ),
      ),
    );
  }
}

/// Coloured pill with an icon and a label: state is never colour alone.
class StatusPill extends StatelessWidget {
  const StatusPill({
    required this.label,
    required this.color,
    this.icon,
    super.key,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    // Light mode: text a shade darker than the tint, for 4.5:1 contrast.
    final ink = Theme.of(context).brightness == Brightness.light
        ? Color.lerp(color, Colors.black, 0.3)!
        : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: ink),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: ink, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// Status colours: reserved for state, readable in light and dark.
Color statusColor(BuildContext context, DayStatus s) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  final scheme = Theme.of(context).colorScheme;
  return switch (s) {
    DayStatus.complete => dark ? AppColors.mint : AppColors.success,
    DayStatus.incomplete => dark ? const Color(0xFFF2B65A) : AppColors.warning,
    DayStatus.missing => scheme.error,
    DayStatus.absent => scheme.primary,
    DayStatus.holiday =>
      dark ? const Color(0xFFC4A7F5) : const Color(0xFF6B4BB3),
    DayStatus.weekend || DayStatus.future => scheme.onSurfaceVariant,
  };
}

IconData statusIcon(DayStatus s) => switch (s) {
  DayStatus.complete => Icons.check_circle_rounded,
  DayStatus.incomplete => Icons.timelapse_rounded,
  DayStatus.missing => Icons.error_rounded,
  DayStatus.absent => Icons.beach_access_rounded,
  DayStatus.holiday => Icons.celebration_rounded,
  DayStatus.weekend => Icons.weekend_rounded,
  DayStatus.future => Icons.schedule_rounded,
};

String statusLabel(BuildContext context, DayStatus s) {
  final l = context.l10n;
  return switch (s) {
    DayStatus.complete => l.statusComplete,
    DayStatus.incomplete => l.statusIncomplete,
    DayStatus.missing => l.statusMissing,
    DayStatus.absent => l.statusAbsent,
    DayStatus.holiday => l.statusHoliday,
    DayStatus.weekend => l.statusWeekend,
    DayStatus.future => l.statusFuture,
  };
}

/// Entry state pill: lock state and late-entry state.
Widget? entryPill(BuildContext context, TimeRecord e) {
  final l = context.l10n;
  final scheme = Theme.of(context).colorScheme;
  if (e.delay == DelayStatus.pending) {
    return StatusPill(
      label: l.delayPending,
      color: statusColor(context, DayStatus.incomplete),
      icon: Icons.hourglass_top_rounded,
    );
  }
  if (e.delay == DelayStatus.rejected) {
    return StatusPill(
      label: l.delayRejected,
      color: scheme.error,
      icon: Icons.block_rounded,
    );
  }
  return switch (e.status) {
    EntryStatus.closed => StatusPill(
      label: l.entryClosed,
      color: scheme.onSurfaceVariant,
      icon: Icons.lock_rounded,
    ),
    EntryStatus.invoiced => StatusPill(
      label: l.entryInvoiced,
      color: scheme.onSurfaceVariant,
      icon: Icons.receipt_long_rounded,
    ),
    EntryStatus.open => null,
  };
}

String workPlaceLabel(BuildContext context, WorkPlace w) {
  final l = context.l10n;
  return switch (w) {
    WorkPlace.office => l.workPlaceOffice,
    WorkPlace.home => l.workPlaceHome,
    WorkPlace.away => l.workPlaceAway,
  };
}

String absenceTypeLabel(BuildContext context, AbsenceType? t) {
  final l = context.l10n;
  return switch (t) {
    AbsenceType.vacation => l.absVacation,
    AbsenceType.sick => l.absSick,
    AbsenceType.overtime => l.absOvertime,
    AbsenceType.training => l.absTraining,
    AbsenceType.special => l.absSpecial,
    null => l.absAway,
  };
}

IconData absenceIcon(AbsenceType? t) => switch (t) {
  AbsenceType.vacation => Icons.beach_access_rounded,
  AbsenceType.sick => Icons.medical_services_rounded,
  AbsenceType.overtime => Icons.more_time_rounded,
  AbsenceType.training => Icons.school_rounded,
  AbsenceType.special => Icons.star_rounded,
  null => Icons.event_busy_rounded,
};

/// A ring that fills with progress; the centre shows the figure.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    required this.value,
    required this.color,
    required this.child,
    this.size = 112,
    super.key,
  });

  /// 0..1 (capped).
  final double value;
  final Color color;
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0, 1)),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => CustomPaint(
        painter: _RingPainter(
          value: v,
          color: color,
          track: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: Center(child: child),
      ),
    ),
  );
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.value, required this.color, required this.track});

  final double value;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 10.0;
    final rect = Offset.zero & size;
    final r = rect.deflate(stroke / 2);
    canvas.drawArc(
      r,
      0,
      2 * math.pi,
      false,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    if (value > 0) {
      canvas.drawArc(
        r,
        -math.pi / 2,
        2 * math.pi * value,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color || old.track != track;
}
