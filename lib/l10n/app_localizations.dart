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

  /// No description provided for @historyEntryCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 entry} other{{count} entries}}'**
  String historyEntryCount(int count);

  /// No description provided for @todayHeader.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayHeader;

  /// No description provided for @diaryFilterMealsOnly.
  ///
  /// In en, this message translates to:
  /// **'Meals only'**
  String get diaryFilterMealsOnly;

  /// No description provided for @diaryFilterShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get diaryFilterShowAll;

  /// No description provided for @diaryFilterOnMsg.
  ///
  /// In en, this message translates to:
  /// **'Meals only, coach replies hidden'**
  String get diaryFilterOnMsg;

  /// No description provided for @diaryFilterOffMsg.
  ///
  /// In en, this message translates to:
  /// **'Coach replies shown again'**
  String get diaryFilterOffMsg;

  /// No description provided for @yesterdayHeader.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterdayHeader;

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
  /// **'Type away, the coach takes it from there.'**
  String get emptyTodayBody;

  /// No description provided for @emptyPastDayHeadline.
  ///
  /// In en, this message translates to:
  /// **'Nothing logged'**
  String get emptyPastDayHeadline;

  /// No description provided for @emptyPastDayBody.
  ///
  /// In en, this message translates to:
  /// **'No entries for this day yet. You can add them now.'**
  String get emptyPastDayBody;

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

  /// No description provided for @trendsWeightEyebrow.
  ///
  /// In en, this message translates to:
  /// **'WEIGHT'**
  String get trendsWeightEyebrow;

  /// No description provided for @trendsWeightEmpty.
  ///
  /// In en, this message translates to:
  /// **'Update your weight in Settings to see the trajectory here.'**
  String get trendsWeightEmpty;

  /// No description provided for @trendsWeightSince.
  ///
  /// In en, this message translates to:
  /// **'Since {firstDate}'**
  String trendsWeightSince(String firstDate);

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

  /// No description provided for @confirmReparse.
  ///
  /// In en, this message translates to:
  /// **'Re-estimate'**
  String get confirmReparse;

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

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonGenericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get commonGenericError;

  /// No description provided for @commonSendError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send. Try again.'**
  String get commonSendError;

  /// No description provided for @homeOpenDayHelp.
  ///
  /// In en, this message translates to:
  /// **'Open day'**
  String get homeOpenDayHelp;

  /// No description provided for @homeCoachThinking.
  ///
  /// In en, this message translates to:
  /// **'Coach is thinking…'**
  String get homeCoachThinking;

  /// No description provided for @homeCoachLookingAtMeal.
  ///
  /// In en, this message translates to:
  /// **'Coach is looking at your meal…'**
  String get homeCoachLookingAtMeal;

  /// No description provided for @homePhotoTextHint.
  ///
  /// In en, this message translates to:
  /// **'Add amounts or notes (optional)'**
  String get homePhotoTextHint;

  /// No description provided for @settingsButtonShowTips.
  ///
  /// In en, this message translates to:
  /// **'Show tips again'**
  String get settingsButtonShowTips;

  /// No description provided for @bundlingToast.
  ///
  /// In en, this message translates to:
  /// **'Notice that? When you log several items quickly, the coach bundles them into one reply. Less noise in your diary.'**
  String get bundlingToast;

  /// No description provided for @confirmScanAnother.
  ///
  /// In en, this message translates to:
  /// **'Add another item'**
  String get confirmScanAnother;

  /// No description provided for @confirmAddByBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan a barcode'**
  String get confirmAddByBarcode;

  /// No description provided for @confirmAddByPhoto.
  ///
  /// In en, this message translates to:
  /// **'Take or pick a photo'**
  String get confirmAddByPhoto;

  /// No description provided for @confirmAddByText.
  ///
  /// In en, this message translates to:
  /// **'Type some text'**
  String get confirmAddByText;

  /// No description provided for @confirmAddTextSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Another item'**
  String get confirmAddTextSheetTitle;

  /// No description provided for @confirmAddTextSheetHint.
  ///
  /// In en, this message translates to:
  /// **'What else did you have?'**
  String get confirmAddTextSheetHint;

  /// No description provided for @confirmAddTextSheetCta.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get confirmAddTextSheetCta;

  /// No description provided for @confirmBundleHint.
  ///
  /// In en, this message translates to:
  /// **'Item {n} of this meal. The coach will analyse them together.'**
  String confirmBundleHint(int n);

  /// No description provided for @tipsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tips & Tricks'**
  String get tipsTitle;

  /// No description provided for @tipsSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get tipsSkip;

  /// No description provided for @tipsNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get tipsNext;

  /// No description provided for @tipsDone.
  ///
  /// In en, this message translates to:
  /// **'Let\'s go'**
  String get tipsDone;

  /// No description provided for @tipsCounter.
  ///
  /// In en, this message translates to:
  /// **'{current} of {total}'**
  String tipsCounter(int current, int total);

  /// No description provided for @tip1Title.
  ///
  /// In en, this message translates to:
  /// **'Photo + text nails it'**
  String get tip1Title;

  /// No description provided for @tip1Body.
  ///
  /// In en, this message translates to:
  /// **'Take a photo and add one or two words about what\'s on it. That way the app knows exactly which foods it\'s looking at. Far more accurate than a photo alone. Tip: instead of typing, tap the microphone on the iOS keyboard and dictate.'**
  String get tip1Body;

  /// No description provided for @tip2Title.
  ///
  /// In en, this message translates to:
  /// **'Barcode trains your brands'**
  String get tip2Title;

  /// No description provided for @tip2Body.
  ///
  /// In en, this message translates to:
  /// **'Scan the barcode for packaged products like skyr or cereal. You get exact values, and the app remembers what you buy often.'**
  String get tip2Body;

  /// No description provided for @tip3Title.
  ///
  /// In en, this message translates to:
  /// **'Your favourites are one tap away'**
  String get tip3Title;

  /// No description provided for @tip3Body.
  ///
  /// In en, this message translates to:
  /// **'Just type the first few letters (“Sky…”) and you\'ll see suggestions from your history. Tap → done, with the brand values from last time. The more you log, the better the app knows you.'**
  String get tip3Body;

  /// No description provided for @tip4Title.
  ///
  /// In en, this message translates to:
  /// **'Micros live in the diary'**
  String get tip4Title;

  /// No description provided for @tip4Body.
  ///
  /// In en, this message translates to:
  /// **'Tap a micro in the header for details. Pick which 3 appear under Settings → Coach & nutrition → Micronutrients. Taking a supplement? Snap its nutrition label and the app reads the values and folds them into your day total.'**
  String get tip4Body;

  /// No description provided for @tip5Title.
  ///
  /// In en, this message translates to:
  /// **'Log a missed meal later'**
  String get tip5Title;

  /// No description provided for @tip5Body.
  ///
  /// In en, this message translates to:
  /// **'Tap the day at the top of the diary and pick a date, then just write what you ate. Or log from Today and switch date and time on the \"Today · 08:24\" pill in the save sheet.'**
  String get tip5Body;

  /// No description provided for @tip6Title.
  ///
  /// In en, this message translates to:
  /// **'Just say what you ate'**
  String get tip6Title;

  /// No description provided for @tip6Body.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have to structure it as \"cappuccino 200 ml\". \"A cappuccino please\" or \"a bowl of cereal with berries\" is enough. The app figures out it\'s a meal, estimates a typical portion, and logs it.'**
  String get tip6Body;

  /// No description provided for @homeCoachBundling.
  ///
  /// In en, this message translates to:
  /// **'Coach is waiting briefly for more items… ({count})'**
  String homeCoachBundling(int count);

  /// No description provided for @homeEmptyRangeSingle.
  ///
  /// In en, this message translates to:
  /// **'{label} · no entries'**
  String homeEmptyRangeSingle(String label);

  /// No description provided for @homeEmptyRangeMulti.
  ///
  /// In en, this message translates to:
  /// **'{from} to {to} · {count} days without entries'**
  String homeEmptyRangeMulti(String from, String to, int count);

  /// No description provided for @homeEmptyDayText.
  ///
  /// In en, this message translates to:
  /// **'No entries'**
  String get homeEmptyDayText;

  /// No description provided for @homeEmptyDayTextPast.
  ///
  /// In en, this message translates to:
  /// **'Nothing was logged on this day'**
  String get homeEmptyDayTextPast;

  /// No description provided for @homeCoachPausedNote.
  ///
  /// In en, this message translates to:
  /// **'Coach is paused for past days'**
  String get homeCoachPausedNote;

  /// No description provided for @homeCoachOnlyTodayHint.
  ///
  /// In en, this message translates to:
  /// **'Coach questions only work for today - switch to Today at the top.'**
  String get homeCoachOnlyTodayHint;

  /// No description provided for @confirmPastDaySavedToast.
  ///
  /// In en, this message translates to:
  /// **'Entry saved · Coach paused for past days'**
  String get confirmPastDaySavedToast;

  /// No description provided for @homeEmptyDayAdd.
  ///
  /// In en, this message translates to:
  /// **'add'**
  String get homeEmptyDayAdd;

  /// No description provided for @homeEmptyRangePickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Which day?'**
  String get homeEmptyRangePickerTitle;

  /// No description provided for @homeEmptyRangePickerHint.
  ///
  /// In en, this message translates to:
  /// **'Pick the day you want to log into. You\'ll choose the time next.'**
  String get homeEmptyRangePickerHint;

  /// No description provided for @homeScrollToTop.
  ///
  /// In en, this message translates to:
  /// **'Jump to top'**
  String get homeScrollToTop;

  /// No description provided for @homeScrollToBottom.
  ///
  /// In en, this message translates to:
  /// **'Jump to today'**
  String get homeScrollToBottom;

  /// No description provided for @homeTimePickerHelp.
  ///
  /// In en, this message translates to:
  /// **'Pick a time'**
  String get homeTimePickerHelp;

  /// No description provided for @homeDatePickerHelp.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get homeDatePickerHelp;

  /// No description provided for @settingsWeightLoggedOn.
  ///
  /// In en, this message translates to:
  /// **'Weighed on: {date}'**
  String settingsWeightLoggedOn(String date);

  /// No description provided for @homeTimeSuffix.
  ///
  /// In en, this message translates to:
  /// **''**
  String get homeTimeSuffix;

  /// No description provided for @homePastDayHeader.
  ///
  /// In en, this message translates to:
  /// **'Entry for {day}'**
  String homePastDayHeader(String day);

  /// No description provided for @homePastDayBody.
  ///
  /// In en, this message translates to:
  /// **'What did you eat or drink?'**
  String get homePastDayBody;

  /// No description provided for @homePastDayInputHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. cereal with yogurt, one bowl'**
  String get homePastDayInputHint;

  /// No description provided for @homeContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get homeContinue;

  /// No description provided for @homePhotoCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get homePhotoCamera;

  /// No description provided for @homePhotoGallery.
  ///
  /// In en, this message translates to:
  /// **'Photo Library'**
  String get homePhotoGallery;

  /// No description provided for @homePhotoButton.
  ///
  /// In en, this message translates to:
  /// **'Add a photo'**
  String get homePhotoButton;

  /// No description provided for @scanButton.
  ///
  /// In en, this message translates to:
  /// **'Scan barcode'**
  String get scanButton;

  /// No description provided for @scanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan barcode'**
  String get scanTitle;

  /// No description provided for @scanHint.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at the product\'s barcode'**
  String get scanHint;

  /// No description provided for @scanNotFound.
  ///
  /// In en, this message translates to:
  /// **'Product not found. Just type the meal instead.'**
  String get scanNotFound;

  /// No description provided for @homeMainInputHint.
  ///
  /// In en, this message translates to:
  /// **'Log a meal / ask the coach'**
  String get homeMainInputHint;

  /// No description provided for @homeMealDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{summary}\"?'**
  String homeMealDeleteTitle(String summary);

  /// No description provided for @homePhotoNotFoodError.
  ///
  /// In en, this message translates to:
  /// **'That photo doesn\'t look like food. Describe it as text or try another photo.'**
  String get homePhotoNotFoodError;

  /// No description provided for @homeMealHintsHeader.
  ///
  /// In en, this message translates to:
  /// **'Notes for this meal'**
  String get homeMealHintsHeader;

  /// No description provided for @favoriteRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{summary}\"?'**
  String favoriteRemoveTitle(String summary);

  /// No description provided for @favoriteRemoveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get favoriteRemoveConfirm;

  /// No description provided for @reminderChannelName.
  ///
  /// In en, this message translates to:
  /// **'Meal reminders'**
  String get reminderChannelName;

  /// No description provided for @reminderChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Daily reminders to log your meals.'**
  String get reminderChannelDescription;

  /// No description provided for @reminderBreakfastTitle.
  ///
  /// In en, this message translates to:
  /// **'Breakfast?'**
  String get reminderBreakfastTitle;

  /// No description provided for @reminderBreakfastBody.
  ///
  /// In en, this message translates to:
  /// **'If you\'ve already had something, type your meal in.'**
  String get reminderBreakfastBody;

  /// No description provided for @reminderMidmorningTitle.
  ///
  /// In en, this message translates to:
  /// **'Mid-morning snack?'**
  String get reminderMidmorningTitle;

  /// No description provided for @reminderMidmorningBody.
  ///
  /// In en, this message translates to:
  /// **'Apple, yogurt, a bun? Type your meal in.'**
  String get reminderMidmorningBody;

  /// No description provided for @reminderLunchTitle.
  ///
  /// In en, this message translates to:
  /// **'Lunchtime.'**
  String get reminderLunchTitle;

  /// No description provided for @reminderLunchBody.
  ///
  /// In en, this message translates to:
  /// **'The coach is waiting for your meal.'**
  String get reminderLunchBody;

  /// No description provided for @reminderMidafternoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Anything in between?'**
  String get reminderMidafternoonTitle;

  /// No description provided for @reminderMidafternoonBody.
  ///
  /// In en, this message translates to:
  /// **'Type your meal in so you\'ve got the day covered.'**
  String get reminderMidafternoonBody;

  /// No description provided for @reminderDinnerTitle.
  ///
  /// In en, this message translates to:
  /// **'Dinner logged?'**
  String get reminderDinnerTitle;

  /// No description provided for @reminderDinnerBody.
  ///
  /// In en, this message translates to:
  /// **'Last entry today and you\'re done.'**
  String get reminderDinnerBody;

  /// No description provided for @reminderSlotBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get reminderSlotBreakfast;

  /// No description provided for @reminderSlotMidmorning.
  ///
  /// In en, this message translates to:
  /// **'Mid-morning snack'**
  String get reminderSlotMidmorning;

  /// No description provided for @reminderSlotLunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get reminderSlotLunch;

  /// No description provided for @reminderSlotMidafternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon snack'**
  String get reminderSlotMidafternoon;

  /// No description provided for @reminderSlotDinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get reminderSlotDinner;

  /// No description provided for @feedbackMailSubject.
  ///
  /// In en, this message translates to:
  /// **'NourishMe feedback'**
  String get feedbackMailSubject;

  /// No description provided for @feedbackMailTriageHint.
  ///
  /// In en, this message translates to:
  /// **'Please don\'t edit below, it helps with triage.'**
  String get feedbackMailTriageHint;

  /// No description provided for @feedbackMailDeviceLabel.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get feedbackMailDeviceLabel;

  /// No description provided for @reminderPermissionBlocked.
  ///
  /// In en, this message translates to:
  /// **'Notifications are blocked in iOS Settings.'**
  String get reminderPermissionBlocked;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsHubAboutYou.
  ///
  /// In en, this message translates to:
  /// **'About you'**
  String get settingsHubAboutYou;

  /// No description provided for @settingsHubAboutYouSummary.
  ///
  /// In en, this message translates to:
  /// **'Profile, phase, activity'**
  String get settingsHubAboutYouSummary;

  /// No description provided for @settingsHubCoach.
  ///
  /// In en, this message translates to:
  /// **'Coach & nutrition'**
  String get settingsHubCoach;

  /// No description provided for @settingsHubCoachSummary.
  ///
  /// In en, this message translates to:
  /// **'Goal, macros, micros, supplements'**
  String get settingsHubCoachSummary;

  /// No description provided for @settingsHubApp.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get settingsHubApp;

  /// No description provided for @settingsHubAppSummary.
  ///
  /// In en, this message translates to:
  /// **'Reminders, favourites, theme'**
  String get settingsHubAppSummary;

  /// No description provided for @settingsSectionProfile.
  ///
  /// In en, this message translates to:
  /// **'Your profile'**
  String get settingsSectionProfile;

  /// No description provided for @settingsSectionPhase.
  ///
  /// In en, this message translates to:
  /// **'Current phase'**
  String get settingsSectionPhase;

  /// No description provided for @settingsSectionMilk.
  ///
  /// In en, this message translates to:
  /// **'Breast milk'**
  String get settingsSectionMilk;

  /// No description provided for @settingsSectionActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity level'**
  String get settingsSectionActivity;

  /// No description provided for @settingsSectionMacros.
  ///
  /// In en, this message translates to:
  /// **'Macro split'**
  String get settingsSectionMacros;

  /// No description provided for @settingsSectionReminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get settingsSectionReminders;

  /// No description provided for @settingsSectionTheme.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsSectionTheme;

  /// No description provided for @settingsSectionPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsSectionPrivacy;

  /// No description provided for @settingsAnalyticsToggle.
  ///
  /// In en, this message translates to:
  /// **'Anonymous usage statistics'**
  String get settingsAnalyticsToggle;

  /// No description provided for @settingsAnalyticsHint.
  ///
  /// In en, this message translates to:
  /// **'Helps us improve the app. Fully anonymous, no personal data or meal contents, can be turned off anytime.'**
  String get settingsAnalyticsHint;

  /// No description provided for @settingsSectionFavorites.
  ///
  /// In en, this message translates to:
  /// **'Manage favourites'**
  String get settingsSectionFavorites;

  /// No description provided for @settingsFieldBirthdate.
  ///
  /// In en, this message translates to:
  /// **'Your date of birth'**
  String get settingsFieldBirthdate;

  /// No description provided for @settingsFieldHeight.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get settingsFieldHeight;

  /// No description provided for @settingsFieldWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get settingsFieldWeight;

  /// No description provided for @settingsFieldHeightSuffix.
  ///
  /// In en, this message translates to:
  /// **'cm'**
  String get settingsFieldHeightSuffix;

  /// No description provided for @settingsFieldWeightSuffix.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get settingsFieldWeightSuffix;

  /// No description provided for @settingsBirthdatePickerHelp.
  ///
  /// In en, this message translates to:
  /// **'Pick your date of birth'**
  String get settingsBirthdatePickerHelp;

  /// No description provided for @settingsButtonFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get settingsButtonFeedback;

  /// No description provided for @settingsButtonReset.
  ///
  /// In en, this message translates to:
  /// **'Reset app'**
  String get settingsButtonReset;

  /// No description provided for @settingsButtonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get settingsButtonSave;

  /// No description provided for @settingsResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset app?'**
  String get settingsResetTitle;

  /// No description provided for @settingsResetBody.
  ///
  /// In en, this message translates to:
  /// **'All entries, favourites and your profile will be deleted. You\'ll start with onboarding again.'**
  String get settingsResetBody;

  /// No description provided for @settingsResetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get settingsResetConfirm;

  /// No description provided for @settingsSavedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Profile saved'**
  String get settingsSavedSnackbar;

  /// No description provided for @settingsPhaseLactating.
  ///
  /// In en, this message translates to:
  /// **'Producing milk'**
  String get settingsPhaseLactating;

  /// No description provided for @settingsPhaseLactatingHint.
  ///
  /// In en, this message translates to:
  /// **'Breastfeeding or pumping'**
  String get settingsPhaseLactatingHint;

  /// No description provided for @settingsPhasePregnant.
  ///
  /// In en, this message translates to:
  /// **'Pregnant'**
  String get settingsPhasePregnant;

  /// No description provided for @settingsPhasePregnantHint.
  ///
  /// In en, this message translates to:
  /// **'Currently pregnant'**
  String get settingsPhasePregnantHint;

  /// No description provided for @settingsPhaseTrimester.
  ///
  /// In en, this message translates to:
  /// **'Trimester'**
  String get settingsPhaseTrimester;

  /// No description provided for @settingsMilkChildren.
  ///
  /// In en, this message translates to:
  /// **'Children you\'re feeding milk to'**
  String get settingsMilkChildren;

  /// No description provided for @settingsMilkAgeLabel.
  ///
  /// In en, this message translates to:
  /// **'Age of the children'**
  String get settingsMilkAgeLabel;

  /// No description provided for @settingsMilkVolume.
  ///
  /// In en, this message translates to:
  /// **'Breast milk you produce per day'**
  String get settingsMilkVolume;

  /// No description provided for @settingsMilkVolumePerDay.
  ///
  /// In en, this message translates to:
  /// **'{volume} ml/day → +{supplement} kcal/day'**
  String settingsMilkVolumePerDay(int volume, int supplement);

  /// No description provided for @settingsMilkVolumeInfoSummary.
  ///
  /// In en, this message translates to:
  /// **'Synthesis cost: ~0.84 kcal per ml of milk.'**
  String get settingsMilkVolumeInfoSummary;

  /// No description provided for @settingsMilkVolumeInfoDetail.
  ///
  /// In en, this message translates to:
  /// **'If you pump and know your volume, enter it exactly. Otherwise the share slider above gives an estimate.'**
  String get settingsMilkVolumeInfoDetail;

  /// No description provided for @settingsMilkVolumeInfoSource.
  ///
  /// In en, this message translates to:
  /// **'DGE 2025, EFSA 2017'**
  String get settingsMilkVolumeInfoSource;

  /// No description provided for @settingsActivityInfoSummary.
  ///
  /// In en, this message translates to:
  /// **'Influences daily expenditure (PAL factor)'**
  String get settingsActivityInfoSummary;

  /// No description provided for @settingsActivityInfoDetail.
  ///
  /// In en, this message translates to:
  /// **'Low 1.2: barely moving. Moderate 1.375: walks, light housework. Active 1.55: regular training. High 1.725: intense training or physical labour. With a baby at home, usually \"Moderate\".'**
  String get settingsActivityInfoDetail;

  /// No description provided for @settingsActivityInfoSource.
  ///
  /// In en, this message translates to:
  /// **'DGE PAL classification'**
  String get settingsActivityInfoSource;

  /// No description provided for @activityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get activityLow;

  /// No description provided for @activityLowHint.
  ///
  /// In en, this message translates to:
  /// **'Barely any movement'**
  String get activityLowHint;

  /// No description provided for @activityModerate.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get activityModerate;

  /// No description provided for @activityModerateHint.
  ///
  /// In en, this message translates to:
  /// **'Walks, light housework'**
  String get activityModerateHint;

  /// No description provided for @activityActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activityActive;

  /// No description provided for @activityActiveHint.
  ///
  /// In en, this message translates to:
  /// **'Regular training'**
  String get activityActiveHint;

  /// No description provided for @activityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get activityHigh;

  /// No description provided for @activityHighHint.
  ///
  /// In en, this message translates to:
  /// **'Intense training, physical work'**
  String get activityHighHint;

  /// No description provided for @childAge0to6.
  ///
  /// In en, this message translates to:
  /// **'0–6 mo'**
  String get childAge0to6;

  /// No description provided for @childAge0to6Hint.
  ///
  /// In en, this message translates to:
  /// **'Full milk demand'**
  String get childAge0to6Hint;

  /// No description provided for @childAge6to12.
  ///
  /// In en, this message translates to:
  /// **'6–12 mo'**
  String get childAge6to12;

  /// No description provided for @childAge6to12Hint.
  ///
  /// In en, this message translates to:
  /// **'With solids'**
  String get childAge6to12Hint;

  /// No description provided for @childAge12plus.
  ///
  /// In en, this message translates to:
  /// **'12+ mo'**
  String get childAge12plus;

  /// No description provided for @childAge12plusHint.
  ///
  /// In en, this message translates to:
  /// **'Extended breastfeeding'**
  String get childAge12plusHint;

  /// No description provided for @settingsMacroTitle.
  ///
  /// In en, this message translates to:
  /// **'Macro split'**
  String get settingsMacroTitle;

  /// No description provided for @settingsMacroInfoSummary.
  ///
  /// In en, this message translates to:
  /// **'Protein / fat / carbs as % of daily kcal'**
  String get settingsMacroInfoSummary;

  /// No description provided for @settingsMacroInfoDetail.
  ///
  /// In en, this message translates to:
  /// **'Default split per DGE: protein from your weight (1.2 g/kg in lactation), fat ~30% of kcal, carbs make up the rest. You can adjust protein and fat for a specific diet (low-carb, high-protein). Carbs always rebalance to 100%.'**
  String get settingsMacroInfoDetail;

  /// No description provided for @settingsMacroProtein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get settingsMacroProtein;

  /// No description provided for @settingsMacroFat.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get settingsMacroFat;

  /// No description provided for @settingsMacroCarbs.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get settingsMacroCarbs;

  /// No description provided for @settingsMacroCarbsAuto.
  ///
  /// In en, this message translates to:
  /// **'auto'**
  String get settingsMacroCarbsAuto;

  /// No description provided for @settingsMacroResetAuto.
  ///
  /// In en, this message translates to:
  /// **'Reset to auto'**
  String get settingsMacroResetAuto;

  /// No description provided for @settingsMacroAutoLabel.
  ///
  /// In en, this message translates to:
  /// **'(auto {percent} %)'**
  String settingsMacroAutoLabel(int percent);

  /// No description provided for @settingsOutcomeBase.
  ///
  /// In en, this message translates to:
  /// **'Base + activity'**
  String get settingsOutcomeBase;

  /// No description provided for @settingsOutcomePregnancy.
  ///
  /// In en, this message translates to:
  /// **'Pregnancy (T{trimester})'**
  String settingsOutcomePregnancy(int trimester);

  /// No description provided for @settingsOutcomeLactation.
  ///
  /// In en, this message translates to:
  /// **'Milk supplement'**
  String get settingsOutcomeLactation;

  /// No description provided for @themeAuto.
  ///
  /// In en, this message translates to:
  /// **'Follows device setting'**
  String get themeAuto;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @settingsReminderToggleTitle.
  ///
  /// In en, this message translates to:
  /// **'Meal reminders'**
  String get settingsReminderToggleTitle;

  /// No description provided for @settingsReminderToggleOn.
  ///
  /// In en, this message translates to:
  /// **'On. Set what you want to hear and when.'**
  String get settingsReminderToggleOn;

  /// No description provided for @settingsReminderToggleOff.
  ///
  /// In en, this message translates to:
  /// **'Off. Turning on will ask iOS for permission once.'**
  String get settingsReminderToggleOff;

  /// No description provided for @settingsErrorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String settingsErrorPrefix(String message);

  /// No description provided for @settingsMilkChildSingular.
  ///
  /// In en, this message translates to:
  /// **'Age of the child'**
  String get settingsMilkChildSingular;

  /// No description provided for @settingsMilkChildPlural.
  ///
  /// In en, this message translates to:
  /// **'Ages of the children'**
  String get settingsMilkChildPlural;

  /// No description provided for @settingsMilkShareSingular.
  ///
  /// In en, this message translates to:
  /// **'Breast milk share: {percent}%'**
  String settingsMilkShareSingular(int percent);

  /// No description provided for @settingsMilkSharePlural.
  ///
  /// In en, this message translates to:
  /// **'Breast milk share per baby: {percent}%'**
  String settingsMilkSharePlural(int percent);

  /// No description provided for @settingsMilkVolumePerDayLabel.
  ///
  /// In en, this message translates to:
  /// **'{volume} ml/day → +{supplement} kcal/day'**
  String settingsMilkVolumePerDayLabel(int volume, int supplement);

  /// No description provided for @settingsMilkVolumeInfoTopic.
  ///
  /// In en, this message translates to:
  /// **'Daily milk volume'**
  String get settingsMilkVolumeInfoTopic;

  /// No description provided for @settingsMilkVolumeInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Energy = volume × 0.84 kcal/ml'**
  String get settingsMilkVolumeInfoTitle;

  /// No description provided for @settingsTodayTarget.
  ///
  /// In en, this message translates to:
  /// **'Your daily target'**
  String get settingsTodayTarget;

  /// No description provided for @settingsMacroCarbsRemainder.
  ///
  /// In en, this message translates to:
  /// **'Carbs (remainder)'**
  String get settingsMacroCarbsRemainder;

  /// No description provided for @settingsMacroSliderValue.
  ///
  /// In en, this message translates to:
  /// **'{percent} % · {grams}g · {kcal} kcal'**
  String settingsMacroSliderValue(int percent, int grams, int kcal);

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeSystemHint.
  ///
  /// In en, this message translates to:
  /// **'Follows device setting'**
  String get themeSystemHint;

  /// No description provided for @themeLightHint.
  ///
  /// In en, this message translates to:
  /// **'Light theme'**
  String get themeLightHint;

  /// No description provided for @themeDarkHint.
  ///
  /// In en, this message translates to:
  /// **'Dark theme'**
  String get themeDarkHint;

  /// No description provided for @settingsReminderTimeFormat.
  ///
  /// In en, this message translates to:
  /// **'{hour}:{minute}'**
  String settingsReminderTimeFormat(String hour, String minute);

  /// No description provided for @infoBackgroundTooltip.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get infoBackgroundTooltip;

  /// No description provided for @onboardingRestartTitle.
  ///
  /// In en, this message translates to:
  /// **'Restart onboarding?'**
  String get onboardingRestartTitle;

  /// No description provided for @onboardingRestartBody.
  ///
  /// In en, this message translates to:
  /// **'Your inputs so far will be discarded.'**
  String get onboardingRestartBody;

  /// No description provided for @onboardingRestartConfirm.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get onboardingRestartConfirm;

  /// No description provided for @onboardingRestartTooltip.
  ///
  /// In en, this message translates to:
  /// **'Restart onboarding'**
  String get onboardingRestartTooltip;

  /// No description provided for @onboardingStepIndicator.
  ///
  /// In en, this message translates to:
  /// **'STEP {step} OF {total}'**
  String onboardingStepIndicator(int step, int total);

  /// No description provided for @onboardingButtonNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingButtonNext;

  /// No description provided for @onboardingButtonStart.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingButtonStart;

  /// No description provided for @onboardingFooterEditLater.
  ///
  /// In en, this message translates to:
  /// **'You can change every value later in settings.'**
  String get onboardingFooterEditLater;

  /// No description provided for @onboardingTagline.
  ///
  /// In en, this message translates to:
  /// **'Nutrition that does the math.'**
  String get onboardingTagline;

  /// No description provided for @onboardingSubline.
  ///
  /// In en, this message translates to:
  /// **'A live coach for pregnancy and breastfeeding. Evidence-based, privacy-friendly, no calorie-counting fuss.'**
  String get onboardingSubline;

  /// No description provided for @onboardingWelcomeReassurance.
  ///
  /// In en, this message translates to:
  /// **'No pressure: everything you enter now can be changed anytime in settings.'**
  String get onboardingWelcomeReassurance;

  /// No description provided for @onboardingPhaseQuestion.
  ///
  /// In en, this message translates to:
  /// **'Which phase are you in?'**
  String get onboardingPhaseQuestion;

  /// No description provided for @onboardingPhaseExplainer.
  ///
  /// In en, this message translates to:
  /// **'We use this to calculate your energy supplement and protein target.'**
  String get onboardingPhaseExplainer;

  /// No description provided for @onboardingPhaseLactation.
  ///
  /// In en, this message translates to:
  /// **'Breastfeeding'**
  String get onboardingPhaseLactation;

  /// No description provided for @onboardingPhaseLactationHint.
  ///
  /// In en, this message translates to:
  /// **'You\'re producing breast milk (nursing or pumping)'**
  String get onboardingPhaseLactationHint;

  /// No description provided for @onboardingPhasePregnancy.
  ///
  /// In en, this message translates to:
  /// **'Pregnancy'**
  String get onboardingPhasePregnancy;

  /// No description provided for @onboardingPhasePregnancyHint.
  ///
  /// In en, this message translates to:
  /// **'Currently pregnant'**
  String get onboardingPhasePregnancyHint;

  /// No description provided for @onboardingPhaseBothNote.
  ///
  /// In en, this message translates to:
  /// **'Pregnancy and breastfeeding supplements will be added together.'**
  String get onboardingPhaseBothNote;

  /// No description provided for @onboardingBasicsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your basic data'**
  String get onboardingBasicsTitle;

  /// No description provided for @onboardingBasicsInfoTopic.
  ///
  /// In en, this message translates to:
  /// **'Basic data'**
  String get onboardingBasicsInfoTopic;

  /// No description provided for @onboardingBasicsInfoSummary.
  ///
  /// In en, this message translates to:
  /// **'Needed to calculate your basal metabolic rate'**
  String get onboardingBasicsInfoSummary;

  /// No description provided for @onboardingBasicsInfoDetail.
  ///
  /// In en, this message translates to:
  /// **'We use the Mifflin-St Jeor formula to estimate your daily basal metabolic rate. That plus your activity factor plus the pregnancy/breastfeeding supplement gives your daily target.'**
  String get onboardingBasicsInfoDetail;

  /// No description provided for @onboardingBasicsInfoSource.
  ///
  /// In en, this message translates to:
  /// **'Mifflin-St Jeor 1990, DGE'**
  String get onboardingBasicsInfoSource;

  /// No description provided for @onboardingActivityHintBaby.
  ///
  /// In en, this message translates to:
  /// **'With a baby at home, usually \"Moderate\". Adjust when you go back to more sport.'**
  String get onboardingActivityHintBaby;

  /// No description provided for @onboardingDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get onboardingDetailsTitle;

  /// No description provided for @onboardingVolumeShareQuestionSingular.
  ///
  /// In en, this message translates to:
  /// **'What\'s your share of the feeding?'**
  String get onboardingVolumeShareQuestionSingular;

  /// No description provided for @onboardingVolumeShareQuestionPlural.
  ///
  /// In en, this message translates to:
  /// **'What\'s your share per child?'**
  String get onboardingVolumeShareQuestionPlural;

  /// No description provided for @onboardingVolumeInfoDetail.
  ///
  /// In en, this message translates to:
  /// **'Energy cost of milk synthesis is ~0.84 kcal per ml. Typical volumes: single 0-6mo ~780 ml/day, twins ~1500 ml/day, 6-12mo ~575 ml, >12mo ~300 ml. If you pump and know your volume, enter it exactly.'**
  String get onboardingVolumeInfoDetail;

  /// No description provided for @onboardingResultEyebrow.
  ///
  /// In en, this message translates to:
  /// **'CALCULATION'**
  String get onboardingResultEyebrow;

  /// No description provided for @onboardingResultMacrosEyebrow.
  ///
  /// In en, this message translates to:
  /// **'MACRONUTRIENTS · DAILY TARGET'**
  String get onboardingResultMacrosEyebrow;

  /// No description provided for @onboardingLedeBase.
  ///
  /// In en, this message translates to:
  /// **'Base + activity: {kcal} kcal'**
  String onboardingLedeBase(String kcal);

  /// No description provided for @onboardingLedePregnancy.
  ///
  /// In en, this message translates to:
  /// **'+ {kcal} kcal pregnancy (T{trimester})'**
  String onboardingLedePregnancy(String kcal, int trimester);

  /// No description provided for @onboardingLedeLactation.
  ///
  /// In en, this message translates to:
  /// **'+ {kcal} kcal breastfeeding'**
  String onboardingLedeLactation(String kcal);

  /// No description provided for @onboardingRemindersDetail.
  ///
  /// In en, this message translates to:
  /// **'Five slots across the day. iOS will ask once for permission when you tap \"Open diary\".'**
  String get onboardingRemindersDetail;

  /// No description provided for @onboardingDisclaimerTitle.
  ///
  /// In en, this message translates to:
  /// **'Briefly: not medical advice.'**
  String get onboardingDisclaimerTitle;

  /// No description provided for @onboardingDisclaimerBody.
  ///
  /// In en, this message translates to:
  /// **'NourishMe is a personal wellness tool, not a medical device. For medical questions, talk to your doctor or midwife. For allergies or pre-existing conditions, double-check coach suggestions yourself.'**
  String get onboardingDisclaimerBody;

  /// No description provided for @onboardingDisclaimerLink.
  ///
  /// In en, this message translates to:
  /// **'More details'**
  String get onboardingDisclaimerLink;

  /// No description provided for @settingsSectionDiet.
  ///
  /// In en, this message translates to:
  /// **'Diet & allergies'**
  String get settingsSectionDiet;

  /// No description provided for @settingsDietStyleLabel.
  ///
  /// In en, this message translates to:
  /// **'Diet style'**
  String get settingsDietStyleLabel;

  /// No description provided for @dietStyleOmnivore.
  ///
  /// In en, this message translates to:
  /// **'Omnivore'**
  String get dietStyleOmnivore;

  /// No description provided for @dietStyleVegetarian.
  ///
  /// In en, this message translates to:
  /// **'Vegetarian'**
  String get dietStyleVegetarian;

  /// No description provided for @dietStyleVegan.
  ///
  /// In en, this message translates to:
  /// **'Vegan'**
  String get dietStyleVegan;

  /// No description provided for @dietStylePescatarian.
  ///
  /// In en, this message translates to:
  /// **'Pescatarian'**
  String get dietStylePescatarian;

  /// No description provided for @settingsDietVeganPhaseHint.
  ///
  /// In en, this message translates to:
  /// **'Vegan during pregnancy or breastfeeding needs deliberate supplementation: B12 cannot be covered through food (a daily supplement is essential), DHA from algae oil (200-300 mg/day), plus attention to iodine, iron, choline and vitamin D. Talk to your midwife or a registered nutrition professional. The coach now watches for these gaps proactively.'**
  String get settingsDietVeganPhaseHint;

  /// No description provided for @settingsDietRestrictionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Avoid'**
  String get settingsDietRestrictionsLabel;

  /// No description provided for @settingsDietRestrictionsHint.
  ///
  /// In en, this message translates to:
  /// **'Tap any that apply. The coach won\'t suggest these.'**
  String get settingsDietRestrictionsHint;

  /// No description provided for @restrictionLactose.
  ///
  /// In en, this message translates to:
  /// **'Lactose'**
  String get restrictionLactose;

  /// No description provided for @restrictionGluten.
  ///
  /// In en, this message translates to:
  /// **'Gluten'**
  String get restrictionGluten;

  /// No description provided for @restrictionEggs.
  ///
  /// In en, this message translates to:
  /// **'Eggs'**
  String get restrictionEggs;

  /// No description provided for @restrictionNuts.
  ///
  /// In en, this message translates to:
  /// **'Nuts'**
  String get restrictionNuts;

  /// No description provided for @restrictionFish.
  ///
  /// In en, this message translates to:
  /// **'Fish'**
  String get restrictionFish;

  /// No description provided for @restrictionShellfish.
  ///
  /// In en, this message translates to:
  /// **'Shellfish'**
  String get restrictionShellfish;

  /// No description provided for @restrictionSoy.
  ///
  /// In en, this message translates to:
  /// **'Soy'**
  String get restrictionSoy;

  /// No description provided for @settingsDietNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Note for the coach (optional)'**
  String get settingsDietNotesLabel;

  /// No description provided for @settingsDietNotesHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. histamine sensitive, no spicy food'**
  String get settingsDietNotesHint;

  /// No description provided for @factEnergyLactationTopic.
  ///
  /// In en, this message translates to:
  /// **'Energy supplement, breastfeeding phase'**
  String get factEnergyLactationTopic;

  /// No description provided for @factEnergyLactationSummary.
  ///
  /// In en, this message translates to:
  /// **'~84 kcal per 100 ml of milk'**
  String get factEnergyLactationSummary;

  /// No description provided for @factEnergyLactationDetail.
  ///
  /// In en, this message translates to:
  /// **'Energy density of breast milk 0.67 kcal/g × synthesis efficiency 80% = ~84 kcal per 100 ml. Typical volumes: exclusive 0-6 mo ~780 ml/day, 6-12 mo ~550 ml, >12 mo ~200-400 ml. Twins exclusive: ~1,500 ml (+~1,100 kcal). DGE flat rate: +500 kcal for one child 0-6 mo.'**
  String get factEnergyLactationDetail;

  /// No description provided for @factEnergyLactationSource.
  ///
  /// In en, this message translates to:
  /// **'DGE 2025, EFSA 2017, WHO/FAO 2004'**
  String get factEnergyLactationSource;

  /// No description provided for @factEnergyPregnancyTopic.
  ///
  /// In en, this message translates to:
  /// **'Energy supplement, pregnancy'**
  String get factEnergyPregnancyTopic;

  /// No description provided for @factEnergyPregnancySummary.
  ///
  /// In en, this message translates to:
  /// **'T1: 0, T2: +250, T3: +500 kcal/day'**
  String get factEnergyPregnancySummary;

  /// No description provided for @factEnergyPregnancyDetail.
  ///
  /// In en, this message translates to:
  /// **'Assumes pre-pregnancy BMI 18.5-24.9 and unchanged activity. With multiples: +300 kcal per additional fetus (ACOG rule of thumb), so twins in T3 about +800 kcal.'**
  String get factEnergyPregnancyDetail;

  /// No description provided for @factEnergyPregnancySource.
  ///
  /// In en, this message translates to:
  /// **'DGE 2025, EFSA, ACOG'**
  String get factEnergyPregnancySource;

  /// No description provided for @factProteinLactationTopic.
  ///
  /// In en, this message translates to:
  /// **'Protein requirement'**
  String get factProteinLactationTopic;

  /// No description provided for @factProteinLactationSummary.
  ///
  /// In en, this message translates to:
  /// **'Lactation: 1.2 g/kg body weight/day (DGE)'**
  String get factProteinLactationSummary;

  /// No description provided for @factProteinLactationDetail.
  ///
  /// In en, this message translates to:
  /// **'Non-pregnant baseline: 0.8 g/kg. Pregnancy T2: 0.9 g/kg, T3: 1.0 g/kg. Lactation 0-6 mo: 1.2 g/kg (about +23 g/day above baseline). Good sources: lean meat, fish, legumes, eggs, dairy, tofu.'**
  String get factProteinLactationDetail;

  /// No description provided for @factProteinLactationSource.
  ///
  /// In en, this message translates to:
  /// **'DGE 2025, EFSA 2012'**
  String get factProteinLactationSource;

  /// No description provided for @kcalRemainingPositive.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal left'**
  String kcalRemainingPositive(String kcal);

  /// No description provided for @kcalRemainingZero.
  ///
  /// In en, this message translates to:
  /// **'Target reached'**
  String get kcalRemainingZero;

  /// No description provided for @kcalRemainingNegative.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal over target'**
  String kcalRemainingNegative(String kcal);

  /// No description provided for @kcalCombined.
  ///
  /// In en, this message translates to:
  /// **'{current} / {target} kcal'**
  String kcalCombined(String current, String target);

  /// No description provided for @macroLabelProtein.
  ///
  /// In en, this message translates to:
  /// **'P'**
  String get macroLabelProtein;

  /// No description provided for @macroLabelCarbs.
  ///
  /// In en, this message translates to:
  /// **'C'**
  String get macroLabelCarbs;

  /// No description provided for @macroLabelFat.
  ///
  /// In en, this message translates to:
  /// **'F'**
  String get macroLabelFat;

  /// No description provided for @nutritionMacroProtein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get nutritionMacroProtein;

  /// No description provided for @nutritionMacroCarbs.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get nutritionMacroCarbs;

  /// No description provided for @nutritionMacroFat.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get nutritionMacroFat;

  /// No description provided for @nutritionHeaderKcalTarget.
  ///
  /// In en, this message translates to:
  /// **' kcal target'**
  String get nutritionHeaderKcalTarget;

  /// No description provided for @macroDetailKcalName.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get macroDetailKcalName;

  /// No description provided for @macroDetailProteinName.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get macroDetailProteinName;

  /// No description provided for @macroDetailCarbsName.
  ///
  /// In en, this message translates to:
  /// **'Carbohydrates'**
  String get macroDetailCarbsName;

  /// No description provided for @macroDetailFatName.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get macroDetailFatName;

  /// No description provided for @macroDetailRemaining.
  ///
  /// In en, this message translates to:
  /// **'{value} {unit} to go'**
  String macroDetailRemaining(String value, String unit);

  /// No description provided for @macroDetailMet.
  ///
  /// In en, this message translates to:
  /// **'Target met'**
  String get macroDetailMet;

  /// No description provided for @macroDetailOver.
  ///
  /// In en, this message translates to:
  /// **'{value} {unit} over target'**
  String macroDetailOver(String value, String unit);

  /// No description provided for @macroDetailSweetNote.
  ///
  /// In en, this message translates to:
  /// **'On target. More isn\'t better here, {target} {unit} is your daily goal.'**
  String macroDetailSweetNote(String target, String unit);

  /// No description provided for @macroDetailOverNote.
  ///
  /// In en, this message translates to:
  /// **'{name} over today\'s target. No stress, single days balance out.'**
  String macroDetailOverNote(String name);

  /// No description provided for @macroDetailNeutralNote.
  ///
  /// In en, this message translates to:
  /// **'Building toward {target} {unit}.'**
  String macroDetailNeutralNote(String target, String unit);

  /// No description provided for @nutritionDetailContributions.
  ///
  /// In en, this message translates to:
  /// **'Today\'s contributions'**
  String get nutritionDetailContributions;

  /// No description provided for @nutritionDetailNoContributions.
  ///
  /// In en, this message translates to:
  /// **'No entries today yet.'**
  String get nutritionDetailNoContributions;

  /// No description provided for @nutritionDetailClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get nutritionDetailClose;

  /// No description provided for @microDetailTwinDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Twins: data is limited, target values are extrapolated from singleton recommendations. Please coordinate with your midwife or doctor.'**
  String get microDetailTwinDisclaimer;

  /// No description provided for @microDetailAwarenessNote.
  ///
  /// In en, this message translates to:
  /// **'No DGE reference value. The number shown is an EFSA estimate (Adequate Intake), meant for orientation rather than a fixed target.'**
  String get microDetailAwarenessNote;

  /// No description provided for @microDetailMilkDependentTitle.
  ///
  /// In en, this message translates to:
  /// **'Reaches your baby'**
  String get microDetailMilkDependentTitle;

  /// No description provided for @microDetailBufferedTitle.
  ///
  /// In en, this message translates to:
  /// **'Your reserves'**
  String get microDetailBufferedTitle;

  /// No description provided for @microDetailMilkDependentBody.
  ///
  /// In en, this message translates to:
  /// **'{name} passes directly into your milk, what you eat reaches your baby.'**
  String microDetailMilkDependentBody(String name);

  /// No description provided for @microDetailBufferedBody.
  ///
  /// In en, this message translates to:
  /// **'Your milk\'s {name} stays stable, drawn from your own reserves. Mind yourself.'**
  String microDetailBufferedBody(String name);

  /// No description provided for @microDetailNoContributions.
  ///
  /// In en, this message translates to:
  /// **'No entries with {name} today yet.'**
  String microDetailNoContributions(String name);

  /// No description provided for @microDetailSourceHeader.
  ///
  /// In en, this message translates to:
  /// **'Source & target'**
  String get microDetailSourceHeader;

  /// No description provided for @infoSourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get infoSourceLabel;

  /// No description provided for @settingsSectionMicronutrients.
  ///
  /// In en, this message translates to:
  /// **'Micronutrients in header'**
  String get settingsSectionMicronutrients;

  /// No description provided for @settingsMicrosDescription.
  ///
  /// In en, this message translates to:
  /// **'Which micronutrients to show at the top of the diary. Max 3. When nothing is selected, the app uses the recommendation for your phase.'**
  String get settingsMicrosDescription;

  /// No description provided for @settingsMicrosUsingDefaults.
  ///
  /// In en, this message translates to:
  /// **'Currently using the phase recommendation.'**
  String get settingsMicrosUsingDefaults;

  /// No description provided for @settingsMicrosMaxReached.
  ///
  /// In en, this message translates to:
  /// **'3 of 3 selected'**
  String get settingsMicrosMaxReached;

  /// No description provided for @settingsMicrosReset.
  ///
  /// In en, this message translates to:
  /// **'Reset to phase recommendation'**
  String get settingsMicrosReset;

  /// No description provided for @settingsMilkBirthdateLabel.
  ///
  /// In en, this message translates to:
  /// **'Birth date (youngest child)'**
  String get settingsMilkBirthdateLabel;

  /// No description provided for @settingsMilkBirthdatePick.
  ///
  /// In en, this message translates to:
  /// **'Pick birth date'**
  String get settingsMilkBirthdatePick;

  /// No description provided for @settingsMilkBirthdateClear.
  ///
  /// In en, this message translates to:
  /// **'Clear birth date'**
  String get settingsMilkBirthdateClear;

  /// No description provided for @settingsMilkBirthdateAuto.
  ///
  /// In en, this message translates to:
  /// **'Age bucket follows automatically.'**
  String get settingsMilkBirthdateAuto;

  /// No description provided for @settingsMilkBirthdatePickerHelp.
  ///
  /// In en, this message translates to:
  /// **'When was your (youngest) child born?'**
  String get settingsMilkBirthdatePickerHelp;

  /// No description provided for @settingsMilkBirthdateUseBucket.
  ///
  /// In en, this message translates to:
  /// **'Pick the age bracket instead?'**
  String get settingsMilkBirthdateUseBucket;

  /// No description provided for @settingsMilkBirthdateBackToDate.
  ///
  /// In en, this message translates to:
  /// **'More precise with a birth date?'**
  String get settingsMilkBirthdateBackToDate;

  /// No description provided for @settingsMilkBirthdateAgeMonthsOne.
  ///
  /// In en, this message translates to:
  /// **'1 month old'**
  String get settingsMilkBirthdateAgeMonthsOne;

  /// No description provided for @settingsMilkBirthdateAgeMonths.
  ///
  /// In en, this message translates to:
  /// **'{months} months old'**
  String settingsMilkBirthdateAgeMonths(int months);

  /// No description provided for @settingsSectionGoal.
  ///
  /// In en, this message translates to:
  /// **'Coach focus'**
  String get settingsSectionGoal;

  /// No description provided for @settingsGoalHint.
  ///
  /// In en, this message translates to:
  /// **'What should the coach optimise for? Details and safety guardrails behind the info icon.'**
  String get settingsGoalHint;

  /// No description provided for @settingsGoalNutrients.
  ///
  /// In en, this message translates to:
  /// **'Nutrients'**
  String get settingsGoalNutrients;

  /// No description provided for @settingsGoalBody.
  ///
  /// In en, this message translates to:
  /// **'Body goal'**
  String get settingsGoalBody;

  /// No description provided for @settingsGoalBoth.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get settingsGoalBoth;

  /// No description provided for @settingsGoalMacroImplication.
  ///
  /// In en, this message translates to:
  /// **'More protein to preserve muscle in a deficit. Visible and adjustable in the Macros section.'**
  String get settingsGoalMacroImplication;

  /// No description provided for @settingsPhaseNeither.
  ///
  /// In en, this message translates to:
  /// **'Neither'**
  String get settingsPhaseNeither;

  /// No description provided for @settingsPhaseNeitherHint.
  ///
  /// In en, this message translates to:
  /// **'Currently neither pregnant nor producing breast milk, e.g. after weaning or before a pregnancy.'**
  String get settingsPhaseNeitherHint;

  /// No description provided for @onboardingPhaseNeither.
  ///
  /// In en, this message translates to:
  /// **'Neither'**
  String get onboardingPhaseNeither;

  /// No description provided for @onboardingPhaseNeitherHint.
  ///
  /// In en, this message translates to:
  /// **'I\'m neither pregnant nor producing breast milk.'**
  String get onboardingPhaseNeitherHint;

  /// No description provided for @onboardingGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'What do you want to focus on?'**
  String get onboardingGoalTitle;

  /// No description provided for @onboardingGoalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can change this any time in Settings.'**
  String get onboardingGoalSubtitle;

  /// No description provided for @coachIngredientsReplyHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. zucchini, chicken'**
  String get coachIngredientsReplyHint;

  /// No description provided for @coachIngredientsSavedSnack.
  ///
  /// In en, this message translates to:
  /// **'Noted. I\'ll factor it in next time.'**
  String get coachIngredientsSavedSnack;

  /// No description provided for @supplementSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Supplement'**
  String get supplementSectionTitle;

  /// No description provided for @supplementOnboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Are you taking a supplement?'**
  String get supplementOnboardingTitle;

  /// No description provided for @supplementOnboardingBody.
  ///
  /// In en, this message translates to:
  /// **'Folic acid, prenatal multivitamin, or similar? Snap a photo of the nutrition table on the back of the box and the app adds the values to your daily totals automatically.'**
  String get supplementOnboardingBody;

  /// No description provided for @supplementAddCta.
  ///
  /// In en, this message translates to:
  /// **'Photograph nutrition table'**
  String get supplementAddCta;

  /// No description provided for @supplementSkipCta.
  ///
  /// In en, this message translates to:
  /// **'No, not taking one'**
  String get supplementSkipCta;

  /// No description provided for @supplementSourceCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get supplementSourceCamera;

  /// No description provided for @supplementSourceGallery.
  ///
  /// In en, this message translates to:
  /// **'From gallery'**
  String get supplementSourceGallery;

  /// No description provided for @supplementParsing.
  ///
  /// In en, this message translates to:
  /// **'Reading label...'**
  String get supplementParsing;

  /// No description provided for @supplementReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Check the values'**
  String get supplementReviewTitle;

  /// No description provided for @supplementReviewHint.
  ///
  /// In en, this message translates to:
  /// **'Values from your label. You can edit the name and amounts before saving.'**
  String get supplementReviewHint;

  /// No description provided for @supplementFieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get supplementFieldName;

  /// No description provided for @supplementFieldDoses.
  ///
  /// In en, this message translates to:
  /// **'Doses per day'**
  String get supplementFieldDoses;

  /// No description provided for @supplementSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get supplementSave;

  /// No description provided for @supplementCancel.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get supplementCancel;

  /// No description provided for @supplementRetry.
  ///
  /// In en, this message translates to:
  /// **'Different photo'**
  String get supplementRetry;

  /// No description provided for @supplementRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove supplement'**
  String get supplementRemove;

  /// No description provided for @supplementEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get supplementEdit;

  /// No description provided for @supplementEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit supplement'**
  String get supplementEditTitle;

  /// No description provided for @supplementEditHint.
  ///
  /// In en, this message translates to:
  /// **'Adjust name, doses or values directly. No new photo needed.'**
  String get supplementEditHint;

  /// No description provided for @supplementAddAnotherCta.
  ///
  /// In en, this message translates to:
  /// **'Add another supplement'**
  String get supplementAddAnotherCta;

  /// No description provided for @supplementCurrentLabel.
  ///
  /// In en, this message translates to:
  /// **'Current: {name}'**
  String supplementCurrentLabel(String name);

  /// No description provided for @supplementCurrentDoses.
  ///
  /// In en, this message translates to:
  /// **'{doses} doses per day'**
  String supplementCurrentDoses(int doses);

  /// No description provided for @factGoalTopic.
  ///
  /// In en, this message translates to:
  /// **'Coach focus'**
  String get factGoalTopic;

  /// No description provided for @factGoalSummary.
  ///
  /// In en, this message translates to:
  /// **'Nutrients vs. body goal: what changes'**
  String get factGoalSummary;

  /// No description provided for @factGoalDetail.
  ///
  /// In en, this message translates to:
  /// **'Nutrients (default): coach optimises only for adequate supply, no deficit talk.\n\nBody goal/Both: coach is allowed to suggest moderate deficits, but only under clear safety guardrails - never below 1,800 kcal/day in lactation, deficit max 300-500 kcal/day, at the earliest 6-8 weeks postpartum, NEVER a deficit in pregnancy, micronutrients and protein stay on target. On workout days raise protein instead of widening the deficit. One nudge to coordinate with midwife or doctor.\n\nIn the app header the protein target is raised (lactation: 1.5 g/kg instead of 1.2; otherwise 1.6 g/kg instead of 0.8) for muscle preservation during the deficit. Carbs and fat stay.'**
  String get factGoalDetail;

  /// No description provided for @factGoalSource.
  ///
  /// In en, this message translates to:
  /// **'Guardrails validated by a registered nutrition professional (Diätassistentin) June 2026, based on DGE 2025, EFSA 2017, CDC. Body-goal protein bump: standard recomp recommendation (1.5-1.8 g/kg), defensive within the lactation range'**
  String get factGoalSource;
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
