import '../l10n/app_localizations.dart';
import '../models/user_profile_settings.dart';

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
