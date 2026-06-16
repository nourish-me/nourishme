import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

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
SnackBar importantSnack({
  required String message,
  required String dismissLabel,
}) =>
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      // Stay until the user actually dismisses (Vanessa Build+30: "wenn
      // ich nichts drücke sollte der nicht nach 10s verschwinden").
      // Duration.days(1) is the Flutter-idiomatic way to express
      // "persistent" - the SnackBar API requires a non-null duration.
      duration: const Duration(days: 1),
      action: SnackBarAction(label: dismissLabel, onPressed: () {}),
    );

String importantSnackLabel(BuildContext context) =>
    AppLocalizations.of(context).snackDismiss;
