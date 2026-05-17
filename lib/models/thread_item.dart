enum ThreadItemType {
  meal,
  coachResponse,
  userQuestion,
  coachAnswer,
}

class ThreadItem {
  final String id;
  final DateTime timestamp;
  final ThreadItemType type;
  final String? mealId;
  final String? text;

  const ThreadItem({
    required this.id,
    required this.timestamp,
    required this.type,
    this.mealId,
    this.text,
  });

  factory ThreadItem.meal({required String mealId, required DateTime at}) =>
      ThreadItem(
        id: 'm-${at.microsecondsSinceEpoch}',
        timestamp: at,
        type: ThreadItemType.meal,
        mealId: mealId,
      );

  factory ThreadItem.coachResponse({required String text, required DateTime at}) =>
      ThreadItem(
        id: 'cr-${at.microsecondsSinceEpoch}',
        timestamp: at,
        type: ThreadItemType.coachResponse,
        text: text,
      );

  factory ThreadItem.userQuestion({required String text, required DateTime at}) =>
      ThreadItem(
        id: 'uq-${at.microsecondsSinceEpoch}',
        timestamp: at,
        type: ThreadItemType.userQuestion,
        text: text,
      );

  factory ThreadItem.coachAnswer({required String text, required DateTime at}) =>
      ThreadItem(
        id: 'ca-${at.microsecondsSinceEpoch}',
        timestamp: at,
        type: ThreadItemType.coachAnswer,
        text: text,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'type': type.name,
        if (mealId != null) 'mealId': mealId,
        if (text != null) 'text': text,
      };

  factory ThreadItem.fromJson(Map<String, dynamic> j) => ThreadItem(
        id: j['id'] as String,
        timestamp: DateTime.parse(j['timestamp'] as String),
        type: ThreadItemType.values.firstWhere((t) => t.name == j['type']),
        mealId: j['mealId'] as String?,
        text: j['text'] as String?,
      );
}
