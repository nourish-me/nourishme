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
  String historyEntryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '1 entry',
    );
    return '$_temp0';
  }

  @override
  String get todayHeader => 'Today';

  @override
  String get diaryFilterMealsOnly => 'Meals only';

  @override
  String get diaryFilterShowAll => 'Show all';

  @override
  String get diaryFilterOnMsg => 'Meals only, coach replies hidden';

  @override
  String get diaryFilterOffMsg => 'Coach replies shown again';

  @override
  String get yesterdayHeader => 'Yesterday';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get emptyTodayHeadline => 'What did you eat today?';

  @override
  String get emptyTodayBody => 'Type away, the coach takes it from there.';

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
  String get trendsWeightEyebrow => 'WEIGHT';

  @override
  String get trendsWeightEmpty =>
      'Update your weight in Settings to see the trajectory here.';

  @override
  String trendsWeightSince(String firstDate) {
    return 'Since $firstDate';
  }

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
  String get confirmReparse => 'Re-estimate';

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
  String get homeCoachLookingAtMeal => 'Coach is looking at your meal…';

  @override
  String get homePhotoTextHint => 'Add amounts or notes (optional)';

  @override
  String get settingsButtonShowTips => 'Show tips again';

  @override
  String get bundlingToast =>
      'Notice that? When you log several items quickly, the coach bundles them into one reply. Less noise in your diary.';

  @override
  String get tipsTitle => 'Tips & Tricks';

  @override
  String get tipsSkip => 'Skip';

  @override
  String get tipsNext => 'Next';

  @override
  String get tipsDone => 'Let\'s go';

  @override
  String tipsCounter(int current, int total) {
    return '$current of $total';
  }

  @override
  String get tip1Title => 'Photo + text nails it';

  @override
  String get tip1Body =>
      'Take a photo and add one or two words about what\'s on it. That way the app knows exactly which foods it\'s looking at. Far more accurate than a photo alone. Tip: instead of typing, tap the microphone on the iOS keyboard and dictate.';

  @override
  String get tip2Title => 'Barcode trains your brands';

  @override
  String get tip2Body =>
      'Scan the barcode for packaged products like skyr or cereal. You get exact values, and the app remembers what you buy often.';

  @override
  String get tip3Title => 'Your favourites are one tap away';

  @override
  String get tip3Body =>
      'Just type the first few letters (“Sky…”) and you\'ll see suggestions from your history. Tap → done, with the brand values from last time. The more you log, the better the app knows you.';

  @override
  String get tip4Title => 'Coach replies are tappable';

  @override
  String get tip4Body =>
      'Some coach replies have chip suggestions beneath them. Tap one → the question is already half-typed in your input.';

  @override
  String get tip5Title => 'Log a missed meal later';

  @override
  String get tip5Body =>
      'Tap a past day in your diary → you can set the date and time and log the meal retroactively.';

  @override
  String homeCoachBundling(int count) {
    return 'Coach is waiting briefly for more items… ($count)';
  }

  @override
  String homeEmptyRangeSingle(String label) {
    return '$label · no entries';
  }

  @override
  String homeEmptyRangeMulti(String from, String to, int count) {
    return '$from to $to · $count days without entries';
  }

  @override
  String get homeEmptyDayText => 'No entries';

  @override
  String get homeEmptyDayAdd => 'add';

  @override
  String get homeEmptyRangePickerTitle => 'Which day?';

  @override
  String get homeEmptyRangePickerHint =>
      'Pick the day you want to log into. You\'ll choose the time next.';

  @override
  String get homeScrollToTop => 'Jump to top';

  @override
  String get homeScrollToBottom => 'Jump to today';

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
  String get scanButton => 'Scan barcode';

  @override
  String get scanTitle => 'Scan barcode';

  @override
  String get scanHint => 'Point the camera at the product\'s barcode';

  @override
  String get scanNotFound => 'Product not found. Just type the meal instead.';

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
      'Please don\'t edit below, it helps with triage.';

  @override
  String get feedbackMailDeviceLabel => 'Device';

  @override
  String get reminderPermissionBlocked =>
      'Notifications are blocked in iOS Settings.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionProfile => 'Your profile';

  @override
  String get settingsSectionPhase => 'Current phase';

  @override
  String get settingsSectionMilk => 'Breast milk';

  @override
  String get settingsSectionActivity => 'Activity level';

  @override
  String get settingsSectionMacros => 'Macro split';

  @override
  String get settingsSectionReminders => 'Reminders';

  @override
  String get settingsSectionTheme => 'Appearance';

  @override
  String get settingsSectionPrivacy => 'Privacy';

  @override
  String get settingsAnalyticsToggle => 'Anonymous usage statistics';

  @override
  String get settingsAnalyticsHint =>
      'Helps us improve the app. Fully anonymous, no personal data or meal contents, can be turned off anytime.';

  @override
  String get settingsSectionFavorites => 'Manage favourites';

  @override
  String get settingsFieldBirthdate => 'Date of birth';

  @override
  String get settingsFieldHeight => 'Height';

  @override
  String get settingsFieldWeight => 'Weight';

  @override
  String get settingsFieldHeightSuffix => 'cm';

  @override
  String get settingsFieldWeightSuffix => 'kg';

  @override
  String get settingsBirthdatePickerHelp => 'Pick your date of birth';

  @override
  String get settingsButtonFeedback => 'Send feedback';

  @override
  String get settingsButtonReset => 'Reset app';

  @override
  String get settingsButtonSave => 'Save';

  @override
  String get settingsResetTitle => 'Reset app?';

  @override
  String get settingsResetBody =>
      'All entries, favourites and your profile will be deleted. You\'ll start with onboarding again.';

  @override
  String get settingsResetConfirm => 'Reset';

  @override
  String get settingsSavedSnackbar => 'Profile saved';

  @override
  String get settingsPhaseLactating => 'Producing milk';

  @override
  String get settingsPhaseLactatingHint => 'Breastfeeding or pumping';

  @override
  String get settingsPhasePregnant => 'Pregnant';

  @override
  String get settingsPhasePregnantHint => 'Currently pregnant';

  @override
  String get settingsPhaseTrimester => 'Trimester';

  @override
  String get settingsMilkChildren => 'Children you\'re feeding milk to';

  @override
  String get settingsMilkAgeLabel => 'Age of the children';

  @override
  String get settingsMilkVolume => 'Estimated daily volume';

  @override
  String settingsMilkVolumePerDay(int volume, int supplement) {
    return '$volume ml/day → +$supplement kcal/day';
  }

  @override
  String get settingsMilkVolumeInfoSummary =>
      'Synthesis cost: ~0.84 kcal per ml of milk.';

  @override
  String get settingsMilkVolumeInfoDetail =>
      'If you pump and know your volume, enter it exactly. Otherwise the share slider above gives an estimate.';

  @override
  String get settingsMilkVolumeInfoSource => 'DGE 2025, EFSA 2017';

  @override
  String get settingsActivityInfoSummary =>
      'Influences daily expenditure (PAL factor)';

  @override
  String get settingsActivityInfoDetail =>
      'Low 1.2: barely moving. Moderate 1.375: walks, light housework. Active 1.55: regular training. High 1.725: intense training or physical labour. With a baby at home, usually \"Moderate\".';

  @override
  String get settingsActivityInfoSource => 'DGE PAL classification';

  @override
  String get activityLow => 'Low';

  @override
  String get activityLowHint => 'Barely any movement';

  @override
  String get activityModerate => 'Medium';

  @override
  String get activityModerateHint => 'Walks, light housework';

  @override
  String get activityActive => 'Active';

  @override
  String get activityActiveHint => 'Regular training';

  @override
  String get activityHigh => 'High';

  @override
  String get activityHighHint => 'Intense training, physical work';

  @override
  String get childAge0to6 => '0–6 mo';

  @override
  String get childAge0to6Hint => 'Full milk demand';

  @override
  String get childAge6to12 => '6–12 mo';

  @override
  String get childAge6to12Hint => 'With solids';

  @override
  String get childAge12plus => '12+ mo';

  @override
  String get childAge12plusHint => 'Extended breastfeeding';

  @override
  String get settingsMacroTitle => 'Macro split';

  @override
  String get settingsMacroInfoSummary =>
      'Protein / fat / carbs as % of daily kcal';

  @override
  String get settingsMacroInfoDetail =>
      'Default split per DGE: protein from your weight (1.2 g/kg in lactation), fat ~30% of kcal, carbs make up the rest. You can adjust protein and fat for a specific diet (low-carb, high-protein). Carbs always rebalance to 100%.';

  @override
  String get settingsMacroProtein => 'Protein';

  @override
  String get settingsMacroFat => 'Fat';

  @override
  String get settingsMacroCarbs => 'Carbs';

  @override
  String get settingsMacroCarbsAuto => 'auto';

  @override
  String get settingsMacroResetAuto => 'Reset to auto';

  @override
  String settingsMacroAutoLabel(int percent) {
    return '(auto $percent %)';
  }

  @override
  String get settingsOutcomeBase => 'Base + activity';

  @override
  String settingsOutcomePregnancy(int trimester) {
    return 'Pregnancy (T$trimester)';
  }

  @override
  String get settingsOutcomeLactation => 'Milk supplement';

  @override
  String get themeAuto => 'Follows device setting';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsReminderToggleTitle => 'Meal reminders';

  @override
  String get settingsReminderToggleOn =>
      'On. Set what you want to hear and when.';

  @override
  String get settingsReminderToggleOff =>
      'Off. Turning on will ask iOS for permission once.';

  @override
  String settingsErrorPrefix(String message) {
    return 'Error: $message';
  }

  @override
  String get settingsMilkChildSingular => 'Age of the child';

  @override
  String get settingsMilkChildPlural => 'Ages of the children';

  @override
  String settingsMilkShareSingular(int percent) {
    return 'Breast milk share: $percent%';
  }

  @override
  String settingsMilkSharePlural(int percent) {
    return 'Breast milk share per baby: $percent%';
  }

  @override
  String settingsMilkVolumePerDayLabel(int volume, int supplement) {
    return '$volume ml/day → +$supplement kcal/day';
  }

  @override
  String get settingsMilkVolumeInfoTopic => 'Daily milk volume';

  @override
  String get settingsMilkVolumeInfoTitle => 'Energy = volume × 0.84 kcal/ml';

  @override
  String get settingsTodayTarget => 'Your daily target';

  @override
  String get settingsMacroCarbsRemainder => 'Carbs (remainder)';

  @override
  String settingsMacroSliderValue(int percent, int grams, int kcal) {
    return '$percent % · ${grams}g · $kcal kcal';
  }

  @override
  String get themeSystem => 'System';

  @override
  String get themeSystemHint => 'Follows device setting';

  @override
  String get themeLightHint => 'Light theme';

  @override
  String get themeDarkHint => 'Dark theme';

  @override
  String settingsReminderTimeFormat(String hour, String minute) {
    return '$hour:$minute';
  }

  @override
  String get infoBackgroundTooltip => 'Background';

  @override
  String infoSourceLabel(String source) {
    return 'Source: $source';
  }

  @override
  String get onboardingRestartTitle => 'Restart onboarding?';

  @override
  String get onboardingRestartBody => 'Your inputs so far will be discarded.';

  @override
  String get onboardingRestartConfirm => 'Restart';

  @override
  String get onboardingRestartTooltip => 'Restart onboarding';

  @override
  String onboardingStepIndicator(int step, int total) {
    return 'STEP $step OF $total';
  }

  @override
  String get onboardingButtonNext => 'Next';

  @override
  String get onboardingButtonStart => 'Get started';

  @override
  String get onboardingFooterEditLater =>
      'You can change every value later in settings.';

  @override
  String get onboardingTagline => 'Nutrition that does the math.';

  @override
  String get onboardingSubline =>
      'A live coach for pregnancy and breastfeeding. Evidence-based, privacy-friendly, no calorie-counting fuss.';

  @override
  String get onboardingPhaseQuestion => 'Which phase are you in?';

  @override
  String get onboardingPhaseExplainer =>
      'We use this to calculate your energy supplement and protein target.';

  @override
  String get onboardingPhaseLactation => 'Breastfeeding';

  @override
  String get onboardingPhaseLactationHint =>
      'You\'re producing breast milk (nursing or pumping)';

  @override
  String get onboardingPhasePregnancy => 'Pregnancy';

  @override
  String get onboardingPhasePregnancyHint => 'Currently pregnant';

  @override
  String get onboardingPhaseBothNote =>
      'Pregnancy and breastfeeding supplements will be added together.';

  @override
  String get onboardingBasicsTitle => 'Your basic data';

  @override
  String get onboardingBasicsInfoTopic => 'Basic data';

  @override
  String get onboardingBasicsInfoSummary =>
      'Needed to calculate your basal metabolic rate';

  @override
  String get onboardingBasicsInfoDetail =>
      'We use the Mifflin-St Jeor formula to estimate your daily basal metabolic rate. That plus your activity factor plus the pregnancy/breastfeeding supplement gives your daily target.';

  @override
  String get onboardingBasicsInfoSource => 'Mifflin-St Jeor 1990, DGE';

  @override
  String get onboardingActivityHintBaby =>
      'With a baby at home, usually \"Moderate\". Adjust when you go back to more sport.';

  @override
  String get onboardingDetailsTitle => 'Details';

  @override
  String get onboardingVolumeShareQuestionSingular =>
      'What\'s your share of the feeding?';

  @override
  String get onboardingVolumeShareQuestionPlural =>
      'What\'s your share per child?';

  @override
  String get onboardingVolumeInfoDetail =>
      'Energy cost of milk synthesis is ~0.84 kcal per ml. Typical volumes: single 0-6mo ~780 ml/day, twins ~1500 ml/day, 6-12mo ~575 ml, >12mo ~300 ml. If you pump and know your volume, enter it exactly.';

  @override
  String get onboardingResultEyebrow => 'CALCULATION';

  @override
  String get onboardingResultMacrosEyebrow => 'MACRONUTRIENTS · DAILY TARGET';

  @override
  String onboardingLedeBase(String kcal) {
    return 'Base + activity: $kcal kcal';
  }

  @override
  String onboardingLedePregnancy(String kcal, int trimester) {
    return '+ $kcal kcal pregnancy (T$trimester)';
  }

  @override
  String onboardingLedeLactation(String kcal) {
    return '+ $kcal kcal breastfeeding';
  }

  @override
  String get onboardingRemindersDetail =>
      'Five slots across the day. iOS will ask once for permission when you tap \"Open diary\".';

  @override
  String get onboardingDisclaimerTitle => 'Briefly: not medical advice.';

  @override
  String get onboardingDisclaimerBody =>
      'NourishMe is a personal wellness tool, not a medical device. For medical questions, talk to your doctor or midwife. For allergies or pre-existing conditions, double-check coach suggestions yourself.';

  @override
  String get onboardingDisclaimerLink => 'More details';

  @override
  String get settingsSectionDiet => 'Diet & allergies';

  @override
  String get settingsDietStyleLabel => 'Diet style';

  @override
  String get dietStyleOmnivore => 'Omnivore';

  @override
  String get dietStyleVegetarian => 'Vegetarian';

  @override
  String get dietStyleVegan => 'Vegan';

  @override
  String get dietStylePescatarian => 'Pescatarian';

  @override
  String get settingsDietRestrictionsLabel => 'Avoid';

  @override
  String get settingsDietRestrictionsHint =>
      'Tap any that apply. The coach won\'t suggest these.';

  @override
  String get restrictionLactose => 'Lactose';

  @override
  String get restrictionGluten => 'Gluten';

  @override
  String get restrictionEggs => 'Eggs';

  @override
  String get restrictionNuts => 'Nuts';

  @override
  String get restrictionFish => 'Fish';

  @override
  String get restrictionShellfish => 'Shellfish';

  @override
  String get restrictionSoy => 'Soy';

  @override
  String get settingsDietNotesLabel => 'Note for the coach (optional)';

  @override
  String get settingsDietNotesHint => 'e.g. histamine sensitive, no spicy food';

  @override
  String get factEnergyLactationTopic =>
      'Energy supplement, breastfeeding phase';

  @override
  String get factEnergyLactationSummary => '~84 kcal per 100 ml of milk';

  @override
  String get factEnergyLactationDetail =>
      'Energy density of breast milk 0.67 kcal/g × synthesis efficiency 80% = ~84 kcal per 100 ml. Typical volumes: exclusive 0-6 mo ~780 ml/day, 6-12 mo ~550 ml, >12 mo ~200-400 ml. Twins exclusive: ~1,500 ml (+~1,100 kcal). DGE flat rate: +500 kcal for one child 0-6 mo.';

  @override
  String get factEnergyLactationSource => 'DGE 2025, EFSA 2017, WHO/FAO 2004';

  @override
  String get factEnergyPregnancyTopic => 'Energy supplement, pregnancy';

  @override
  String get factEnergyPregnancySummary => 'T1: 0, T2: +250, T3: +500 kcal/day';

  @override
  String get factEnergyPregnancyDetail =>
      'Assumes pre-pregnancy BMI 18.5-24.9 and unchanged activity. With multiples: +300 kcal per additional fetus (ACOG rule of thumb), so twins in T3 about +800 kcal.';

  @override
  String get factEnergyPregnancySource => 'DGE 2025, EFSA, ACOG';

  @override
  String get factProteinLactationTopic => 'Protein requirement';

  @override
  String get factProteinLactationSummary =>
      'Lactation: 1.2 g/kg body weight/day (DGE)';

  @override
  String get factProteinLactationDetail =>
      'Non-pregnant baseline: 0.8 g/kg. Pregnancy T2: 0.9 g/kg, T3: 1.0 g/kg. Lactation 0-6 mo: 1.2 g/kg (about +23 g/day above baseline). Good sources: lean meat, fish, legumes, eggs, dairy, tofu.';

  @override
  String get factProteinLactationSource => 'DGE 2025, EFSA 2012';

  @override
  String kcalRemainingPositive(String kcal) {
    return '$kcal kcal left';
  }

  @override
  String get kcalRemainingZero => 'Target reached';

  @override
  String kcalRemainingNegative(String kcal) {
    return '$kcal kcal over target';
  }

  @override
  String kcalCombined(String current, String target) {
    return '$current / $target kcal';
  }

  @override
  String get macroLabelProtein => 'P';

  @override
  String get macroLabelCarbs => 'C';

  @override
  String get macroLabelFat => 'F';
}
