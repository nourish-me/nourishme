---
name: write-release-notes
description: >-
  Schreibt TestFlight-Release-Notes für NourishMe auf Englisch UND Deutsch,
  konsistent im etablierten Stil: kurzer Intro-Satz, knappe Bullets sortiert
  nach User-Impact (größter zuerst), Auto-Update-Tipp am Ende. Trigger bei
  "Release Notes für Build X", "Notes für TestFlight", "schreib die
  Release-Notes", oder wenn nach einem neuen Build die Änderungen zusammen-
  gefasst werden sollen. Vanessa setzt das Intro/Outro oft selbst dazu, aber
  Liste + Bullets + Auto-Update-Tipp baut der Skill.
---

# Release-Notes-Skill: NourishMe

Ziel: ein TestFlight-„What to Test"-Feld, das Tester in 20 Sekunden lesen
und verstehen welche Änderung sie auf welcher Stelle suchen sollen. Nicht
zu lang (Apple-Limit: 4000 Zeichen, in der Praxis < 800), nicht zu
marketing-y, immer DE + EN parallel.

## Pflicht-Struktur (für jede Sprache identisch)

1. **Ein Intro-Satz**, freundlich, persönlich, nicht generisch.
   **Variieren bei jedem Build** — Tester sollen nicht das Gefühl
   bekommen sie lesen denselben Boilerplate-Satz. Vanessa hat das
   ausdrücklich gewünscht: jede Release-Notes-Runde bekommt eine
   neue Formulierung mit gleichem Vibe (warm, ehrlich, persönlich).
   Beispiele aus denen ich frei rotiere ODER eine ähnliche neue
   Variante schreibe:
   - „Today is your lucky day, we've just shipped more updates
     thanks to more feedback we received. Happy testing and please
     continue sharing your thoughts!"
   - „Frischer Build is up. Diese Runde gehen viele Sachen direkt
     auf Feedback zurück das ihr geschickt habt, danke!"
   - „Kleines Update, einige große Fixes. Wenn ihr etwas testet was
     hier nicht auftaucht, immer her damit."
   - „New build is up. Mostly polish + a couple of safety fixes you
     flagged. Open for feedback as always."
   - „Update ist drauf. Hauptthema diesmal: [konkretes Thema, z.B.
     Settings-Auto-Save / Coach-Mikronährstoffe / Safety-Schicht].
     Schaut gern explizit dort hin und sagt Bescheid."
   - „Hi Tester:innen, hier kommt der nächste Build. Bestätigt mir
     gerne ob [X] jetzt besser läuft."

   Wähle eine andere Variante als beim VORLETZTEN Build (falls
   bekannt). Wenn ein konkretes Hauptthema im Build dominiert
   (z.B. „Stillzeit-Onboarding refactor"), spiele es im Intro
   namentlich an, das hilft Tester:innen sich gezielt darauf zu
   fokussieren.

   Vanessa fügt das Intro manchmal selbst dazu — wenn sie es im
   Auftrag explizit verlangt, sonst frag kurz, ob sie ein eigenes
   Intro setzt.

2. **Bullet-Liste, sortiert nach User-Impact** (größter zuerst,
   kleinster zuletzt). Drei bis sechs Bullets ist die übliche Länge.
   Ein Bullet pro abgeschlossenem Change, NICHT pro Commit.

3. **TestFlight-Auto-Update-Tipp am Ende** (immer, sofern Vanessa
   nicht explizit "ohne Tipp" sagt). **Auch hier variieren** — die
   Botschaft („schalte Auto-Updates in TestFlight ein") ist fest,
   die Formulierung wechselt von Build zu Build. Beispiele für die
   Rotation:
   - „💡 Tip: open the TestFlight app, tap on NourishMe, and switch
     on 'Automatic Updates' - that way you'll get every new build
     straight away without us having to nudge you."
   - „💡 Tipp: In der TestFlight-App auf NourishMe tippen und
     'Automatische Updates' aktivieren, dann ploppt jeder neue
     Build automatisch auf dem Handy auf."
   - „💡 Klein-Tipp: TestFlight → NourishMe → Auto-Updates an, sonst
     verpasst ihr Builds und ich muss euch immer pingen."
   - „💡 Reminder: TestFlight kann automatisch updaten, ein Tap
     drauf, 'Automatic Updates' on, fertig."
   - „💡 Falls noch nicht: in der TestFlight-App unter NourishMe
     'Automatische Updates' einschalten, dann ist der nächste Build
     sofort bei dir."

   Wähle eine andere Variante als beim letzten Build. Tonalität
   bleibt locker und nicht-zwanghaft.

## Ranking nach User-Impact (Reihenfolge der Bullets)

Faustregel: **Wenn ein Tester die App in der ersten Minute öffnet, was
sieht/spürt er als erstes?** Das oben.

1. Strukturelle Änderungen die jeden Tester treffen: Refactor des
   Hauptscreens, Navigation, Onboarding (für neue Tester der erste
   Eindruck), Speichern-Flow.
2. Spürbare UX-Polish die JEDER bemerkt: neue Animationen,
   Haptic-Feedback, sichtbare Layout-Änderungen, neue Button-Positionen.
3. Daten-/Berechnungs-Qualität die zwar unsichtbar abläuft aber das
   Vertrauen prägt: Kalorienschätzung, Coach-Antworten, Safety-Regeln.
4. Spezialisierte Features die nur eine Teilmenge sieht: Vegan-Hinweis
   (nur vegane Schwangere/Stillende), Twin-Specific-Logik, etc.
5. Bug-Fixes die offensichtliche Reibung wegnehmen: Duplizieren, Chat
   stürzt nicht mehr ab, i18n-Fixes.
6. Subtiles Polish: Typo-Updates, Dialog-Theming, Wording-Klarstellungen.

Wenn ein Bullet in mehrere Kategorien fällt, oberste Kategorie zählt.

## Sprach-Stil

- **Keine Em-Dashes** (Projekt-Konvention aus `CLAUDE.md`). Komma,
  Doppelpunkt, oder neuer Satz stattdessen. Hyphen-Minus „-" ist OK.
- **Keine Marketing-Sprache** („revolutionary", „game-changer", „now
  with"). Stattdessen direkt was sich geändert hat.
- **Konkret statt abstrakt.** Nicht „improved diary UX", sondern „day
  swipe slides like a page turn, with haptic". Tester verstehen
  konkrete Sätze besser.
- **Beispiele in Klammern wenn hilfreich.** „You can rename it (e.g.,
  'Muesli' to 'Muesli with banana')" macht den Punkt fassbar.
- **Du-Form auf Deutsch**, nicht „Sie". Vanessa duzt ihre Tester.
- **Knapp.** Ein Satz pro Bullet, max zwei wenn unvermeidbar. Apple-
  TestFlight-Felder werden in einem schmalen Modal angezeigt — je
  länger der Satz, je mehr Scrollen.

## Wie ich die Bullets baue

1. Liste der Commits seit letztem ausgespielten Build via
   `git log --oneline <last-build-hash>..HEAD` ziehen. Wenn der
   letzte Build-Hash unklar ist, Vanessa fragen welcher Build aktuell
   bei Testern liegt.
2. Pro Commit prüfen: was sieht der User davon? Wenn unsichtbar (z.B.
   reine Test-Hinzufügung, internes Refactoring, build-bump), KEIN
   Bullet.
3. Mehrere kleine Commits zum gleichen Thema (z.B. „milkshare wording"
   + „onboarding milkshare dedup") in EIN Bullet zusammenfassen.
4. Bullets nach den Kategorien oben einordnen, dann sortieren.
5. EN zuerst schreiben, dann DE Satz-für-Satz übersetzen — nicht
   umgekehrt. EN ist die kürzere Sprache, hält die Bullets knapp;
   DE wird sonst zu lang.

## Format ausgegeben an Vanessa

```
**English**

<Intro-Satz>

- Bullet 1 (größter Impact)
- Bullet 2
- ...

💡 Tip: <Auto-Update-Tipp>

**Deutsch**

<Intro-Satz auf Deutsch>

- Bullet 1
- ...

💡 Tipp: <Auto-Update-Tipp DE>
```

Beide Versionen in EINER Antwort, durch `**English**` / `**Deutsch**`
visuell getrennt.

## Spezialfall: Build-Bump ohne neue Features

Wenn nur Tests / build-bump committed wurde (kein user-facing Change),
ehrlich antworten: „Seit dem letzten Build gibt's keine sichtbaren
Änderungen, nur interne Tests. Lohnt sich kein neuer TestFlight-
Upload." Statt Bullets erfinden.

## Anti-Pattern (bewusst NICHT tun)

- Bullets nach Commit-Chronologie sortieren (= zufällige Reihenfolge
  aus Sicht des Testers).
- Internals als Bullet auflisten („refactored the diary state to a
  single-day model"). Tester interessiert nicht WIE, sondern WAS sie
  sehen.
- Intro-Sätze die jeden Build gleich klingen („Hi testers! Here's
  what's new!"). Aus dem Pool oben rotieren oder eine neue Variante
  schreiben, NIE zweimal exakt dasselbe Intro.
- Outro-Auto-Update-Tipps die wörtlich identisch sind zum letzten
  Build. Botschaft bleibt gleich, Formulierung wechselt.
- Beide Sprachen mit Em-Dashes — würde gegen Projekt-Konvention
  verstoßen.
- Auto-Update-Tipp weglassen, ohne explizite Bitte. Die meisten
  Tester haben das nicht aktiv und verpassen Builds.
