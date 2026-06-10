# Build 1.0.0+20 — TestFlight Release Notes

Stand: 2026-06-10. 67 Commits seit Build +19. Copy-paste-fertig für App
Store Connect → TestFlight → "What to Test" pro Sprache. ~3400 Zeichen
DE / ~3200 EN (Apple-Limit 4000).

---

## Deutsch

**Neu**

• Mikronährstoff-Tracker live im Diary-Header. Bis zu 3 selbstgewählte Mikros (Cholin, Folat, Eisen, B12, Jod, Vitamin D, DHA, Calcium, Zink) mit Tagesfortschritt; Tap aufs Donut zeigt Details und Quellen.
• Supplements per Foto scannen. Die App liest das Etikett mit Vision aus, du kannst mehrere Supplements parallel führen und jedes ohne neues Foto editieren.
• Coach fragt einmal pro Tag „Was möchtest du heute aufbrauchen?". Deine Antwort fließt in spätere Vorschläge ein, ohne dass du sie wiederholen musst.
• Neuer Coach-Fokus „Körperziel": etwas höheres Protein-Ziel für Muskelschutz, mit stillzeit-sicheren Defizit-Leitplanken (1800-kcal-Boden in Stillzeit, max. 300–500 kcal Defizit, frühestens 6–8 Wochen postpartum).
• Dritte Phase-Option im Onboarding: „weder schwanger noch stillend" (z.B. nach dem Abstillen).
• Settings komplett restrukturiert. Drei Bereiche im Drill-Down statt 11 Sections in einer langen Liste: Über dich / Coach & Ernährung / App.
• Push-Erinnerungen werden übersprungen, wenn der Slot heute schon geloggt wurde (nicht erst kurz vor Fire-Time, sondern nach Slot-Zeit-Bucket).
• Vergangenen Tag nachträglich loggen funktioniert jetzt auch auf Tagen, die schon Einträge haben.
• Diary: leere-Tage-Ranges zeigen ein + Icon — der Tap-CTA war vorher leicht zu übersehen.

**Verbessert**

• Protein-Bedarf bei Übergewicht: jetzt vom Normalgewicht (BMI 25) statt vom Ist-Gewicht (DGE 2025 Fußnote a). Vorher überschätzt.
• Coach-Antwort hängt nicht mehr 60+ Sekunden nach einem Mengen-Edit.
• Tap auf einen vergangenen Tag im Verlauf springt jetzt zuverlässig zum ersten Eintrag.
• Bundled-Scan + Text-Save in der gleichen Minute behält die Reihenfolge.
• Coach erwähnt nach 14 Uhr proaktiv Mikronährstoffe, die unter 70 % vom Tagesziel liegen.
• Diary-Header: Makro- und Mikro-Labels werden nicht mehr abgeschnitten, wenn rechts daneben Platz wäre.
• 6 deterministische Safety-Regeln (Koffein, Alkohol, Quecksilberfisch, rohe Tierprodukte, Leber im 1. Trimester, milchhemmende Kräuter) — funktionieren auch, wenn das Modell kurz nicht erreichbar ist.
• Crash-Reporting via Sentry, damit echte Bugs schneller bei mir landen.

**Polish**

• iOS-native Schriftskala statt eigener Mix.
• Em-Dashes raus aus allen UI-Strings und Coach-Antworten.
• Settings-Hinweistexte gekürzt, Details hinter Info-Icons.
• „Coach-Fokus" als eigener Onboarding-Schritt, Phase-Details werden bei „weder noch" übersprungen.

**Tipps-Deck aktualisiert**

• Neuer Tipp: Mikronährstoffe + Supplement-Scan + Customising über die Settings — viele Beta-Testerinnen hatten das übersehen.
• „Just say what you ate" rückt vor (direkt nach dem Barcode-Tipp).

---

## English

**New**

• Live micronutrient tracker in the diary header. Pick up to 3 (choline, folate, iron, B12, iodine, vitamin D, DHA, calcium, zinc) with daily progress; tap the donut for details and sources.
• Scan supplements by photo. The app reads the nutrition label via Vision; you can keep multiple supplements active and edit each one without rescanning.
• Coach asks once a day "anything you want to use up today?" and folds your answer into later suggestions so you don't repeat yourself.
• New "body goal" coach focus: slightly higher protein target for muscle preservation, with lactation-safe deficit guardrails (1800 kcal floor while producing milk, max 300–500 kcal deficit, earliest 6–8 weeks postpartum).
• Third phase option in onboarding: "neither pregnant nor producing breast milk" (e.g. after weaning).
• Settings fully restructured. Three grouped areas in a drill-down hub instead of 11 stacked sections: About you / Coach & nutrition / App.
• Push reminders skip when the slot is already logged today (by time-of-day bucket, not just within an hour of fire time).
• Retroactive logging now works on past days that already have entries.
• Diary: empty-day ranges show a + icon — the tap CTA was easy to miss before.

**Improved**

• Protein target for overweight users now derived from BMI-25 reference weight instead of current weight (per DGE 2025 footnote a). Was overestimating before.
• Coach reply no longer hangs 60+ seconds after an amount edit.
• Tapping a past day in History now reliably jumps to that day's first entry.
• Bundled scan + text save in the same minute keeps insertion order.
• Coach proactively names micronutrients under 70 % of target after 2pm.
• Diary header: macro and micro labels no longer get truncated when there's empty space next to them.
• 6 deterministic safety rules (caffeine, alcohol, mercury fish, raw animal products, T1 liver, lactation-suppressing herbs) — work even if the model is briefly unavailable.
• Crash reporting via Sentry so real bugs reach me faster.

**Polish**

• iOS-native type scale instead of our own mix.
• Em-dashes removed across UI strings and coach replies.
• Settings hints shortened, details moved behind info icons.
• "Coach focus" as its own onboarding step; phase details skipped on "neither".

**Tips deck updated**

• New tip: micronutrient tracker + supplement scan + customising via Settings — most beta testers had missed it.
• "Just say what you ate" moved up to sit right after the barcode tip.
