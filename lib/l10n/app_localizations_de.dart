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
  String historyEntryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Einträge',
      one: '1 Eintrag',
    );
    return '$_temp0';
  }

  @override
  String get todayHeader => 'Heute';

  @override
  String get diaryFilterMealsOnly => 'Nur Mahlzeiten';

  @override
  String get diaryFilterShowAll => 'Alle anzeigen';

  @override
  String get diaryFilterOnMsg => 'Nur Mahlzeiten, Coach-Antworten ausgeblendet';

  @override
  String get diaryFilterOffMsg => 'Coach-Antworten wieder eingeblendet';

  @override
  String get yesterdayHeader => 'Gestern';

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
  String get trendsWeightEyebrow => 'GEWICHT';

  @override
  String get trendsWeightEmpty =>
      'Aktualisiere dein Gewicht in den Einstellungen, um deinen Verlauf hier zu sehen.';

  @override
  String trendsWeightSince(String firstDate) {
    return 'Seit $firstDate';
  }

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
  String get confirmReparse => 'Neu schätzen';

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
  String get homeCoachLookingAtMeal => 'Coach schaut sich deine Mahlzeit an…';

  @override
  String get homePhotoTextHint => 'Mengen oder Notizen ergänzen (optional)';

  @override
  String get settingsButtonShowTips => 'Tipps erneut zeigen';

  @override
  String get bundlingToast =>
      'Schon gemerkt? Mehrere Bestandteile schnell hintereinander geloggt → der Coach bündelt sie zu einer Antwort. Reduziert den Lärm im Tagebuch.';

  @override
  String get confirmScanAnother => 'Weiteren Bestandteil hinzufügen';

  @override
  String get confirmAddByBarcode => 'Barcode scannen';

  @override
  String get confirmAddByPhoto => 'Foto machen oder wählen';

  @override
  String get confirmAddByText => 'Text eintippen';

  @override
  String get confirmAddTextSheetTitle => 'Weiterer Bestandteil';

  @override
  String get confirmAddTextSheetHint => 'Was hast du noch dazu?';

  @override
  String get confirmAddTextSheetCta => 'Weiter';

  @override
  String confirmBundleHint(int n) {
    return 'Bestandteil $n dieser Mahlzeit. Der Coach analysiert alle zusammen.';
  }

  @override
  String get tipsTitle => 'Tipps & Tricks';

  @override
  String get tipsSkip => 'Überspringen';

  @override
  String get tipsNext => 'Weiter';

  @override
  String get tipsDone => 'Los geht\'s';

  @override
  String tipsCounter(int current, int total) {
    return '$current von $total';
  }

  @override
  String get tip1Title => 'Foto + Text macht\'s präzise';

  @override
  String get tip1Body =>
      'Mach ein Foto und sag in einem Wort dazu, was es ist. So weiß die App genau, welche Lebensmittel drauf sind. Die Schätzung wird viel präziser als mit Foto allein. Tipp: statt zu tippen kannst du das Mikrofon auf der iOS-Tastatur antippen und reinsprechen.';

  @override
  String get tip2Title => 'Barcode trainiert deine Marken';

  @override
  String get tip2Body =>
      'Scanne den Barcode bei verpackten Produkten wie Skyr oder Müsli. Du kriegst die exakten Werte, und die App merkt sich, was du oft kaufst.';

  @override
  String get tip3Title => 'Deine Lieblings-Produkte sind eine Antippung weg';

  @override
  String get tip3Body =>
      'Schreib nur den Anfang („Sky…“) und du siehst Vorschläge aus deiner Historie. Tap → fertig, mit den Marken-Werten von letztem Mal. Je öfter du loggst, desto besser kennt dich die App.';

  @override
  String get tip4Title => 'Coach-Antworten antippbar';

  @override
  String get tip4Body =>
      'Manche Coach-Antworten haben Chip-Vorschläge drunter. Tippe einen → die Frage steht halb fertig in deinem Eingabefeld.';

  @override
  String get tip5Title => 'Verpasste Mahlzeit nachtragen';

  @override
  String get tip5Body =>
      'Tap auf einen vergangenen Tag im Tagebuch → du kannst Datum und Uhrzeit setzen und nachträglich loggen.';

  @override
  String get tip6Title => 'Tipp einfach in Alltagssprache';

  @override
  String get tip6Body =>
      'Du musst nicht „Cappuccino 200 ml“ tippen. „Einen Cappuccino bitte“ oder „eine Schüssel Müsli mit Beeren“ reicht. Die App erkennt, dass es eine Mahlzeit ist, schätzt eine typische Portion und legt sie an.';

  @override
  String homeCoachBundling(int count) {
    return 'Coach wartet kurz auf weitere Items… ($count)';
  }

  @override
  String homeEmptyRangeSingle(String label) {
    return '$label · keine Einträge';
  }

  @override
  String homeEmptyRangeMulti(String from, String to, int count) {
    return '$from bis $to · $count Tage leer';
  }

  @override
  String get homeEmptyDayText => 'Keine Einträge';

  @override
  String get homeEmptyDayAdd => 'hinzufügen';

  @override
  String get homeEmptyRangePickerTitle => 'Welcher Tag?';

  @override
  String get homeEmptyRangePickerHint =>
      'Wähle den Tag, in den du einen Eintrag schreiben willst. Die Uhrzeit kommt im nächsten Schritt.';

  @override
  String get homeScrollToTop => 'Nach ganz oben';

  @override
  String get homeScrollToBottom => 'Zu heute';

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
  String get scanButton => 'Barcode scannen';

  @override
  String get scanTitle => 'Barcode scannen';

  @override
  String get scanHint => 'Richte die Kamera auf den Strichcode des Produkts';

  @override
  String get scanNotFound =>
      'Produkt nicht gefunden. Tipp die Mahlzeit einfach ein.';

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
      'Bitte ändere unten drunter nichts, der Block hilft beim Triage.';

  @override
  String get feedbackMailDeviceLabel => 'Gerät';

  @override
  String get reminderPermissionBlocked =>
      'Benachrichtigungen sind in den iOS-Einstellungen blockiert.';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsHubAboutYou => 'Über dich';

  @override
  String get settingsHubAboutYouSummary => 'Profil, Phase, Aktivität';

  @override
  String get settingsHubCoach => 'Coach & Ernährung';

  @override
  String get settingsHubCoachSummary => 'Ziel, Makros, Mikros, Supplements';

  @override
  String get settingsHubApp => 'App';

  @override
  String get settingsHubAppSummary => 'Erinnerungen, Favoriten, Design';

  @override
  String get settingsSectionProfile => 'Dein Profil';

  @override
  String get settingsSectionPhase => 'Aktuelle Phase';

  @override
  String get settingsSectionMilk => 'Muttermilch';

  @override
  String get settingsSectionActivity => 'Aktivitätslevel';

  @override
  String get settingsSectionMacros => 'Makro-Split';

  @override
  String get settingsSectionReminders => 'Erinnerungen';

  @override
  String get settingsSectionTheme => 'Design';

  @override
  String get settingsSectionPrivacy => 'Datenschutz';

  @override
  String get settingsAnalyticsToggle => 'Anonyme Nutzungsstatistik';

  @override
  String get settingsAnalyticsHint =>
      'Hilft uns die App zu verbessern. Komplett anonym, keine persönlichen Daten oder Mahlzeiten-Inhalte, jederzeit abschaltbar.';

  @override
  String get settingsSectionFavorites => 'Favoriten verwalten';

  @override
  String get settingsFieldBirthdate => 'Dein Geburtsdatum';

  @override
  String get settingsFieldHeight => 'Größe';

  @override
  String get settingsFieldWeight => 'Gewicht';

  @override
  String get settingsFieldHeightSuffix => 'cm';

  @override
  String get settingsFieldWeightSuffix => 'kg';

  @override
  String get settingsBirthdatePickerHelp => 'Dein Geburtsdatum wählen';

  @override
  String get settingsButtonFeedback => 'Feedback senden';

  @override
  String get settingsButtonReset => 'App zurücksetzen';

  @override
  String get settingsButtonSave => 'Speichern';

  @override
  String get settingsResetTitle => 'App zurücksetzen?';

  @override
  String get settingsResetBody =>
      'Alle Einträge, Favoriten und dein Profil werden gelöscht. Du startest danach mit dem Onboarding.';

  @override
  String get settingsResetConfirm => 'Zurücksetzen';

  @override
  String get settingsSavedSnackbar => 'Profil gespeichert';

  @override
  String get settingsPhaseLactating => 'Milchproduzierend';

  @override
  String get settingsPhaseLactatingHint => 'Stillend oder pumpend';

  @override
  String get settingsPhasePregnant => 'Schwanger';

  @override
  String get settingsPhasePregnantHint => 'Aktuell schwanger';

  @override
  String get settingsPhaseTrimester => 'Trimester';

  @override
  String get settingsMilkChildren => 'Kinder, die du mit Milch versorgst';

  @override
  String get settingsMilkAgeLabel => 'Alter der Kinder';

  @override
  String get settingsMilkVolume => 'Muttermilch, die du täglich produzierst';

  @override
  String settingsMilkVolumePerDay(int volume, int supplement) {
    return '$volume ml/Tag → +$supplement kcal/Tag';
  }

  @override
  String get settingsMilkVolumeInfoSummary =>
      'Energiekosten der Synthese: ~0,84 kcal pro ml Milch.';

  @override
  String get settingsMilkVolumeInfoDetail =>
      'Wenn du pumpst und dein Volumen kennst, trage es exakt ein. Anteil-Slider darüber liefert sonst eine Schätzung.';

  @override
  String get settingsMilkVolumeInfoSource => 'DGE 2025, EFSA 2017';

  @override
  String get settingsActivityInfoSummary =>
      'Beeinflusst den Tagesumsatz (PAL-Faktor)';

  @override
  String get settingsActivityInfoDetail =>
      'Gering 1,2: kaum Bewegung. Mäßig 1,375: Spaziergänge, leichte Hausarbeit. Aktiv 1,55: regelmäßiges Training. Hoch 1,725: intensives Training oder körperliche Arbeit. Bei Babys zu Hause meist \"Mäßig\".';

  @override
  String get settingsActivityInfoSource => 'DGE PAL-Klassifikation';

  @override
  String get activityLow => 'Gering';

  @override
  String get activityLowHint => 'Kaum Bewegung';

  @override
  String get activityModerate => 'Mäßig';

  @override
  String get activityModerateHint => 'Spaziergänge, leichte Hausarbeit';

  @override
  String get activityActive => 'Aktiv';

  @override
  String get activityActiveHint => 'Regelmäßiges Training';

  @override
  String get activityHigh => 'Hoch';

  @override
  String get activityHighHint => 'Intensives Training, körperliche Arbeit';

  @override
  String get childAge0to6 => '0–6 Mo';

  @override
  String get childAge0to6Hint => 'Voller Milchbedarf';

  @override
  String get childAge6to12 => '6–12 Mo';

  @override
  String get childAge6to12Hint => 'Mit Beikost';

  @override
  String get childAge12plus => '12+ Mo';

  @override
  String get childAge12plusHint => 'Erweiterte Stillzeit';

  @override
  String get settingsMacroTitle => 'Makro-Split';

  @override
  String get settingsMacroInfoSummary =>
      'Anteile von Protein / Fett / KH am Tagesziel';

  @override
  String get settingsMacroInfoDetail =>
      'Standard-Split aus DGE: Protein ergibt sich aus deinem Gewicht (1,2 g/kg in der Stillzeit), Fett ~30 % der kcal, Kohlenhydrate füllen den Rest. Du kannst Protein und Fett anpassen wenn du einer spezifischen Ernährung folgst (Low-Carb, High-Protein). Kohlenhydrate werden automatisch als Rest berechnet.';

  @override
  String get settingsMacroProtein => 'Protein';

  @override
  String get settingsMacroFat => 'Fett';

  @override
  String get settingsMacroCarbs => 'Kohlenhydrate';

  @override
  String get settingsMacroCarbsAuto => 'Rest';

  @override
  String get settingsMacroResetAuto => 'Auto wiederherstellen';

  @override
  String settingsMacroAutoLabel(int percent) {
    return '(Auto $percent %)';
  }

  @override
  String get settingsOutcomeBase => 'Grundbedarf + Aktivität';

  @override
  String settingsOutcomePregnancy(int trimester) {
    return 'Schwangerschaft (T$trimester)';
  }

  @override
  String get settingsOutcomeLactation => 'Muttermilch-Aufschlag';

  @override
  String get themeAuto => 'Folgt dem Geräte-Setting';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get settingsReminderToggleTitle => 'Mahlzeit-Erinnerungen';

  @override
  String get settingsReminderToggleOn =>
      'Aktiv. Stelle ein, was du wann hören willst.';

  @override
  String get settingsReminderToggleOff =>
      'Aus. Bei Aktivierung fragt iOS einmal um Erlaubnis.';

  @override
  String settingsErrorPrefix(String message) {
    return 'Fehler: $message';
  }

  @override
  String get settingsMilkChildSingular => 'Alter des Kindes';

  @override
  String get settingsMilkChildPlural => 'Alter der Kinder';

  @override
  String settingsMilkShareSingular(int percent) {
    return 'Muttermilch-Anteil: $percent%';
  }

  @override
  String settingsMilkSharePlural(int percent) {
    return 'Muttermilch-Anteil pro Kind: $percent%';
  }

  @override
  String settingsMilkVolumePerDayLabel(int volume, int supplement) {
    return '$volume ml/Tag → +$supplement kcal/Tag';
  }

  @override
  String get settingsMilkVolumeInfoTopic => 'Tagesvolumen Muttermilch';

  @override
  String get settingsMilkVolumeInfoTitle => 'Energie = Volumen × 0,84 kcal/ml';

  @override
  String get settingsTodayTarget => 'Dein Tagesziel';

  @override
  String get settingsMacroCarbsRemainder => 'Kohlenhydrate (Rest)';

  @override
  String settingsMacroSliderValue(int percent, int grams, int kcal) {
    return '$percent % · ${grams}g · $kcal kcal';
  }

  @override
  String get themeSystem => 'System';

  @override
  String get themeSystemHint => 'Folgt dem Geräte-Setting';

  @override
  String get themeLightHint => 'Helles Theme';

  @override
  String get themeDarkHint => 'Dunkles Theme';

  @override
  String settingsReminderTimeFormat(String hour, String minute) {
    return '$hour:$minute';
  }

  @override
  String get infoBackgroundTooltip => 'Hintergrund';

  @override
  String infoSourceLabel(String source) {
    return 'Quelle: $source';
  }

  @override
  String get onboardingRestartTitle => 'Onboarding neu starten?';

  @override
  String get onboardingRestartBody =>
      'Deine bisherigen Eingaben werden verworfen.';

  @override
  String get onboardingRestartConfirm => 'Neu starten';

  @override
  String get onboardingRestartTooltip => 'Onboarding neu starten';

  @override
  String onboardingStepIndicator(int step, int total) {
    return 'SCHRITT $step VON $total';
  }

  @override
  String get onboardingButtonNext => 'Weiter';

  @override
  String get onboardingButtonStart => 'Loslegen';

  @override
  String get onboardingFooterEditLater =>
      'Du kannst alle Werte später in den Einstellungen anpassen.';

  @override
  String get onboardingTagline => 'Ernährung, die mitrechnet.';

  @override
  String get onboardingSubline =>
      'Live-Coach für Schwangerschaft und Stillzeit. Wissenschaftlich fundiert, datenschutzfreundlich, ohne Kalorien-Zähl-Kram.';

  @override
  String get onboardingPhaseQuestion => 'In welcher Phase bist du?';

  @override
  String get onboardingPhaseExplainer =>
      'Daraus berechnen wir deinen Energie-Aufschlag und das Protein-Ziel.';

  @override
  String get onboardingPhaseLactation => 'Stillzeit';

  @override
  String get onboardingPhaseLactationHint =>
      'Du produzierst Muttermilch (stillend oder pumpend)';

  @override
  String get onboardingPhasePregnancy => 'Schwangerschaft';

  @override
  String get onboardingPhasePregnancyHint => 'Aktuell schwanger';

  @override
  String get onboardingPhaseBothNote =>
      'Schwangerschafts- und Stillzeit-Aufschlag werden addiert.';

  @override
  String get onboardingBasicsTitle => 'Deine Basisdaten';

  @override
  String get onboardingBasicsInfoTopic => 'Basisdaten';

  @override
  String get onboardingBasicsInfoSummary => 'Brauchen wir für den Grundbedarf';

  @override
  String get onboardingBasicsInfoDetail =>
      'Wir berechnen mit der Mifflin-St Jeor Formel deinen täglichen Grundbedarf. Daraus plus Aktivitätsfaktor plus Schwangerschaft/Stillzeit-Aufschlag ergibt sich dein Tagesziel.';

  @override
  String get onboardingBasicsInfoSource => 'Mifflin-St Jeor 1990, DGE';

  @override
  String get onboardingActivityHintBaby =>
      'Bei einem Baby zu Hause meist \"Mäßig\". Anpassen wenn du wieder mehr Sport machst.';

  @override
  String get onboardingDetailsTitle => 'Details';

  @override
  String get onboardingVolumeShareQuestionSingular =>
      'Wie groß ist dein Anteil an der Ernährung?';

  @override
  String get onboardingVolumeShareQuestionPlural =>
      'Wie groß ist dein Anteil pro Kind?';

  @override
  String get onboardingVolumeInfoDetail =>
      'Die Energiekosten der Milchsynthese liegen bei ~0,84 kcal pro ml Milch. Typische Volumina: einzeln 0-6 Mo ~780 ml/Tag, Zwillinge ~1.500 ml/Tag, 6-12 Mo ~575 ml, >12 Mo ~300 ml. Wenn du abpumpst und dein Volumen kennst, trage es genau ein.';

  @override
  String get onboardingResultEyebrow => 'BERECHNUNG';

  @override
  String get onboardingResultMacrosEyebrow => 'MAKRONÄHRSTOFFE · TAGESBEDARF';

  @override
  String onboardingLedeBase(String kcal) {
    return 'Grundbedarf + Aktivität: $kcal kcal';
  }

  @override
  String onboardingLedePregnancy(String kcal, int trimester) {
    return '+ $kcal kcal Schwangerschaft (T$trimester)';
  }

  @override
  String onboardingLedeLactation(String kcal) {
    return '+ $kcal kcal für Stillen';
  }

  @override
  String get onboardingRemindersDetail =>
      'Fünf Slots über den Tag verteilt. iOS fragt einmal um Erlaubnis, wenn du \"Tagebuch öffnen\" tippst.';

  @override
  String get onboardingDisclaimerTitle => 'Kurz: keine medizinische Beratung.';

  @override
  String get onboardingDisclaimerBody =>
      'NourishMe ist ein persönliches Wellness-Tool, kein medizinisches Produkt. Bei medizinischen Fragen sprich mit deiner Ärztin oder Hebamme. Bei Allergien oder Vorerkrankungen prüfe Coach-Vorschläge selbst.';

  @override
  String get onboardingDisclaimerLink => 'Mehr dazu';

  @override
  String get settingsSectionDiet => 'Ernährung & Allergien';

  @override
  String get settingsDietStyleLabel => 'Ernährungsweise';

  @override
  String get dietStyleOmnivore => 'Omnivor';

  @override
  String get dietStyleVegetarian => 'Vegetarisch';

  @override
  String get dietStyleVegan => 'Vegan';

  @override
  String get dietStylePescatarian => 'Pescetarisch';

  @override
  String get settingsDietRestrictionsLabel => 'Vermeiden';

  @override
  String get settingsDietRestrictionsHint =>
      'Tippe an was zutrifft. Der Coach schlägt diese nicht vor.';

  @override
  String get restrictionLactose => 'Laktose';

  @override
  String get restrictionGluten => 'Gluten';

  @override
  String get restrictionEggs => 'Eier';

  @override
  String get restrictionNuts => 'Nüsse';

  @override
  String get restrictionFish => 'Fisch';

  @override
  String get restrictionShellfish => 'Schalentiere';

  @override
  String get restrictionSoy => 'Soja';

  @override
  String get settingsDietNotesLabel => 'Notiz an den Coach (optional)';

  @override
  String get settingsDietNotesHint =>
      'z.B. histaminempfindlich, kein scharfes Essen';

  @override
  String get factEnergyLactationTopic => 'Energie-Aufschlag Stillzeit';

  @override
  String get factEnergyLactationSummary => 'Pro 100 ml Milch ~84 kcal';

  @override
  String get factEnergyLactationDetail =>
      'Energiedichte Muttermilch 0,67 kcal/g × Synthese-Effizienz 80 % = ~84 kcal pro 100 ml. Typische Volumina: exklusiv 0-6 Mo ~780 ml/Tag, 6-12 Mo ~550 ml, >12 Mo ~200-400 ml. Zwillinge exklusiv: ~1.500 ml (+~1.100 kcal). DGE-Pauschal +500 kcal bei einem Kind 0-6 Mo.';

  @override
  String get factEnergyLactationSource => 'DGE 2025, EFSA 2017, WHO/FAO 2004';

  @override
  String get factEnergyPregnancyTopic => 'Energie-Aufschlag Schwangerschaft';

  @override
  String get factEnergyPregnancySummary => 'T1: 0, T2: +250, T3: +500 kcal/Tag';

  @override
  String get factEnergyPregnancyDetail =>
      'Voraussetzung: Vor-SS-BMI 18,5-24,9, unveränderte Aktivität. Bei Mehrlingen: +300 kcal pro zusätzlichem Fetus (ACOG-Faustformel), also Zwillinge T3 etwa +800 kcal.';

  @override
  String get factEnergyPregnancySource => 'DGE 2025, EFSA, ACOG';

  @override
  String get factProteinLactationTopic => 'Protein-Bedarf';

  @override
  String get factProteinLactationSummary => 'Stillzeit: 1,2 g/kg KG/Tag (DGE)';

  @override
  String get factProteinLactationDetail =>
      'Nicht-schwangere Frau Basis: 0,8 g/kg. Schwangerschaft T2: 0,9 g/kg, T3: 1,0 g/kg. Stillzeit 0-6 Mo: 1,2 g/kg (+~23 g/Tag über Basis). Gut: mageres Fleisch, Fisch, Hülsenfrüchte, Eier, Milchprodukte, Tofu.';

  @override
  String get factProteinLactationSource => 'DGE 2025, EFSA 2012';

  @override
  String kcalRemainingPositive(String kcal) {
    return 'Noch $kcal kcal';
  }

  @override
  String get kcalRemainingZero => 'Tagesziel erreicht';

  @override
  String kcalRemainingNegative(String kcal) {
    return '$kcal kcal über Ziel';
  }

  @override
  String kcalCombined(String current, String target) {
    return '$current / $target kcal';
  }

  @override
  String get macroLabelProtein => 'P';

  @override
  String get macroLabelCarbs => 'KH';

  @override
  String get macroLabelFat => 'F';

  @override
  String get nutritionMacroProtein => 'Protein';

  @override
  String get nutritionMacroCarbs => 'Kohlenh.';

  @override
  String get nutritionMacroFat => 'Fett';

  @override
  String get nutritionHeaderKcalTarget => ' kcal Ziel';

  @override
  String get macroDetailKcalName => 'Kalorien';

  @override
  String get macroDetailProteinName => 'Protein';

  @override
  String get macroDetailCarbsName => 'Kohlenhydrate';

  @override
  String get macroDetailFatName => 'Fett';

  @override
  String macroDetailRemaining(String value, String unit) {
    return 'noch $value $unit';
  }

  @override
  String get macroDetailMet => 'Ziel erreicht';

  @override
  String macroDetailOver(String value, String unit) {
    return '$value $unit über Ziel';
  }

  @override
  String macroDetailSweetNote(String target, String unit) {
    return 'Im Zielkorridor. Mehr ist hier nicht besser, die $target $unit sind dein Tagesziel.';
  }

  @override
  String macroDetailOverNote(String name) {
    return '$name über dem Tagesziel. Kein Stress, einzelne Tage gleichen sich aus.';
  }

  @override
  String macroDetailNeutralNote(String target, String unit) {
    return 'Noch im Aufbau Richtung $target $unit.';
  }

  @override
  String get nutritionDetailContributions => 'Heute beigetragen';

  @override
  String get nutritionDetailNoContributions => 'Noch keine Einträge heute.';

  @override
  String get nutritionDetailClose => 'Schließen';

  @override
  String get microDetailTwinDisclaimer =>
      'Zwillinge: Datenlage begrenzt, Zielwerte aus Einlings-Werten hochgerechnet. Bitte mit Hebamme oder Ärztin abstimmen.';

  @override
  String get microDetailAwarenessNote =>
      'Kein DGE-Referenzwert. Der angezeigte Wert ist eine EFSA-Schätzung (Adequate Intake) und dient als Orientierung, nicht als feste Empfehlung.';

  @override
  String get microDetailMilkDependentTitle => 'Erreicht dein Baby';

  @override
  String get microDetailBufferedTitle => 'Deine Reserven';

  @override
  String microDetailMilkDependentBody(String name) {
    return '$name geht direkt in deine Muttermilch über, was du isst, kommt beim Baby an.';
  }

  @override
  String microDetailBufferedBody(String name) {
    return '$name-Gehalt in der Milch bleibt stabil, auf Kosten deiner eigenen Reserven. Schau auf dich.';
  }

  @override
  String microDetailNoContributions(String name) {
    return 'Noch keine Einträge mit $name heute.';
  }

  @override
  String get microDetailSourceHeader => 'Quelle & Zielwert';

  @override
  String get settingsSectionMicronutrients => 'Mikronährstoffe im Header';

  @override
  String get settingsMicrosDescription =>
      'Welche Mikronährstoffe oben im Tagebuch angezeigt werden. Maximal 3. Wenn keiner gewählt ist, nutzt die App den Vorschlag für deine Phase.';

  @override
  String get settingsMicrosUsingDefaults => 'Aktuell: Phase-Vorschlag aktiv.';

  @override
  String get settingsMicrosMaxReached => '3 von 3 gewählt';

  @override
  String get settingsMicrosReset => 'Auf Phase-Vorschlag zurück';

  @override
  String get settingsMilkBirthdateLabel => 'Geburtsdatum (jüngstes Kind)';

  @override
  String get settingsMilkBirthdatePick => 'Geburtsdatum eintragen';

  @override
  String get settingsMilkBirthdateClear => 'Geburtsdatum entfernen';

  @override
  String get settingsMilkBirthdateAuto =>
      'Alter wird daraus laufend berechnet.';

  @override
  String get settingsMilkBirthdatePickerHelp =>
      'Wann wurde dein (jüngstes) Kind geboren?';

  @override
  String get settingsMilkBirthdateUseBucket => 'Lieber nur das Alter wählen?';

  @override
  String get settingsMilkBirthdateBackToDate => 'Genauer mit Geburtsdatum?';

  @override
  String get settingsMilkBirthdateAgeMonthsOne => '1 Monat alt';

  @override
  String settingsMilkBirthdateAgeMonths(int months) {
    return '$months Monate alt';
  }

  @override
  String get settingsSectionGoal => 'Coach-Ziel';

  @override
  String get settingsGoalHint =>
      'Worauf soll der Coach optimieren? Details und Sicherheits-Leitplanken hinter dem Info-Icon.';

  @override
  String get settingsGoalNutrients => 'Nährstoffe';

  @override
  String get settingsGoalBody => 'Körperziel';

  @override
  String get settingsGoalBoth => 'Beides';

  @override
  String get settingsGoalMacroImplication =>
      'Mehr Protein für Muskelschutz im Defizit. Im Bereich Makros sichtbar und anpassbar.';

  @override
  String get settingsPhaseNeither => 'Weder noch';

  @override
  String get settingsPhaseNeitherHint =>
      'Aktuell weder schwanger noch stillend, z.B. nach dem Abstillen oder vor einer Schwangerschaft.';

  @override
  String get onboardingPhaseNeither => 'Weder noch';

  @override
  String get onboardingPhaseNeitherHint =>
      'Weder schwanger noch produziere ich Muttermilch.';

  @override
  String get onboardingGoalTitle => 'Worauf willst du dich konzentrieren?';

  @override
  String get onboardingGoalSubtitle =>
      'Du kannst das jederzeit in den Einstellungen ändern.';

  @override
  String get coachIngredientsReplyHint => 'z.B. Zucchini, Hähnchen';

  @override
  String get coachIngredientsSavedSnack =>
      'Notiert. Beim nächsten Tipp denke ich dran.';

  @override
  String get supplementSectionTitle => 'Nahrungsergänzung';

  @override
  String get supplementOnboardingTitle => 'Nimmst du ein Supplement?';

  @override
  String get supplementOnboardingBody =>
      'Folio, Femibion oder ähnliches? Fotografiere die Nährwerttabelle auf der Rückseite der Packung, dann rechnet die App die Werte automatisch jeden Tag mit.';

  @override
  String get supplementAddCta => 'Nährwerttabelle fotografieren';

  @override
  String get supplementSkipCta => 'Nein, nehme keins';

  @override
  String get supplementSourceCamera => 'Kamera';

  @override
  String get supplementSourceGallery => 'Aus Galerie';

  @override
  String get supplementParsing => 'Etikett wird ausgelesen...';

  @override
  String get supplementReviewTitle => 'Werte prüfen';

  @override
  String get supplementReviewHint =>
      'Werte aus deinem Etikett. Du kannst Name und Mengen vor dem Speichern anpassen.';

  @override
  String get supplementFieldName => 'Name';

  @override
  String get supplementFieldDoses => 'Dosen pro Tag';

  @override
  String get supplementSave => 'Speichern';

  @override
  String get supplementCancel => 'Verwerfen';

  @override
  String get supplementRetry => 'Anderes Foto';

  @override
  String get supplementRemove => 'Supplement entfernen';

  @override
  String get supplementEdit => 'Bearbeiten';

  @override
  String get supplementEditTitle => 'Supplement bearbeiten';

  @override
  String get supplementEditHint =>
      'Passe Name, Dosen oder Werte direkt an. Kein neues Foto nötig.';

  @override
  String get supplementAddAnotherCta => 'Weiteres Supplement hinzufügen';

  @override
  String supplementCurrentLabel(String name) {
    return 'Aktuell: $name';
  }

  @override
  String supplementCurrentDoses(int doses) {
    return '$doses Dosen pro Tag';
  }

  @override
  String get factGoalTopic => 'Coach-Ziel';

  @override
  String get factGoalSummary => 'Nährstoffe vs. Körperziel: was sich ändert';

  @override
  String get factGoalDetail =>
      'Nährstoffe (Standard): Coach optimiert nur auf ausreichende Versorgung, kein Defizit-Talk.\n\nKörperziel/Beides: Coach darf moderate Defizite vorschlagen, aber nur unter klaren Sicherheits-Leitplanken: nie unter 1.800 kcal/Tag in der Stillzeit, Defizit max. 300-500 kcal/Tag, frühestens 6-8 Wochen postpartum, in der Schwangerschaft NIE ein Defizit, Mikronährstoffe und Protein bleiben auf Soll. An Sport-Tagen Protein erhöhen statt Defizit vergrößern. Ein Hinweis, mit Hebamme oder Ärztin abzustimmen.\n\nIm App-Header wird das Protein-Ziel angehoben (Stillzeit: 1,5 g/kg statt 1,2; sonst 1,6 g/kg statt 0,8) zur Muskel-Erhaltung im Defizit. Carbs und Fett bleiben.';

  @override
  String get factGoalSource =>
      'Leitplanken bestätigt von Ernährungsberaterin Juni 2026, basierend auf DGE 2025, EFSA 2017, CDC. Protein-Anhebung im Körperziel: Standard-Recomp-Empfehlung (1,5-1,8 g/kg), defensiv im Stillzeit-Range';
}
