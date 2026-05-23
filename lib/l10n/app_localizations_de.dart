// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'NourishMe';

  @override
  String get tabDiary => 'Tagebuch';

  @override
  String get tabHistory => 'Verlauf';

  @override
  String get tabTrends => 'Trends';

  @override
  String get todayHeader => 'Heute';

  @override
  String get settingsTooltip => 'Einstellungen';

  @override
  String get emptyTodayHeadline => 'Was hast du heute gegessen?';

  @override
  String get emptyTodayBody =>
      'Tipp einfach drauf los, der Coach erkennt den Rest.';

  @override
  String get emptyHistoryHeadline => 'Der Verlauf beginnt heute.';

  @override
  String get emptyFavoritesHeadline => 'Noch keine Favoriten.';

  @override
  String get emptyFavoritesBody =>
      'Tippe beim Mahlzeit-Loggen auf den Stern, um eine Mahlzeit als Favorit zu speichern.';

  @override
  String get emptyFavoritesExample => 'Müsli mit Beeren';

  @override
  String get emptySafetyEyebrow => 'FOOD SAFETY · BFR';

  @override
  String get emptySafetyHeadline => 'Alles unauffällig.';

  @override
  String get emptySafetyMercury => 'Quecksilber';

  @override
  String get emptySafetyMercuryNote => 'ok';

  @override
  String get emptySafetyListeria => 'Listeria-Risiko';

  @override
  String get emptySafetyListeriaNote => 'pasteurisiert ok';

  @override
  String get emptySafetyCaffeine => 'Koffein';

  @override
  String get emptySafetyCaffeineNote => '< 200 mg';

  @override
  String get trendsTitle => 'Trends';

  @override
  String get trendsWeekEyebrow => 'LETZTE 7 TAGE';

  @override
  String get trendsWeekTitle => 'Kalorien-Verlauf';

  @override
  String trendsWeekSummary(int inRange, String avgKcal) {
    return '$inRange von 7 Tagen im Zielbereich · Ø $avgKcal kcal';
  }

  @override
  String get trendsStreakEyebrow => 'STREAK';

  @override
  String get trendsStreakZero => 'Heute ist dein erster Sweet-Spot-Tag.';

  @override
  String get trendsStreakOne => '1 Tag im Sweet-Spot.';

  @override
  String trendsStreakMany(int count) {
    return '$count Tage im Sweet-Spot in Folge.';
  }

  @override
  String get trendsAveragesEyebrow => 'WOCHENSCHNITT';

  @override
  String get trendsAveragesTitle => 'Pro Tag mit Eintrag';

  @override
  String get trendsLabelKcal => 'Kalorien';

  @override
  String get trendsLabelProtein => 'Protein';

  @override
  String get trendsLabelCarbs => 'Kohlenhydrate';

  @override
  String get trendsLabelFat => 'Fett';

  @override
  String trendsTargetPrefix(String target) {
    return 'Ziel $target';
  }

  @override
  String get trendsConsistencyEyebrow => 'KONSISTENZ';

  @override
  String get trendsConsistencyTitle => 'Tracking-Tage';

  @override
  String get trendsConsistencyEmpty =>
      'Sobald du deine erste Mahlzeit loggst, beginnt deine Tracking-Reise hier.';

  @override
  String trendsConsistencyBody(int days, int trackedDays) {
    return 'Du nutzt NourishMe seit $days Tagen, mit Einträgen an $trackedDays Tagen.';
  }

  @override
  String get trendsTopMealsEyebrow => 'HÄUFIGSTE MAHLZEITEN';

  @override
  String get trendsTopMealsTitle => 'Letzte 7 Tage';

  @override
  String get historyNoEntries => 'Noch keine Einträge';

  @override
  String get historyKcalSeparator => '·';

  @override
  String get confirmTitleNew => 'Prüfen und speichern';

  @override
  String get confirmTitleEdit => 'Bearbeiten';

  @override
  String get confirmSave => 'Speichern';

  @override
  String get confirmCancel => 'Abbrechen';

  @override
  String get confirmFieldPortion => 'Portion';

  @override
  String get confirmFieldKcal => 'kcal';

  @override
  String get confirmFieldProtein => 'Protein';

  @override
  String get confirmFieldCarbs => 'KH';

  @override
  String get confirmFieldFat => 'Fett';

  @override
  String confirmAliasPrefix(String alias) {
    return '≈ $alias';
  }

  @override
  String get confirmFavoriteAdd => 'Als Favorit speichern';

  @override
  String get confirmFavoriteRemove => 'Favorit entfernen';

  @override
  String get confirmDescriptionHint => 'Beschreibung';

  @override
  String get confirmDetailsToggle => 'Details anzeigen';

  @override
  String get confirmDetailsHide => 'Details ausblenden';

  @override
  String get confirmDiscardTitle => 'Änderungen verwerfen?';

  @override
  String get confirmDiscardBody =>
      'Deine ungespeicherten Änderungen gehen verloren.';

  @override
  String get confirmDiscardAbort => 'Abbrechen';

  @override
  String get confirmDiscardConfirm => 'Verwerfen';

  @override
  String get confirmHintsHeader => 'Hinweise zu dieser Mahlzeit';

  @override
  String get confirmSafetyHeader => 'Bitte beachte';

  @override
  String get confirmCoachErrorFallback =>
      'Coach-Antwort konnte nicht erstellt werden. Probier es später nochmal.';

  @override
  String get commonDone => 'Fertig';

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get commonDelete => 'Löschen';

  @override
  String get commonGenericError =>
      'Etwas ist schiefgelaufen. Probier es nochmal.';

  @override
  String get commonSendError =>
      'Senden hat nicht geklappt. Probier es nochmal.';

  @override
  String get homeOpenDayHelp => 'Tag öffnen';

  @override
  String get homeCoachThinking => 'Coach denkt nach…';

  @override
  String homeEmptyRangeSingle(String label) {
    return '$label · keine Einträge';
  }

  @override
  String homeEmptyRangeMulti(String from, String to, int count) {
    return '$from — $to · $count Tage leer';
  }

  @override
  String get homeEmptyDayText => 'Keine Einträge';

  @override
  String get homeEmptyDayAdd => 'hinzufügen';

  @override
  String get homeTimePickerHelp => 'Uhrzeit wählen';

  @override
  String get homeTimeSuffix => ' Uhr';

  @override
  String homePastDayHeader(String day) {
    return 'Eintrag für $day';
  }

  @override
  String get homePastDayBody => 'Was hast du gegessen oder getrunken?';

  @override
  String get homePastDayInputHint => 'z.B. Müsli mit Joghurt, 1 Schüssel';

  @override
  String get homeContinue => 'Weiter';

  @override
  String get homePhotoCamera => 'Kamera';

  @override
  String get homePhotoGallery => 'Galerie';

  @override
  String get homePhotoButton => 'Foto hinzufügen';

  @override
  String get homeMainInputHint => 'Essen loggen / Frage stellen';

  @override
  String homeMealDeleteTitle(String summary) {
    return '\"$summary\" löschen?';
  }

  @override
  String get homePhotoNotFoodError =>
      'Das Bild scheint kein Essen zu zeigen. Beschreibe es als Text oder probier ein anderes Foto.';

  @override
  String get homeMealHintsHeader => 'Hinweise zu dieser Mahlzeit';

  @override
  String favoriteRemoveTitle(String summary) {
    return '\"$summary\" entfernen?';
  }

  @override
  String get favoriteRemoveConfirm => 'Entfernen';

  @override
  String get reminderChannelName => 'Mahlzeit-Erinnerungen';

  @override
  String get reminderChannelDescription =>
      'Tägliche Erinnerungen, deine Mahlzeiten zu loggen.';

  @override
  String get reminderBreakfastTitle => 'Frühstück?';

  @override
  String get reminderBreakfastBody =>
      'Falls du schon was hattest, tippe deine Mahlzeit ein.';

  @override
  String get reminderMidmorningTitle => 'Kleine Stärkung?';

  @override
  String get reminderMidmorningBody =>
      'Apfel, Joghurt, Brötchen? Tippe deine Mahlzeit ein.';

  @override
  String get reminderLunchTitle => 'Mittagszeit.';

  @override
  String get reminderLunchBody => 'Coach wartet auf deine Mahlzeit.';

  @override
  String get reminderMidafternoonTitle => 'Zwischendurch was gegessen?';

  @override
  String get reminderMidafternoonBody =>
      'Tippe deine Mahlzeit ein, dann hast du den Tag im Bild.';

  @override
  String get reminderDinnerTitle => 'Abendessen geloggt?';

  @override
  String get reminderDinnerBody =>
      'Letzter Eintrag heute, danach ist Feierabend.';

  @override
  String get reminderSlotBreakfast => 'Frühstück';

  @override
  String get reminderSlotMidmorning => 'Vormittags-Snack';

  @override
  String get reminderSlotLunch => 'Mittagessen';

  @override
  String get reminderSlotMidafternoon => 'Nachmittags-Snack';

  @override
  String get reminderSlotDinner => 'Abendessen';

  @override
  String get feedbackMailSubject => 'NourishMe Feedback';

  @override
  String get feedbackMailTriageHint =>
      'Bitte ändere unten drunter nichts — der Block hilft beim Triage.';

  @override
  String get feedbackMailDeviceLabel => 'Gerät';

  @override
  String get reminderPermissionBlocked =>
      'Benachrichtigungen sind in den iOS-Einstellungen blockiert.';
}
