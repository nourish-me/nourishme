import 'coach_response_type.dart';

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
  // Optional safety-layer classification (Task #88.5). Drives bubble
  // styling: emergency = red-ish + clinic-call affordance, escalation
  // = orange + "talk to midwife" framing, blocked = grey + fallback
  // message. Null/normal renders as a regular coach bubble. Legacy
  // entries (pre-#93) carry null and read as normal.
  final CoachResponseType? responseType;
  // System/UI message rather than a real coach utterance: the empty-reply
  // fallback and the error/connection messages. Rendered as a bubble so the
  // user sees it, but excluded from the chat history fed back to the coach
  // (_buildHistory) so the model never reads its own "couldn't reply" /
  // "overloaded" notices as prior turns. Default false; legacy entries
  // (without the key) load as false and behave exactly as before.
  final bool isSystemNotice;

  const ThreadItem({
    required this.id,
    required this.timestamp,
    required this.type,
    this.mealId,
    this.text,
    this.responseType,
    this.isSystemNotice = false,
  });

  factory ThreadItem.meal({required String mealId, required DateTime at}) =>
      ThreadItem(
        id: 'm-${at.microsecondsSinceEpoch}',
        timestamp: at,
        type: ThreadItemType.meal,
        mealId: mealId,
      );

  factory ThreadItem.coachResponse({
    String? mealId,
    required String text,
    required DateTime at,
    CoachResponseType responseType = CoachResponseType.normal,
    bool isSystemNotice = false,
  }) =>
      ThreadItem(
        id: 'cr-${at.microsecondsSinceEpoch}',
        timestamp: at,
        type: ThreadItemType.coachResponse,
        mealId: mealId,
        text: text,
        responseType: responseType,
        isSystemNotice: isSystemNotice,
      );

  factory ThreadItem.userQuestion({required String text, required DateTime at}) =>
      ThreadItem(
        id: 'uq-${at.microsecondsSinceEpoch}',
        timestamp: at,
        type: ThreadItemType.userQuestion,
        text: text,
      );

  factory ThreadItem.coachAnswer({
    required String text,
    required DateTime at,
    CoachResponseType responseType = CoachResponseType.normal,
    bool isSystemNotice = false,
  }) =>
      ThreadItem(
        id: 'ca-${at.microsecondsSinceEpoch}',
        timestamp: at,
        type: ThreadItemType.coachAnswer,
        text: text,
        responseType: responseType,
        isSystemNotice: isSystemNotice,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'type': type.name,
        if (mealId != null) 'mealId': mealId,
        if (text != null) 'text': text,
        if (responseType != null && responseType != CoachResponseType.normal)
          'responseType': responseType!.wire,
        if (isSystemNotice) 'isSystemNotice': true,
      };

  factory ThreadItem.fromJson(Map<String, dynamic> j) => ThreadItem(
        id: j['id'] as String,
        timestamp: DateTime.parse(j['timestamp'] as String),
        type: ThreadItemType.values.firstWhere((t) => t.name == j['type']),
        mealId: j['mealId'] as String?,
        text: j['text'] as String?,
        responseType: j['responseType'] is String
            ? CoachResponseType.fromWire(j['responseType'] as String)
            : null,
        isSystemNotice: j['isSystemNotice'] == true,
      );
}
