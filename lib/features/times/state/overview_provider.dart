import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/backend/backend.dart';
import '../../app_lock/app_lock.dart';
import '../../auth/state/session.dart';
import '../data/overview_repository.dart';
import '../domain/german_time.dart';
import '../model/overview_data.dart';

final overviewRepositoryProvider = Provider<OverviewRepository>(
  (ref) => SupabaseOverviewRepository(ref.watch(supabaseClientProvider)),
);

/// Today in German time, whatever the phone's zone (F3 AC9).
final germanTodayProvider = Provider<DateTime>(
  (ref) =>
      GermanTime.startOfDay(GermanTime.fromInstant(ref.watch(clockProvider)())),
);

/// The month [month] belongs to, as the key of [overviewProvider].
DateTime monthKey(DateTime month) => DateTime.utc(month.year, month.month);

/// The signed-in user's overview for one month plus six days on each
/// side, so week views across the month edge are complete. Kept in memory
/// per month for the session; reloaded with ref.refresh.
final overviewProvider = FutureProvider.family<OverviewData, DateTime>((
  ref,
  month,
) async {
  final userId = ref.watch(
    sessionProvider.select((s) => s is SignedIn ? s.user.id : null),
  );
  final session = ref.read(sessionProvider);
  if (userId == null || session is! SignedIn) {
    throw StateError('Not signed in');
  }
  final first = monthKey(month);
  final last = DateTime.utc(first.year, first.month + 1, 0);
  return ref
      .watch(overviewRepositoryProvider)
      .load(
        userId: userId,
        from: GermanTime.addDays(first, -6),
        to: GermanTime.addDays(last, 6),
        today: ref.read(germanTodayProvider),
        settings: session.context.settings,
      );
});
