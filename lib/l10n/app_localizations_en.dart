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
}
