import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../main.dart' show rootScaffoldMessengerKey;

// Builds a SnackBar tuned for "user needs to actually read this" messages
// (Coach paused, Past-day saved, Cross-day bulk, etc.). Style intent
// (Vanessa Build+29 feedback: default 3-4 s was too fast to read):
//   - 10 s duration (Material 3 caps SnackBar at this; longer requires
//     a different surface)
//   - explicit "Verstanden" / "Got it" action so readers can dismiss
//     ahead of the timer; tapping the action also closes the snack
//   - SnackBarBehavior.floating to lift it off the bottom edge so the
//     close button is comfortably tappable
//   - swipe-to-dismiss is on by default on floating snacks
//
// For lightweight confirmations ("Mahlzeit gespeichert") keep the
// vanilla SnackBar with the 4 s default - this helper is for the
// surface where the user is being told something they couldn't have
// predicted.
//
// Caller-supplied dismissLabel keeps the helper synchronous-friendly:
// the message itself is often pre-captured before async work, and we
// don't want to wake AppLocalizations.of(context) on a possibly-stale
// BuildContext from a finally{} block. importantSnackLabel() pulls it
// off a live context once, up-front.
// Canonical duration for the importantSnack helper. Exported so callers
// can chain a belt-and-braces force-dismiss timer at the same length.
const Duration importantSnackDuration = Duration(seconds: 8);

SnackBar importantSnack({
  required String message,
  required String dismissLabel,
}) =>
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      // Build +35 snackbar audit: 8 s sits inside Material 3's 4-10 s
      // range for snackbars-with-action and is short enough that the
      // tester complaint ("hält ewig, ich kann nicht woanders klicken")
      // doesn't recur. Combined with the snackbarDismissOnNavObserver in
      // main.dart, snacks now also disappear the moment the user
      // navigates away. The explicit Verstanden action stays so
      // attentive readers can dismiss earlier.
      duration: importantSnackDuration,
      action: SnackBarAction(label: dismissLabel, onPressed: () {}),
    );

// Belt-and-braces force-dismiss: Flutter's floating SnackBar with an
// action sometimes ignores its declared duration on iOS (tester report
// Build +35 follow-up: "snack stays forever"). Schedule a manual
// hideCurrentSnackBar to guarantee dismissal.
void scheduleImportantSnackForceDismiss() {
  Future.delayed(importantSnackDuration + const Duration(milliseconds: 200),
      () {
    rootScaffoldMessengerKey.currentState?.hideCurrentSnackBar();
  });
}

String importantSnackLabel(BuildContext context) =>
    AppLocalizations.of(context).snackDismiss;
