import 'package:flutter_mobile/features/user_context/model/company_settings.dart';
import 'package:flutter_mobile/features/user_context/model/user_context.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures.dart';

void main() {
  group('CompanySettings', () {
    test('parses a setting row', () {
      final s = CompanySettings.fromJson({
        'break_rule': 'attendance',
        'min_break_piece_minutes': 10,
        'show_overtime_card': true,
        'colleague_absence_visibility': 'category',
        'missing_time_entry_reminder_time': '09:00:00',
        'unknown_column': 'ignored',
      });
      expect(s.breakRule, BreakRule.attendance);
      expect(s.minBreakPieceMinutes, 10);
      expect(s.showOvertimeCard, isTrue);
      expect(s.colleagueAbsenceVisibility, ColleagueAbsenceVisibility.category);
      expect(s.missingEntryReminderTime, '09:00:00');
    });

    test('falls back to defaults for missing values', () {
      final s = CompanySettings.fromJson({});
      expect(s.breakRule, BreakRule.statutory);
      expect(s.minBreakPieceMinutes, 15);
      expect(s.colleagueAbsenceVisibility, ColleagueAbsenceVisibility.none);
    });
  });

  group('UserAccess (spec section 3)', () {
    test('plain user sees no approvals', () {
      final a = userContext().access;
      expect(a.hasTimeTracking, isTrue);
      expect(a.seesApprovals, isFalse);
    });

    test('supervisor without permission approves absences', () {
      final a = userContext(supervises: true).access;
      expect(a.canApproveAbsences, isTrue);
      expect(a.canApproveLateEntries, isFalse);
    });

    test('absencerequests permission approves absences', () {
      expect(
        userContext(permissions: {'absencerequests': true})
            .access
            .canApproveAbsences,
        isTrue,
      );
    });

    test('approveDelays needs write access', () {
      expect(
        userContext(permissions: {'approveDelays': true})
            .access
            .canApproveLateEntries,
        isTrue,
      );
      expect(
        userContext(permissions: {'approveDelays': false})
            .access
            .canApproveLateEntries,
        isFalse,
      );
    });

    test('no role or no licence means no access', () {
      expect(userContext(roles: {}).access.hasTimeTracking, isFalse);
      expect(userContext(licence: false).access.hasTimeTracking, isFalse);
    });
  });

  test('UserContext survives a JSON round trip', () {
    final c = userContext(
      supervises: true,
      permissions: {'approveDelays': true},
    );
    final back = UserContext.fromJson(c.toJson());
    expect(back.userId, c.userId);
    expect(back.access.roles, c.access.roles);
    expect(back.access.permissions, c.access.permissions);
    expect(back.access.supervisesSomeone, isTrue);
    expect(back.loadedAt, c.loadedAt);
  });
}
