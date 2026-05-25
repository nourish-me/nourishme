import '../models/weight_entry.dart';

// Recent weight trajectory derived from the logged history, expressed as a
// weekly rate so the coach can judge whether loss/gain is in a safe range.
class WeightTrend {
  final double latestKg;
  final double kgPerWeek;
  final int days;

  const WeightTrend({
    required this.latestKg,
    required this.kgPerWeek,
    required this.days,
  });

  // DGE: gradual loss up to ~0.5 kg/week is considered safe while producing
  // milk; faster loss can reduce supply. A gain of similar magnitude is also
  // worth surfacing. Used to decide whether the per-meal coach should mention
  // it at all (it always has it in chat).
  bool get isNotable => kgPerWeek.abs() >= 0.5;
}

// Computes the trend from the most recent window so a long-stable history
// doesn't dilute a recent change. Returns null when there isn't enough data
// (fewer than two entries, or too short a span to infer a weekly rate).
WeightTrend? computeWeightTrend(
  List<WeightEntry> entries, {
  int windowDays = 21,
  int minDays = 3,
}) {
  if (entries.length < 2) return null;
  final sorted = [...entries]
    ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
  final latest = sorted.last;
  final cutoff = latest.recordedAt.subtract(Duration(days: windowDays));
  var reference = sorted.firstWhere(
    (e) => e.recordedAt.isAfter(cutoff),
    orElse: () => sorted.first,
  );
  if (reference.recordedAt == latest.recordedAt) {
    reference = sorted.first; // only one point in the window
  }
  final days = latest.recordedAt.difference(reference.recordedAt).inDays;
  if (days < minDays) return null;
  final kgPerWeek = (latest.weightKg - reference.weightKg) / days * 7;
  return WeightTrend(
      latestKg: latest.weightKg, kgPerWeek: kgPerWeek, days: days);
}

// One-line, locale-aware summary for the coach context block.
String formatWeightTrendForCoach(WeightTrend t, {required bool isDe}) {
  final abs = t.kgPerWeek.abs().toStringAsFixed(1);
  final kg = t.latestKg.toStringAsFixed(1);
  if (isDe) {
    if (t.kgPerWeek.abs() < 0.05) {
      return 'Gewichtstrend: stabil (aktuell $kg kg, über ${t.days} Tage)';
    }
    final dir = t.kgPerWeek < 0 ? 'Abnahme' : 'Zunahme';
    return 'Gewichtstrend: $dir ca. $abs kg/Woche (aktuell $kg kg, über ${t.days} Tage)';
  }
  if (t.kgPerWeek.abs() < 0.05) {
    return 'Weight trend: stable (currently $kg kg, over ${t.days} days)';
  }
  final dir = t.kgPerWeek < 0 ? 'loss' : 'gain';
  return 'Weight trend: $dir ~$abs kg/week (currently $kg kg, over ${t.days} days)';
}
