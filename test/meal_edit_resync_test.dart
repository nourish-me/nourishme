import 'package:flutter_test/flutter_test.dart';
import 'package:nurturetrack/services/thread_repository.dart';

// Pins the pure gate behind the 13:36-ordering fix. A meal edit must move
// the meal's ThreadItem (the sort key) whenever EITHER the nutritional
// values OR the time changed. The time half is the bug: a pure time-edit
// updated MealEntry.createdAt (the chip) but, because the old gate only
// checked values, never resynced the ThreadItem timestamp - so the entry
// kept sorting at its old slot while the chip showed the new time.
//
// Ordering-resync only. Whether such an edit also regenerates the coach
// reply is a SEPARATE decision (CoachSessionManager.shouldRegenCoachOnEdit,
// covered in coach_session_manager_test.dart) - the two are deliberately
// decoupled: a shifted clock resyncs ordering but never fires a Claude call.
void main() {
  final morning = DateTime(2026, 6, 23, 9, 0);
  final afternoon = DateTime(2026, 6, 23, 13, 36);

  group('mealEditNeedsThreadResync', () {
    test('pure time-edit (values equal, time changed) → true (the bug fix)',
        () {
      expect(
        mealEditNeedsThreadResync(
          oldCreatedAt: morning,
          newCreatedAt: afternoon,
          valuesChanged: false,
        ),
        isTrue,
      );
    });

    test('value-edit (time unchanged) → true', () {
      expect(
        mealEditNeedsThreadResync(
          oldCreatedAt: morning,
          newCreatedAt: morning,
          valuesChanged: true,
        ),
        isTrue,
      );
    });

    test('nothing changed (same time, same values) → false', () {
      expect(
        mealEditNeedsThreadResync(
          oldCreatedAt: morning,
          newCreatedAt: morning,
          valuesChanged: false,
        ),
        isFalse,
      );
    });

    test('fresh meal (oldCreatedAt == null), no value change → false', () {
      // A new meal has no prior ThreadItem to resync here; it is added on the
      // !isEdit path. Only a real value change would force true.
      expect(
        mealEditNeedsThreadResync(
          oldCreatedAt: null,
          newCreatedAt: afternoon,
          valuesChanged: false,
        ),
        isFalse,
      );
    });
  });
}
