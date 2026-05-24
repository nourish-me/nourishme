// Single weight reading captured by the user. Pure visualization data
// (the Trends tab renders a line chart over time), no medical commentary
// in the app: weight interpretation belongs to the user's physician or
// midwife. profile.weightKg stays the source of truth for BMR/TDEE
// calculation; this entry log accumulates as the user edits Settings.
class WeightEntry {
  final String id;
  final double weightKg;
  final DateTime recordedAt;

  const WeightEntry({
    required this.id,
    required this.weightKg,
    required this.recordedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'weightKg': weightKg,
        'recordedAt': recordedAt.toIso8601String(),
      };

  factory WeightEntry.fromJson(Map<String, dynamic> json) => WeightEntry(
        id: json['id'] as String,
        weightKg: (json['weightKg'] as num).toDouble(),
        recordedAt: DateTime.parse(json['recordedAt'] as String),
      );
}
