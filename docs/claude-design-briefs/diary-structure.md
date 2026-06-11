# Brief: Diary readability + meal-slot structure

For Claude Design. Two specific UX problems on the Tagebuch (diary) screen
that beta testers keep flagging. Looking for design directions, not just
small CSS tweaks.

---

## Background

NourishMe is a nutrition tracker for pregnant and breastfeeding moms. The
diary is the main screen — it scrolls vertically through days, each day
showing the meals logged in chronological order, with coach replies
inline between meals. Users open the app ~6–10 times a day, mostly to
log a meal or skim what they ate.

The diary today (rough ASCII of one day's worth):

```
─────── Heute, Mittwoch ─────────────
  Müsli mit Joghurt          08:24
                              380 kcal  ✏

  Coach: "Guter Start. Versuche
   mittags ein Stück Lachs..."

  Skyr mit Beeren            10:15
                              120 kcal  ✏

  Lachs-Bowl                 13:02
                              580 kcal  ✏

  Coach: "Top, Iod-Bedarf für
   heute fast gedeckt..."

─────── Gestern, Dienstag ───────────
  ... etc
```

Top of screen is a permanent header showing today's totals (kcal/macros/
3 micros). Slidable actions on each meal row for edit/duplicate/delete.
Tap a meal row = edit. Tap a past day's separator = add meal to that day.

## Problem 1 — Tage sind nicht auf einen Blick unterscheidbar

Beta feedback: "Beim Scrollen verliere ich, wo der eine Tag aufhört und
der nächste anfängt." The day separator is just a thin rule + date label
right now; visually too quiet against the meal cards stacked between
days.

What we've tried internally:
- Per-day micro pills next to the separator (live, shows partial day)
- "+" icon on past-day separators (recently added so add-affordance is
  visible)

What we haven't tried (open to whatever you suggest):
- Alternating background tints per day
- A bigger day "card" wrapper around each day's meals
- Sticky day header that pins until the next day reaches the top
- Per-day summary chip (kcal vs target, completed meals count)
- Day-of-week + day-of-month as separate visual elements
- Subtle date-jumping affordance (mini calendar strip at top?)

## Problem 2 — No meal-slot structure (Frühstück / Mittag / Abend / Snack)

Beta feedback: "Ich sehe nur eine Liste mit Uhrzeiten — keine Struktur,
keine Hilfe zu erkennen, ob ich heute überhaupt zu Mittag gegessen habe."

Two things rolled into one wish:

(a) **Recognition** — let me see at a glance which slot a meal was. A
user logging "Skyr 10:15" knows it was a snack; the diary should reflect
that grouping so a full day reads as Frühstück → Snack → Mittag →
Snack → Abend.

(b) **Gentle structure nudge** — a soft signal that a slot is "missing"
on a given day. Not a guilt-trip, not a push notification, just a way to
notice "hm, ich hab heute noch nichts gegessen, was Mittagessen
ähnelt." Goal: nudge people toward structured eating without prescribing
when to eat.

Slot inference is technically easy — we already have reminder time slots
in settings (breakfast 8:00, midmorning 10:30, lunch 12:30, midafternoon
15:30, dinner 18:30) and a `slotForMealTime()` helper that maps a
timestamp to the nearest slot by bucket. So the data is there; the
question is purely how to **present** it.

Open questions for you:

- Should slots be shown as section headers within a day ("Frühstück
  · 08:00–10:00") with meals tucked underneath?
- Or as tags / pills on each meal card ("Müsli 380 kcal · Frühstück")?
- Or as a horizontal slot-strip at the top of each day (5 little
  circles, filled when the slot is covered)?
- How do we treat "snack between slots" without being pedantic?
- How do we visualise an empty slot without nagging? Greyed
  placeholder? A dotted gap in the timeline?
- How does this read on a Snacker-only day where someone genuinely
  eats five small meals — the structure shouldn't punish that.
- What changes on past days (read-only, no nudge needed) vs today
  (incomplete, nudge plausible)?

## Constraints

- iOS-only, Material 3 base theme. We're using a hand-tuned "Field
  Manual" palette: warm paper background, deep pine green for primary,
  amber accent. Type system installed (Newsreader display, SF Pro body,
  JetBrains Mono for labels/numbers).
- The diary is also the same screen where the user types a new meal —
  the input bar sits at the bottom, ~64 pt tall. Any sticky-header
  design needs to coexist with that.
- We respect DynamicType, so absolute sizes shouldn't blow up at the
  large-text accessibility setting.
- Phase-aware: a pregnant user, a lactating user, and a "neither"-phase
  user all see this. Coach focus and goal are also configurable.
- Single-user app, no social features, no sharing.

## What we don't want

- Heavy gamification (streak counters in your face, badges, etc.)
- Adding chrome for the sake of structure when the existing flow works
  well for most users
- Anything that makes logging feel like work or surveillance

## What we'd love from you

- Two or three rough directions for **Problem 1** (day differentiation)
  with quick sketches or written description of the visual mechanic
- Two or three rough directions for **Problem 2** (slot structure +
  gentle nudge) with the same
- Honest opinion on whether one or both problems are real or whether
  we're over-fitting to two loud testers
- Anything we missed in the framing
