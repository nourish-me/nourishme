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
| Iodine-gap nag trigger tuning                 | 💎   | ❓      | → +37                  |
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

**Update-Message [DE]:**

> Hey Henrike, eine neue App Version unterwegs - hoffentlich bis (über)morgen bei dir!
>
> Eine Entschuldigung vorab: ich habe **heute erst** in App Store Connect die Internal-Feedback-Sektion entdeckt, wo dein TestFlight-Feedback (Screenshots) landet. Mir war das vorher nicht klar - daher kam dein Feedback erst heute richtig in meinen Backlog. Sorry für die Verzögerung! **Vielen Dank trotzdem für die Reports + Screenshots**, mit denen ich sofort die Diagnose erleichtern konnte.
>
> Aus deinem Feedback gefixt mit der Version die (über)morgen kommt:
> - kcal-Schätzung für Einzellebensmittel ist jetzt mit harten Ankern (1 gekochtes Ei NIE über 100 kcal, Banane ~105 kcal, Apfel ~95 kcal etc.). Dein Beispiel mit dem Ei bei 155 kcal sollte nicht mehr passieren.
>
> Zum Supplement-Setup-Timeout: danke für die Rückmeldung, dass es beim zweiten Versuch geklappt hat - dann war das vermutlich die Zug-Verbindung und nicht die App. Damit haken wir das ab.
>
> Danke nochmal!

### Julia Mayer (T10) — TestFlight, iPhone 14 Pro DE

| Feedback | Type | Status | Build |
|---|---|---|---|
| Lactation profile gets pregnancy warnings | 🐛 | ✅ | +36 |
| Time picker AM/PM cumbersome | 💎 | ✅ | +37 |
| Dynamic activity adjustment (HealthKit + manual fallback) | 🚀 | ⛔ | parked in idea-backlog |
| Coach ignores onboarding supplements in chat | 🐛 | 🟡 | → ? |

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
