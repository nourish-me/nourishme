// Where a MealEntry was entered from. Replaces the stringly-typed
// `source` parameter that used to live on ConfirmScreen, which a typo
// in a caller could silently desync from PostHog's `meal_logged.method`
// dimension. Enum gives us compile-time guarantees, the analyticsLabel
// getter is the single source of truth for the analytics string.
//
// Add a new source by extending the enum AND adding its analytics
// label. The labels are the wire-format PostHog already knows; don't
// rename without considering existing dashboards.
enum MealEntrySource {
  text('text'),
  photo('photo'),
  barcode('barcode'),
  favorite('favorite'),
  quickAdd('quick_add'),
  edit('edit'),
  history('history');

  // Stable string sent to PostHog as the meal_logged.method property.
  // Must match the values dashboards / cohorts were built against.
  final String analyticsLabel;

  const MealEntrySource(this.analyticsLabel);
}
