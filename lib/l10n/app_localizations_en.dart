// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'NourishMe';

  @override
  String get tabDiary => 'Diary';

  @override
  String get tabHistory => 'History';

  @override
  String get tabTrends => 'Trends';

  @override
  String get todayHeader => 'Today';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get emptyTodayHeadline => 'What did you eat today?';

  @override
  String get emptyTodayBody => 'Type away — the coach takes it from there.';

  @override
  String get emptyHistoryHeadline => 'Your history starts today.';

  @override
  String get emptyFavoritesHeadline => 'No favourites yet.';

  @override
  String get emptyFavoritesBody =>
      'When logging a meal, tap the star to save it as a favourite.';

  @override
  String get emptyFavoritesExample => 'Yogurt with berries';

  @override
  String get emptySafetyEyebrow => 'FOOD SAFETY · BFR';

  @override
  String get emptySafetyHeadline => 'All clear.';

  @override
  String get emptySafetyMercury => 'Mercury';

  @override
  String get emptySafetyMercuryNote => 'ok';

  @override
  String get emptySafetyListeria => 'Listeria risk';

  @override
  String get emptySafetyListeriaNote => 'pasteurised ok';

  @override
  String get emptySafetyCaffeine => 'Caffeine';

  @override
  String get emptySafetyCaffeineNote => '< 200 mg';

  @override
  String get trendsTitle => 'Trends';

  @override
  String get trendsWeekEyebrow => 'LAST 7 DAYS';

  @override
  String get trendsWeekTitle => 'Calorie pattern';

  @override
  String trendsWeekSummary(int inRange, String avgKcal) {
    return '$inRange of 7 days in target range · avg $avgKcal kcal';
  }

  @override
  String get trendsStreakEyebrow => 'STREAK';

  @override
  String get trendsStreakZero => 'Today can be your first sweet-spot day.';

  @override
  String get trendsStreakOne => '1 day in the sweet spot.';

  @override
  String trendsStreakMany(int count) {
    return '$count days in the sweet spot in a row.';
  }

  @override
  String get trendsAveragesEyebrow => 'WEEKLY AVERAGE';

  @override
  String get trendsAveragesTitle => 'Per logged day';

  @override
  String get trendsLabelKcal => 'Calories';

  @override
  String get trendsLabelProtein => 'Protein';

  @override
  String get trendsLabelCarbs => 'Carbohydrates';

  @override
  String get trendsLabelFat => 'Fat';

  @override
  String trendsTargetPrefix(String target) {
    return 'Target $target';
  }

  @override
  String get trendsConsistencyEyebrow => 'CONSISTENCY';

  @override
  String get trendsConsistencyTitle => 'Tracking days';

  @override
  String get trendsConsistencyEmpty =>
      'Once you log your first meal, your tracking journey begins here.';

  @override
  String trendsConsistencyBody(int days, int trackedDays) {
    return 'You\'ve been using NourishMe for $days days, with entries on $trackedDays days.';
  }

  @override
  String get trendsTopMealsEyebrow => 'MOST FREQUENT MEALS';

  @override
  String get trendsTopMealsTitle => 'Last 7 days';

  @override
  String get historyNoEntries => 'No entries yet';

  @override
  String get historyKcalSeparator => '·';

  @override
  String get confirmTitleNew => 'Review and save';

  @override
  String get confirmTitleEdit => 'Edit';

  @override
  String get confirmSave => 'Save';

  @override
  String get confirmCancel => 'Cancel';

  @override
  String get confirmFieldPortion => 'Portion';

  @override
  String get confirmFieldKcal => 'kcal';

  @override
  String get confirmFieldProtein => 'Protein';

  @override
  String get confirmFieldCarbs => 'Carbs';

  @override
  String get confirmFieldFat => 'Fat';

  @override
  String confirmAliasPrefix(String alias) {
    return '≈ $alias';
  }

  @override
  String get confirmFavoriteAdd => 'Save as favourite';

  @override
  String get confirmFavoriteRemove => 'Remove favourite';

  @override
  String get confirmDescriptionHint => 'Description';

  @override
  String get confirmDetailsToggle => 'Show details';

  @override
  String get confirmDetailsHide => 'Hide details';

  @override
  String get confirmDiscardTitle => 'Discard changes?';

  @override
  String get confirmDiscardBody => 'Your unsaved changes will be lost.';

  @override
  String get confirmDiscardAbort => 'Cancel';

  @override
  String get confirmDiscardConfirm => 'Discard';

  @override
  String get confirmHintsHeader => 'Notes for this meal';

  @override
  String get confirmSafetyHeader => 'Please note';

  @override
  String get confirmCoachErrorFallback =>
      'Couldn\'t get a coach reply. Try again later.';

  @override
  String get commonDone => 'Done';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonGenericError => 'Something went wrong. Try again.';

  @override
  String get commonSendError => 'Couldn\'t send. Try again.';

  @override
  String get homeOpenDayHelp => 'Open day';

  @override
  String get homeCoachThinking => 'Coach is thinking…';

  @override
  String homeEmptyRangeSingle(String label) {
    return '$label · no entries';
  }

  @override
  String homeEmptyRangeMulti(String from, String to, int count) {
    return '$from — $to · $count days without entries';
  }

  @override
  String get homeEmptyDayText => 'No entries';

  @override
  String get homeEmptyDayAdd => 'add';

  @override
  String get homeTimePickerHelp => 'Pick a time';

  @override
  String get homeTimeSuffix => '';

  @override
  String homePastDayHeader(String day) {
    return 'Entry for $day';
  }

  @override
  String get homePastDayBody => 'What did you eat or drink?';

  @override
  String get homePastDayInputHint => 'e.g. cereal with yogurt, one bowl';

  @override
  String get homeContinue => 'Continue';

  @override
  String get homePhotoCamera => 'Camera';

  @override
  String get homePhotoGallery => 'Photo Library';

  @override
  String get homePhotoButton => 'Add a photo';

  @override
  String get homeMainInputHint => 'Log a meal / ask the coach';

  @override
  String homeMealDeleteTitle(String summary) {
    return 'Delete \"$summary\"?';
  }

  @override
  String get homePhotoNotFoodError =>
      'That photo doesn\'t look like food. Describe it as text or try another photo.';

  @override
  String get homeMealHintsHeader => 'Notes for this meal';

  @override
  String favoriteRemoveTitle(String summary) {
    return 'Remove \"$summary\"?';
  }

  @override
  String get favoriteRemoveConfirm => 'Remove';

  @override
  String get reminderChannelName => 'Meal reminders';

  @override
  String get reminderChannelDescription => 'Daily reminders to log your meals.';

  @override
  String get reminderBreakfastTitle => 'Breakfast?';

  @override
  String get reminderBreakfastBody =>
      'If you\'ve already had something, type your meal in.';

  @override
  String get reminderMidmorningTitle => 'Mid-morning snack?';

  @override
  String get reminderMidmorningBody =>
      'Apple, yogurt, a bun? Type your meal in.';

  @override
  String get reminderLunchTitle => 'Lunchtime.';

  @override
  String get reminderLunchBody => 'The coach is waiting for your meal.';

  @override
  String get reminderMidafternoonTitle => 'Anything in between?';

  @override
  String get reminderMidafternoonBody =>
      'Type your meal in so you\'ve got the day covered.';

  @override
  String get reminderDinnerTitle => 'Dinner logged?';

  @override
  String get reminderDinnerBody => 'Last entry today and you\'re done.';

  @override
  String get reminderSlotBreakfast => 'Breakfast';

  @override
  String get reminderSlotMidmorning => 'Mid-morning snack';

  @override
  String get reminderSlotLunch => 'Lunch';

  @override
  String get reminderSlotMidafternoon => 'Afternoon snack';

  @override
  String get reminderSlotDinner => 'Dinner';

  @override
  String get feedbackMailSubject => 'NourishMe feedback';

  @override
  String get feedbackMailTriageHint =>
      'Please don\'t edit below — it helps with triage.';

  @override
  String get feedbackMailDeviceLabel => 'Device';

  @override
  String get reminderPermissionBlocked =>
      'Notifications are blocked in iOS Settings.';
}
