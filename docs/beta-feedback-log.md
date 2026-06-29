# Beta Feedback Log

Collection point for tester voices from the beta phase. One block per session, sorted chronologically. **Internal document** - real names are in here so Vanessa can trace per-tester what needs to be addressed where. Do NOT share in demo screenshots or public repos.

**Pattern rule:** single voices are noted but NOT acted on invasively right away. Only when two or more testers independently raise the same point does it become a UI/feature change. Exception: no-brainer improvements that benefit every tester (prompt sharpening, coach tone, safety corrections) go in directly.

## Legend

**Type:**
- 🐛 Bugfix - broken behaviour or wrong data, usually small to medium
- 💎 Polish - UX/tone/trigger fine-tuning, usually small
- 🚀 Feature - new mechanic, usually larger

**Status:**
- ✅ fixed
- 🟡 planned (open)
- ❓ waiting on tester follow-up
- 🔬 single voice, collecting
- ⛔ closed (closed-by-tester / clarified / wontfix / out-of-scope)

**Build column:**
- `+36` = already shipped
- `→ +37` = planned for build
- `→ ?` = not yet scheduled

## View 1 - Master Long List (sorted by priority)

→ Aktueller Status aller offenen Items: siehe [`board.md`](board.md).

---

## View 2 - Per-Tester View

For per-tester update messages: what each tester reported, with status and build.

### Eva (T1) — lactation, often out and about with toddler DE

| Feedback                                                     | Type | Status | Build     |
| ------------------------------------------------------------ | ---- | ------ | --------- |
| Photo recognition inaccurate                                 | 💎   | ✅      | up to +33 |
| Retro-logging discovery (header pill)                        | 💎   | ✅      | +36       |
| Daily-target frustration (snacks forgotten, coach guardrail) | 💎   | ✅      | +36       |
| Repeat-meal discovery (favourites via coach)                 | 💎   | ✅      | +36       |
| Forgets to log because phone isn't at table                  | -    | ❓      | -         |

**Update-Message [DE]:**

> Hey Eva, kurzes Update: die App-Version, die zu deinen letzten Punkten direkt was bringt, ist auf dem Weg.
>
> **NEU in der kommenden Version, passend zu unserem Chat:**
> - **Tagesziel-Frust:** Coach-Guardrail eingebaut, der dich sanft erinnert dass das Tagesziel ein Wochen-Richtwert ist - genau die Framing-Idee, die ich dir in der Sprachnachricht erklärt hatte, jetzt fest verdrahtet im Coach-Tone.
> - **Favoriten-Discovery:** beim ersten Meal-Save wird der Stern oben rechts aktiv beworben, damit der Workflow „halbe Brezn als Favorit speichern → Re-Log mit einem Tap" sichtbar wird. Genau das was ich neulich beschrieben hatte, jetzt nicht mehr versteckt.
> - **Retro-Logging:** das Datum oben im Tagebuch ist jetzt der Titel selbst mit kleinem Pfeil, bei vergangenen Tagen siehst du „VERGANGENER TAG" + „Heute"-Button zum Zurückspringen. Eine der zwei Wege aus meiner Sprachnachricht, jetzt deutlich prominenter.
> - Foto-Erkennung-Prompt wurde nochmal nachgezogen (Salat-Komponenten werden jetzt aktiv aufgezählt statt generalisiert).
>
> Wenn du Lust hast, sag mir gerne noch zurück was du aus meinen vier Rückfragen schon ausprobiert hast und wo dein Suchpfad anders war - kein Stress, das hilft mir nur dabei zu verstehen wo die Discovery-Lücken noch sind.
>
> Danke nochmal fürs Mitdenken!

### Celine (T2) — pregnant, works at a school DE

| Feedback                                      | Type | Status | Build                  |
| --------------------------------------------- | ---- | ------ | ---------------------- |
| Backcamembert false-positive raw-milk warning | 🐛   | ✅      | old                    |
| Praise even for chocolate (tone confirmation) | -    | ✅      | -                      |
| Iodine-gap nag trigger tuning                 | 💎   | ✅      | +37 (cooldown enough)  |
| Multi-photo bulk flow for afternoon           | 🚀   | ✅      | +27 (discovery)        |
| Weekly micronutrient overview (dedicated tab) | 🚀   | 🟡     | → +39 (partial in +36) |

**Update-Message [DE]:**

> Hey Celine, ich war neulich in der WhatsApp schon sehr lösungsfreudig unterwegs (Cooldown, Trends-Tab, Sonntag-Push). Bevor ich das wirklich baue möchte ich aber nochmal kurz mit dir checken was du eigentlich brauchst - sonst baue ich an deinem Bedarf vorbei. Vier kleine Rückfragen, dann setze ich es um:
>
> **Iod-Cooldown (1×/Woche):**
> - Würde 1×/Woche immer noch zu oft auftauchen? Anders gesagt: lieber Cooldown im Coach (selten, aber nicht null), oder lieber komplett aus dem Coach raus (= Toggle als Default) und du prüfst stattdessen aktiv in der Wochenansicht ob was fehlt?
> - Gilt das nur für Iod, oder gibt's andere Mikros (Vitamin D, etc.) wo du bewusst auf Supplementierung verzichtest und gleich behandelt werden sollten?
>
> **Wochenübersicht-Tab:**
> - Was wäre der Hauptzweck für dich - beruhigt sein dass alles im grünen Bereich ist, oder gezielt nachsteuern („nächste Woche mehr Algen einbauen")? Das ändert das Design (passiv vs. handlungsempfehlend).
> - Wann würdest du auf Top-Quellen pro Nährstoff tappen - täglich, nur 1× pro Woche, oder eher gar nicht (= nicht wichtig genug)?
>
> **Donut-„sporadisch":**
> - Meinst du der Donut taucht zu selten auf (sollte häufiger), zu unauffällig (sollte prominenter sein), oder genau richtig zurückgenommen (deshalb passive Wochenansicht statt mehr Donut)?
>
> **Sonntag-Recap-Push:**
> - Wäre das was du dir wünschen würdest, oder war das eher meine Projektion? Möchtest du überhaupt Push-Erinnerungen für sowas?
>
> Plus noch eine Rückfrage von neulich: **Multi-Photo-Upload** gibt es schon länger (im iOS-Picker mehrere Bilder auswählen, alle landen im Review-Screen, EXIF-Zeit als Default). Hast du das Feature schon entdeckt? Falls nicht, kann ich dir kurz beschreiben wie du es findest.
>
> Sorry für die zweite Runde Fragen - lieber jetzt 5 Minuten verstehen als 3 Wochen am Bedarf vorbei zu bauen. Sprachnachricht oder zwei Sätze pro Punkt reichen total.
>
> Danke fürs Testen!

### Corina (T3) — lactation, 1-year-old child EN

| Feedback                               | Type | Status    | Build                           |
| -------------------------------------- | ---- | --------- | ------------------------------- |
| Push reminder fires despite logging    | 🐛   | ✅         | +35                             |
| Snack recommendations too frequent     | 💎   | ✅         | +25                             |
| History tiles show micros              | 💎   | ✅         | +36                             |
| Repeat-meal discovery (favourites)     | 💎   | ✅         | +36                             |
| Daily-weight + auto kcal-adjust        | 🚀   | 🟡        | → +37                           |
| Dynamic activity adjustment (HealthKit + manual fallback) | 🚀   | ⛔         | parked in idea-backlog          |
| Water tap counter                      | 🚀   | 🟡        | → +38                           |
| Pattern-avoidance weekly coach         | 🚀   | 🟡        | → +38                           |
| Component granularity per meal         | 🚀   | 🟡        | → +39                           |
| Cycle / period awareness               | -    | ⛔         | out-of-scope (see idea-backlog) |
| Delete bug                             | -    | ⛔         | closed-by-tester                |
| Daily calorie estimate 2600 kcal       | -    | ⛔         | clarified                       |
| "Coffee remember" feature              | -    | ❓         | -                               |
| Recruitment of 9 lactating moms        | -    | strategic | -                               |

**Update-Message [EN] — ON HOLD (2026-06-19):**

Corina has had a heavy feedback exchange in the last days (multiple deep WhatsApp threads covering 10+ items). Holding the next written update so she doesn't feel barraged. Send when:
- We've shipped the items currently flagged → +37/+38/+39 (so the message has substance to confirm), OR
- Corina reaches out with new feedback / questions of her own

**Open questions to address when the next message goes out:**

1. **Workout/sport sessions scope** — confirm with her that the app stays as a nutrition coach with kcal-input, NOT a fitness tracker (no workout journal, no streaks/trends). Sport sessions give a kcal-plus on top of daily target. Does that fit what she wanted, or did she have something richer in mind?
2. **"Coffee remember" → favourites discovery** — after the +36 SnackBar tip surfaces the favourites feature, validate with her that this covers what she meant by "remember", or whether she actually wanted a *reminder* (app pings at 9 am: "your usual coffee?") instead of a quick-repeat function.
3. **Cycle reversal** — we initially said yes in WhatsApp (Apple-Health-context-layer angle), then reversed back to out-of-scope after sleeping on it. Needs an explicit honest mention with reasoning (own lifecycle phase, own data model, specialised apps do this better) when the topic comes up again, so she doesn't feel ignored.
4. **Multi-photo bulk-save discovery** — promised to build it her exact way, but it already exists since +27 (was a discovery problem). Confirm whether she found it / uses it now.

**Building blocks for the eventual message** (mix-and-match when ready):
- Confirmed in build: push reminder fix, salad midwife disclaimer, snack recommendation toggle, history-tile micros, daily-target-frustration coach guardrail, favourites SnackBar tip
- Roadmap with her design clarifications:
  - Daily-weight + active kcal-adjust (manual morning input → "eat less today" / "ok to eat more")
  - Water tap-counter (two home-screen icons "my glass" + "my bottle", custom sizes in Settings, no reminders)
  - Pattern-avoidance weekly coach ("hey, lots of sugar this week" style)
  - Component granularity per meal (with Sarah)

### Svenja (T5) — new DE

| Feedback | Type | Status | Build |
|---|---|---|---|
| Retro-logging discovery (header pill) | 💎 | ✅ | +36 |
| Repeat-meal discovery (favourites via coach) | 💎 | ✅ | +36 |

**Update-Message [DE]:**

> Hey Svenja, eine neue App-Version ist unterwegs - hoffentlich bald bei dir!
>
> Aus deinem Feedback gefixt mit der kommenden Version:
> - Retro-Logging-Discovery: das Datum oben im Tagebuch ist jetzt der Titel mit Pfeil, plus „VERGANGENER TAG"-Hinweis + „Heute"-Button bei vergangenen Tagen
> - Beim ersten Meal-Save siehst du einen einmaligen Hinweis auf die Favoriten-Funktion (Stern oben rechts beim Speichern), damit du häufige Mahlzeiten in Sekunden wieder loggen kannst
>
> Eine Rückfrage:
> - Hast du die Favoriten-Funktion vorher schon entdeckt, oder ist der neue Tipp das erste Mal dass du davon hörst? Falls Letzteres: probier sie ein paar Tage aus und sag mir, ob das deine „häufige Mahlzeiten"-Erwartung trifft, oder ob der Coach sie zusätzlich proaktiv vorschlagen sollte.
>
> Danke fürs Testen!

### Simone (T6) — lactation DE

| Feedback | Type | Status | Build |
|---|---|---|---|
| Shell-pasta confusion (Conchigliette) | 🐛 | ✅ | +34/+35 |
| Push reminder fires despite logging | 🐛 | ✅ | +35 |
| kcal estimate too low (320 vs 555) | 🐛 | ✅ | confirmed Build 35 (560 kcal) |

**Update-Message [DE]:**

> Hey Simone, danke für die schnellen Rückmeldungen gestern! Damit haken wir die zwei Punkte aus deiner letzten Runde sauber ab:
> - Muschelnudel/Conchiglie-Verwechslung: weg ✅
> - Push-Erinnerungen trotz geloggter Mahlzeit: weg ✅
>
> Plus deine 560 kcal-Schätzung auf der Hühnersuppe lag schön nah an den ~555 kcal, die wir als realistisch identifiziert hatten.
>
> Mit der nächsten App-Version geht noch ein zusätzlicher Suppen-Anker raus, der die kcal-Schätzung für Suppen mit Sättigungs-Beilage absichert („nie unter 100 kcal/100g"). Falls du also wieder eine Suppe loggst und die Schätzung sich komisch niedrig anfühlt, sag Bescheid - sonst ist von deiner Seite alles aus dem Backlog raus.
>
> Danke fürs gewissenhafte Testen!

### Sarah (T7) — lactation, Folio supplement DE

| Feedback | Type | Status | Build |
|---|---|---|---|
| DHA hallucination 325% from porridge | 🐛 | ✅ | +35 |
| Coach chat sees micros + supplements | 💎 | ✅ | +35 |
| Component granularity per meal | 🚀 | 🟡 | → +39 |
| More than 3 micros + dedicated tab | 🚀 | 🟡 | → +39 |
| Streak-Logik / Gamification (Monatsstreak) | 🚀 | ⛔ | out-of-scope (idea-backlog) |

**Update-Message [DE]:**

> Hey Sarah, super lieb! Dein „richtig gut um einen bewussteren Blick für Nährstoffe zu bekommen" macht mir gerade voll Mut, weil das genau der Anspruch der App ist.
>
> Zu deinen zwei konkreten Wünschen:
>
> 1. **Mehr als 3 Mikros**: deine Struktur „3 in der Übersicht vorne + eigener Reiter mit allen ausgewählten" trifft genau unseren Plan. Geplant für eine der kommenden Versionen.
> 2. **Komponenten-Granularität**: dein Lern-Motiv („was muss ich für welche Nährstoffe essen") macht mir klar, dass eine Coach-Variante auf Nachfrage nicht reicht - du willst es bei jeder Mahlzeit sehen, damit sich Muster einprägen. Also: wir bauen die Aufschlüsselung in die Mahlzeit-Karte ein (pro Komponente: kcal + Mikros + Quellen-Highlight). Datenmodell-Update, kommt in einer der nächsten Versionen.
>
> Eine Rückfrage zur Implementierung:
> - Wenn du eine Mahlzeit „Porridge mit Haferflocken, Walnüssen, Leinsamen, Heidelbeeren, Honig" loggst, möchtest du jede Komponente komplett einzeln aufgeschlüsselt (kcal + Mikros pro Item), oder reicht eine Quellen-Auflistung pro Mikronährstoff („Jod kommt aus: Heidelbeeren ~45µg + Leinsamen ~12µg")? Erstes ist umfangreicher, zweites schneller umsetzbar und vielleicht zum Lernen sogar fokussierter.
>
> Danke nochmal für das wertvolle Feedback!

### Isabella Hoesch (T8) — TestFlight, iPhone 11 DE

| Feedback | Type | Status | Build |
|---|---|---|---|
| Lactation profile gets pregnancy warnings | 🐛 | ✅ | +36 |
| Onboarding daily-volume slider as "estimated card" | 💎 | ✅ | +36 |
| History tiles show micros with status icons | 💎 | ✅ | +36 |
| Retro-logging discovery (pizza for yesterday) | 💎 | ✅ | +36 |
| Day switch lands at end of today's chat | 🐛 | 🟡 | → +37 |
| More than 3 micros + dedicated tab | 🚀 | 🟡 | → +39 |

**Update-Message [DE] — SENT 2026-06-20 (follow-up with apology + scroll-fix-correction):**

> Hey Isa, ich wollte mich nochmal richtig entschuldigen dass ich so spät auf deine Screenshots reagiert habe. Die landeten in der Internal-Feedback-Sektion in App Store Connect, die mir ehrlich gesagt erst kürzlich aufgefallen ist - hatte sie schlicht übersehen. Sorry dafür, deine Reports waren super strukturiert und hätten viel früher in den Backlog gemusst.
>
> Die neue App-Version ist gerade auf dem Weg ins TestFlight und enthält folgende Sachen aus deinen Reports:
> - ⚠️ Stillzeit-Profil kriegt keine Schwangerschafts-Warnungen mehr (das war P0, dein Mozzarella-Carpaccio + Räucherlachs-Beispiel)
> - Onboarding-Tagesvolumen sitzt jetzt in einer „Berechnet für dich"-Karte mit klarem Marker
> - Verlauf zeigt drei Mikronährstoff-Chips pro Tag mit Status-Icons
> - Tagebuch-Header: das Datum ist jetzt der Titel mit Pfeil + „VERGANGENER TAG"-Hinweis bei vergangenen Tagen
> - Bonus: Tandem-Phase (Schwanger + milchproduzierend) ist jetzt in den Settings als 4. Option
>
> Was noch nicht drin ist, aber für den nächsten Build geplant:
> - Mehr als 3 Mikros + eigener Reiter mit allen ausgewählten
> - Der Datum-Switch-Scroll-Fix - hatte ich dir letzte Woche zugesagt, beim Re-Test heute hat er aber leider noch nicht gegriffen. Schiebe ich in eine saubere Audit-Runde, kommt im nächsten Build richtig
>
> Nochmal danke für die strukturierten Reports - hat echt geholfen!

**Vorheriger Draft (an Isabella gestern gesendet, danach durch den o.g. follow-up superseded):**

> Hey Isabella, nochmal eine neue App Version ist unterwegs - hoffentlich bis (über)morgen bei dir! 
>
> Eine Entschuldigung vorab: ich habe **heute erst** in App Store Connect die Internal-Feedback-Sektion entdeckt, wo dein TestFlight-Feedback mit Screenshots landet. Mir war das vorher nicht klar - daher kam dein Feedback erst heute richtig in meinen Backlog. Sorry für die Verzögerung! **Vielen Dank trotzdem für die super strukturierten Reports mit Screenshots**, die haben sofort gezeigt wo ich was tun muss.
>
> Aus deinem Feedback gefixt mit der Version die (über)morgen kommt::
> - ⚠️ Stillzeit-Profil bekommt keine Schwangerschafts-Warnungen mehr (war P0 klinisch - du hattest Mozzarella Carpaccio + Räucherlachs gemeldet)
> - Onboarding Tagesvolumen-Slider sitzt jetzt in einer „Berechnet für dich"-Karte mit klarem Marker
> - Verlauf-Kacheln zeigen drei Mikronährstoffe pro Tag mit Status
> - Retro-Logging-Discovery: Datum oben als Titel mit Pfeil + „VERGANGENER TAG"-Hinweis bei vergangenen Tagen
> - **Bonus:** Tandem-Phase (Schwanger + milchproduzierend) ist jetzt in den Settings auswählbar - das war vorher nicht möglich, obwohl im Onboarding ja
> - Datum-Switch landet jetzt am Anfang des gewählten Tages, nicht mehr am Ende des heutigen Chats (Scroll-Fix beim Date-Picker)
>
> Aus deinem Feedback noch offen:
> - Mehr als 3 Mikros + eigener Reiter
>
> Eine Rückfrage zum Mikronährstoff-Überblick:
> - **NEU in der kommenden Version:** im Verlauf-Tab kommen drei Mikronährstoff-Chips pro Tag in die Übersicht (deine Idee, zusammen mit Sarah). Den **Trends-Tab** mit allen ausgewählten Mikros + Tagesverlauf gibt es schon. Reicht das zusammen für den täglichen Überblick und den „was fehlt noch heute"-Vibe, den du dir gewünscht hattest, oder fehlt dir das noch an einer dritten Stelle (z.B. im Tagebuch-Header)?
>
> Danke nochmal für das gewissenhafte Testen!

### Henrike Böckmann (T9) — TestFlight, iPhone 16 Pro DE

| Feedback | Type | Status | Build |
|---|---|---|---|
| kcal single-food too high (egg 155 vs 100) | 🐛 | ✅ | +36 |
| Supplement setup timeout on Google screenshot | 🐛 | ⛔ | closed (train) |
| Component breakdown before saving (in Confirm Screen)          | 🚀   | 🔬     | → ?                                  |
| Empty state illustration not tappable                          | 💎   | 🔬     | → ?                                  |
| Iron not populated for oats (Haferflocken)                     | 🐛   | 🟡     | → ?                                  |
**Update-Message [DE] — aktualisiert 2026-06-22 (WhatsApp-Nachtrag integriert):**

> Hey Henrike, danke für deine WhatsApp und die Screenshots heute Morgen!
>
> Kurzes Update zu allem auf einmal:
>
> **Schon gefixt (kommt mit der nächsten Version):**
> - kcal-Schätzung für Einzellebensmittel: harte Anker drin (1 gekochtes Ei NIE über 100 kcal, Banane ~105 kcal etc.). Dein Ei-Beispiel mit 155 kcal passiert nicht mehr.
>
> **Eisen bei Haferflocken:** du hast vollkommen recht, Haferflocken enthalten Eisen (~4 mg/100 g, das sind ~8 % deines Tagesziels bei einer normalen Portion). Der Tracker sollte das zeigen. Ich habe nachgesehen: der Bug ist real, die App hat Hafer als Eisenquelle nicht klar genug im Radar. Fix kommt in einer der nächsten Versionen. Gut, dass du's geprüft hast.
>
> **Deine zwei Screenshot-Ideen:**
> - Komponenten-Liste im Confirm-Screen (bevor man speichert): gute Idee, notiert. Ist eine größere Änderung, kommt nicht sofort, aber ich habe sie im Backlog.
> - Leeres Tagebuch antippen um den Coach zu starten: kleines Detail, finde ich auch intuitiver. Schaue ich mir an.
>
> **Supplement-Setup-Timeout damals:** kein Problem, dass es beim zweiten Mal geklappt hat zeigt, dass es die Zugverbindung war. Damit ist das erledigt.
>
> Wann kommt was: der Eisen-Fix landet in der nächsten oder übernächsten Version, die Screenshot-Ideen dahinter. Ich melde mich wenn was davon draußen ist.
>
> Danke nochmal fürs genaue Hinschauen und Googeln!

### Julia Mayer (T10) — TestFlight, iPhone 14 Pro DE

| Feedback | Type | Status | Build |
|---|---|---|---|
| Lactation profile gets pregnancy warnings | 🐛 | ✅ | +36 |
| Time picker AM/PM cumbersome | 💎 | ✅ | +37 |
| Dynamic activity adjustment (HealthKit + manual fallback) | 🚀 | ⛔ | parked in idea-backlog |
| Coach ignores onboarding supplements in chat (Fetesept, label-scanned) | 🐛 | 🟡 | → coach-context fix (in Bau) |

**Update-Message [DE]:**

> Hey Julia, eine neue App Version unterwegs - hoffentlich bis (über)morgen bei dir!
>
> Eine Entschuldigung vorab: ich habe **heute erst** in App Store Connect die Internal-Feedback-Sektion entdeckt, wo dein TestFlight-Feedback (Screenshots) landet. Mir war das vorher nicht klar - daher kam dein Feedback erst heute richtig in meinen Backlog. Sorry für die Verzögerung! **Vielen Dank trotzdem für die super klaren Reports** - mit deinen Schritt-für-Schritt-Beschreibungen konnte ich sofort gucken wo ich was tun muss.
>
> Aus deinem Feedback gefixt der Version die morgen oder übermorgen kommt:
> - ⚠️ Stillzeit-Profil bekommt keine Schwangerschafts-Warnungen mehr (war P0 - du hattest Pfannkuchen mit Räucherlachs/Schinken gemeldet)
> - **Bonus:** „Schwanger + milchproduzierend" (Tandem) ist jetzt als 4. Phase in den Settings auswählbar - vorher konntest du nur entweder/oder wählen
>
> Aus deinem Feedback noch offen:
> - Uhrzeit-Picker AM/PM Polish-Runde
>
> Aus deinem Feedback in den Ideen-Backlog gewandert (nicht in der aktuellen Beta-Welle):
> - **Dynamische Aktivitäts-Anpassung über HealthKit + manueller Fallback** - elegant, aber zu groß für die aktuelle Beta-Welle (OS-Permission-Flows, nicht-triviale Fallback-UI). Revisit wenn HealthKit aus anderen Gründen reinkommt oder wenn das statische Level häufiger als Kalibrierungs-Miss gemeldet wird.
>
> Danke nochmal für das gründliche Testen + die Aktivitäts-Klarstellung per E-Mail!

### Rebecca Brill (T12) — TestFlight, EN UI, pregnant 2T EN

| Feedback                                                       | Type | Status | Build                            |
| -------------------------------------------------------------- | ---- | ------ | -------------------------------- |
| Tandem (pregnant + breastfeeding) discovery + auto-readjust    | 🐛   | ✅      | +36 (4th Tandem option in Settings) |
| Trimester auto-advance from due date                           | 🚀   | 🔬     | → ?                              |
| DHA shown 0 from eggs despite coach mentioning DHA             | 🐛   | 🟡     | → +37                            |
| German banner in English-UI supplement form (i18n)             | 🐛   | 🟡     | → +37                            |
| App-Value-Confirmation (logging straightforward, CV accuracy, mindfulness) | - | ✅      | -                                |
| Retroactive coach silent before next meal (today's entry, 60-min gate) | 💎 | 🟡 | → ? (new card proposed) |
| Calorie target too low for pregnancy+lactation+sport combo (RMR-Input) | 🚀 | 🔬 | → ? (screenshots pending) |
| Protein >100% in ring but coach says "under target" | 🐛 | 🔬 | → ? (2nd voice, board card Patricia T13) |

**Update-Message [EN] — SENT 2026-06-20 (after +36 TestFlight upload, with investigative JTBD follow-ups):**

> Hi Rebecca, the new version landed on TestFlight as promised. Here's how your three points map onto it:
>
> **Pregnant + breastfeeding:** there's now a dedicated 4th option in Settings → Profile ("Pregnant + producing milk"). Curious how it feels to you, and whether anything about how you discover/find it could be smoother.
>
> **DHA showing 0 from eggs, and the German banner in the otherwise-English supplement form:** both confirmed as real bugs on our side, we're working on them. Before I touch the DHA one in particular: when the coach mentioned DHA-in-eggs but the value stayed at 0, what would you have wanted to happen instead - the value populated to a realistic number, or the coach not mentioning a nutrient that isn't reflected in the data? Both are valid; the right fix depends on which jars more.
>
> **Auto-trimester from a due date:** noted, sitting in the idea backlog. Curious about the underlying need: is the "I'll have to update this myself in a couple of months" a friction you actually expect to hit (and want avoided), or more a hypothetical observation while doing the setup?
>
> Looking forward to your "few more days into it" notes whenever you've got them. 🙏

**Previous short-ack draft (sent 2026-06-19 evening, superseded by the SENT message above):**

> Hi Rebecca, thanks so much for the thoughtful feedback - really happy you're enjoying it! 💛
>
> Quick note for tonight, will come back properly in a day or two with concrete fixes:
> - Pregnant + breastfeeding becomes a dedicated 4th option in the next version (Settings → Profile), which solves both the discovery AND the auto-readjust-to-one thing you hit
> - The DHA-in-eggs showing 0 and the German banner in the otherwise-English supplement form are real bugs, noted
> - Auto-trimester from a due date is a clever idea, looking into it
>
> Coming back to you in 1-2 days with a new build. And keep the notes coming - exactly the kind of detail that helps ❤️

### Lotte (T11) — beta, EN UI DE

| Feedback                                                       | Type | Status | Build                                |
| -------------------------------------------------------------- | ---- | ------ | ------------------------------------ |
| App-Value-Confirmation (micro insight, photo, barcode work well) | -    | ✅      | -                                    |
| Item language not normalized at scan time (French nut mix)     | 🐛   | 🟡     | → +37                                |
| Item list mixed languages when re-tracking (Müsli)             | 💎   | 🔬     | → ?                                  |
| Tracking feels more cumbersome than expected                   | -    | ❓      | likely favourites discovery (#16)    |
| Doesn't know app is bilingual                                  | -    | ❓      | discovery, mention in update message |
| Re-track findability: language doesn't matter, just findability | -   | ✅      | JTBD clarified, closes open direction question |
| Favourites star not yet tried                                  | 💎   | 🔬     | likely discovery, aligns with SnackBar tip |
| Coach quick-reply "I rarely eat fish" shown for vegetarian     | 🐛   | 🟡     | → ? |
| Date chip appears to require confirmation even for today        | 💎   | 🟡     | → ?                                  |
| Entries out of order when backlogging without time adjustment   | 🐛   | 🟡     | → ?                                  |
**Update-Message [DE] — SENT 2026-06-20 (after +36 TestFlight upload, with investigative JTBD follow-ups):**

> Hey Lotte, die neue App-Version ist über TestFlight bei dir gelandet. Hier was wir aus deinen drei Punkten machen:
>
> **Bildkennung + Barcode + Mikro-Lücken-Aufdeckung:** freut mich riesig zu hören - das ist der Kern was die App leisten soll. ✅
>
> **Nussmischung auf Französisch + Sprach-Wirrwarr im Re-Tracking:** das nehmen wir uns als nächstes vor. Eine Rückfrage davor, damit ich's richtig baue: wenn du dir das ideale Verhalten vorstellst, sollte die App den Produktnamen einfach immer in deiner App-Sprache zeigen (egal woher der Scan kam), oder ist eine sinnvolle Re-Track-Vorschlagsliste das eigentlich Wichtige (und dir egal in welcher Sprache der einzelne Eintrag heißt, solange du ihn wiederfindest)?
>
> **„Mühsam"-Punkt:** das ist genau der wichtige. Wenn du nochmal an einem konkreten Tag denkst wo du gedacht hast „uff, schon wieder", was war's: das Tippen selbst, das Fotografieren, das Wiederfinden was du schonmal geloggt hast, oder noch was anderes? In der aktuellen Version gibt's beim ersten Meal-Save einen einmaligen Hinweis auf den Stern oben rechts beim Save-Sheet (für „diese Mahlzeit als Favorit speichern → beim nächsten Mal in einem Tap wiederholen") - sag mir gerne ob du den siehst und ob das deinen „mühsam"-Punkt überhaupt trifft, oder ob es woanders klemmt.
>
> Und falls dich beim Onboarding oder bei den ersten Mahlzeiten was speziell verwundert oder gestoppt hat, immer gerne her damit. Danke!

**Previous draft (deferred until +36 TestFlight upload; superseded by the SENT message above because it described pre-ship features and asked leading questions):**

> Hey Lotte, mega Dankeschön für die ausführliche erste Rückmeldung! Vier Sachen zu deinen Punkten:
>
> **Zur Bildkennung + Barcode-Erkennung + Mikro-Lücken-Aufdeckung:** freut mich riesig zu hören, genau das soll die App. ✅
>
> **Zur Nussmischung auf Französisch + Sprach-Wirrwarr im Re-Tracking:** ist ein Bug von uns. Beim Barcode-Scan übernimmt die App aktuell den Produktnamen in der Sprache die das Produkt zurückgibt, statt in deiner UI-Sprache. Fix kommt in der nächsten App-Version: bei Scan-Zeit wird der Name normalisiert, dann ist auch die Re-Track-Liste konsistent.
>
> **Zur App-Sprache:** ja, die App kann auch Deutsch! Sie folgt der iPhone-System-Sprache - wenn dein iPhone auf Englisch steht, ist die App auch Englisch. Wechsel über iOS → Einstellungen → Allgemein → Sprache & Region (oder gezielt für NourishMe: iOS → Einstellungen → NourishMe → Sprache).
>
> **Zum „mühsam"-Punkt:** wenn du oft das gleiche isst (Müsli morgens), gibt's eine Favoriten-Funktion - beim Save-Sheet siehst du oben rechts einen Stern, einmal drücken → beim nächsten Mal loggst du's mit einem Tap statt Foto/Eingabe. In der kommenden Version wird der Stern explizit beworben (per einmaligem Hinweis bei der ersten Mahlzeit), weil ihn viele übersehen. Probier's ein paar Tage mit deinem Müsli und sag mir gerne wie das wirkt.
>
> Ein paar Rückfragen weil du frisch dabei bist:
> - Wie war der Einstieg (Onboarding, erste Mahlzeit, Coach-Antwort)?
> - Gibt's andere Stellen wo du gestockt bist oder dir was anders gewünscht hast, auch Kleinigkeiten?
>
> Danke nochmal!

---

### Patricia (T13) — WhatsApp, current beta DE

| Feedback | Type | Status | Build |
|---|---|---|---|
| Retro-time not picked up: text "9:00 Uhr" ignored, entry gets submit time | 🐛 | 🟡 | → ? |
| Alarms working (positive) | - | ✅ | - |
| Protein 18/148g (12%) — suspect wrong target | 🐛 | 🔬 | → ? (needs profile check) |
| Algenöl triggers seaweed/algae warning (Algae-rule substring match) | 🐛 | 🟡 | → ? |
| Algenöl: missing "take with fat" combination note | 💎 | 🟡 | → ? |
| Safety Sign-off: Launch-Gate-Vorbehalt (kein aktives Empfehlen) | #safety | 🟡 | → ? (Launch-Gate-Karte #P0) |
| Safety Sign-off: Toxoplasmose-Abdeckung (neue Frage) | 🐛 | 🟡 | → ? (Recherche nötig) |
| Safety Sign-off: Hartkäse nicht warnen, Wortlaut + Quelle | 🐛 | 🟡 | → bereit /create-plan |
| Safety Sign-off: Rohei-Wording "kritisch prüfen" | 🐛 | 🟡 | → bereit /create-plan |
| Safety Sign-off: Salbei/Pfefferminze – kein Sign-off, Eigenrecherche | 🐛 | ❓ | → Recherche Vanessa |
| Safety Sign-off: Flambiert weiterhin warnen | 🐛 | 🟡 | → bereit /create-plan |
| Safety Sign-off: Leber gesamte Schwangerschaft meiden | 🐛 | 🟡 | → bereit /create-plan |
| Safety Sign-off: Stillzeit Roh-Tier ok (bestätigt) | - | ✅ | → bestätigt |
| Safety Sign-off: Quecksilber Stillzeit einschränken (bestätigt) | - | ✅ | → bestätigt |
| Safety Sign-off: Algen/Jod jetzt auch Stillzeit warnen (neu) | 🐛 | 🟡 | → bereit /create-plan |


## Pattern Clusters (reference)

Which themes were mentioned how often. For pattern-rule decisions.

| Cluster | Voices | Type | Severity |
|---|---|---|---|
| ⚠️ Safety phase: lactation profile gets pregnancy warnings (fixed +36) | 2 (Isabella + Julia) | 🐛 | **P0** |
| kcal estimate calibration (over/under) | 2 (Henrike + Simone) | 🐛 | P1 |
| Retro-logging discovery (fixed +36) | 3 (Eva + Svenja + Isabella) | 💎 | P1 |
| Micronutrient visibility + depth | 4 (Isabella + Sarah ×2 + Corina) | 🚀 | P1 |
| Repeat-meal discovery / favourites | 4 (Eva + Svenja + Corina + Lotte) | 💎 | P2 |
| Dynamic activity adjustment (HealthKit + manual fallback) - parked in idea-backlog | 2 (Julia + Corina) | 🚀 | P2 |
| Water tracking | 1 (Corina) | 🚀 | P2 |
| Weight tracking + auto-adjust | 1 (Corina) | 🚀 | P2 |
| Picker UX (time + date) - fixed +37 via CupertinoDatePicker | 1 (Julia) | 💎 | P3 |
| Supplement setup robustness (timeout) | 1 (Henrike) | 🐛 | P3 |
| Cycle / period awareness | 1 (Corina) | ⛔ | out-of-scope, see idea-backlog |
| Onboarding daily-volume discoverability (fixed +36) | 1 (Isabella) | 💎 | P3 |
| Pattern-avoidance weekly coach | 1 (Corina) | 🚀 | P3 |
| Item language normalization (scan + re-track display) | 1 (Lotte) | 🐛 | P2 |
| App-Value-Confirmation (positive feedback) | 3 (Sarah + Lotte + Rebecca) | ✅ | - |
| i18n inconsistencies (mixed-language strings in single screen) | 2 (Lotte + Rebecca) | 🐛 | P2 |

---

## Code Bugs (separate from tester feedback)

From the code review session:

| Severity | Finding | Status |
|---|---|---|
| High | **Protein target with overweight** was wrong in coach path. Reported by dietitian. | ✅ fixed (`proteinTargetGrams`) |
| High | **Micronutrient cast** `(v as num)` could crash meal save. | ✅ fixed (`_parseMicronutrients`) |
| Medium | **Midnight ordering bug**. | ✅ fixed (`coachAnchorFor`) |
| Medium | **Kombucha** triggered the algae rule incorrectly. | ✅ fixed (exclusion) |
| Medium | **Beta bug "bundled scan + text lands at top"** - reported, never reproduced. | 🐛 open |
| Medium | **`ThreadRepository.add()`** race on rapid bundle save. | 🐛 open, hard to test deterministically |

---

## Open Items Without Tester Status

- 🐛 F3 past-day scroll: highlight pulse as patch in +35, real fix still open
- 💎 A6 capsule math: prompt hardening in +34/+35, model adherence to verify (Henrike tested Femibion)
- ✅ Salad midwife bug: per_meal hardening in +35, Vanessa tested herself

## Known Limitations (wontfix-discussed)

- Push reminder with <1 min lead time: iOS system race, not app-fixable (Corina's test with 1-min lead)
- Progressive disclosure in Settings: was never in, won't be added back (decided by Vanessa)

---

## Detail Blocks (chronological by session)

Original notes per session as a detail view. View 1 + View 2 above aggregate from this.

## 2026-06-15 · Eva (T1) · Build +24 · voice message

Profile: lactating mother, often out and about with toddler.

1. **Photo recognition inaccurate** (status: in-progress, no-brainer)
   - Example A: "plums with cream" instead of blueberries with yogurt.
   - Example B: salad with cucumber/tomato/nuts → small items not recognised.
   - Planned: sharpen photo prompt, inject brand history.

2. **Forgets to log because phone isn't at the table** (status: waiting)
   - Discovery problem with push reminders.

3. **Retroactive logging - how?** (status: open, PATTERN Eva+Svenja+Isabella)
   - Exists (AppBar day picker), discovery problem.

4. **Daily target not reached, small snacks forgotten** (status: in-progress)
   - Coach "daily target is a weekly average" as guardrail. Plus explain favourites feature.

---

## 2026-06-15 · Celine (T2) · Build +24 · WhatsApp text

Profile: works at a school, relaxed eater, looks at data curiously rather than tracking meticulously.

1. **Multi-photo upload for afternoon catch-up** (status: open)
   - Preference: save all photos at once + edit individually → bulk queue.
   - Task #105 created.

2. **Backcamembert false-positive raw-milk warning** (status: ✅ fixed)
   - Heat marker added to SafetyRules.

3. **Praise even for chocolate lands well** (status: ✅ fixed, confirmation)
   - Confirms non-judgemental tone works.

4. **Iodine systematically low** (status: waiting/in-progress)
   - Has Femibion-style supplement (no iodine). Values are REAL.
   - Micronutrient-gap trigger is too naggy when nutrient is chronically deficient. Task #106.
   - Confirmed: weekly overview would be great (Task #107).
   - Donut sporadic → passive notification > prominent donut status.

---

## 2026-06-15 · Corina (T3) · Build before +24 · WhatsApp voice + follow-up

Profile: lactating mother, ~1-year-old child, working (school), uses CHAT path to log.

1. **Backfill / coach doesn't know meal time** (status: in-progress, PATTERN Celine+Corina)
   - She logs late, coach reacts at the wrong time of day.
   - Chat path: chat_base_de/en now detects past-meal language.

2. **Delete bug** (status: closed-by-tester)

3. **"Coffee remember" feature** (status: waiting)
   - Likely favourites discovery problem.

4. **Calorie estimate too high (2600 kcal)** (status: clarified, no action)
   - Correctly computed from Mifflin + activity + lactation supplement.

5. **Snack recommendations too frequent** (status: ✅ fixed)
   - Task #108: settings toggle for meal structure, shipped in +25.

6. **Recruitment of 9 lactating mothers** (status: open, strategic)

---

## 2026-06-16 · Svenja (T5) · Build +24 · WhatsApp text

Profile: new, one message so far.

1. **Retro-logging discovery: "log food for the day before"** (status: open, PATTERN Eva+Svenja+Isabella)
   - Feature exists, discovery problem.

---

## 2026-06-17 · Simone (T6) · Build +33 → +34/+35 · WhatsApp

Profile: lactating mother.

1. **Shell-pasta bug: photo confused with mussels** (status: ✅ fixed in +34/+35)
   - Photo of chicken soup with Conchigliette → coach interpreted as mussels, phantom listeria warning in the diary.
   - Pasta-shape anchor in parse prompt (+34) + safety-layer filter + rawAnimal exclusion (+35).
   - Verification pending (Simone was still on v33 at first retest, should retest the same photo on v35).

2. **Calorie estimate too low (320 vs ~555)** (status: open, PATTERN Simone+Henrike)
   - First estimate of Conchigliette soup was 320 kcal, real ~555 for 380g.
   - Henrike reports the opposite: single items too high.

3. **Push reminder fires despite meal log** (status: ✅ fixed in +35)
   - Default reminder times (8am breakfast) fired even though she had logged earlier.
   - recomputeSkipsForToday built, verification pending.

---

## 2026-06-17 → 2026-06-18 · Corina (T3) Round 2 · Build +33 → +35 · WhatsApp

Profile: same as T3, now with more detailed feedback after a testing round.

1. **Daily-weight logging with hard adjustment** (status: open)
   - Manual entry in the morning (normal scale, no smart scale).
   - Wants the calorie target to auto-adjust.
   - Per scope: input mechanism for kcal calibration, no trend/streak UI in the app.

2. **Cycle / period context** (status: ⛔ out-of-scope per CLAUDE.md Produkt-Scope, moved to idea-backlog)

   > „You retain more water in certain phases"
   >
   > „horrible PMS with crazy cravings"

   - Wanted the app to know the cycle (manually or via Apple Health).
   - Decision: cycle is its own lifecycle phase; revisit when maintenance phase grows or 3+ voices ask. See `docs/idea-backlog.md`.

3. **Food-avoidance pattern coach** (status: open)
   - „du isst zu viel Zucker"-style coaching, not micronutrient-deficit style.
   - Coach weekly review with pattern detection.

4. **Water tracking** (status: open)
   - Tap-glass icon, personalisable („not all glasses are equal").
   - Proposed: setting for „1 glass = X ml" + „1 bottle = Y ml", two icons under the diary header.
   - Per scope: in scope as hydration daily status (raised need in lactation), no streak UI.

5. **Push reminder fires despite meal log** (status: ✅ fixed in +35)
   - Same bug as Simone. To verify on v35.

---

## 2026-06-17 → 2026-06-18 · Sarah (T7) · Build +33 → +35 · WhatsApp

Profile: lactating mother, has Folio supplement.

1. **DHA hallucination 325% from porridge** (status: ✅ fixed in +35)
   - Porridge with walnuts + flaxseed → model counted ALA as DHA.
   - DHA zero rule in parse prompt + coach now sees micros + supplements in chat context.
   - Sarah confirmed the v35 fix:

   > „Bei Jod sehe ich jetzt aus welcher Mahlzeit es kommt" ✅

2. **Component granularity per meal** (status: open, PATTERN Sarah+Corina)

   > „Bei Jod sehe ich jetzt aus welcher Mahlzeit es kommt, weiß aber noch nicht aus welchem Bestandteil."

   - Wants per-component (oats/walnuts/almond milk) view of who contributes what.

3. **More than 3 micros + dedicated tab** (status: open, PATTERN Sarah+Isabella)
   - Today: max 3 micros in header. Wants more data without header overflow.
   - Suggestion: top 3 prominent, dedicated tab for all selected.

---

## 2026-06-11 · Isabella Hoesch (T8) · TestFlight v18 · Screenshots

Profile: iPhone 11, iOS 26.4.2, sends structured TestFlight feedback.

1. **Onboarding daily-volume slider misunderstood** (status: open)

   > „Bei Babies die keine Flasche nehmen schwer zu beantworten."

   - Doesn't realise the value is an output of the previous questions.
   - Solution proposal: visual separation as „calculated card" with different background.

2. **Day switch lands at end of TODAY's chat** (status: open)
   - Expected: start of selected day's chat.
   - Scroll race condition on day switch. Related to F3 (past-day scroll).

3. **⚠️ Lactation profile shows pregnancy warnings** (status: open at time of report, fixed in +36)
   - Red beets and mozzarella carpaccio → warning „avoid raw-milk cheese in pregnancy" although Isabella set lactation.
   - Hypothesis: LLM layer too defensive or deterministic rule has wrong phase gate.

4. **Cannot add retroactive entry** (status: open, PATTERN Eva+Svenja+Isabella)
   - Pizza from yesterday → couldn't set the date. Discovery problem.

5. **History tiles show only kcal, not micros** (status: open at time, addressed in +36)

   > „Tägliche Übersicht über meine Nährwerte und was noch fehlt cool."

   - Plus: „nährstoffreiche Ernährung motiviert mehr als ein Kalorienziel."

---

## 2026-06-13 → 17 · Henrike Böckmann (T9) · TestFlight v20/v33 · Screenshots

Profile: iPhone 16 Pro, iOS 26.5.

1. **Supplement setup timeout on Google search screenshot** (status: open)
   - Searched for Femibion via Google and uploaded the screenshot (not a photo of the label).
   - Coach response:

   > „The coach is taking too long, try again in a moment."

   - Likely: vision model struggled with the unusual source.

2. **kcal estimate too high (egg: 155 vs ~100)** (status: open at time, fixed for single items in +36)

   > „Grundsätzlich kommt es mir so vor dass eher über- als unterschätzt wird."

   - Conflict with Simone, who reported under-estimate on a German main dish.
   - Hypothesis: model is generous on single items, conservative on complex dishes.

---

## 2026-06-17 · Julia Mayer (T10) · TestFlight v33 · Screenshots

Profile: iPhone 14 Pro, iOS 26.5.

1. **Time picker AM/PM cumbersome** (status: open)

   > „Das Auswählen der Uhrzeit (morgens oder der Switch auf abends) wird nicht immer übernommen."

   - Suggestion: a morning/evening slider at the top, then a single clock face instead of two.

2. **⚠️ Lactation profile shows pregnancy warnings** (status: open at time, fixed in +36)

   > „Ich habe angegeben, dass ich eine stillende Mutter bin. Trotzdem erhalte ich Warnungen für Lebensmittel, die in der Schwangerschaft nicht erlaubt sind."

   - Screenshot shows a pancake meal with smoked-salmon/ham/raw-milk related warning.

3. **Workout/sport sessions in kcal balance** (status: open, PATTERN Julia+Corina)
   - Activity level hard to set at the start because it varies.
   - Wants to add sport sessions as kcal-plus.
   - Per scope: in scope as kcal-input mechanism, not as fitness tracker (no streak/trend UI).

## 2026-06-19 · Lotte (T11) · TestFlight (current beta) · WhatsApp text

New tester. Three-point feedback after first sessions, EN UI on her phone.

1. **App-Value-Confirmation** (positive)

   > „Es gibt einem super Aufschluss darüber was in der Ernährung fehlt (z.b. bei mir Protein), Bilderkennung klappt erstaunlich gut und das lesen der Barcodes"

   - Confirms three core mechanics: micronutrient gap insight, photo recognition, barcode scanning. Joins Sarah (#34) in the App-Value-Confirmation cluster (2 voices).

2. **Item language not normalized at scan time** (🐛, single voice, P2)

   > „die App ist bei mir Englisch (weiß gar nicht ob es eine andere gibt?!). wenn ich etwas eingebe/scanne funktioniert sowohl deutsch als auch Englisch, aber wenn ich etwas erneut tracken will wie bspw. Das Müsli was ich jeden morgen esse ist es irgendwie ein kleines wirrwarr an sprachen. Idealerweise würde mir unabhängig der Sprache etwas vorgeschlagen."

   > „ich habe eine nussmischung gescannt und die App hat sie mir auf Französisch gespeichert 😅 das macht es natürlich erst recht schwer die Mischung wieder zu finden wenn ich sie nochmal esse."

   - Two symptoms of the same root cause: items are stored with whatever-language name they came in with (product DB returns name in product's native language; user can type DE or EN; previous saves keep their original language). Fix: normalize at scan/save time to user's UI language. Plus a display-side fallback for already-saved items in other languages would help the existing Müsli case.
   - Discovery angle: Lotte also doesn't know the app has a German option ("weiß gar nicht ob es eine andere gibt?!"). Worth addressing explicitly in her update message.

3. **Tracking feels more cumbersome than expected** (❓, likely favourites discovery)

   > „in summe muss ich sagen, dass es mühsamer ist als ich dachte alles aufzuschreiben, was aber vllt auch an meinem random Essverhalten liegt 🙈"

   - 4th voice in the favourites-discovery cluster (Eva + Svenja + Corina + Lotte). The +36 SnackBar tip (T41) should help, but for Lotte specifically: validate post-+36 whether the SnackBar surface is enough or whether the daily Müsli case needs an even stronger discovery push.

---

## 2026-06-18 · Julia Mayer (T10) · App 1.0.0 (35) · TestFlight, iPhone 14 Pro, iOS 26.5

New point from Build 35 testing round.

1. **Coach ignores onboarding supplements in chat** (status: open, 🐛)

   > "Ich habe beim Setup des Accounts mein tägliches Supplement angegeben. Bei Nachfrage, ob es ausreicht, erkennt der Coach nicht, dass ich bereits etwas supplementiere, greift also nicht auf meine Account-Einstellungen zurück."

   - Code check (2026-06-21): `home_input.dart` _buildContext() DOES include active supplements in the todayContext block (lines ~482-497): `=== Active supplements ===` lists each ActiveSupplement's name + per-nutrient values, and the aggregated micronutrients block (`=== Micronutrients today (from meals + active supplements) ===`) already folds in supplement values. This is the fix that shipped in +35 for Sarah (T7). The per_meal_en.dart system prompt also says the context includes micros + supplements.
   - Likely root cause: Julia has build 35 (Build ID 35), but the supplement context fix was for the CHAT path (coach_session_manager / chat call). On inspection, the chat path reads `profile.activeSupplements` from Hive live via `userProfileProvider`. If Julia's supplement is stored as a profile field (onboarding "daily supplement" entry) but NOT as a structured `ActiveSupplement` object with parsed nutrient values (e.g. saved as free text only, never photo-parsed), it would NOT appear in the supplement block. The context block only emits supplements that have non-empty `values` maps. A supplement name-only entry (no nutrient values parsed) would be invisible to the coach.
   - Needs clarification: did Julia go through the supplement label scan flow, or did she type the supplement name only? If name-only, the coach has no structured data to reference.

---

## 2026-06-21 · Lotte (T11) · current beta · WhatsApp

Follow-up round after first messages.

1. **Re-track findability JTBD clarified** (status: ✅ JTBD closed for this tester)

   > "Wenn ich z.B. meine Zimtschnecke immer wieder finde, egal ob ich 'Zimtschn...' oder 'Cinnamon...' eingebe, finde ich es egal, in welcher Sprache es gespeichert wird."

   - Lotte's JTBD: findability matters, not language consistency. The open "item-language" Backlog card's direction question (normalise to UI language vs. reliable re-track list) is answered from her side: a reliable re-track list regardless of language is sufficient. Does not close the card (other testers may care about visual consistency), but narrows the minimum viable fix.

2. **Favourites star not yet tried** (status: 🔬 single voice, aligns with SnackBar tip)

   > "Da gucke ich mir das mit dem Stern als Favorit mal an. Habe ich bisher nicht genutzt."

   - Confirms the SnackBar tip (+36) is still needed. Discovery problem, not feature gap. 4th voice in favourites-discovery cluster (Eva + Svenja + Corina + Lotte).

3. **Coach quick-reply "I rarely eat fish or seafood" shown for vegetarian profile** (status: open, 🐛)

   - Screenshot: Coach Quick-Reply chip shows "I rarely eat fish or seafood". Lotte's Diet & allergies: "Vegetarian" selected. App language: English.
   - Code check (2026-06-21): The follow-up chips are generated by the LLM in the per-meal coach reply (per_meal_en.dart, followUpInstructionEn: "Examples: 'I rarely eat fish', 'I need on-the-go ideas'..."). The diet line IS threaded into the per-meal user message via buildDietLine() and the system prompt says "If a dietary profile is in the context, RESPECT it absolutely" (per_meal_en.dart line 37). However the `followUpInstructionEn` example text is verbatim "I rarely eat fish" — the model appears to echo example bullets rather than generate diet-aware ones. The dietary profile does reach the context (buildDietLine returns "Diet: vegetarian" when dietStyle != 'omnivore'), so this is a prompt compliance failure: the model ignores the diet constraint specifically in the follow-up section.

---

## 2026-06-21 · Patricia (T13) · current beta · WhatsApp

New tester, first feedback round.

1. **Retro-time not picked up from text** (status: open, 🐛)

   > "Was mich stört ist, dass ich nicht nachtragen kann. Ich habe der App z.B. gesagt, dass ich um 9:00 Uhr morgens ein Brötchen mit Nutella gegessen habe. Es wurde aber erst für 22:47 Uhr notiert."

   - Code check (2026-06-21): ConfirmScreen._mealTime defaults to `DateTime.now()` for fresh entries when today is focused (`_sameDay(focused, today)` → `_mealTime = nowInit`). The text "um 9:00 Uhr morgens" is parsed as a meal NAME by parseMeal, not interpreted as a timestamp — the parseMeal response has no `logged_at` or `timestamp` field. The confirm screen has no mechanism to extract a time from the raw text and pre-fill the time picker. The user must manually adjust the time chip in ConfirmScreen before saving. This is a known UX gap: the time picker exists and was improved (+37, CupertinoDatePicker), but the text-to-time mapping is not implemented.
   - The "Coach paused for retroactive" threshold (60 min) means that even if she DOES adjust the time picker to 9:00, the coach call would be suppressed (>60 min gap) — which is correct. The entry time itself being wrong (22:47 instead of 9:00) is what she reports.

2. **Alarms working** (status: ✅ positive confirmation)

   - Confirms push reminder fix from +35 is working for Patricia.

3. **Protein 18/148g (12%)** (status: 🔬 single voice, needs profile check)

   - Screenshot shows protein 18/148g (12% of target), "noch 130g". Patricia says "irgendwie stimmt das mit den Proteinen bei mir immer noch nicht."
   - Code check (2026-06-21, cross-verified): there are TWO protein numbers in `calorie_target.dart`. The COACH uses `proteinTargetGrams()` (BMI-25-capped reference weight × DGE g/kg for phase/goal; lactation 1.2, pregnancy T2 0.9 / T3 1.0, baseline 0.8, body-goal 1.5/1.6). The UI ring shows `calculateMacroTargets().proteinG = targetKcal × proteinPct / 4`, where `proteinPct = customProteinPct` if set, else `autoMacroSplit()` (which round-trips the capped grams). 148g is implausible from the capped path for any realistic body (it implies actual weight without the BMI cap), so it almost certainly comes from a CUSTOM macro split (Settings protein slider), while the coach reasons with ~80g. So the two surfaces can diverge: the `// single source of truth` comment is aspirational, the capped grams are not actually wired into the macro split when a custom % is set. Action: Explore pass on the two paths + ask Patricia for phase and whether she changed the macro slider.
   - Pattern note: no prior tester raised protein target as specifically wrong (the nutritionist-flagged "protein at high BMI" bug was fixed). Single voice, collecting.

4. **Algenöl triggers algae/seaweed safety warning** (status: open, 🐛)

   - Screenshot: entry "Algenöl 10 ml / 120 kcal" triggers the banner: "Algen/Algenprodukte: in der Schwangerschaft besser meiden. Jodgehalt schwankt stark und liegt oft über der Tagesobergrenze, dazu Arsen..." Patricia's phase: likely pregnant (message is DE, warning text references Schwangerschaft).
   - Code check (2026-06-21): `SafetyRules.algae()` in `safety_rules.dart` line 634 checks `if (!phase.isPregnant) return null` — so it only fires in pregnancy. Then `algaeTokens` from safety-rules.json includes "algen" as a token. `_tokenContains("Algenöl", "algen")` → token "algenöl" CONTAINS substring "algen" → TRUE. So "Algenöl" trips the rule via the "algen" substring. This IS the kombu/kombucha pattern repeated for algae oil: Algenöl is NOT a raw seaweed product. There is currently no "algenöl" exclusion in the algaeExclusions list (only ["kombucha"]). Confirmed bug: same structural pattern as the Kombucha bug (fixed) but for algae oil.
   - Patricia's factual correction is also accurate: algae OIL (specifically DHA algae oil like Norsan, MorEPA, etc.) is a controlled, purified supplement where algae is cultivated, not wild-harvested seaweed. The iodine/arsenic concern of the DGE rule applies to raw seaweed products, not to refined algae oil DHA supplements. The warning is both triggered incorrectly (Algenöl ≠ Algenprodukt in the DGE sense) AND factually misleading for this product category.
   - The warning text also says "Schwangerschaft" which suggests Patricia is pregnant (Laktation-only users get null from algae() per line 636).

5. **Algenöl: missing "take with fat meal" note** (status: open, 💎)

   - Patricia correctly notes that DHA algae oil requires co-ingestion with fat for absorption (fat-soluble omega-3). This is a nutrition coaching point, not a safety rule. Would live in the per-meal coach response or a supplement-specific coaching tip when Algenöl is logged.
   - In scope: this is a supplement recommendation that changes the efficacy of a key nutrient. Coach Communication-Layer.


## 2026-06-21 · Patricia (T13) · Follow-up · WhatsApp

1. **Protein 148g confirmed as her own custom macro split** (status: ✅ ❓ resolved)

   - „Du hast komplett recht es lag an mir mit den Proteinen." The 148 g came from her own protein% setting, not a miscalculation. Answers the open question on the "Protein target: UI macro split vs coach diverge" card; card re-framed to a design gap and downgraded #P2 → #P3.

2. **Found the manual time picker** (status: ✅ self-resolved, discovery)

   - „Habe das mit der Uhrzeit jetzt auch gefunden. Leuchtet einem ja entgegen, wenn man drauf achtet." She discovered the existing time picker. De-escalates the "Stated time in free text not applied" card to a discovery point; the text-parsing gap stays open for the next tester.


## 2026-06-21 · Vanessa (intern) · current build · Screenshots

1. **Coach error messages hardcoded English** (status: open, 🐛 i18n)

   - The coach timeout message showed in English on a German app: "The coach is taking too long. Try again in a moment. For urgent questions please reach out to your midwife or doctor." Code check: the whole CoachApiException family is hardcoded EN in claude_client.dart (timeout :410, no-internet :415, connection :420, overloaded :432, unavailable :438/444/465). Same class as the supplement-banner i18n bug. New backlog card. Decision: option B (localize the family + workaround hint, no dedicated retry button yet).

2. **No coach retry button** (status: open)

   - The error bubble is a terminal state; the only way to retry is re-saving the meal. The "T42 retry-loop" (+36 follow-up) was the ListView scroll retry, not a coach retry. Folded into the i18n card as the deferred retry decision (option B).

3. **Meal counted despite coach timeout** (status: ✅ intended)

   - Finn Crisp (170 kcal, 32% fibre) still counted into the day's totals although the coach timed out. Confirmed correct: confirm_screen.dart:410 saves the meal before the async/unawaited coach call; the daily aggregation reads from mealRepo, not the coach response.

4. **Coach blind to logged meals → wrong "next meal" slot** (status: open, 🐛)

   - At 13:19, with a salad + Knäckebrot already logged and a "3 main meals + 1 snack" pattern, the coach still announced "lunch is coming up". generatePerMealResponse() receives only the pattern preference, aggregate totals and the current hour, not the list of meals logged today, so it can't tell whether the salad was the snack or the lunch. The logged list (mealsForTotal) is collected (coach_session_manager.dart:264) but never passed to the coach call. → candidate for a holistic coach-context audit (what the coach sees vs needs), pending Vanessa's go.

---

## 2026-06-21/22 · Lotte (T11) · current beta · WhatsApp (follow-up round 2)

Two new points after Vanessa's update message (2026-06-20 sent message above).

1. **Date confirmation required even when logging for today** (status: open, 💎 UX-Reibung)

   > "Noch eine Sache die ‚nervt': dass man jedes mal das Datum des aktuellen Tages bestätigen muss obwohl man sich ja schon entschieden hat für genau diesen Tag etwas zu tracken."

   - Code check (2026-06-22): In confirm_screen.dart, the combined date+time chip is always shown and always tappable. The CupertinoDatePicker rework (+37) kept the chip visible regardless of whether the time is today or a retro-date. For a fresh same-day entry, _mealTime defaults to DateTime.now() and _isDeviationFromToday is false (no amber tint), but the chip is still visible and appears as "Heute / HH:MM". The date half of the pill ("Heute") is a confirm trigger because the entire pill calls _pickMealDateTime() on tap. Lotte may be reading "Heute" as a required confirmation tap rather than a label. Or: she sees the date chip and feels she has to interact with it. In either case, the chip is not causing a blocking confirmation step — saving without tapping it works. This is a perceived-friction / discoverability issue: the chip's date part looks clickable-and-required even when it would just confirm "today".
   - Pairs with the "holistic scroll audit" and the time-ordering follow-up below.

2. **Entries out of order: neither entry-input order nor meal times** (status: open, 🐛)

   > "Und heute sind die Zeiten ziemlich Wild. Ich habe zwar auch jetzt heute Abend alles nachgetragen aber es ist trotzdem ein ziemliches durcheinander. Weder in der Reihenfolge in der ich es eingetragen habe nor in der der Zeiten."

   - Code check (2026-06-22): thread_repository.dart sorts by `i.timestamp`, which for meal items is set to `meal.createdAt` (confirm_screen.dart:537: `ThreadItem.meal(mealId: meal.id, at: meal.createdAt)`). When Lotte backlogs everything in the evening, if she did NOT manually adjust the time chip for each entry, all entries would default to either DateTime.now() (for today) or noon (past days). Multiple entries saved minutes apart would then cluster with nearly-identical timestamps, producing an arbitrary-looking order that is neither the real meal sequence nor the entry-input sequence. If she DID adjust times: the sort would put them in chronological meal order, which should be "correct" — but might look like "not the order I entered them" if she entered dinner before lunch. The "neither input order nor time order" description most likely means she did partial adjustments: some times adjusted, some not, producing a mix. Root cause: the confirm screen offers time editing but the chip does not draw attention to itself as a required step when backlogging. The stable mergeSort already handles ties correctly (ThreadRepository.add() race aside). This is the UX consequence of Lotte's friction with the date chip (point 1 above): she doesn't adjust the time because the chip feels like a barrier she wants to skip, so multiple entries land at the same time and the order becomes unpredictable.
   - The "holistic scroll-behavior audit" in Bau (#s7c7jg) does NOT cover this: that card is about scroll position after day switch, not entry timestamp ordering.
   - Pattern note: no prior tester raised timestamp-ordering as a problem when backlogging. Single voice. Patricia had a related issue (stated time in text not applied, #P2) but from a different angle (she didn't adjust the picker, not that the picker felt like a blocker).

---

## 2026-06-21 · Julia Mayer (T10) · current beta · E-Mail + Screenshot (follow-up)

Follow-up mail thread. Note: also contains personal / non-feedback content (Bogenhausen, coffee invite) — strip PII from this log, handle in Vanessa's reply.

1. **Coach ignores onboarding supplements — root cause clarified** (status: ✅ partially resolved by screenshot, 🟡 build fix pending)

   > "ich habe beim Set-up ein Foto von der Packung gemacht, wo die Nährstoff Angaben drauf sind."
   >
   > "Mit expliziten Hinweis und zweimaligen Nachfragen hatte es dann geschafft."

   - Screenshot shows coach correctly acknowledging Fetesept supplement coverage after explicit prompting.
   - Root cause update (2026-06-22): Julia confirms she went through label scan (photo of the Fetesept packaging with nutrition table), so her supplement IS stored as an ActiveSupplement with parsed nutrient values. The problem is NOT the name-only gap identified in the 2026-06-18 log block. The bug is that the coach did NOT use the supplement data on the first attempt; it took two explicit re-prompts. This pattern is consistent with: (a) the coach context not including the supplement block in the initial call, or (b) the model ignoring it despite it being present. The Coach Context Audit (#7iyecl, in Bau) addresses exactly this — it unifies the context builder so active supplements with parsed values are reliably in both the per-meal and chat context. The fix is built (Phase 1 done per board.md) but NOT yet deployed to TestFlight. Julia's screenshot is a pre-fix state. Once the coach-context fix ships, Julia's scenario (Fetesept label-scanned, supplement block populated) should work on first ask.
   - Action: no separate card needed. Update Julia that the fix is on the way in the next build. Add "Fetesept correctly acknowledged after 2 prompts (pre-fix state)" to the context audit verification list so the device test explicitly covers this exact supplement.

---

## 2026-06-22 · Henrike Böckmann (T9) · current beta · In-App Screenshot feedback

Two new points from in-app screenshot submissions, 2026-06-22 morning.

1. **Component breakdown visible before saving (in Confirm Screen)** (status: open, 🚀 Feature, 09:03)

   > "Anregung: im vorherigen step hab ich Foto & Text eingegeben und er sagt mir ja die gesamt nutrition Werte. Ich kontrolliere dann immer auf dem Screen den ich dir geteilt habe, ob er die einzelnen Bestandteile erkannt hat. Für mich n=1 wäre es praktisch wenn diese schon im schritt vorher unter Details aufgelistet wären. Dann hätte ich die Chance zu korrigieren schon im ersten Schritt."

   - Code check (2026-06-22): MealParseResult (claude_client.dart:47) does NOT carry a structured components list. The confirm screen only sees summary (string), kcal, macros, portionAmount, safetyWarnings, micronutrients. Component names are embedded in the summary string (e.g. "Haferflocken mit Hafermilch, halber Apfel, Walnüssen") but are not structured as a separate list. Surfacing a component list in the confirm screen would require: (a) the parser to emit a `components` array in its JSON response and (b) MealParseResult to carry it and (c) the confirm screen to render it. The existing "component granularity per meal" card (#P1, Backlog) solves a different problem: it shows per-component micronutrient breakdowns on the already-saved meal card. Henrike's request is pre-save correction, not post-save analytics.
   - Pattern note: this is a new dimension of the component theme. Sarah + Corina asked for per-component micros AFTER saving. Henrike asks for component list BEFORE saving (as a verification step). These are related but distinct features. Henrike is 2nd voice on the general "I want to see components" theme, but the first on the pre-save angle specifically.
   - Pairs with the broader "component granularity" card.

2. **Empty state illustration tappable → opens input** (status: open, 💎 UX, 08:59)

   > "Eine Idee: als ich das erste Mal auf diesem Screen war, wollte ich dort klicken was ich gelb eingekreist habe, um loszulegen. Weiß nicht ob es jedem so geht, aber für mich wäre intuitiv wenn ein Klick dort den Coach öffnet."

   - Code check (2026-06-22): EmptyToday widget (lib/widgets/empty/empty_today.dart) renders a Container with NMIcons.meal(size:48) inside a rounded box. The widget is wrapped in a Padding; there is no GestureDetector or InkWell on the illustration or the outer box. The widget has no tap handler at all. The home_screen.dart adds EmptyToday() into the ListView items list (line 819, 828) but does not wrap it in any tap-aware widget. Making the illustration tappable would require either wrapping EmptyToday in a GestureDetector in home_screen.dart, or adding an optional onTap callback to EmptyToday itself.
   - Single voice, low-friction fix.


---

## 2026-06-22 · Henrike Böckmann (T9) · current beta · WhatsApp (Nachtrag zur gleichen Triage-Runde)

WhatsApp messages 09:08–09:10, same day as the in-app screenshot feedback above.

1. **Iron not populated for oats (Haferflocken)** (status: open, 🐛 Bug)

   > "Ich hab Haferflocken getrackt aber er erkennt nicht dass diese Eisen enthalten. Der Tracker hat nur die Menge aus dem femibion."
   >
   > "Haferflocken enthalten aber Eisen laut Google 😂 ich lerne schön was dazu weil ich mein Halbwissen bzw. Gefühl dann immer kurz kontrollieren muss."

   - Henrike is correct: Haferflocken contain ~4 mg iron per 100 g (whole-grain cereal; the DGE lactation daily target is ~20 mg). A standard 40 g dry oat portion yields ~1.6 mg, which is ~8% of the lactation daily target — well above the 5% prompt threshold that governs whether the key is emitted.
   - Code check (2026-06-22, parse_de.dart line 146, parse_en.dart line 140): iron reference values list "Getreide-Vollkorn 2-3 mg/100 g" / "Whole-grain cereals 2-3 mg/100 g" as the plant-source example. Haferflocken (dry rolled oats, ~4 mg/100 g) fit this category but are NOT named explicitly. There is NO explicit iron zero-rule comparable to the STRICT DHA ZERO RULE. This means the underlying mechanism differs from the DHA-eggs bug (which was a self-contradicting null override): iron in oats should not be zeroed by any rule. The likely failure mode is model-level underconfidence: the prompt's iron anchor emphasises legumes and meat (which the model reliably associates with iron) and uses "Getreide-Vollkorn" as a vague category without naming oats, leaving the model to decide whether to populate the key. For the specific "Haferflocken getrackt" input, the model likely defaults to the nearest familiar anchor (legumes / meat) and decides oats are below threshold or not "important enough" to populate — a soft underfill rather than a hard rule.
   - This is NOT the same structural class as the DHA-eggs fix. DHA had an explicit STRICT ZERO RULE that overrode the reference table. Iron has no such rule; the fix is adding "Haferflocken trocken ~4 mg/100 g" (or dry oats ~4 mg/100 g in EN) as a named anchor in the iron plausibility line, similar to how the iodine anchor was extended to include industrial baked goods to prevent systematic under-estimation. Whether this becomes a standalone oat anchor or a broader "parser underestimates iron in plant-source cereals" fix (adding also quinoa, amaranth, fortified breakfast cereals) is a plan-time decision.
   - Clinical relevance: iron is one of the critical nutrients for breastfeeding (DGE target 20 mg/day; plant-only sources are already harder to reach than animal sources). Systematic absence of iron from oat logs makes the tracker useless as a gap detector for this nutrient for any tester with a plant-forward breakfast pattern (Henrike, Lotte, likely others).
   - Pattern note: first explicit "iron not showing for oats" report. The broader "parser underestimates micros in plant sources" pattern (DHA from eggs as the trigger case, now iron from oats as the second concrete example) has 2 datapoints. Not yet a 2-tester pattern for THIS symptom specifically (Henrike is 1 voice), but the same class of bug as DHA in eggs — both are cases where the reference table has the right data but the model doesn't surface it for a specific food. Suggest addressing together as a single targeted prompt fix rather than a separate full card.

2. **Setup worked fine** (status: ✅ positive confirmation, no action)

   > "(Kontext, früher) Setup hatte einwandfrei geklappt."

   - Positive confirmation of the onboarding flow. No action needed.

3. **Personal / non-feedback** (09:10, strip PII)

   - Personal questions about Vanessa's parental leave and app plans. No triage action; handle in Vanessa's personal reply.


## 2026-06-23 · Julia Mayer (T10) · current beta (+36) · In-App Screenshot

1. **Diary entries out of chronological order on retro-logged meals** (status: ✅ fixed, riding +37) · 🐛

   > "Beim nachträglichen hinzufügen von Magneten Mahlzeiten gibt es Problem mit dem Time Stamp. Die Reihenfolge stimmt nicht (15 Uhr als letzte Mahlzeit, nach 20h und 18h) Liebe Grüße Julia"

   - Screenshot (Gestern view, build +36): order is 12:00 → 18:00 → 20:00 → **15:00 last**, the 15:00 entry (Walkers Shortbread) sits at the bottom despite its earlier chip time. This is the EXACT 13:36-ordering symptom Lotte reported (T11). **Second independent voice** for the same bug, so it is now a 2-tester pattern, not a single voice.
   - Already root-caused and FIXED before this report (Fix A, 2026-06-23): a pure time-edit updated `MealEntry.createdAt` (the chip) but not the `ThreadItem` sort key, because the `_appendToThread` early-return only checked values, not the time. Fix decouples ordering resync from coach regen via two pure functions; +10 tests, suite 389 green. See [[board.md]] (Review & Test) and [[docs/plans/2026-06-23-time-only-edit-thread-resync|→ Plan]].
   - Action: ships with build +37. **Report back to Julia (and Lotte) once +37 is on TestFlight that the ordering bug is fixed.**

---

## 2026-06-24 · Celine (T2) · current beta · WhatsApp (Antwort auf Rückfrage)

1. **Iodine-gap nag trigger tuning** (status: ✅ resolved, cooldown was enough) · 💎

   - Celine meldet zurück, dass mit dem Jod-Hinweis nun alles passt. Antwort auf die investigative Rückfrage vom 2026-06-22 (wie oft sie den Hinweis auf dem aktuellen Build noch sieht).
   - Bestätigt die Explore-Hypothese: der per-Nutrient 7-Tage-Cooldown (#106, ausgeliefert in +26, also NACH ihrem ursprünglichen +24-Report) hat den akuten täglichen Nag bereits auf wöchentlich gekappt. Kein „deliberate-skip"-Opt-out nötig.
   - Action: Karte geschlossen, keine weitere Arbeit. Der separate Wunsch nach einer Wochenübersicht läuft eigenständig über die Backlog-Karte „Broader micronutrient view".

---

## 2026-06-24 · Sarah (T7) · current beta · WhatsApp (Antwort auf Rückfrage)

1. **Broader micronutrient view** (status: clarified → per-DAY full view is the real need) · 🚀

   - Antwort auf die investigative Frage vom 2026-06-24 (in welchem Moment sie auf die Nährwerte schaut, was sie sehen will, wo sie zuerst schaut).
   - Sarah: sie tippt im Tagebuch die einzelnen Mikros an, um zu sehen woher sie kommen, und hätte gerne eine **Übersicht pro Tag**, „weil man ja auch übererfüllen kann".
   - Befund: das ist die im Explore identifizierte Lücke. Es gibt KEINE Tages-Vollansicht aller Mikros; der Trends-Tab ist ein 7-Tage-Schnitt, deckt „pro Tag" also nicht. Der Bedarf ist Über- UND Untererfüllung auf Tagesebene, dort wo sie ohnehin hinschaut (Tagebuch, Mikro-Tap).
   - Cross-Link: ihr „woher kommen die Mikros / welche Zutat" gehört zur separaten Karte „Component granularity per meal" (Sarah + Corina).
   - Discovery offen: ob sie den Trends-Tab (Wochen-Übersicht aller 11 Mikros, % + Farbe) überhaupt kennt. Hinweis-/Klärungs-Nachricht an Sarah gesendet 2026-06-24. Ändert die Plan-Entscheidung nicht (Trends deckt „pro Tag" nicht), liefert aber das Discoverability-Signal.
   - Action: genug für /create-plan zur Tages-Vollansicht; nicht auf Sarahs Trends-Antwort blocken.


---

## 2026-06-27 · Rebecca Brill (T12) · current beta · WhatsApp

Antwort-Runde auf unsere investigativen Rückfragen vom 2026-06-20. Screenshots zu Mahlzeiten angekündigt ("tonight").

1. **Retroaktiver Coach-Trigger: Logging kurz vor der nächsten Mahlzeit** (status: open, 💎 UX-Reibung)
   - Rebecca loggt typischerweise kurz VOR der nächsten Mahlzeit (nicht direkt nach dem Essen), um zu sehen was sie als nächstes essen sollte. Der Coach ist dann stumm weil die 60-min-Grenze greift. Unser Vorschlag "Trigger wenn heutiger Eintrag + noch keine spätere Mahlzeit geloggt" wurde von ihr mit Daumen-hoch bestätigt. Verwandt mit existierender `isRetroactiveMeal`-Funktion (coach_session_manager.dart). Neue Board-Karte vorgeschlagen (#P2), erst /create-plan nach Rebeccas Screenshot-Runde.

2. **Kalorien-Ziel möglicherweise zu niedrig für Kombination Schwangerschaft+Stillen+Sport** (status: 🔬 collecting, Screenshots ausstehend)
   - Rebecca überschreitet ihr tägliches kcal-Ziel konstant. Hypothese: 2200 kcal reicht nicht für ihre Kombination (schwanger + stillend + Krafttraining). Sie selbst kavalisiert ("maybe I'm just overeating") und fragt ob Userinnen mit bekanntem Ruheumsatz (RMR) ein personalisierteres Ziel einstellen könnten. Screenshots kommen heute Abend. Einzelstimme, unsicherer Bedarf. Kein Board-Eintrag bis Screenshots vorliegen.

3. **Protein-Total >100% UI aber Coach sagt "unter Ziel"** (status: 🔬 zweite Stimme auf bestehender Karte)
   - Rebecca beobachtet täglich Protein >100% im UI-Ring, aber der Coach kommentiert sie als unter Ziel. Entspricht exakt der Board-Karte "Protein target: UI macro split vs coach proteinTargetGrams diverge" (Patricia T13, #P3). Screenshot steht aus. Rebecca ist zweite Stimme, Hochstufung auf #P2 nach Screenshot prüfen.

---

## 2026-06-27 · Sarah (T7) · current beta · WhatsApp + Sprachnachricht (Antwort auf Rückfrage)

1. **Broader micronutrient view: Tages- vs. Wochenbasis, Discovery** (status: Bestätigung bestehender Plan)
   - Sarah kannte den Trends-Tab, hatte ihn vergessen. Tagesbasis ist ihr greifbarer, Woche bleibt wichtig für den Überblick. Bestätigt die Explore-Entscheidung: Trends deckt "pro Tag" nicht. Kein neuer Punkt, Bestätigung des Plans. Gehört zu bestehender Karte "Broader micronutrient view" (Explore, bereit für /create-plan).

2. **Mehr als 3 Mikros + Reiter mit allen ausgewählten** (status: Bestätigung bestehender Karte)
   - Sarahs Struktur "3 vorne + eigener Reiter" trifft exakt den Plan. Bestehende Karte, keine neue Aktion.

3. **Wochenübersicht ausklappbar mit Tagesbasis** (status: Bestätigung bestehender Plan)
   - Sprachnachricht: sie will einen ausklappbaren Wochenreiter mit Tagesbasis (inkl. Übererfüllung). Das ist die Tages-Vollansicht aus dem bestehenden Plan. Keine neue Karte.

4. **Streak-Logik / Gamification** (status: ⛔ out of scope, park-karte)
   - Spontan und selbst "noch nicht zu Ende gedacht": Monatsstreak, jeden Tag Nährstoffe erfüllt. Out of scope laut CLAUDE.md (Streak-UI ist explizit kein In-Scope-Element). Park-Karte Idea Backlog.

---

## 2026-06-27 · Patrizia (T13) · WhatsApp + PDF · Safety Sign-off (Antwort auf unsere Sign-off-Anfrage 2026-06-23)

Ernährungsberaterin/Ärztin, Gutachterin (= Patricia T13, dieselbe Person wie die Algenöl-/Protein-Stimme, Schreibweise variiert Patricia/Patrizia). Fachlicher Sign-off auf geschlossene Liste Safety-Grenzfälle ([[docs/explore/safety-borderline-signoff]]).

Generalvorbehalt (verbatim): "Also meine ehrliche Meinung: Wenn ich du wäre, würde ich so eine App nicht launchen bevor sie nicht von einer Ernährungsfachkraft die auf Schwangere und Stillende spezialisiert ist überprüft wurde [...] würde ich diese App als Ärztin und Ernährungsmedizinerin ehrlicherweise so wie sie jetzt ist nicht aktiv empfehlen." → Launch-Gate-Karte vorgeschlagen (#P0 #safety).

1. **Salami/Schinken/Räucherfisch Listerien-Warnung: bestätigt. NEU: Toxoplasmose** (status: open, 🐛 Safety-Lücke)
   - Listerien-Warnung: bestätigt. Patrizia fragt aber: "Was ist mit Toxoplasmose?" + PDF beigefügt. Toxoplasmose ist in der aktuellen Safety-Grenzfall-Liste nicht abgedeckt. Recherche-Schritt nötig, dann zweite Sign-off-Runde oder Einschluss in Safety-Build.

2. **Harte/lang gereifte Käse: NICHT warnen, exakter Wortlaut + Quelle** (status: open → bereit für /create-plan)
   - "Nur lang gereifter Hartkäse aus Rohmilch ist unproblematisch" (Netzwerk gesund ins Leben), Quelle angeben. Gruyère, Parmigiano, Pecorino etc. aus Roh-Käse-Match herausnehmen. Klarer Sign-off.

3. **Rohei-Speisen: warnen auch bei pasteurisiertem Ei, Wording auf "kritisch prüfen, im Zweifel weglassen"** (status: open → bereit für /create-plan)
   - Bestätigt aktuelle Praxis (warnen), Wording-Anpassung. Klarer Sign-off.

4. **Salbei/Pfefferminze: kein Sign-off, Eigenrecherche nötig** (status: open, Rückdelegation)
   - "Schau nochmal genau nach ob es da ein offizielles Statement gibt." Kein Veto, kein Bestätigung. Vanessa recherchiert DGE/BfR/Netzwerk-gesund-ins-Leben, dann erneut vorlegen.

5. **Flambiert: weiterhin warnen** (status: open → bereit für /create-plan)
   - "Es muss im inneren auf 70 Grad kommen. Das wird durch flambieren vermutlich nicht erreicht das ist ja nur oberflächlich." "Flambiert" aus Hitze-Ausnahme-Liste entfernen. Klarer Sign-off.

6. **Leber: gesamte Schwangerschaft meiden** (status: open → bereit für /create-plan)
   - "Immer an die offiziellen Empfehlungen halten wenn BfR sagt meiden dann meiden." T2/T3-Abschwächung entfernen. Klarer Sign-off.

7. **Stillzeit: keine Warnung Rohmilchkäse/roher Schinken/Räucherfisch, nur Schalentiere** (status: bestätigt)
   - "Ja denke schon." Bestätigt aktuelle Implementierung (Phase-Scoping C11 im Explore-Doc).

8. **Quecksilber Stillzeit "einschränken": bestätigt. Algen/Jod in Stillzeit: NEU warnen** (status: open, teilweise → bereit für /create-plan)
   - Quecksilber "einschränken" in Stillzeit: bestätigt. Algen/Jod in Stillzeit bisher still, Patrizia sagt ebenfalls warnen. Neue Regel nötig. Klarer Sign-off.

---

# Validierungs-Interviews — präskriptiver Mikronährstoff-Wert (Juni 2026)

Zweck: Prüfen, ob "kenne und schließe deine Nährstofflücken" der tragende Wert ist, und ob Testerinnen ihn so suchen. Zwei Tiefen-Interviews (Simone aktiv, Isabella aktiv). Beide Mitschriften aus Sprachnachrichten, teils mit Lücken, hier nur belastbar Zusammengefasstes. Strategische Gesamt-Synthese über die ganze Beta in [[docs/beta-learnings]].

**Die gestellten Fragen**
1. Was hat dich dazu bewegt, NourishMe testen zu wollen, und was hast du dir erwartet?
2. Wann hast du zuletzt eine Mahlzeit geloggt, und was hat dich in dem Moment dazu gebracht?
3. Erinnerst du dich an eine konkrete Coach-Antwort, die dir wirklich etwas gebracht hat?
4. Was müsste die App können, damit du sie morgen wirklich vermissen würdest? (bzw. was würdest du vermissen, wenn sie weg wäre)
5. Wie löst du dein Thema gerade ohne die App, und wo ist das besser oder schlechter?
6. Hast du für vergleichbare Dinge (Apps, Kurse, Beratung) schon mal Geld ausgegeben, wofür und wie viel? Plus: was nervt dich am meisten / Zauberstab-Wunsch?

## 2026-06 · Simone (T6) — Stillzeit, aktiv (32 Sessions), installiert 16.06.2026 · Validierungs-Interview

**Zusammenfassung**
- Zuletzt geloggt heute Mittag, gezielt um zu sehen, was der Coach zum Eisengehalt sagt, weil sie wieder Mühe hat, auf genug Eisen zu kommen.
- Konkrete Coach-Antworten sind ihr nicht hängengeblieben. Man könne nach Lebensmitteln fragen, aber das gehe "nicht weit genug". Wunsch: eine konkrete Mahlzeiten-Zusammenstellung.
- Wäre die App weg, würde sie sie nicht stark vermissen. Sie würde sonst wenig tracken, sich aber hin und wieder Gedanken um ihre Nährstoffe machen.
- Geld ausgegeben nur einmal: Wochenbett-App "The Weeks" mit täglichem Lese-Content, ca. 20 bis 25 Euro.
- Größter Wunsch: Rezepte eingeben oder importieren und dann "eine Portion davon" loggen können.

**Kritische Analyse**
- Wichtigster Befund: eine der aktivsten Testerinnen (32 Sessions) bei niedrigem empfundenen Wert. Hohe Nutzung heißt hier Neugier/Nachschauen, nicht Bindung.
- Wert (H2): schwach. Der Coach ist informativ, sie braucht ihn präskriptiv ("sag mir, was ich essen soll, um mein Eisen zu decken"). Das ist die unbesetzte Stufe 3 der Tiefe-Leiter.
- Retention (H3): "würde ich nicht vermissen" ist trotz hoher Aktivität ein Abwanderungs-Signal, deckt sich mit der flachen meal_logged-Retention-Kurve.
- Zahlungsbereitschaft: zahlt selten und niedrig (ca. 20 bis 25 Euro für Inhalt/Begleitung, nicht fürs Tracken). Gelbes Licht für 8,99/Monat.
- Reibung vs. Wert: klar Wert, nicht Reibung. Sie loggt mühelos, bekommt nur zu wenig zurück.
- Produkt-Signal: präskriptive Vorschläge (auch von Sarah genannt, also 2 Stimmen, grenzwertig roadmap-reif). Rezept-Import bisher Einzelstimme, sammeln.
- Caveat: n=1, Bekannten-Bias, selbstberichtet.

## 2026-06 · Isabella Hoesch (T8) — Stillzeit, aktiv, strukturierte Testerin · Validierungs-Interview

**Zusammenfassung**
- Auslöser zum Loggen war Neugier, wie sich die App entwickelt hat, kein akuter Bedarf. Loggen klappt an entspannten Tagen mit Handy griffbereit.
- Kern-Hindernis: Handy nicht immer dabei, kein Fan von Handy am Tisch. Retro-Logging (nachträglich loggen) war für sie eine entscheidende Verbesserung.
- Wert kommt vom Loggen, nicht vom Chat: sofortiger Effekt (Werte ändern sich direkt, "Balken vollkriegen wollen"), plus Impuls, die nächste Mahlzeit zur Tageslücke passend zu wählen. Die automatischen Rückmeldungen beim Loggen findet sie durchweg nützlich.
- Wenn die App weg wäre: würde den Überblick vermissen, käme aber zurecht. Alternative wäre ChatGPT. Nie Geld für solche Themen ausgegeben; Quellen sind ChatGPT und Austausch mit anderen Müttern.
- Größtes Ärgernis: dass sie überhaupt tracken muss (mag weder kochen noch tracken). Konkret: zu viele Notifications, sie ist ein Schnell-Deinstallierer-Typ, maximal zwei pro Tag.
- Extra-Ideen: Supplements einmalig im Profil hinterlegen, damit sie automatisch in die Tagesübersicht einrechnen (statt dauerhaft 0% DHA trotz genommener Tablette). Glaubwürdigkeit über ein echtes Experten-Gesicht (Patricia, Ernährungswissenschaftlerin) bei Tipps. "Tipp des Tages" / Fun-Facts zum Lernen. Chat und Loggen im Interface trennen. Tabs Trends/Verlauf nutzt sie nicht. Community als möglicher Moat-Gedanke.

**Kritische Analyse**
- Bestätigt die bescheidene Mikronährstoff-Version direkt: der "Balken füllen plus Impuls zur nächsten Mahlzeit" ist gelebte Stufe 1 bis 3 (Lücke sehen, selbst handeln).
- Gleiches Warnsignal wie Simone: engagiert, mag es, würde es aber nicht stark vermissen, Alternative ist ChatGPT. Damit 2 von 2 Tiefen-Interviews mit ChatGPT als Substitut. Der gefährlichste Wettbewerber ist ein kostenloses ChatGPT, das die Zielgruppe schon nutzt. Die offene Existenzfrage: ist der Wert deutlich besser als ChatGPT, sodass jemand zahlt und bleibt.
- Reibung ist der strukturelle Killer: "dass ich tracken muss". Was sie hält, ist Reibung senken (Retro-Logging hat sie gerettet). Mikro-Tiefe ist wertlos, wenn Loggen zu mühsam bleibt.
- Mehrstimmige, reife Feature-Signale: Supplements im Profil (löst das 0%-DHA-Problem, auch bei Celine/Rebecca/Sarah Thema, erhöht Genauigkeit und damit Glaubwürdigkeit der Mikro-Achse). Experten-Gesicht/klinische Fundierung wird hier unaufgefordert als Vertrauens- und Bindungs-Hebel verlangt ("dann halte ich mich daran"), nicht nur als Compliance.
- Fokus-Signal: Wert konzentriert in Log + "was fehlt heute". Trends/Verlauf und Chat werden kaum genutzt (Chat auch bei Simone kaum). Nicht mehr Tabs bauen, den täglichen Loop schärfen. Präskriptive Vorschläge gehören in den Log-Flow, nicht in ein Chatfenster.
- Vorsicht bei Community-Moat: eigener schwerer Produktmuskel, beißt sich mit dem Account-losen Datenschutz-Modell. Wahrscheinlicher Graben ist die expertenfundierte, schwangerschafts/stillzeit-spezifische präskriptive Tiefe.
- Caveat: n=1, Bekannten-Bias, selbstberichtet.

## Querschnitt aus beiden Interviews
- Pro Mikro-Wette: Beide bestätigen den Lücken-sehen-und-schließen-Wert auf der Erlebnis-Seite (Isabella explizit über den Balken-Loop, Simone über ihren Eisen-Bedarf).
- Contra / offenes Risiko: Beide sind engagiert, würden die App aber nicht stark vermissen, und beider Alternative ist ChatGPT. Bindung und Zahlungsbereitschaft sind unbewiesen und wirken nach diesen Gesprächen eher fraglich.
- Klarste nächste Bauten (mehrstimmig, niedriges Risiko): 1) Supplements im Profil, 2) sichtbare Fachperson hinter den Empfehlungen (zahlt auf Vertrauen, Bindung UND Safety ein), 3) Reibung im Loggen weiter senken.
- Offene Existenzfrage für die nächste Validierung: Schlägt der präskriptive Mikro-Wert ChatGPT deutlich genug, um Bindung und Zahlung zu rechtfertigen? Genau das soll der Concierge-Test (Eisen, von Hand, wenige Tage) beantworten.

---

# PMF-Runde 2 — Disappointment / Payment / Recommend (Juni 2026)

Sean-Ellis-artige PMF-Befragung. Vier Antworten (Eva, Nena NEU, Lotte, Corina). Drei davon Sprachnachrichten, **lückenhaft auto-transkribiert**, hier nur belastbar Zusammengefasstes. Vanessas eigene Learnings dazu liegen in der Strategie-Synthese [[docs/beta-learnings]], nicht hier (Trennung Fakten/Deutung).

**Die gestellten Fragen**
1. Wie enttäuscht wärst du, wenn es NourishMe nicht mehr gäbe (sehr / ein bisschen / gar nicht), und warum?
2. Was war das eine, das dir wirklich geholfen hat?
3. Was hat dich am meisten abgehalten, bzw. wann hast du aufgehört, es zu nutzen, und warum?
4. Würdest du für so etwas zahlen, und wenn ja, was fühlt sich pro Monat fair an?
5. Wem würdest du die App empfehlen, und wie würdest du sie in einem Satz beschreiben?

## 2026-06 · Eva (T1) — Stillzeit · PMF (Sprachnachricht, lückenhaft)
- **Hindernis (Q3):** nichts an der App selbst, sondern das Momentum: Handy beim Essen nicht dabei, oder Essen schon durch ("wie mache ich das jetzt?"). **Zeit war der entscheidende Faktor.** Mit dem Foto-Logging klappte es deutlich besser, vor allem wenn bekannte Produkte erkannt werden.
- **Geholfen (Q2):** Push-Notifications ("hast du Frühstück/Snack/Abendessen eingetragen?") als Erinnerung, plus die Tagesverläufe (sehen wie sich Werte über die Zeit ändern, normale vs. heiße Woche).
- **Payment (Q4):** grundsätzlich ja. Sieht Wert/Zielgruppe **vor allem bei Erstlingsmamas** (checken mehr); beim zweiten Kind weiß man "ich werde die Zeit eh nicht haben". **Werbefreiheit ist ein großer Zahlungsgrund** ("wenn keine Werbung dabei ist, bist du eher bereit zu zahlen").
- **Empfehlung (Q5):** gezielt an neue/erste Schwangere.

## 2026-06 · Nena (T14, NEU) — PMF (Sprachnachricht, lückenhaft)
- **Disappointment (Q1):** Mega-Fan der Idee/App, erzählt allen begeistert davon. ABER konnte es **nicht im Alltag etablieren**, schafft es trotz Reminder selten, abends nachzutragen. Schätzt das Nachtragen über mehrere Tage, kommt aktuell aber nicht dazu / setzt Prioritäten anders.
- **Hindernis (Q3):** Routine-Bildung nie erreicht; in der Theorie mega, in der Praxis nicht hinbekommen. Generelle Handy-Müdigkeit (nicht app-spezifisch). Idee: mehr **Spracheingabe** (alles reinsprechen, Coach übernimmt) würde für sie wahrscheinlich besser funktionieren, hat sie noch nicht getestet.
- **Geholfen (Q2):** wenn sie den Coach genutzt hat, hat sie die Tipps sofort umgesetzt. Konkretes Beispiel: schneller Snack gesucht → Vorschlag (z.B. mit Hummus) → hatte es da, "mega gefeiert".
- **Payment (Q4):** ja, sobald für sich etabliert und Mehrwert gefunden; die Coach-Tipps sind sehr wertvoll. Braucht erst Routine/Testphase, dann legitim zu zahlen.

## 2026-06 · Lotte (T11) — Stillzeit (3-Jähriger + 2,5-Monate-altes Baby) · PMF (Sprachnachricht, lückenhaft)
- **Disappointment (Q1):** zwischen "ein bisschen" und "gar nicht".
- **Geholfen (Q2):** hat ihr als **Indikator/Diktat** geholfen, zu erkennen dass sie **viel zu wenig Protein** isst. Diese eine Erkenntnis reicht ihr, sie muss nicht jeden Tag reingucken, sie weiß jetzt einfach "mehr auf proteinreiche Sachen achten" und kann das selbst grob einschätzen.
- **Hindernis (Q3):** zwei sehr aktive kleine Kinder, keine Zeit/Nerv für eine Zusatzaufgabe, hat gefühlt genug zu tun. Ist nicht der super-akribische Ernährungs-Typ, ein Indikator genügt ihr.
- **Payment (Q4):** **nein** (sagt aber selbst, sie ist generell jemand, der nicht zahlt).
- **Empfehlung (Q5):** an 2 Freundinnen weitergeleitet; eine fand es "zu viel Komplexität obendrauf auf den Alltag" (außer man hat echte Schwierigkeiten), Essen-Tracken sei ohnehin anstrengend. Beide haben es wohl letztlich nicht angeschaut, kein Feedback. War sich selbst unsicher, ob Tracken ihr guttut.

## 2026-06 · Corina (T3) — Stillzeit, viel Arbeit · PMF (englische Sprachnachricht, klarer)
- **Disappointment (Q1):** "quite disappointed". Hält sie für eine "amazing app", die "a huge difference" machen würde. Hat sie vielen Freundinnen + Kolleginnen empfohlen ("wow, super interesting"). Sieht großes Potenzial als **allgemeiner Food-Tracker** über die Zielgruppe hinaus, würde sie nach Schwangerschaft/Stillzeit weiternutzen wenn zur Gewohnheit geworden. (Stärkstes Retention-Signal der Runde.)
- **Geholfen (Q2):** dass man **Foto ODER Text** nehmen kann, "fit any way I managed to try", nicht nur ein Weg. Plus die **Warnungen** ("you drank too much coffee", "eat something healthier because you had an emotional day").
- **Hindernis (Q3):** viel Arbeit, vergisst es; **Backtracking/Backfill hat sehr geholfen**. Heißes Wetter, planloses Snacken, kein Schema, Hauptfokus Abendessen. Deshalb die letzten Tage weniger genutzt.
- **Payment (Q4):** "yes, probably". **7-Tage-Trial ist zu kurz für eine neue App, ein Monat würde "hook you".** Preis-Anker: ca. **5 [€/Monat]** bzw. **~30 pro Jahr**; mehr als das, unsicher ob Leute aktuell zahlen ("we're paying for a lot of things right now"). Ehrliche Einschätzung.
- **Empfehlung (Q5):** an alle. Ein-Satz: "if you want to keep your worries away from having to track what you eat, you should do it, especially in pregnancy" (ihre Angst war in der Schwangerschaft höher).

---

# Anhang: Roh-Transkripte der Validierungs-Interviews (Simone, Isabella)

Wörtliche, unbearbeitete Sprachnachricht-Transkripte (Lücken mit `___` markiert). Dies ist die QUELLE der bereits oben zusammengefassten Validierungs-Interviews (Simone T6, Isabella T8) im Abschnitt „Validierungs-Interviews — präskriptiver Mikronährstoff-Wert". Kein neues Signal, hier nur fürs verbatim-Archiv. (Ein drittes Transkript lag nicht vor.)

## Roh-Transkript · Simone (T6) — Stillzeit, aktiv

> Hi Vanessa, kein Problem unser kleiner ist gerade auch unerwartet wieder wach ___. Also ich versteh das mit der Hitze so zu deinen Fragen. Wann hab ich das letzte Mal ne Mahlzeit gelockt heute Mittag vor allem um einmal zu gucken __ der Coach zu dem Eisengehalt von der Mahlzeit sagt, weil ich _ __ wieder Probleme hab da auf ausreichende Menge zu kommen zum zweiten konkrete Antworten _ mir bis jetzt nicht so wirklich hängen geblieben was was ultra hilfreich ist. Klar kann man irgendwie mal fragen. Was sind jetzt konkrete Lebensmittel, die man __ __ _ ____ irgendwie essen könnte Aber das geht mir glaube ich manchmal noch nicht weit genug. Vielleicht wär's dann sogar irgendwie ganz __ ____ konkrete Mahlzeit, Zusammenstellung oder Ähnliches zu haben Ich glaub deswegen auch wenn wenn die App morgen weg wäre So ultra, viel würde ich nicht vermissen, weil ich sonst auch wenig eigentlich in Richtung __ ___ __ _____ würde ich mir so hin und wieder ein bisschen mehr Gedanken machen. Komme ich wirklich auf meine Nährstoffe etc. Zum vierten ich hab Das einzige Mal glaube ich, wo ich wirklich Geld im Zusammenhang mit ______ ___ ___. __ so ne Wochenbett App von The Weeks. Das war quasi dann für für irgendwie in die ____ __ _ auch __ __ ___ jemandem jeden Tag lesen konnte. Ich glaub das war aber auch nur so 20 € Fünf was ich richtig richtig cool fände wäre wenn man wirklich auch Rezepte einfach eingeben oder ___ könnte. Das hat bei mir bis jetzt noch nicht so richtig gut geklappt weil ich dann doch oft irgendwie mal was nach Rezept koche und es dann wirklich praktisch wäre das irgendwie so exakt wie möglich zu haben. _ dann einfach sagen zu können okay von dem Rezept eine Portion genau ich glaub das das _ _ ___ mal

## Roh-Transkript · Isabella Hoesch (T8) — Stillzeit, aktiv

> Guten Morgen so ich probier jetzt mal hier die Fragen zu beantworten Möglicherweise schreib ich ein bisschen ab, oder? Genau wenn wenn die Frage mich woanders hinführt also wann hab ich letzte Mal eine Mahlzeit gelockt und was hat mich in dem Moment konkreter zu ________ __ vorgestern? Und mich hat's gebracht natürlich weil ich einfach wissen wollte, wie sich die App weiter entwickelt hat Und ich würde'_ eher so beantworten. Also warum habe ich warum konnte ich da gut ______, weil wir da irgendwie entspannten Tag hatten und mein _____ ___ bereit war. Ich glaub das ist eher bei mir ein Thema. Ich hab mein Handy halt nicht immer bei mir und vor allem bin ich auch kein Fan Handy am Tisch. Deswegen mache ich das oft nicht und anfangs konnte ich dann nicht nach ______ aber das hast du ja inzwischen schon wieder Verbessert also das war für mich ein wichtiges ne wichtige Änderung, dass ich im Nachgang loggen kann. Genau das war super und dann mache ich das halt. Irgendwie hab ich das jetzt in den letzten _____ ___ ______ Woche mal im Auto gemacht oder am Abend mal ___ ____ ___ eingefallen ist und ich mein Handy grad da hatte. Genau das war wichtig Genau, aber gut, ich erzähl jetzt am besten über die Fragen hinaus weil wenn ich logge finde ich jetzt schon mal richtig cool dass ich verschiedene Nährwerte sehen kann und wie sich eben das Bloggern also ich ____ __ _____ cool, wenn man etwas tut auf einer App und man kriegt ______ ___ Effekt. Also ich trag das ein und sofort verändern sich die Werte das ist ___ ist das macht dann Spaß einfach so so direkten ______ ___ __ ______ zu sehen und dann will man ja quasi diese Balken voll kriegen Genau das ist auf jeden Fall gut gut gemacht das ___ ____ __ riesengroße Verbesserung Was fällt mir jetzt dazu noch ein? Oder geh ich zur nächsten Frage?

> So ich _______ ___ _____ ___ ______ zu machen, erinnerst du dich an eine konkrete _____? Antworte dir wirklich, was gebracht hat. Also ich hab jetzt nicht viel mit dem Coach gechattet, sondern einfach gelockt Und das hat mir mal was gebracht also eben zu sehen was es wofür gut was ist wo drinnen also diese Antworten beim Bloggern die finde ich schon mal gut, dass da auch ____ ______________ ist was gut und was schlecht ist ___ deswegen finde ich schon, dass die eigentlich alle also die bringen alle was die sind. Die bringen mir mehr wert. ___ ___ ___ ___ ____ ___ ich auch immer direkt Den Impuls, dass sich das dann schaffen mich dann irgendwie das dann die nächsten Mahlzeiten entsprechend in die Richtung ausfallen was eben bei mir fehlt für den Tag also das bringt schon auf jeden Fall was aber genauso zum Fragen stellen und chatten dafür ___ ___ _____ nicht so viel verwendet habe ich einfach _____ _____ so viel Bedarf gehabt Genau

> So, wenn die App morgen weg wäre, was würde ____ vermissen? Also ich muss sagen ich bin ja ich hab's ja ganz gut geschafft bisher auch ohne App aber es ist schon wirklich cool eben diesen Überblick zu haben aber von wie sich wie gut ich esse irgendwie ___ ___ _____ ___ __________ Und ja, das fände ich schon. Das würde ich vermissen, dass ich da irgendwie __ ___ _________ hab. ___ aber stattdessen würde ich wahrscheinlich nicht viel tun, wenn ich einfach schauen, dass ich weiterhin ausgewogen esse und _________ ___ _________ ____ ____ die voll ist ja immer mit ChatGPT bisschen quatschen. Das wäre wahrscheinlich meine Alternative.

> Und dann hab ich Geld ausgegeben für diese Themen nein also ChatGPT ist mein Berater bei vielem auch bei dem Thema ___ und der Austausch mit mit anderen Müttern und Leuten, die sich mit _________________ _________, dass da wohl ich meine Infos her

> Was nervt mich am meisten? Also, dass ich tracken muss! Daran kannst du jetzt nichts ändern. Ich finde einfach: noch eine App runterladen und dann da regelmäßig rein tippen. Gerade wenn man mit Kind eh gar nicht immer gefühlt zu viel am Handy ist. Ja, da kommt man halt. Also hätte ich jetzt gerade keine Alternative. Ich habe keinen Smart Tracker, der immer weiß, was ich esse. Am liebsten hätte ich einen Koch, der für mich kocht und dann auch noch das auf dem Schirm hat, was ich essen soll. Kann er gerne eine App benutzen oder auch nicht. Aber das wäre meine Idee. Eigentlich sollte Manu die App benutzen. Manu sollte für mich kochen und dann die App benutzen, um zu schauen, dass noch alles ausgewogen ist und ich eine andere Sicht bekomme. Das würde mich dann schon auch interessieren, was sich wie auswirkt, einfach weil ich es interessant finde. Aber ich koche nicht gerne und ich tracke auch nicht gerne. Von daher, in einer Traumwelt, würde das etwas anderes für mich tun.

> Aber jetzt, wenn man ein bisschen konkreter, also ein bisschen konstruktiver für dich zu sein an der App: Ich mag es nicht, wenn es zu viele Notifications sind. Also, ich habe eigentlich eher am Handy alle Notifications ausgestellt. Und jetzt bei Nourish Me habe ich es eben in der Meister-Tages-Übersicht. Also, ich kriege die und kann die dann auch gucken, aber das ploppt sich die ganze Zeit auf. Ich weiß, man muss Notifications machen, damit die Leute die App nicht vergessen, aber wenn es zu viele sind, bin ich dann direkt jemand, der dann deinstalliert. Genau, vielleicht so. Ich weiß gar nicht, wie viele es sind am Tag, aber da würde ich nicht mehr als zwei, also für mich nicht mehr als zwei. Ansonsten bin ich ein bisschen geprägt. Ansonsten nervt mich wenig an der App. Also, ich finde die Coolheit mit Intuitiv verbessert sich super, super schnell. Auch, dass ich jetzt Tage links und rechts warten kann, das war, finde ich, auch ein super guter Verbesserungsschritt.

> So, du musst dir jetzt diese Nachricht anhören, die geht ein bisschen länger, weil ich einfach hier ein bisschen nachdenke und rumblubbere. Aber vielleicht einen Punkt: Also, ich habe jetzt wirklich für mich, das Login ist das Hauptziel-Feature und halt sofort sehen, was brauche ich heute noch. Die zwei anderen Tabs, da weiß ich zum Beispiel jetzt gerade aus dem Kopf gar nicht, was da ist. Also, ich glaube, einmal eben so Zusammenfassungen von den verschiedenen Tagen und das andere weiß ich grad gar nicht. Also, das ist für mich so gar nicht so relevant oder so, dass ich's nämlich so genutzt habe. Das wäre ja hilfreich.

> Genau, da habe ich noch einen anderen Gedanken gehabt neulich. Viele Mamas nehmen ja Nahrungsergänzungsmittel, vor allem Vegetarier oder Veganer. Aber auch so gibt es ja diese Mama-Baby-Tabletten, also Nahrungsergänzungsmittel. Und da finde ich zum Beispiel cool, wenn man im Account oder im Profil, also den Standardeinstellungen, mit eintragen könnte: „Hey, ich nehme die und zwar jeden Tag." Dann rechnet das und dann ist es quasi in meiner Tagesübersicht verordnet. Also, dann fehlt mir zum Beispiel nicht immer null DHA-Prozent, sondern habe ich einfach standardmäßig, bin ich da bei, keine Ahnung, 80 Prozent oder 100 Prozent. Weil genau, das ist ja auch relevant. Also, dass man dann nicht nur die Balken vollkriegen will, aber eigentlich hat man schon die Tablette gemampft. Genau, dass man das eintragen kann, aber halt einmal und nicht jeden Tag sagen muss: „Okay, ich habe jetzt schon 100 Milligramm DHA zu mir genommen." Das fände ich noch, das würde es halt vollständiger machen und einfacher machen und mich vielleicht auch dazu bringen, in meinen Tabletten jeden Tag zu gehen. Genau, den Gedanken hatte ich neulich.

> Ansonsten, ja, vielleicht kannst du, ich weiß nicht, ob du dich irgendwie an HUB oder irgendwelchen anderen so Tracking-Apps orientierst. Die machen ja auch, also haben sie zumindest vor einem Jahr, jetzt noch genutzt, viel so mit Community gemacht. Ich glaube, dass man da irgendwie so einen Community-Aspekt reinkriegt. Es gibt nicht unbedingt, dass ich mich austauschen muss mit anderen Müttern oder kann, aber eher, dass ich so sehe: „Ah, okay, die benutzen das auch" oder „die ranken so" oder „die haben diese Werte" oder irgendwie im Schnitt vergleiche ich so und so zu diesen. Oder einfach nur: „Hey, 40 andere Mamas haben auch gerade entweder waren relativ oder haben auch gerade Nudeln gegessen" oder irgendwas, dass ich einfach das Gefühl habe, da ist Leben und das sind noch andere. Ich glaube, für dich jetzt als Gründerin oder als dass du es aufbaust, zu überlegen: „Okay, wie kriegst du, wie kannst du einen Aspekt reinbringen, den dann nicht der nächste direkt kopieren kann?" Und das würde ich sagen, ist halt immer die Marke mit der…

> So, jetzt hab ich grad gekuckt bei den zwei anderen Tabs das sind ja Trends und Verlauf. Vielleicht kannst du es irgendwie zusammenpacken beziehungsweise Trends. Das war für mich wenig informativ. Vor allem wenn man nicht regelmäßig alles einträgt dann fühlt man sich wenn ___ ______ vergisst, dann fühlt man sich direkt, so dass die Werte über die Zahlen nicht mehr relevant sind für ein man denkt sich auch die stimmen ja nicht richtig. Ich hab eine zwei Tage mein Mittagessen nicht getrackt dann denkt man direkt okay der ganze ___ ______ einem gar nix mehr. Aber was interessant oder was ich cool fände, wären immer so Tipp des Tages oder irgendwie weißt du so Minir ________? Wie wusstest du, dass bla bla bla dieses Essen und dass das dieser Nährstoff sich __ __ auswirkt und da wollte ich immer fragen wie wie war denn euer dein und Patrizias Austausch, das würde ich mich voll interessieren zu hören. _____ hoffe es hat mindestens Spaß gemacht und vielleicht könnt ihr was zusammen machen genau und eben in dem Gedanken wenn man dann nicht _____ nur in dem Tab jetzt ne so einen Tipp des Tages nicht nur irgendwie ne ki Text hat sondern dann eben so ein _______, weißt du so ein kleines Profil also Mini Profilfoto mit Patricia sowieso Ernährungswissenschaftlerin oder Ernährungsberaterin _________, ____? Sagt dies und das dann wirkt es alles direkt noch mal von dir da weil ich finde die meisten Leute wenn sie ki hören denken Sie ist nicht so viel wert aber es ist halt irgendwie schnell schnell gemacht und wenn wenn du da noch mal irgendwie so ne Glaubwürdigkeit rein rein bringst in dem da ah okay eine Wissenschaftlerin oder eine zertifizierte Person hat sich dazu auch noch geäußert und empfiehlt mir das und das Das _____ ___, dass wir das irgendwie noch mal aufwerten, die das Erlebnis genau und ich erinnere mich nämlich zum Beispiel wie ich mich mit der ________ nur ganz kurz über irgendwelche Öle unterhalten hab. Da ging's jetzt fürs Kind aber ist ja auch genauso gut für Schwangere und stillende gibt's sehr genug interessante Informationen. Wo ich mir grad hab okay wie war das noch mal? Was hat sie mir noch mal erzählt? Natürlich kann ich das alles irgendwie nach googeln und nach Chat aber ja irgendwie ist es find ich mehr wert wenn man da so ein Gesicht hat und und man weiß okay die Person die kennt sich wirklich damit aus und die hat mir jetzt das empfohlen und dann halte ich mich daran. __, den glaube ich zumindest genau das ist noch so ein Gedanke

> So noch ein. Den hatte ich mir schon vorher mal aufgeschrieben, aber noch _____ ________. Ich würde ich ___ __ ______ ich hab jetzt den Coach nicht. Kann nicht viele Fragen gestellt hab nur gelockt und ___ ___ _____ für ____, ___ intuitiver ____ das Bloggern und das chatten nicht im gleichen Interface wäre, also ich weiß nicht vielleicht kannst du auch bei diesem ____ ____, dass du dann sagst okay einen einen Tipp ist eben ______, einen ____ ____ chatten und ein Tipp sind diese Infos und über meinen über über ______ ______ ____ ____ ______ ______ Menü komme ich dann irgendwie auf meinen Verlauf und meine Historie, weil die interessiert mich um ehrlich zu sein nicht weil ich will ja eigentlich mein Ziel, dass ich jeden Tag mich ausgewogen ernähre Außer der Coach hilft mir auch noch, mich über die Woche hin ausgewogen __ ________. Ist natürlich auch noch ne andere. Bin ich noch gar nicht nachgedacht hab aber aktuell will ich ja einfach jeden Tag ____ ausgewogen ________. Und Fragen stellen können und ___ bekommen die, die ich jetzt nicht erfragt hätte, weil die mir gar nicht in den weil also genau ich meine ich kann immer Sachen fragen die ich im Kopf hab aber ich will ja auch Sachen lernen die ich nicht im Kopf hab also Neues und das dann eben durch diese ja diese Fun Wissen ____ oder sowas genau aber Hauptfeedback war eben Chat ___ ______ irgendwie getrennt zu behandeln

> So, dann wünsch ich dir jetzt mal viel Spaß beim abhören meines Gelaber und wollte aber grundsätzlich noch mal sagen. Also du ____ __ ____ ___ super Job gemacht ich ____'_ ich find's ne super App jetzt schon also auf jeden Fall mit Mehrwert und wie schnell du __________ und das Feedback einbaust, das ist echt Wahnsinn. Also Hut ab ___ ___ ich glaub du bist da wirklich an was dran also alle fragen sich ja was können Sie essen wie viel und so weiter und ich weiß ___ __ viele Mütter und die meisten Mütter noch mal mehr noch mal viel mehr drauf achten als ich also, dass ich nicht gerne _______ und so weiter Ich glaube, es gibt viel mehr, die das gerne tun. Vor allem wenn sie dann wisst. Also dann die Sicherheit haben, dass sie sich gut ernähren und das eben fürs Kind alles richtig und bestmöglich Sd also ne Unterstützung ist es ihr Kind sich bestmöglich entwickeln kann Das ist mehr als genug Motivation die App zu nutzen, die wirklich schon super ist und sich rapide weiter verbessert. Also bleib dran du machst es super und wenn ich dir aber irgendwas noch helfen kann oder? Ja, gib Bescheid. Ich werde weiterhin tracken.
