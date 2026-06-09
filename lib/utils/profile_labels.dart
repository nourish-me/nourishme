import '../l10n/app_localizations.dart';
import '../models/user_profile_settings.dart';
import '../services/nutrition_facts.dart';

// Bridges AppLocalizations into the language-agnostic label value types
// that ActivityLevel / ChildAgeGroup factories expect. Keeps the model
// file free of generated-l10n imports.

ActivityLabels activityLabelsOf(AppLocalizations l10n) => ActivityLabels(
      low: l10n.activityLow,
      lowHint: l10n.activityLowHint,
      moderate: l10n.activityModerate,
      moderateHint: l10n.activityModerateHint,
      active: l10n.activityActive,
      activeHint: l10n.activityActiveHint,
      high: l10n.activityHigh,
      highHint: l10n.activityHighHint,
    );

ChildAgeLabels childAgeLabelsOf(AppLocalizations l10n) => ChildAgeLabels(
      zeroToSix: l10n.childAge0to6,
      zeroToSixHint: l10n.childAge0to6Hint,
      sixToTwelve: l10n.childAge6to12,
      sixToTwelveHint: l10n.childAge6to12Hint,
      twelvePlus: l10n.childAge12plus,
      twelvePlusHint: l10n.childAge12plusHint,
    );

// Localized NutritionFact constructors for the three facts that surface
// in the UI as InfoButton bottom sheets. The remaining static facts in
// NutritionFacts are only consumed by the coachContextBlock, which is
// already split DE/EN inside the LLM-prompt path.
NutritionFact energyLactationFact(AppLocalizations l10n) => NutritionFact(
      topic: l10n.factEnergyLactationTopic,
      summary: l10n.factEnergyLactationSummary,
      detail: l10n.factEnergyLactationDetail,
      source: l10n.factEnergyLactationSource,
    );

NutritionFact energyPregnancyFact(AppLocalizations l10n) => NutritionFact(
      topic: l10n.factEnergyPregnancyTopic,
      summary: l10n.factEnergyPregnancySummary,
      detail: l10n.factEnergyPregnancyDetail,
      source: l10n.factEnergyPregnancySource,
    );

NutritionFact proteinLactationFact(AppLocalizations l10n) => NutritionFact(
      topic: l10n.factProteinLactationTopic,
      summary: l10n.factProteinLactationSummary,
      detail: l10n.factProteinLactationDetail,
      source: l10n.factProteinLactationSource,
    );

NutritionFact goalFact(AppLocalizations l10n) => NutritionFact(
      topic: l10n.factGoalTopic,
      summary: l10n.factGoalSummary,
      detail: l10n.factGoalDetail,
      source: l10n.factGoalSource,
    );
