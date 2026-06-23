/// Pure onboarding step gate, extracted from OnboardingScreen so the
/// "may the user advance from this step?" rule is unit-testable without
/// pumping the widget. The screen's `_canAdvance` getter delegates here.
class OnboardingValidation {
  const OnboardingValidation._();

  // Step indices we branch on (single source of truth, also used by the
  // screen's skip branching). Order: welcome, phase, goal, body,
  // phase_details, supplement, summary, consent.
  static const phaseDetailsStepIndex = 4;
  static const supplementStepIndex = 5;
  static const summaryStepIndex = 6;
  static const consentStepIndex = 7;

  /// Whether the Next button is enabled on [step]. Pure: all inputs passed
  /// in. Mirrors the per-step rules in the onboarding flow.
  static bool canAdvance({
    required int step,
    required bool isPregnant,
    required bool isLactating,
    required bool phaseExplicitlyNeither,
    required String heightText,
    required String weightText,
    required bool numChildrenAcknowledged,
    required bool childAgeAcknowledged,
    required bool healthDataConsent,
  }) {
    switch (step) {
      case 1:
        // Phase: at least one of pregnant/lactating/neither must be picked.
        return isPregnant || isLactating || phaseExplicitlyNeither;
      case 2:
        // Goal defaults to 'nutrients'; no forced choice.
        return true;
      case 3:
        // Body: height + weight must parse (comma or dot decimal).
        return _parsesAsNumber(heightText) && _parsesAsNumber(weightText);
      case phaseDetailsStepIndex:
        // Lactation: children-count AND child's age must be explicitly
        // acknowledged, otherwise the milk-share/volume sections are still
        // hidden and the kcal estimate would run off bucket-defaults.
        if (isLactating &&
            (!numChildrenAcknowledged || !childAgeAcknowledged)) {
          return false;
        }
        return true;
      case summaryStepIndex:
        // Disclaimer is plain text now (acceptance timestamp recorded on
        // finish), no gate.
        return true;
      case consentStepIndex:
        // Mandatory health-data consent; without it the coach can send
        // nothing. Analytics consent is optional, so not gated.
        return healthDataConsent;
      default:
        return true;
    }
  }

  static bool _parsesAsNumber(String s) =>
      double.tryParse(s.replaceAll(',', '.')) != null;
}
