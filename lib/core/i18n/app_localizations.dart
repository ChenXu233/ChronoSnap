import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'i18n/app_localizations.dart';
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
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'ChronoSnap'**
  String get appTitle;

  /// No description provided for @projectList.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get projectList;

  /// No description provided for @createProject.
  ///
  /// In en, this message translates to:
  /// **'Create Project'**
  String get createProject;

  /// No description provided for @projectName.
  ///
  /// In en, this message translates to:
  /// **'Project Name'**
  String get projectName;

  /// No description provided for @projectNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter project name'**
  String get projectNameHint;

  /// No description provided for @shootingInterval.
  ///
  /// In en, this message translates to:
  /// **'Shooting Interval'**
  String get shootingInterval;

  /// No description provided for @intervalSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds} seconds'**
  String intervalSeconds(Object seconds);

  /// No description provided for @intervalMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes'**
  String intervalMinutes(Object minutes);

  /// No description provided for @intervalHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours'**
  String intervalHours(Object hours);

  /// No description provided for @totalShots.
  ///
  /// In en, this message translates to:
  /// **'Total Shots'**
  String get totalShots;

  /// No description provided for @totalShotsHint.
  ///
  /// In en, this message translates to:
  /// **'Number of photos to take'**
  String get totalShotsHint;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes'**
  String durationMinutes(Object minutes);

  /// No description provided for @cameraSettings.
  ///
  /// In en, this message translates to:
  /// **'Camera Settings'**
  String get cameraSettings;

  /// No description provided for @lockFocus.
  ///
  /// In en, this message translates to:
  /// **'Lock Focus'**
  String get lockFocus;

  /// No description provided for @lockExposure.
  ///
  /// In en, this message translates to:
  /// **'Lock Exposure'**
  String get lockExposure;

  /// No description provided for @autoWhiteBalance.
  ///
  /// In en, this message translates to:
  /// **'Auto White Balance'**
  String get autoWhiteBalance;

  /// No description provided for @startShooting.
  ///
  /// In en, this message translates to:
  /// **'Start Shooting'**
  String get startShooting;

  /// No description provided for @stopShooting.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopShooting;

  /// No description provided for @projectRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get projectRunning;

  /// No description provided for @projectCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get projectCompleted;

  /// No description provided for @projectIdle.
  ///
  /// In en, this message translates to:
  /// **'Idle'**
  String get projectIdle;

  /// No description provided for @completedShots.
  ///
  /// In en, this message translates to:
  /// **'Completed: {count}'**
  String completedShots(Object count);

  /// No description provided for @nextShot.
  ///
  /// In en, this message translates to:
  /// **'Next shot: {time}'**
  String nextShot(Object time);

  /// No description provided for @currentBattery.
  ///
  /// In en, this message translates to:
  /// **'Battery: {level}%'**
  String currentBattery(Object level);

  /// No description provided for @deleteProject.
  ///
  /// In en, this message translates to:
  /// **'Delete Project'**
  String get deleteProject;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this project?'**
  String get confirmDelete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied'**
  String get permissionDenied;

  /// No description provided for @cameraPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Camera permission is required'**
  String get cameraPermissionRequired;

  /// No description provided for @storagePermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Storage permission is required'**
  String get storagePermissionRequired;

  /// No description provided for @noProjects.
  ///
  /// In en, this message translates to:
  /// **'No projects yet'**
  String get noProjects;

  /// No description provided for @tapToCreate.
  ///
  /// In en, this message translates to:
  /// **'Tap + to create a project'**
  String get tapToCreate;
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
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
