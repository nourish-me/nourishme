import 'package:flutter_test/flutter_test.dart';
import 'package:nurturetrack/models/thread_item.dart';

// Locks the ThreadItem JSON round-trip for the new isSystemNotice marker that
// separates UI/system messages (empty-reply fallback, error texts) from real
// coach utterances. The contract that matters:
//   - legacy entries (persisted WITHOUT the key) must keep loading, defaulting
//     to isSystemNotice == false (behave exactly as before, no migration);
//   - a marked entry must round-trip true;
//   - an unmarked entry must NOT write the key (keeps the stored JSON lean,
//     same convention as responseType).

void main() {
  group('ThreadItem.isSystemNotice JSON round-trip', () {
    test('legacy entry without the key loads as false', () {
      final legacy = ThreadItem.fromJson({
        'id': 'cr-123',
        'timestamp': '2026-06-23T09:00:00.000',
        'type': 'coachResponse',
        'text': 'Echte Coach-Antwort von früher.',
        // no isSystemNotice key at all
      });
      expect(legacy.isSystemNotice, isFalse);
      expect(legacy.text, 'Echte Coach-Antwort von früher.');
      expect(legacy.type, ThreadItemType.coachResponse);
    });

    test('system-notice entry round-trips true and writes the key', () {
      final notice = ThreadItem.coachResponse(
        mealId: 'm1',
        text: 'Ich konnte gerade keine Antwort erzeugen. Versuch es bitte gleich noch mal.',
        at: DateTime(2026, 6, 23, 9),
        isSystemNotice: true,
      );
      final json = notice.toJson();
      expect(json['isSystemNotice'], true);
      expect(ThreadItem.fromJson(json).isSystemNotice, isTrue);
    });

    test('normal coach answer omits the key and round-trips false', () {
      final normal = ThreadItem.coachResponse(
        mealId: 'm1',
        text: 'Gut gemacht!',
        at: DateTime(2026, 6, 23, 9),
      );
      final json = normal.toJson();
      expect(json.containsKey('isSystemNotice'), isFalse);
      expect(ThreadItem.fromJson(json).isSystemNotice, isFalse);
    });

    test('coachAnswer carries the marker too (chat error path)', () {
      final notice = ThreadItem.coachAnswer(
        text: 'Verbindungsproblem. Versuch es gleich nochmal.',
        at: DateTime(2026, 6, 23, 9),
        isSystemNotice: true,
      );
      expect(ThreadItem.fromJson(notice.toJson()).isSystemNotice, isTrue);
    });
  });
}
