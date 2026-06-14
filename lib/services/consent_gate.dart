// Pure decision layer for "may we send X to a third-party service?"
// Kept as static functions over plain inputs so the logic is unit-
// testable without spinning up a SettingsRepository or hitting Hive.
// Anything that triggers a network call to Anthropic or PostHog should
// route through one of these checks first, NOT inline the same
// expression repeatedly - a single source of truth keeps GDPR audits
// straightforward.
class ConsentGate {
  ConsentGate._();

  // GDPR Art. 9 lit. a: explicit consent for processing health data
  // (pregnancy phase, lactation, weight, meal payloads, photos of food)
  // by Anthropic in the US. Returns true ONLY when the user actively
  // ticked the mandatory consent box during onboarding and we have a
  // timestamp on record.
  //
  // Hard rule: when this returns false, no profile or meal data may
  // leave the device. Every parseMeal / chat / parseSupplementLabel
  // call must check this first and short-circuit when it's false.
  static bool canSendHealthData(DateTime? healthDataConsentAt) =>
      healthDataConsentAt != null;

  // GDPR-compliant opt-in for non-essential analytics (PostHog, EU).
  // Returns true ONLY when the user actively ticked the OPTIONAL
  // analytics box. Returning false silences every event - no flushing,
  // no buffered backlog, no "we'll send it later" semantics.
  static bool canTrackAnalytics(DateTime? analyticsConsentAt) =>
      analyticsConsentAt != null;
}
