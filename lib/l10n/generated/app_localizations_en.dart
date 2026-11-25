// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Zeiterfassung Bamsenet';

  @override
  String get retry => 'Try again';

  @override
  String get signIn => 'Sign in';

  @override
  String get signOut => 'Sign out';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get emailRequired => 'Please enter your email';

  @override
  String get emailInvalid => 'Please enter a valid email';

  @override
  String get passwordRequired => 'Please enter your password';

  @override
  String get errorInvalidCredentials => 'Wrong email or password';

  @override
  String get errorNoConnection =>
      'No connection. Please check your internet connection.';

  @override
  String get errorAccountDisabled =>
      'Your account is disabled. Please contact your administrator.';

  @override
  String get errorSessionExpired =>
      'Your session has expired. Please sign in again.';

  @override
  String get errorAccessDenied => 'You don\'t have permission to do this.';

  @override
  String get errorServer =>
      'The server reported an error. Please try again later.';

  @override
  String get errorUnknown => 'Something went wrong. Please try again.';

  @override
  String get noAccessTitle => 'No access';

  @override
  String get noAccessBody =>
      'Time tracking is not enabled for your account. Please contact your administrator.';

  @override
  String get resetTitle => 'Reset password';

  @override
  String get resetIntro =>
      'Enter your email. We\'ll send you a link to set a new password.';

  @override
  String get resetSend => 'Send link';

  @override
  String get resetSent =>
      'If an account exists for this email, we\'ve sent you a link. Please check your inbox.';

  @override
  String get backToSignIn => 'Back to sign in';

  @override
  String get navTimes => 'Times';

  @override
  String get navHistory => 'History';

  @override
  String get navAbsence => 'Absence';

  @override
  String get navMore => 'More';

  @override
  String get newEntry => 'New entry';

  @override
  String get notifications => 'Notifications';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'Device language';

  @override
  String get approvals => 'Approvals';

  @override
  String get loading => 'Loading';

  @override
  String get offlineTitle => 'No connection';

  @override
  String get offlineBody =>
      'The app needs an internet connection. It continues on its own as soon as you\'re back online.';

  @override
  String get lockTitle => 'App locked';

  @override
  String get lockBody =>
      'Unlock with your fingerprint, face or your device\'s screen lock.';

  @override
  String get unlock => 'Unlock';

  @override
  String get usePassword => 'Sign in with password';

  @override
  String get lockReason => 'Unlock time tracking';

  @override
  String get appLockSetting => 'Unlock with biometrics';

  @override
  String get appLockSettingHint => 'Fingerprint, face or screen lock';

  @override
  String get offerTitle => 'Unlock faster?';

  @override
  String get offerBody =>
      'Open the app with your fingerprint, face or screen lock instead of your password. You can change this under More at any time.';

  @override
  String get offerLater => 'Later';

  @override
  String get offerEnable => 'Turn on';

  @override
  String get enableReason => 'Turn on biometrics for time tracking';

  @override
  String get unlockFailed =>
      'Not unlocked. Tap “Unlock” and confirm with your fingerprint or PIN.';

  @override
  String get enableFailed =>
      'Unlocking with the screen lock could not be set up.';

  @override
  String get quickSignIn => 'Fingerprint or PIN';

  @override
  String get savedSignInInvalid =>
      'Your password has changed. Please sign in once with the new password.';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get signInHint => 'Sign in with your company account.';

  @override
  String get or => 'or';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingDay => 'Hello';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get timesEmptyTitle => 'Your times will show here';

  @override
  String get timesEmptyBody =>
      'Day, week and month with all entries and your target hours come next.';

  @override
  String get historyEmptyTitle => 'Your history';

  @override
  String get historyEmptyBody =>
      'All your entries with filters and totals will be here soon.';

  @override
  String get absenceEmptyTitle => 'Leave and absence';

  @override
  String get absenceEmptyBody =>
      'Requests, your balances and the team calendar will be here soon.';

  @override
  String get entryEmptyTitle => 'New entry';

  @override
  String get entryEmptyBody =>
      'The form for recording your times is in progress.';

  @override
  String get notificationsEmptyTitle => 'All caught up';

  @override
  String get notificationsEmptyBody => 'New notifications will show here.';

  @override
  String get settingsSection => 'Settings';

  @override
  String get accountSection => 'Account';

  @override
  String get resetSentTitle => 'Check your inbox';

  @override
  String get demoBadge => 'Sample data';

  @override
  String get demoSetting => 'Show sample data';

  @override
  String get demoSettingHint =>
      'To preview the modules until real data is connected';

  @override
  String get tabDay => 'Day';

  @override
  String get tabWeek => 'Week';

  @override
  String get tabMonth => 'Month';

  @override
  String get worked => 'Worked';

  @override
  String get target => 'Target';

  @override
  String get breakLabel => 'Break';

  @override
  String get nightLabel => 'Night';

  @override
  String get statusComplete => 'Complete';

  @override
  String get statusIncomplete => 'Incomplete';

  @override
  String get statusMissing => 'Missing';

  @override
  String get statusAbsent => 'Absent';

  @override
  String get statusHoliday => 'Holiday';

  @override
  String get statusWeekend => 'Weekend';

  @override
  String get statusFuture => 'Planned';

  @override
  String get breakTooShort => 'Break too short';

  @override
  String get missingTitle => 'No entry for this day';

  @override
  String get missingAction => 'Add entry';

  @override
  String get entryOpen => 'Open';

  @override
  String get entryClosed => 'Closed';

  @override
  String get entryInvoiced => 'Invoiced';

  @override
  String get delayPending => 'Awaiting approval';

  @override
  String get delayRejected => 'Not counted';

  @override
  String get overtimeTitle => 'Overtime balance';

  @override
  String get asOf => 'As of';

  @override
  String get weekShort => 'CW';

  @override
  String get hoursUnit => 'h';

  @override
  String get minutesUnit => 'min';

  @override
  String get historyAll => 'All';

  @override
  String get entriesCount => 'entries';

  @override
  String get fieldDate => 'Date';

  @override
  String get fieldStart => 'Start';

  @override
  String get fieldEnd => 'End';

  @override
  String get fieldActivity => 'Activity';

  @override
  String get fieldWorkPlace => 'Work place';

  @override
  String get fieldRemarks => 'Notes';

  @override
  String get fieldCreatedIn => 'Created in';

  @override
  String get fieldSunday => 'Sunday';

  @override
  String get fieldWorking => 'Working time';

  @override
  String get edit => 'Edit';

  @override
  String get vacationTitle => 'Leave';

  @override
  String get available => 'available';

  @override
  String get daysUnit => 'days';

  @override
  String get taken => 'taken';

  @override
  String get planned => 'planned';

  @override
  String get requested => 'requested';

  @override
  String get carryOver => 'Carry-over';

  @override
  String get expiresOn => 'expires on';

  @override
  String get myRequests => 'My requests';

  @override
  String get teamAbsences => 'Team absences';

  @override
  String get newRequest => 'New request';

  @override
  String get absVacation => 'Vacation';

  @override
  String get absSick => 'Sick note';

  @override
  String get absOvertime => 'Overtime off';

  @override
  String get absTraining => 'Training';

  @override
  String get absSpecial => 'Special leave';

  @override
  String get absAway => 'Away';

  @override
  String get reqPending => 'Pending';

  @override
  String get reqApproved => 'Approved';

  @override
  String get reqRejected => 'Rejected';

  @override
  String get reqCancelled => 'Cancelled';

  @override
  String get thisWeek => 'This week';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get noEntriesFilter => 'No entries for this filter';

  @override
  String get weekTotal => 'Week total';

  @override
  String get ofTarget => 'of';

  @override
  String get dayUnit => 'day';

  @override
  String get workPlaceOffice => 'Office';

  @override
  String get workPlaceHome => 'Home office';

  @override
  String get workPlaceAway => 'On the road';

  @override
  String get fieldProject => 'Project';

  @override
  String get fieldSubproject => 'Sub-project';

  @override
  String get fieldHoliday => 'Public holiday';

  @override
  String get fieldHolidayState => 'Federal state of the work place';

  @override
  String get fieldLocation => 'Location';

  @override
  String get holidayStateHint =>
      'Only for changing work places: decides which public holidays apply to this entry.';

  @override
  String get ownLocation => 'Same as my location';

  @override
  String get overviewStale => 'No connection. Showing the last loaded data.';

  @override
  String get overviewIncomplete =>
      'Holidays, work time model or absences could not be loaded completely. The expected time may be off.';

  @override
  String get targetProvisional =>
      'Expected time is provisionally calculated in the app from the work time model, holidays and absences.';

  @override
  String get targetAssumed =>
      'No work time model assigned: expected time assumed as 8 hours Monday to Friday.';

  @override
  String get entryEditTitle => 'Edit entry';

  @override
  String get entrySavingOff =>
      'Saving is not switched on yet. You can fill in and check everything; nothing is sent.';

  @override
  String get entryCompleteTitle => 'Entry is complete';

  @override
  String get entryNotSent =>
      'Nothing was saved or sent. Saving comes once the client has given the go-ahead.';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get chooseProject => 'Choose a project';

  @override
  String get searchProjects => 'Search projects';

  @override
  String get noneOption => 'None';

  @override
  String get nextDay => 'next day';

  @override
  String get suggestedBreak => 'Use the suggested break';

  @override
  String get totalLabel => 'Total';

  @override
  String get calculated => 'Calculated';

  @override
  String get typedByHand => 'Entered by hand';

  @override
  String get furtherDetails => 'Further details';

  @override
  String get warningsTitle => 'Notes';

  @override
  String get notComparedNote =>
      'Your other entries are not loaded. Overlaps, breaks across entries and rest time are only checked when saving.';

  @override
  String get errNoProject => 'Please choose a project';

  @override
  String get errEndNotAfterStart => 'The end must be after the start';

  @override
  String get errLongerThan24h => 'An entry cannot be longer than 24 hours';

  @override
  String get errBreakTooLong => 'The break cannot be longer than the entry';

  @override
  String get errSurchargeAboveWorking => 'Cannot be more than the working time';

  @override
  String get errOverlap => 'Entry overlaps with other entries';

  @override
  String get errAbsenceBlocks =>
      'You are absent on this day. Your company does not allow entries then.';

  @override
  String get errLocked =>
      'This entry is closed or invoiced and cannot be changed.';

  @override
  String warnBreakTooShort(int minutes) {
    return 'Break too short: $minutes minutes are required.';
  }

  @override
  String warnLongDay(int hours) {
    return 'More than $hours hours of work on this day.';
  }

  @override
  String warnRestTooShort(String rest, String required) {
    return 'Rest time only $rest instead of $required hours.';
  }

  @override
  String warnAbsenceDay(String type) {
    return 'You have an absence on this day ($type).';
  }

  @override
  String warnNeedsApproval(int hours) {
    return 'This entry needs approval: it is more than $hours hours in the past.';
  }
}
