// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Zeiterfassung Bamsenet';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get signIn => 'Anmelden';

  @override
  String get signOut => 'Abmelden';

  @override
  String get email => 'E-Mail';

  @override
  String get password => 'Passwort';

  @override
  String get showPassword => 'Passwort anzeigen';

  @override
  String get hidePassword => 'Passwort verbergen';

  @override
  String get forgotPassword => 'Passwort vergessen?';

  @override
  String get emailRequired => 'Bitte E-Mail eingeben';

  @override
  String get emailInvalid => 'Bitte eine gültige E-Mail eingeben';

  @override
  String get passwordRequired => 'Bitte Passwort eingeben';

  @override
  String get errorInvalidCredentials => 'E-Mail oder Passwort falsch';

  @override
  String get errorNoConnection =>
      'Keine Verbindung. Bitte Internetverbindung prüfen.';

  @override
  String get errorAccountDisabled =>
      'Dein Konto ist deaktiviert. Bitte wende dich an deine Verwaltung.';

  @override
  String get errorSessionExpired =>
      'Deine Sitzung ist abgelaufen. Bitte melde dich erneut an.';

  @override
  String get errorAccessDenied => 'Dafür fehlt dir die Berechtigung.';

  @override
  String get errorServer =>
      'Der Server hat einen Fehler gemeldet. Bitte später erneut versuchen.';

  @override
  String get errorUnknown =>
      'Etwas ist schiefgelaufen. Bitte erneut versuchen.';

  @override
  String get noAccessTitle => 'Kein Zugriff';

  @override
  String get noAccessBody =>
      'Für dein Konto ist die Zeiterfassung nicht freigeschaltet. Bitte wende dich an deine Verwaltung.';

  @override
  String get resetTitle => 'Passwort zurücksetzen';

  @override
  String get resetIntro =>
      'Gib deine E-Mail ein. Wir senden dir einen Link, mit dem du ein neues Passwort festlegst.';

  @override
  String get resetSend => 'Link senden';

  @override
  String get resetSent =>
      'Wenn ein Konto zu dieser E-Mail existiert, haben wir dir einen Link geschickt. Bitte prüfe dein Postfach.';

  @override
  String get backToSignIn => 'Zurück zur Anmeldung';

  @override
  String get navTimes => 'Zeiten';

  @override
  String get navHistory => 'Protokoll';

  @override
  String get navAbsence => 'Abwesenheit';

  @override
  String get navMore => 'Mehr';

  @override
  String get newEntry => 'Neuer Eintrag';

  @override
  String get notifications => 'Benachrichtigungen';

  @override
  String get comingSoon => 'Folgt bald';

  @override
  String get language => 'Sprache';

  @override
  String get languageSystem => 'Gerätesprache';

  @override
  String get approvals => 'Freigaben';

  @override
  String get loading => 'Wird geladen';

  @override
  String get offlineTitle => 'Keine Verbindung';

  @override
  String get offlineBody =>
      'Die App braucht eine Internetverbindung. Sobald du wieder online bist, geht es automatisch weiter.';

  @override
  String get lockTitle => 'App gesperrt';

  @override
  String get lockBody =>
      'Entsperre mit Fingerabdruck, Gesicht oder der Displaysperre deines Geräts.';

  @override
  String get unlock => 'Entsperren';

  @override
  String get usePassword => 'Mit Passwort anmelden';

  @override
  String get lockReason => 'Zeiterfassung entsperren';

  @override
  String get appLockSetting => 'Mit Biometrie entsperren';

  @override
  String get appLockSettingHint => 'Fingerabdruck, Gesicht oder Displaysperre';

  @override
  String get offerTitle => 'Schneller entsperren?';

  @override
  String get offerBody =>
      'Öffne die App künftig mit Fingerabdruck, Gesicht oder deiner Displaysperre statt mit dem Passwort. Du kannst das unter „Mehr“ jederzeit ändern.';

  @override
  String get offerLater => 'Später';

  @override
  String get offerEnable => 'Aktivieren';

  @override
  String get enableReason => 'Biometrie für die Zeiterfassung aktivieren';

  @override
  String get unlockFailed =>
      'Nicht entsperrt. Tippe auf „Entsperren“ und bestätige mit Fingerabdruck oder PIN.';

  @override
  String get enableFailed =>
      'Entsperren mit Displaysperre konnte nicht eingerichtet werden.';

  @override
  String get quickSignIn => 'Mit Fingerabdruck oder PIN';

  @override
  String get savedSignInInvalid =>
      'Dein Passwort hat sich geändert. Bitte melde dich einmal mit dem neuen Passwort an.';

  @override
  String get welcomeBack => 'Willkommen zurück';

  @override
  String get signInHint => 'Melde dich mit deinem Firmenkonto an.';

  @override
  String get or => 'oder';

  @override
  String get greetingMorning => 'Guten Morgen';

  @override
  String get greetingDay => 'Hallo';

  @override
  String get greetingEvening => 'Guten Abend';

  @override
  String get timesEmptyTitle => 'Deine Zeiten erscheinen hier';

  @override
  String get timesEmptyBody =>
      'Tag, Woche und Monat mit allen Einträgen und deinem Soll kommen als Nächstes.';

  @override
  String get historyEmptyTitle => 'Dein Protokoll';

  @override
  String get historyEmptyBody =>
      'Hier findest du bald alle Einträge mit Filtern und Summen.';

  @override
  String get absenceEmptyTitle => 'Urlaub und Abwesenheit';

  @override
  String get absenceEmptyBody =>
      'Anträge, deine Kontostände und den Teamkalender findest du bald hier.';

  @override
  String get entryEmptyTitle => 'Neuer Eintrag';

  @override
  String get entryEmptyBody =>
      'Das Formular zum Erfassen deiner Zeiten ist in Arbeit.';

  @override
  String get notificationsEmptyTitle => 'Alles erledigt';

  @override
  String get notificationsEmptyBody =>
      'Neue Benachrichtigungen erscheinen hier.';

  @override
  String get settingsSection => 'Einstellungen';

  @override
  String get accountSection => 'Konto';

  @override
  String get resetSentTitle => 'Schau in dein Postfach';

  @override
  String get demoBadge => 'Beispieldaten';

  @override
  String get demoSetting => 'Beispieldaten anzeigen';

  @override
  String get demoSettingHint =>
      'Zum Ansehen der Module, bis echte Daten angebunden sind';

  @override
  String get tabDay => 'Tag';

  @override
  String get tabWeek => 'Woche';

  @override
  String get tabMonth => 'Monat';

  @override
  String get worked => 'Gearbeitet';

  @override
  String get target => 'Soll';

  @override
  String get breakLabel => 'Pause';

  @override
  String get nightLabel => 'Nacht';

  @override
  String get statusComplete => 'Vollständig';

  @override
  String get statusIncomplete => 'Unvollständig';

  @override
  String get statusMissing => 'Fehlt';

  @override
  String get statusAbsent => 'Abwesend';

  @override
  String get statusHoliday => 'Feiertag';

  @override
  String get statusWeekend => 'Wochenende';

  @override
  String get statusFuture => 'Geplant';

  @override
  String get breakTooShort => 'Pause zu kurz';

  @override
  String get missingTitle => 'Kein Eintrag für diesen Tag';

  @override
  String get missingAction => 'Jetzt erfassen';

  @override
  String get entryOpen => 'Offen';

  @override
  String get entryClosed => 'Festgeschrieben';

  @override
  String get entryInvoiced => 'Abgerechnet';

  @override
  String get delayPending => 'Wartet auf Freigabe';

  @override
  String get delayRejected => 'Nicht berücksichtigt';

  @override
  String get overtimeTitle => 'Überstundenkonto';

  @override
  String get asOf => 'Stand';

  @override
  String get weekShort => 'KW';

  @override
  String get hoursUnit => 'Std';

  @override
  String get minutesUnit => 'Min';

  @override
  String get historyAll => 'Alle';

  @override
  String get entriesCount => 'Einträge';

  @override
  String get fieldDate => 'Datum';

  @override
  String get fieldStart => 'Beginn';

  @override
  String get fieldEnd => 'Ende';

  @override
  String get fieldActivity => 'Tätigkeit';

  @override
  String get fieldWorkPlace => 'Einsatzort';

  @override
  String get fieldRemarks => 'Anmerkungen';

  @override
  String get fieldCreatedIn => 'Erfasst in';

  @override
  String get fieldSunday => 'Sonntag';

  @override
  String get fieldWorking => 'Arbeitszeit';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get vacationTitle => 'Urlaub';

  @override
  String get available => 'verfügbar';

  @override
  String get daysUnit => 'Tage';

  @override
  String get taken => 'genommen';

  @override
  String get planned => 'geplant';

  @override
  String get requested => 'beantragt';

  @override
  String get carryOver => 'Resturlaub';

  @override
  String get expiresOn => 'verfällt am';

  @override
  String get myRequests => 'Meine Anträge';

  @override
  String get teamAbsences => 'Team-Abwesenheiten';

  @override
  String get newRequest => 'Neuer Antrag';

  @override
  String get absVacation => 'Urlaub';

  @override
  String get absSick => 'Krankmeldung';

  @override
  String get absOvertime => 'Überstundenabbau';

  @override
  String get absTraining => 'Weiterbildung';

  @override
  String get absSpecial => 'Sonderurlaub';

  @override
  String get absAway => 'Abwesend';

  @override
  String get reqPending => 'Offen';

  @override
  String get reqApproved => 'Genehmigt';

  @override
  String get reqRejected => 'Abgelehnt';

  @override
  String get reqCancelled => 'Storniert';

  @override
  String get thisWeek => 'Diese Woche';

  @override
  String get today => 'Heute';

  @override
  String get yesterday => 'Gestern';

  @override
  String get noEntriesFilter => 'Keine Einträge für diesen Filter';

  @override
  String get weekTotal => 'Woche gesamt';

  @override
  String get ofTarget => 'von';

  @override
  String get dayUnit => 'Tag';

  @override
  String get workPlaceOffice => 'Büro';

  @override
  String get workPlaceHome => 'Homeoffice';

  @override
  String get workPlaceAway => 'Unterwegs';

  @override
  String get fieldProject => 'Projekt';

  @override
  String get fieldSubproject => 'Unterprojekt';

  @override
  String get fieldHoliday => 'Feiertag';

  @override
  String get fieldHolidayState => 'Bundesland des Einsatzorts';

  @override
  String get fieldLocation => 'Ort';

  @override
  String get holidayStateHint =>
      'Nur bei wechselndem Einsatzort: bestimmt, welche Feiertage für diesen Eintrag gelten.';

  @override
  String get ownLocation => 'Wie mein Standort';

  @override
  String get overviewStale =>
      'Keine Verbindung. Angezeigt wird der letzte Stand.';

  @override
  String get overviewIncomplete =>
      'Feiertage, Arbeitszeitmodell oder Abwesenheiten konnten nicht vollständig geladen werden. Das Soll kann abweichen.';

  @override
  String get targetProvisional =>
      'Soll vorläufig in der App berechnet aus Arbeitszeitmodell, Feiertagen und Abwesenheiten.';

  @override
  String get targetAssumed =>
      'Kein Arbeitszeitmodell hinterlegt: Soll angenommen mit 8 Stunden von Montag bis Freitag.';

  @override
  String get entryEditTitle => 'Eintrag bearbeiten';

  @override
  String get entrySavingOff =>
      'Speichern ist noch nicht freigeschaltet. Du kannst alles ausfüllen und prüfen lassen; es wird nichts gesendet.';

  @override
  String get entryCompleteTitle => 'Eintrag ist vollständig';

  @override
  String get entryNotSent =>
      'Es wurde nichts gespeichert oder gesendet. Speichern kommt, sobald die Freigabe des Kunden vorliegt.';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get save => 'Speichern';

  @override
  String get chooseProject => 'Projekt wählen';

  @override
  String get searchProjects => 'Projekt suchen';

  @override
  String get noneOption => 'Keine Angabe';

  @override
  String get nextDay => 'nächster Tag';

  @override
  String get suggestedBreak => 'Vorgeschlagene Pause übernehmen';

  @override
  String get totalLabel => 'Gesamt';

  @override
  String get calculated => 'Berechnet';

  @override
  String get typedByHand => 'Von Hand eingetragen';

  @override
  String get furtherDetails => 'Weitere Angaben';

  @override
  String get warningsTitle => 'Hinweise';

  @override
  String get notComparedNote =>
      'Deine anderen Einträge sind nicht geladen. Überschneidungen, Pausen über mehrere Einträge und Ruhezeit werden erst beim Speichern geprüft.';

  @override
  String get errNoProject => 'Bitte ein Projekt wählen';

  @override
  String get errEndNotAfterStart => 'Das Ende muss nach dem Beginn liegen';

  @override
  String get errLongerThan24h =>
      'Die Dauer des Eintrags darf nicht länger als 24 Stunden sein';

  @override
  String get errBreakTooLong =>
      'Die Pause darf nicht länger als der Eintrag sein';

  @override
  String get errSurchargeAboveWorking =>
      'Darf nicht größer als die Arbeitszeit sein';

  @override
  String get errOverlap => 'Eintrag überlappt mit anderen Einträgen';

  @override
  String get errAbsenceBlocks =>
      'An diesem Tag bist du abwesend. Deine Firma erlaubt dann keine Einträge.';

  @override
  String get errLocked =>
      'Dieser Eintrag ist festgeschrieben oder abgerechnet und kann nicht geändert werden.';

  @override
  String warnBreakTooShort(int minutes) {
    return 'Pause zu kurz: $minutes Minuten sind vorgeschrieben.';
  }

  @override
  String warnLongDay(int hours) {
    return 'Mehr als $hours Stunden Arbeit an diesem Tag.';
  }

  @override
  String warnRestTooShort(String rest, String required) {
    return 'Ruhezeit nur $rest statt $required Stunden.';
  }

  @override
  String warnAbsenceDay(String type) {
    return 'An diesem Tag hast du eine Abwesenheit ($type).';
  }

  @override
  String warnNeedsApproval(int hours) {
    return 'Dieser Eintrag muss genehmigt werden: er liegt mehr als $hours Stunden zurück.';
  }
}
