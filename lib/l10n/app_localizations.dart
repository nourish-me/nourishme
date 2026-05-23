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
/// import 'l10n/app_localizations.dart';
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

  /// Used as MaterialApp.title and visible in the iOS multitasking switcher.
  ///
  /// In en, this message translates to:
  /// **'NourishMe'**
  String get appTitle;

  /// No description provided for @tabDiary.
  ///
  /// In en, this message translates to:
  /// **'Diary'**
  String get tabDiary;

  /// No description provided for @tabHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get tabHistory;

  /// No description provided for @tabTrends.
  ///
  /// In en, this message translates to:
  /// **'Trends'**
  String get tabTrends;

  /// No description provided for @todayHeader.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayHeader;

  /// No description provided for @settingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTooltip;

  /// No description provided for @emptyTodayHeadline.
  ///
  /// In en, this message translates to:
  /// **'What did you eat today?'**
  String get emptyTodayHeadline;

  /// No description provided for @emptyTodayBody.
  ///
  /// In en, this message translates to:
  /// **'Type away — the coach takes it from there.'**
  String get emptyTodayBody;

  /// No description provided for @emptyHistoryHeadline.
  ///
  /// In en, this message translates to:
  /// **'Your history starts today.'**
  String get emptyHistoryHeadline;

  /// No description provided for @emptyFavoritesHeadline.
  ///
  /// In en, this message translates to:
  /// **'No favourites yet.'**
  String get emptyFavoritesHeadline;

  /// No description provided for @emptyFavoritesBody.
  ///
  /// In en, this message translates to:
  /// **'When logging a meal, tap the star to save it as a favourite.'**
  String get emptyFavoritesBody;

  /// No description provided for @emptyFavoritesExample.
  ///
  /// In en, this message translates to:
  /// **'Yogurt with berries'**
  String get emptyFavoritesExample;

  /// No description provided for @emptySafetyEyebrow.
  ///
  /// In en, this message translates to:
  /// **'FOOD SAFETY · BFR'**
  String get emptySafetyEyebrow;

  /// No description provided for @emptySafetyHeadline.
  ///
  /// In en, this message translates to:
  /// **'All clear.'**
  String get emptySafetyHeadline;

  /// No description provided for @emptySafetyMercury.
  ///
  /// In en, this message translates to:
  /// **'Mercury'**
  String get emptySafetyMercury;

  /// No description provided for @emptySafetyMercuryNote.
  ///
  /// In en, this message translates to:
  /// **'ok'**
  String get emptySafetyMercuryNote;

  /// No description provided for @emptySafetyListeria.
  ///
  /// In en, this message translates to:
  /// **'Listeria risk'**
  String get emptySafetyListeria;

  /// No description provided for @emptySafetyListeriaNote.
  ///
  /// In en, this message translates to:
  /// **'pasteurised ok'**
  String get emptySafetyListeriaNote;

  /// No description provided for @emptySafetyCaffeine.
  ///
  /// In en, this message translates to:
  /// **'Caffeine'**
  String get emptySafetyCaffeine;

  /// No description provided for @emptySafetyCaffeineNote.
  ///
  /// In en, this message translates to:
  /// **'< 200 mg'**
  String get emptySafetyCaffeineNote;

  /// No description provided for @trendsTitle.
  ///
  /// In en, this message translates to:
  /// **'Trends'**
  String get trendsTitle;

  /// No description provided for @trendsWeekEyebrow.
  ///
  /// In en, this message translates to:
  /// **'LAST 7 DAYS'**
  String get trendsWeekEyebrow;

  /// No description provided for @trendsWeekTitle.
  ///
  /// In en, this message translates to:
  /// **'Calorie pattern'**
  String get trendsWeekTitle;

  /// No description provided for @trendsWeekSummary.
  ///
  /// In en, this message translates to:
  /// **'{inRange} of 7 days in target range · avg {avgKcal} kcal'**
  String trendsWeekSummary(int inRange, String avgKcal);

  /// No description provided for @trendsStreakEyebrow.
  ///
  /// In en, this message translates to:
  /// **'STREAK'**
  String get trendsStreakEyebrow;

  /// No description provided for @trendsStreakZero.
  ///
  /// In en, this message translates to:
  /// **'Today can be your first sweet-spot day.'**
  String get trendsStreakZero;

  /// No description provided for @trendsStreakOne.
  ///
  /// In en, this message translates to:
  /// **'1 day in the sweet spot.'**
  String get trendsStreakOne;

  /// No description provided for @trendsStreakMany.
  ///
  /// In en, this message translates to:
  /// **'{count} days in the sweet spot in a row.'**
  String trendsStreakMany(int count);

  /// No description provided for @trendsAveragesEyebrow.
  ///
  /// In en, this message translates to:
  /// **'WEEKLY AVERAGE'**
  String get trendsAveragesEyebrow;

  /// No description provided for @trendsAveragesTitle.
  ///
  /// In en, this message translates to:
  /// **'Per logged day'**
  String get trendsAveragesTitle;

  /// No description provided for @trendsLabelKcal.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get trendsLabelKcal;

  /// No description provided for @trendsLabelProtein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get trendsLabelProtein;

  /// No description provided for @trendsLabelCarbs.
  ///
  /// In en, this message translates to:
  /// **'Carbohydrates'**
  String get trendsLabelCarbs;

  /// No description provided for @trendsLabelFat.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get trendsLabelFat;

  /// No description provided for @trendsTargetPrefix.
  ///
  /// In en, this message translates to:
  /// **'Target {target}'**
  String trendsTargetPrefix(String target);

  /// No description provided for @trendsConsistencyEyebrow.
  ///
  /// In en, this message translates to:
  /// **'CONSISTENCY'**
  String get trendsConsistencyEyebrow;

  /// No description provided for @trendsConsistencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Tracking days'**
  String get trendsConsistencyTitle;

  /// No description provided for @trendsConsistencyEmpty.
  ///
  /// In en, this message translates to:
  /// **'Once you log your first meal, your tracking journey begins here.'**
  String get trendsConsistencyEmpty;

  /// No description provided for @trendsConsistencyBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ve been using NourishMe for {days} days, with entries on {trackedDays} days.'**
  String trendsConsistencyBody(int days, int trackedDays);

  /// No description provided for @trendsTopMealsEyebrow.
  ///
  /// In en, this message translates to:
  /// **'MOST FREQUENT MEALS'**
  String get trendsTopMealsEyebrow;

  /// No description provided for @trendsTopMealsTitle.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get trendsTopMealsTitle;

  /// No description provided for @historyNoEntries.
  ///
  /// In en, this message translates to:
  /// **'No entries yet'**
  String get historyNoEntries;

  /// No description provided for @historyKcalSeparator.
  ///
  /// In en, this message translates to:
  /// **'·'**
  String get historyKcalSeparator;

  /// No description provided for @confirmTitleNew.
  ///
  /// In en, this message translates to:
  /// **'Review and save'**
  String get confirmTitleNew;

  /// No description provided for @confirmTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get confirmTitleEdit;

  /// No description provided for @confirmSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get confirmSave;

  /// No description provided for @confirmCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get confirmCancel;

  /// No description provided for @confirmFieldPortion.
  ///
  /// In en, this message translates to:
  /// **'Portion'**
  String get confirmFieldPortion;

  /// No description provided for @confirmFieldKcal.
  ///
  /// In en, this message translates to:
  /// **'kcal'**
  String get confirmFieldKcal;

  /// No description provided for @confirmFieldProtein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get confirmFieldProtein;

  /// No description provided for @confirmFieldCarbs.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get confirmFieldCarbs;

  /// No description provided for @confirmFieldFat.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get confirmFieldFat;

  /// No description provided for @confirmAliasPrefix.
  ///
  /// In en, this message translates to:
  /// **'≈ {alias}'**
  String confirmAliasPrefix(String alias);

  /// No description provided for @confirmFavoriteAdd.
  ///
  /// In en, this message translates to:
  /// **'Save as favourite'**
  String get confirmFavoriteAdd;

  /// No description provided for @confirmFavoriteRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove favourite'**
  String get confirmFavoriteRemove;

  /// No description provided for @confirmDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get confirmDescriptionHint;

  /// No description provided for @confirmDetailsToggle.
  ///
  /// In en, this message translates to:
  /// **'Show details'**
  String get confirmDetailsToggle;

  /// No description provided for @confirmDetailsHide.
  ///
  /// In en, this message translates to:
  /// **'Hide details'**
  String get confirmDetailsHide;

  /// No description provided for @confirmDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get confirmDiscardTitle;

  /// No description provided for @confirmDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'Your unsaved changes will be lost.'**
  String get confirmDiscardBody;

  /// No description provided for @confirmDiscardAbort.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get confirmDiscardAbort;

  /// No description provided for @confirmDiscardConfirm.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get confirmDiscardConfirm;

  /// No description provided for @confirmHintsHeader.
  ///
  /// In en, this message translates to:
  /// **'Notes for this meal'**
  String get confirmHintsHeader;

  /// No description provided for @confirmSafetyHeader.
  ///
  /// In en, this message translates to:
  /// **'Please note'**
  String get confirmSafetyHeader;

  /// No description provided for @confirmCoachErrorFallback.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t get a coach reply. Try again later.'**
  String get confirmCoachErrorFallback;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;
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
