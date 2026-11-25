import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In de, this message translates to:
  /// **'Zeiterfassung Bamsenet'**
  String get appTitle;

  /// No description provided for @retry.
  ///
  /// In de, this message translates to:
  /// **'Erneut versuchen'**
  String get retry;

  /// No description provided for @signIn.
  ///
  /// In de, this message translates to:
  /// **'Anmelden'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In de, this message translates to:
  /// **'Abmelden'**
  String get signOut;

  /// No description provided for @email.
  ///
  /// In de, this message translates to:
  /// **'E-Mail'**
  String get email;

  /// No description provided for @password.
  ///
  /// In de, this message translates to:
  /// **'Passwort'**
  String get password;

  /// No description provided for @showPassword.
  ///
  /// In de, this message translates to:
  /// **'Passwort anzeigen'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In de, this message translates to:
  /// **'Passwort verbergen'**
  String get hidePassword;

  /// No description provided for @forgotPassword.
  ///
  /// In de, this message translates to:
  /// **'Passwort vergessen?'**
  String get forgotPassword;

  /// No description provided for @emailRequired.
  ///
  /// In de, this message translates to:
  /// **'Bitte E-Mail eingeben'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In de, this message translates to:
  /// **'Bitte eine gültige E-Mail eingeben'**
  String get emailInvalid;

  /// No description provided for @passwordRequired.
  ///
  /// In de, this message translates to:
  /// **'Bitte Passwort eingeben'**
  String get passwordRequired;

  /// No description provided for @errorInvalidCredentials.
  ///
  /// In de, this message translates to:
  /// **'E-Mail oder Passwort falsch'**
  String get errorInvalidCredentials;

  /// No description provided for @errorNoConnection.
  ///
  /// In de, this message translates to:
  /// **'Keine Verbindung. Bitte Internetverbindung prüfen.'**
  String get errorNoConnection;

  /// No description provided for @errorAccountDisabled.
  ///
  /// In de, this message translates to:
  /// **'Dein Konto ist deaktiviert. Bitte wende dich an deine Verwaltung.'**
  String get errorAccountDisabled;

  /// No description provided for @errorSessionExpired.
  ///
  /// In de, this message translates to:
  /// **'Deine Sitzung ist abgelaufen. Bitte melde dich erneut an.'**
  String get errorSessionExpired;

  /// No description provided for @errorAccessDenied.
  ///
  /// In de, this message translates to:
  /// **'Dafür fehlt dir die Berechtigung.'**
  String get errorAccessDenied;

  /// No description provided for @errorServer.
  ///
  /// In de, this message translates to:
  /// **'Der Server hat einen Fehler gemeldet. Bitte später erneut versuchen.'**
  String get errorServer;

  /// No description provided for @errorUnknown.
  ///
  /// In de, this message translates to:
  /// **'Etwas ist schiefgelaufen. Bitte erneut versuchen.'**
  String get errorUnknown;

  /// No description provided for @noAccessTitle.
  ///
  /// In de, this message translates to:
  /// **'Kein Zugriff'**
  String get noAccessTitle;

  /// No description provided for @noAccessBody.
  ///
  /// In de, this message translates to:
  /// **'Für dein Konto ist die Zeiterfassung nicht freigeschaltet. Bitte wende dich an deine Verwaltung.'**
  String get noAccessBody;

  /// No description provided for @resetTitle.
  ///
  /// In de, this message translates to:
  /// **'Passwort zurücksetzen'**
  String get resetTitle;

  /// No description provided for @resetIntro.
  ///
  /// In de, this message translates to:
  /// **'Gib deine E-Mail ein. Wir senden dir einen Link, mit dem du ein neues Passwort festlegst.'**
  String get resetIntro;

  /// No description provided for @resetSend.
  ///
  /// In de, this message translates to:
  /// **'Link senden'**
  String get resetSend;

  /// No description provided for @resetSent.
  ///
  /// In de, this message translates to:
  /// **'Wenn ein Konto zu dieser E-Mail existiert, haben wir dir einen Link geschickt. Bitte prüfe dein Postfach.'**
  String get resetSent;

  /// No description provided for @backToSignIn.
  ///
  /// In de, this message translates to:
  /// **'Zurück zur Anmeldung'**
  String get backToSignIn;

  /// No description provided for @navTimes.
  ///
  /// In de, this message translates to:
  /// **'Zeiten'**
  String get navTimes;

  /// No description provided for @navHistory.
  ///
  /// In de, this message translates to:
  /// **'Protokoll'**
  String get navHistory;

  /// No description provided for @navAbsence.
  ///
  /// In de, this message translates to:
  /// **'Abwesenheit'**
  String get navAbsence;

  /// No description provided for @navMore.
  ///
  /// In de, this message translates to:
  /// **'Mehr'**
  String get navMore;

  /// No description provided for @newEntry.
  ///
  /// In de, this message translates to:
  /// **'Neuer Eintrag'**
  String get newEntry;

  /// No description provided for @notifications.
  ///
  /// In de, this message translates to:
  /// **'Benachrichtigungen'**
  String get notifications;

  /// No description provided for @comingSoon.
  ///
  /// In de, this message translates to:
  /// **'Folgt bald'**
  String get comingSoon;

  /// No description provided for @language.
  ///
  /// In de, this message translates to:
  /// **'Sprache'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In de, this message translates to:
  /// **'Gerätesprache'**
  String get languageSystem;

  /// No description provided for @approvals.
  ///
  /// In de, this message translates to:
  /// **'Freigaben'**
  String get approvals;

  /// No description provided for @loading.
  ///
  /// In de, this message translates to:
  /// **'Wird geladen'**
  String get loading;

  /// No description provided for @offlineTitle.
  ///
  /// In de, this message translates to:
  /// **'Keine Verbindung'**
  String get offlineTitle;

  /// No description provided for @offlineBody.
  ///
  /// In de, this message translates to:
  /// **'Die App braucht eine Internetverbindung. Sobald du wieder online bist, geht es automatisch weiter.'**
  String get offlineBody;

  /// No description provided for @lockTitle.
  ///
  /// In de, this message translates to:
  /// **'App gesperrt'**
  String get lockTitle;

  /// No description provided for @lockBody.
  ///
  /// In de, this message translates to:
  /// **'Entsperre mit Fingerabdruck, Gesicht oder der Displaysperre deines Geräts.'**
  String get lockBody;

  /// No description provided for @unlock.
  ///
  /// In de, this message translates to:
  /// **'Entsperren'**
  String get unlock;

  /// No description provided for @usePassword.
  ///
  /// In de, this message translates to:
  /// **'Mit Passwort anmelden'**
  String get usePassword;

  /// No description provided for @lockReason.
  ///
  /// In de, this message translates to:
  /// **'Zeiterfassung entsperren'**
  String get lockReason;

  /// No description provided for @appLockSetting.
  ///
  /// In de, this message translates to:
  /// **'Mit Biometrie entsperren'**
  String get appLockSetting;

  /// No description provided for @appLockSettingHint.
  ///
  /// In de, this message translates to:
  /// **'Fingerabdruck, Gesicht oder Displaysperre'**
  String get appLockSettingHint;

  /// No description provided for @offerTitle.
  ///
  /// In de, this message translates to:
  /// **'Schneller entsperren?'**
  String get offerTitle;

  /// No description provided for @offerBody.
  ///
  /// In de, this message translates to:
  /// **'Öffne die App künftig mit Fingerabdruck, Gesicht oder deiner Displaysperre statt mit dem Passwort. Du kannst das unter „Mehr“ jederzeit ändern.'**
  String get offerBody;

  /// No description provided for @offerLater.
  ///
  /// In de, this message translates to:
  /// **'Später'**
  String get offerLater;

  /// No description provided for @offerEnable.
  ///
  /// In de, this message translates to:
  /// **'Aktivieren'**
  String get offerEnable;

  /// No description provided for @enableReason.
  ///
  /// In de, this message translates to:
  /// **'Biometrie für die Zeiterfassung aktivieren'**
  String get enableReason;

  /// No description provided for @unlockFailed.
  ///
  /// In de, this message translates to:
  /// **'Nicht entsperrt. Tippe auf „Entsperren“ und bestätige mit Fingerabdruck oder PIN.'**
  String get unlockFailed;

  /// No description provided for @enableFailed.
  ///
  /// In de, this message translates to:
  /// **'Entsperren mit Displaysperre konnte nicht eingerichtet werden.'**
  String get enableFailed;

  /// No description provided for @quickSignIn.
  ///
  /// In de, this message translates to:
  /// **'Mit Fingerabdruck oder PIN'**
  String get quickSignIn;

  /// No description provided for @savedSignInInvalid.
  ///
  /// In de, this message translates to:
  /// **'Dein Passwort hat sich geändert. Bitte melde dich einmal mit dem neuen Passwort an.'**
  String get savedSignInInvalid;

  /// No description provided for @welcomeBack.
  ///
  /// In de, this message translates to:
  /// **'Willkommen zurück'**
  String get welcomeBack;

  /// No description provided for @signInHint.
  ///
  /// In de, this message translates to:
  /// **'Melde dich mit deinem Firmenkonto an.'**
  String get signInHint;

  /// No description provided for @or.
  ///
  /// In de, this message translates to:
  /// **'oder'**
  String get or;

  /// No description provided for @greetingMorning.
  ///
  /// In de, this message translates to:
  /// **'Guten Morgen'**
  String get greetingMorning;

  /// No description provided for @greetingDay.
  ///
  /// In de, this message translates to:
  /// **'Hallo'**
  String get greetingDay;

  /// No description provided for @greetingEvening.
  ///
  /// In de, this message translates to:
  /// **'Guten Abend'**
  String get greetingEvening;

  /// No description provided for @timesEmptyTitle.
  ///
  /// In de, this message translates to:
  /// **'Deine Zeiten erscheinen hier'**
  String get timesEmptyTitle;

  /// No description provided for @timesEmptyBody.
  ///
  /// In de, this message translates to:
  /// **'Tag, Woche und Monat mit allen Einträgen und deinem Soll kommen als Nächstes.'**
  String get timesEmptyBody;

  /// No description provided for @historyEmptyTitle.
  ///
  /// In de, this message translates to:
  /// **'Dein Protokoll'**
  String get historyEmptyTitle;

  /// No description provided for @historyEmptyBody.
  ///
  /// In de, this message translates to:
  /// **'Hier findest du bald alle Einträge mit Filtern und Summen.'**
  String get historyEmptyBody;

  /// No description provided for @absenceEmptyTitle.
  ///
  /// In de, this message translates to:
  /// **'Urlaub und Abwesenheit'**
  String get absenceEmptyTitle;

  /// No description provided for @absenceEmptyBody.
  ///
  /// In de, this message translates to:
  /// **'Anträge, deine Kontostände und den Teamkalender findest du bald hier.'**
  String get absenceEmptyBody;

  /// No description provided for @entryEmptyTitle.
  ///
  /// In de, this message translates to:
  /// **'Neuer Eintrag'**
  String get entryEmptyTitle;

  /// No description provided for @entryEmptyBody.
  ///
  /// In de, this message translates to:
  /// **'Das Formular zum Erfassen deiner Zeiten ist in Arbeit.'**
  String get entryEmptyBody;

  /// No description provided for @notificationsEmptyTitle.
  ///
  /// In de, this message translates to:
  /// **'Alles erledigt'**
  String get notificationsEmptyTitle;

  /// No description provided for @notificationsEmptyBody.
  ///
  /// In de, this message translates to:
  /// **'Neue Benachrichtigungen erscheinen hier.'**
  String get notificationsEmptyBody;

  /// No description provided for @settingsSection.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get settingsSection;

  /// No description provided for @accountSection.
  ///
  /// In de, this message translates to:
  /// **'Konto'**
  String get accountSection;

  /// No description provided for @resetSentTitle.
  ///
  /// In de, this message translates to:
  /// **'Schau in dein Postfach'**
  String get resetSentTitle;

  /// No description provided for @demoBadge.
  ///
  /// In de, this message translates to:
  /// **'Beispieldaten'**
  String get demoBadge;

  /// No description provided for @demoSetting.
  ///
  /// In de, this message translates to:
  /// **'Beispieldaten anzeigen'**
  String get demoSetting;

  /// No description provided for @demoSettingHint.
  ///
  /// In de, this message translates to:
  /// **'Zum Ansehen der Module, bis echte Daten angebunden sind'**
  String get demoSettingHint;

  /// No description provided for @tabDay.
  ///
  /// In de, this message translates to:
  /// **'Tag'**
  String get tabDay;

  /// No description provided for @tabWeek.
  ///
  /// In de, this message translates to:
  /// **'Woche'**
  String get tabWeek;

  /// No description provided for @tabMonth.
  ///
  /// In de, this message translates to:
  /// **'Monat'**
  String get tabMonth;

  /// No description provided for @worked.
  ///
  /// In de, this message translates to:
  /// **'Gearbeitet'**
  String get worked;

  /// No description provided for @target.
  ///
  /// In de, this message translates to:
  /// **'Soll'**
  String get target;

  /// No description provided for @breakLabel.
  ///
  /// In de, this message translates to:
  /// **'Pause'**
  String get breakLabel;

  /// No description provided for @nightLabel.
  ///
  /// In de, this message translates to:
  /// **'Nacht'**
  String get nightLabel;

  /// No description provided for @statusComplete.
  ///
  /// In de, this message translates to:
  /// **'Vollständig'**
  String get statusComplete;

  /// No description provided for @statusIncomplete.
  ///
  /// In de, this message translates to:
  /// **'Unvollständig'**
  String get statusIncomplete;

  /// No description provided for @statusMissing.
  ///
  /// In de, this message translates to:
  /// **'Fehlt'**
  String get statusMissing;

  /// No description provided for @statusAbsent.
  ///
  /// In de, this message translates to:
  /// **'Abwesend'**
  String get statusAbsent;

  /// No description provided for @statusHoliday.
  ///
  /// In de, this message translates to:
  /// **'Feiertag'**
  String get statusHoliday;

  /// No description provided for @statusWeekend.
  ///
  /// In de, this message translates to:
  /// **'Wochenende'**
  String get statusWeekend;

  /// No description provided for @statusFuture.
  ///
  /// In de, this message translates to:
  /// **'Geplant'**
  String get statusFuture;

  /// No description provided for @breakTooShort.
  ///
  /// In de, this message translates to:
  /// **'Pause zu kurz'**
  String get breakTooShort;

  /// No description provided for @missingTitle.
  ///
  /// In de, this message translates to:
  /// **'Kein Eintrag für diesen Tag'**
  String get missingTitle;

  /// No description provided for @missingAction.
  ///
  /// In de, this message translates to:
  /// **'Jetzt erfassen'**
  String get missingAction;

  /// No description provided for @entryOpen.
  ///
  /// In de, this message translates to:
  /// **'Offen'**
  String get entryOpen;

  /// No description provided for @entryClosed.
  ///
  /// In de, this message translates to:
  /// **'Festgeschrieben'**
  String get entryClosed;

  /// No description provided for @entryInvoiced.
  ///
  /// In de, this message translates to:
  /// **'Abgerechnet'**
  String get entryInvoiced;

  /// No description provided for @delayPending.
  ///
  /// In de, this message translates to:
  /// **'Wartet auf Freigabe'**
  String get delayPending;

  /// No description provided for @delayRejected.
  ///
  /// In de, this message translates to:
  /// **'Nicht berücksichtigt'**
  String get delayRejected;

  /// No description provided for @overtimeTitle.
  ///
  /// In de, this message translates to:
  /// **'Überstundenkonto'**
  String get overtimeTitle;

  /// No description provided for @asOf.
  ///
  /// In de, this message translates to:
  /// **'Stand'**
  String get asOf;

  /// No description provided for @weekShort.
  ///
  /// In de, this message translates to:
  /// **'KW'**
  String get weekShort;

  /// No description provided for @hoursUnit.
  ///
  /// In de, this message translates to:
  /// **'Std'**
  String get hoursUnit;

  /// No description provided for @minutesUnit.
  ///
  /// In de, this message translates to:
  /// **'Min'**
  String get minutesUnit;

  /// No description provided for @historyAll.
  ///
  /// In de, this message translates to:
  /// **'Alle'**
  String get historyAll;

  /// No description provided for @entriesCount.
  ///
  /// In de, this message translates to:
  /// **'Einträge'**
  String get entriesCount;

  /// No description provided for @fieldDate.
  ///
  /// In de, this message translates to:
  /// **'Datum'**
  String get fieldDate;

  /// No description provided for @fieldStart.
  ///
  /// In de, this message translates to:
  /// **'Beginn'**
  String get fieldStart;

  /// No description provided for @fieldEnd.
  ///
  /// In de, this message translates to:
  /// **'Ende'**
  String get fieldEnd;

  /// No description provided for @fieldActivity.
  ///
  /// In de, this message translates to:
  /// **'Tätigkeit'**
  String get fieldActivity;

  /// No description provided for @fieldWorkPlace.
  ///
  /// In de, this message translates to:
  /// **'Einsatzort'**
  String get fieldWorkPlace;

  /// No description provided for @fieldRemarks.
  ///
  /// In de, this message translates to:
  /// **'Anmerkungen'**
  String get fieldRemarks;

  /// No description provided for @fieldCreatedIn.
  ///
  /// In de, this message translates to:
  /// **'Erfasst in'**
  String get fieldCreatedIn;

  /// No description provided for @fieldSunday.
  ///
  /// In de, this message translates to:
  /// **'Sonntag'**
  String get fieldSunday;

  /// No description provided for @fieldWorking.
  ///
  /// In de, this message translates to:
  /// **'Arbeitszeit'**
  String get fieldWorking;

  /// No description provided for @edit.
  ///
  /// In de, this message translates to:
  /// **'Bearbeiten'**
  String get edit;

  /// No description provided for @vacationTitle.
  ///
  /// In de, this message translates to:
  /// **'Urlaub'**
  String get vacationTitle;

  /// No description provided for @available.
  ///
  /// In de, this message translates to:
  /// **'verfügbar'**
  String get available;

  /// No description provided for @daysUnit.
  ///
  /// In de, this message translates to:
  /// **'Tage'**
  String get daysUnit;

  /// No description provided for @taken.
  ///
  /// In de, this message translates to:
  /// **'genommen'**
  String get taken;

  /// No description provided for @planned.
  ///
  /// In de, this message translates to:
  /// **'geplant'**
  String get planned;

  /// No description provided for @requested.
  ///
  /// In de, this message translates to:
  /// **'beantragt'**
  String get requested;

  /// No description provided for @carryOver.
  ///
  /// In de, this message translates to:
  /// **'Resturlaub'**
  String get carryOver;

  /// No description provided for @expiresOn.
  ///
  /// In de, this message translates to:
  /// **'verfällt am'**
  String get expiresOn;

  /// No description provided for @myRequests.
  ///
  /// In de, this message translates to:
  /// **'Meine Anträge'**
  String get myRequests;

  /// No description provided for @teamAbsences.
  ///
  /// In de, this message translates to:
  /// **'Team-Abwesenheiten'**
  String get teamAbsences;

  /// No description provided for @newRequest.
  ///
  /// In de, this message translates to:
  /// **'Neuer Antrag'**
  String get newRequest;

  /// No description provided for @absVacation.
  ///
  /// In de, this message translates to:
  /// **'Urlaub'**
  String get absVacation;

  /// No description provided for @absSick.
  ///
  /// In de, this message translates to:
  /// **'Krankmeldung'**
  String get absSick;

  /// No description provided for @absOvertime.
  ///
  /// In de, this message translates to:
  /// **'Überstundenabbau'**
  String get absOvertime;

  /// No description provided for @absTraining.
  ///
  /// In de, this message translates to:
  /// **'Weiterbildung'**
  String get absTraining;

  /// No description provided for @absSpecial.
  ///
  /// In de, this message translates to:
  /// **'Sonderurlaub'**
  String get absSpecial;

  /// No description provided for @absAway.
  ///
  /// In de, this message translates to:
  /// **'Abwesend'**
  String get absAway;

  /// No description provided for @reqPending.
  ///
  /// In de, this message translates to:
  /// **'Offen'**
  String get reqPending;

  /// No description provided for @reqApproved.
  ///
  /// In de, this message translates to:
  /// **'Genehmigt'**
  String get reqApproved;

  /// No description provided for @reqRejected.
  ///
  /// In de, this message translates to:
  /// **'Abgelehnt'**
  String get reqRejected;

  /// No description provided for @reqCancelled.
  ///
  /// In de, this message translates to:
  /// **'Storniert'**
  String get reqCancelled;

  /// No description provided for @thisWeek.
  ///
  /// In de, this message translates to:
  /// **'Diese Woche'**
  String get thisWeek;

  /// No description provided for @today.
  ///
  /// In de, this message translates to:
  /// **'Heute'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In de, this message translates to:
  /// **'Gestern'**
  String get yesterday;

  /// No description provided for @noEntriesFilter.
  ///
  /// In de, this message translates to:
  /// **'Keine Einträge für diesen Filter'**
  String get noEntriesFilter;

  /// No description provided for @weekTotal.
  ///
  /// In de, this message translates to:
  /// **'Woche gesamt'**
  String get weekTotal;

  /// No description provided for @ofTarget.
  ///
  /// In de, this message translates to:
  /// **'von'**
  String get ofTarget;

  /// No description provided for @dayUnit.
  ///
  /// In de, this message translates to:
  /// **'Tag'**
  String get dayUnit;

  /// No description provided for @workPlaceOffice.
  ///
  /// In de, this message translates to:
  /// **'Büro'**
  String get workPlaceOffice;

  /// No description provided for @workPlaceHome.
  ///
  /// In de, this message translates to:
  /// **'Homeoffice'**
  String get workPlaceHome;

  /// No description provided for @workPlaceAway.
  ///
  /// In de, this message translates to:
  /// **'Unterwegs'**
  String get workPlaceAway;

  /// No description provided for @fieldProject.
  ///
  /// In de, this message translates to:
  /// **'Projekt'**
  String get fieldProject;

  /// No description provided for @fieldSubproject.
  ///
  /// In de, this message translates to:
  /// **'Unterprojekt'**
  String get fieldSubproject;

  /// No description provided for @fieldHoliday.
  ///
  /// In de, this message translates to:
  /// **'Feiertag'**
  String get fieldHoliday;

  /// No description provided for @fieldHolidayState.
  ///
  /// In de, this message translates to:
  /// **'Bundesland des Einsatzorts'**
  String get fieldHolidayState;

  /// No description provided for @fieldLocation.
  ///
  /// In de, this message translates to:
  /// **'Ort'**
  String get fieldLocation;

  /// No description provided for @holidayStateHint.
  ///
  /// In de, this message translates to:
  /// **'Nur bei wechselndem Einsatzort: bestimmt, welche Feiertage für diesen Eintrag gelten.'**
  String get holidayStateHint;

  /// No description provided for @ownLocation.
  ///
  /// In de, this message translates to:
  /// **'Wie mein Standort'**
  String get ownLocation;

  /// No description provided for @overviewStale.
  ///
  /// In de, this message translates to:
  /// **'Keine Verbindung. Angezeigt wird der letzte Stand.'**
  String get overviewStale;

  /// No description provided for @overviewIncomplete.
  ///
  /// In de, this message translates to:
  /// **'Feiertage, Arbeitszeitmodell oder Abwesenheiten konnten nicht vollständig geladen werden. Das Soll kann abweichen.'**
  String get overviewIncomplete;

  /// No description provided for @targetProvisional.
  ///
  /// In de, this message translates to:
  /// **'Soll vorläufig in der App berechnet aus Arbeitszeitmodell, Feiertagen und Abwesenheiten.'**
  String get targetProvisional;

  /// No description provided for @targetAssumed.
  ///
  /// In de, this message translates to:
  /// **'Kein Arbeitszeitmodell hinterlegt: Soll angenommen mit 8 Stunden von Montag bis Freitag.'**
  String get targetAssumed;

  /// No description provided for @entryEditTitle.
  ///
  /// In de, this message translates to:
  /// **'Eintrag bearbeiten'**
  String get entryEditTitle;

  /// No description provided for @entrySavingOff.
  ///
  /// In de, this message translates to:
  /// **'Speichern ist noch nicht freigeschaltet. Du kannst alles ausfüllen und prüfen lassen; es wird nichts gesendet.'**
  String get entrySavingOff;

  /// No description provided for @entryCompleteTitle.
  ///
  /// In de, this message translates to:
  /// **'Eintrag ist vollständig'**
  String get entryCompleteTitle;

  /// No description provided for @entryNotSent.
  ///
  /// In de, this message translates to:
  /// **'Es wurde nichts gespeichert oder gesendet. Speichern kommt, sobald die Freigabe des Kunden vorliegt.'**
  String get entryNotSent;

  /// No description provided for @ok.
  ///
  /// In de, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get save;

  /// No description provided for @chooseProject.
  ///
  /// In de, this message translates to:
  /// **'Projekt wählen'**
  String get chooseProject;

  /// No description provided for @searchProjects.
  ///
  /// In de, this message translates to:
  /// **'Projekt suchen'**
  String get searchProjects;

  /// No description provided for @noneOption.
  ///
  /// In de, this message translates to:
  /// **'Keine Angabe'**
  String get noneOption;

  /// No description provided for @nextDay.
  ///
  /// In de, this message translates to:
  /// **'nächster Tag'**
  String get nextDay;

  /// No description provided for @suggestedBreak.
  ///
  /// In de, this message translates to:
  /// **'Vorgeschlagene Pause übernehmen'**
  String get suggestedBreak;

  /// No description provided for @totalLabel.
  ///
  /// In de, this message translates to:
  /// **'Gesamt'**
  String get totalLabel;

  /// No description provided for @calculated.
  ///
  /// In de, this message translates to:
  /// **'Berechnet'**
  String get calculated;

  /// No description provided for @typedByHand.
  ///
  /// In de, this message translates to:
  /// **'Von Hand eingetragen'**
  String get typedByHand;

  /// No description provided for @furtherDetails.
  ///
  /// In de, this message translates to:
  /// **'Weitere Angaben'**
  String get furtherDetails;

  /// No description provided for @warningsTitle.
  ///
  /// In de, this message translates to:
  /// **'Hinweise'**
  String get warningsTitle;

  /// No description provided for @notComparedNote.
  ///
  /// In de, this message translates to:
  /// **'Deine anderen Einträge sind nicht geladen. Überschneidungen, Pausen über mehrere Einträge und Ruhezeit werden erst beim Speichern geprüft.'**
  String get notComparedNote;

  /// No description provided for @errNoProject.
  ///
  /// In de, this message translates to:
  /// **'Bitte ein Projekt wählen'**
  String get errNoProject;

  /// No description provided for @errEndNotAfterStart.
  ///
  /// In de, this message translates to:
  /// **'Das Ende muss nach dem Beginn liegen'**
  String get errEndNotAfterStart;

  /// No description provided for @errLongerThan24h.
  ///
  /// In de, this message translates to:
  /// **'Die Dauer des Eintrags darf nicht länger als 24 Stunden sein'**
  String get errLongerThan24h;

  /// No description provided for @errBreakTooLong.
  ///
  /// In de, this message translates to:
  /// **'Die Pause darf nicht länger als der Eintrag sein'**
  String get errBreakTooLong;

  /// No description provided for @errSurchargeAboveWorking.
  ///
  /// In de, this message translates to:
  /// **'Darf nicht größer als die Arbeitszeit sein'**
  String get errSurchargeAboveWorking;

  /// No description provided for @errOverlap.
  ///
  /// In de, this message translates to:
  /// **'Eintrag überlappt mit anderen Einträgen'**
  String get errOverlap;

  /// No description provided for @errAbsenceBlocks.
  ///
  /// In de, this message translates to:
  /// **'An diesem Tag bist du abwesend. Deine Firma erlaubt dann keine Einträge.'**
  String get errAbsenceBlocks;

  /// No description provided for @errLocked.
  ///
  /// In de, this message translates to:
  /// **'Dieser Eintrag ist festgeschrieben oder abgerechnet und kann nicht geändert werden.'**
  String get errLocked;

  /// No description provided for @warnBreakTooShort.
  ///
  /// In de, this message translates to:
  /// **'Pause zu kurz: {minutes} Minuten sind vorgeschrieben.'**
  String warnBreakTooShort(int minutes);

  /// No description provided for @warnLongDay.
  ///
  /// In de, this message translates to:
  /// **'Mehr als {hours} Stunden Arbeit an diesem Tag.'**
  String warnLongDay(int hours);

  /// No description provided for @warnRestTooShort.
  ///
  /// In de, this message translates to:
  /// **'Ruhezeit nur {rest} statt {required} Stunden.'**
  String warnRestTooShort(String rest, String required);

  /// No description provided for @warnAbsenceDay.
  ///
  /// In de, this message translates to:
  /// **'An diesem Tag hast du eine Abwesenheit ({type}).'**
  String warnAbsenceDay(String type);

  /// No description provided for @warnNeedsApproval.
  ///
  /// In de, this message translates to:
  /// **'Dieser Eintrag muss genehmigt werden: er liegt mehr als {hours} Stunden zurück.'**
  String warnNeedsApproval(int hours);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
