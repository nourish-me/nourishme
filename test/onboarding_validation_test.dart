import 'package:flutter_test/flutter_test.dart';
import 'package:nurturetrack/screens/onboarding_validation.dart';

// Pure unit coverage for the onboarding Next-button gate, extracted from
// OnboardingScreen so the per-step rules are testable without the widget.

bool canAdvance({
  required int step,
  bool isPregnant = false,
  bool isLactating = false,
  bool phaseExplicitlyNeither = false,
  String heightText = '167',
  String weightText = '60',
  bool numChildrenAcknowledged = false,
  bool childAgeAcknowledged = false,
  bool healthDataConsent = false,
}) =>
    OnboardingValidation.canAdvance(
      step: step,
      isPregnant: isPregnant,
      isLactating: isLactating,
      phaseExplicitlyNeither: phaseExplicitlyNeither,
      heightText: heightText,
      weightText: weightText,
      numChildrenAcknowledged: numChildrenAcknowledged,
      childAgeAcknowledged: childAgeAcknowledged,
      healthDataConsent: healthDataConsent,
    );

void main() {
  test('welcome (0) and supplement (5) and unknown steps always advance', () {
    expect(canAdvance(step: 0), isTrue);
    expect(canAdvance(step: OnboardingValidation.supplementStepIndex), isTrue);
    expect(canAdvance(step: 99), isTrue);
  });

  group('phase (step 1): needs a phase pick', () {
    test('nothing picked → blocked', () {
      expect(canAdvance(step: 1), isFalse);
    });
    test('pregnant OR lactating OR explicit-neither → allowed', () {
      expect(canAdvance(step: 1, isPregnant: true), isTrue);
      expect(canAdvance(step: 1, isLactating: true), isTrue);
      expect(canAdvance(step: 1, phaseExplicitlyNeither: true), isTrue);
    });
  });

  test('goal (step 2) always advances (defaults to nutrients)', () {
    expect(canAdvance(step: 2), isTrue);
  });

  group('body (step 3): height + weight must parse', () {
    test('both valid (dot or comma decimal) → allowed', () {
      expect(canAdvance(step: 3, heightText: '167', weightText: '60'), isTrue);
      expect(
          canAdvance(step: 3, heightText: '167,5', weightText: '60,2'), isTrue);
    });
    test('missing or non-numeric → blocked', () {
      expect(canAdvance(step: 3, heightText: '', weightText: '60'), isFalse);
      expect(canAdvance(step: 3, heightText: '167', weightText: 'abc'), isFalse);
    });
  });

  group('phase details (step 4): lactation needs both acknowledgements', () {
    test('non-lactating → allowed regardless of acks', () {
      expect(canAdvance(step: OnboardingValidation.phaseDetailsStepIndex),
          isTrue);
    });
    test('lactating but acks missing → blocked', () {
      expect(
        canAdvance(
            step: OnboardingValidation.phaseDetailsStepIndex,
            isLactating: true,
            numChildrenAcknowledged: true,
            childAgeAcknowledged: false),
        isFalse,
      );
      expect(
        canAdvance(
            step: OnboardingValidation.phaseDetailsStepIndex,
            isLactating: true,
            numChildrenAcknowledged: false,
            childAgeAcknowledged: true),
        isFalse,
      );
    });
    test('lactating with both acks → allowed', () {
      expect(
        canAdvance(
            step: OnboardingValidation.phaseDetailsStepIndex,
            isLactating: true,
            numChildrenAcknowledged: true,
            childAgeAcknowledged: true),
        isTrue,
      );
    });
  });

  test('summary (step 6) always advances', () {
    expect(canAdvance(step: OnboardingValidation.summaryStepIndex), isTrue);
  });

  group('consent (step 7): mandatory health-data consent', () {
    test('without consent → blocked', () {
      expect(canAdvance(step: OnboardingValidation.consentStepIndex), isFalse);
    });
    test('with consent → allowed', () {
      expect(
          canAdvance(
              step: OnboardingValidation.consentStepIndex,
              healthDataConsent: true),
          isTrue);
    });
  });
}
