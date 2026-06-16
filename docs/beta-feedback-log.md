# Beta-Feedback-Log

Sammelstelle für Tester-Stimmen aus der Beta-Phase. Jede Session ein
Block. Tester anonymisiert (T1, T2, ...) damit der Log nicht
versehentlich PII enthält wenn er später in einem Demo-Screenshot
landet. Status pro Punkt: open / in-progress / fixed / waiting-for-
pattern.

Pattern-Regel: einzelne Stimmen werden notiert, aber NICHT sofort
invasiv umgesetzt. Erst wenn zwei oder mehr Tester denselben Punkt
unabhängig nennen, wird das ein UI-/Feature-Change. Ausnahme:
no-brainer-Verbesserungen die allen Testern nützen (z.B. Prompt-
Schärfung, Coach-Tone) kommen direkt rein.

---

## 2026-06-15 · T1 · Build +24 · Sprachnachricht

Tester-Profil: stillende Mutter, viel unterwegs mit Kleinkind.

1. **Foto-Erkennung ungenau** (status: in-progress, no-brainer)
   - Beispiel A: „Pflaumen mit Sahne" geloggt statt Heidelbeeren mit
     Joghurt. Farb-/Form-Verwechslung.
   - Beispiel B: Salat mit viel Kleinzeug (Gurken, Tomaten, Nüsse) -
     das Kleinzeug wird nicht erkannt.
   - Geplant: Foto-Prompt schärfen (alle Komponenten enumerieren,
     bei Ambiguität alltägliche Variante bevorzugen). Plus
     Brand-History auch beim Foto-Parse injizieren, sodass die
     User-eigene Loggings den Foto-Parse beeinflussen.

2. **Vergisst zu loggen weil Handy nicht am Tisch** (status: waiting)
   - Push-Erinnerungen existieren, vermutlich Discovery-Problem.
   - Erst klären ob sie die Pushes aktiv hat, dann entscheiden.

3. **Retroaktiv loggen - wie?** (status: waiting)
   - Geht über AppBar-Tag-Picker oder Pille im Speichern-Sheet.
   - Erst klären ob sie das nicht entdeckt hat, dann entscheiden ob
     UI-Hint nötig ist.

4. **Tagesziel nicht erreicht, kleine Snacks vergessen** (status: in-progress)
   - Doppel-Problem: psychologisch (Frust) + technisch (Snacks
     loggen ist Reibung).
   - Geplant: Coach-Botschaft „Tagesziel ist Richtwert über die
     Woche" als Guardrail im per-meal-Prompt, schützt alle Tester
     vor Perfektionismus-Frust. Plus: in der Antwort die Favoriten-
     Funktion erklären (ein-Tap-Re-Log für regelmäßige Snacks).

---

## 2026-06-15 · T3 · Build vor +24 · WhatsApp-Voice + Follow-Up

Tester-Profil: stillende Mutter, ~1-jähriges Kind, beruflich tätig
(Schule), nutzt CHAT-Path zum Loggen statt Tagebuch-Add-Sheet
(wichtig für #102 - der per_meal-Fix allein hilft ihr nicht).

1. **Backfill / Coach kennt Mahlzeit-Zeit nicht** (status: in-progress, PATTERN T2+T3)
   - Sie loggt fast immer verspätet, Coach sagt „iss was in ein
     paar Stunden" obwohl Mittag in 20 Min ist.
   - Follow-Up: sie nutzt NICHT den Tagebuch-Add-Flow, sondern den
     Coach-Chat („I had X for breakfast"). Daher kommt der per_meal-
     Fix (#102) bei ihr nicht an. Task #102 ist erweitert um den
     chat-Pfad (chat_base_de/en Prompt: erkenne vergangene-Mahlzeit-
     Sprache, reasone mit Zeit-Versatz).

2. **Delete-Bug** (status: closed-by-tester)
   - T3 zog am 2026-06-15 zurück: „forget about it." Vermutlich
     auf altem Build oder reproduziert sich nicht mehr. Task #104
     deprioritised, nicht gelöscht (falls wer anders ähnliches
     berichtet, wieder hochziehen).

3. **„Coffee remember" Feature** (status: waiting)
   - Vermutlich Favoriten-Discovery-Problem. Rückfrage raus.

4. **Kalorien-Schätzung zu hoch (2600 kcal)** (status: clarified, no action)
   - Follow-Up: 1J-Kind, 3-4 Mahlzeiten + Snack, Rest Muttermilch
     2-3× tagsüber + nachts. „500 ml feels right" nach Überlegen.
   - Damit ist die Schätzung wahrscheinlich KORREKT (500ml ≈ 420
     kcal supplement + Mifflin ~1500 + Aktivität ~750 = ~2600).
     „Fühlt sich hoch an" weil sie an non-lactation Wert (1900-
     2000) gewöhnt ist.
   - Action: build +25 Szenarien-Cards können ihr trotzdem helfen
     („Hauptsächlich Beikost + etwas deiner Milch" = 20% wäre evtl.
     zu niedrig, „halbe-halbe" = 50% wäre realistischer Pick).
     Coach könnte zukünftig explizit erklären woher der Aufschlag
     kommt (Idee, kein Task heute). Falls ihre Waage nach 2-4
     Wochen verlässlich abnimmt → Target stimmt. Falls schnell
     abnimmt → Activity-Factor runterstellen.

5. **Snack-Empfehlungen zu häufig** (status: open, T3 confirmed)
   - „Setting it up before would be fine." → bestätigt Settings-
     Toggle für Mahlzeit-Struktur. NEUER Task: #108. No-brainer
     für +25.

6. **Recruitment-Angebot 9 stillende Mütter** (status: open, strategic)
   - Forms-URL bekommen, Antwort an T3 raus mit waitlist-Link.
     Vanessa muss noch Worker-Cap und Beta-Onboarding-Velocity
     einschätzen bevor wir die Welle starten.

---

## 2026-06-16 · T5 · Build +24 · WhatsApp-Text

Tester-Profil: neu, eine Nachricht bisher.

1. **Retro-Logging Discovery: „Essen für den Vortag eintragen"** (status: open, PATTERN T1+T5)
   - Wörtlich: „es wäre toll, wenn man Essen zB für den Vortag
     nachträglich eintragen könnte."
   - Feature EXISTIERT in +24 schon (AppBar-Datum-Tap → Mini-
     Kalender → Tag picken → Mahlzeit normal loggen).
   - Pattern: T1 hatte das exakt gleiche Discovery-Problem. Damit
     qualifiziert für UI-Verbesserung (Task #113).
   - Antwort an T5 raus mit Anleitung wie's heute geht +
     Rückfrage ob sie es nicht gefunden oder zu fummelig fand.

---

## 2026-06-15 · T2 · Build +24 · WhatsApp-Text

Tester-Profil: arbeitet/unterrichtet (Schule erwähnt), entspannte
Esserin, schaut neugierig auf Daten statt akribisch zu tracken.

1. **Multi-Photo-Upload nachmittags nachpflegen** (status: open, single-Stimme)
   - „Heute keine Zeit gehabt, nachmittags mehrere Fotos auf einmal"
   - Drei UI-Optionen skizziert: (a) Multi-Select Picker + Auto-Forward
     durch ConfirmSheets, (b) Bulk-Queue mit Listen-Edit, (c) Quick-Save
     ohne Confirm-Stage.
   - **No-brainer-Vorzieher: EXIF-Timestamp aus Foto-Metadata
     übernehmen** (heute nehmen wir vermutlich DateTime.now(), das ist
     auch für Single-Photo retro-uploads kaputt). Verifizieren ob
     image_picker EXIF mitliefert.
   - Rückfragen an T2 raus: bevorzugtes UX-Pattern, Zeit-Quelle.
   - Pattern-Status: 1/N für Bulk-Flow, auf zweite Stimme warten.

2. **Backcamembert False-Positive Rohmilch-Warnung** (status: in-progress, no-brainer)
   - Unsere SafetyRule trifft auf „camembert" als Rohmilch-Keyword,
     Backcamembert ist aber durchgebacken (Hitze tötet Listerien).
     Warnung schafft Unsicherheit statt Klarheit.
   - Geplant: „Erhitzt-Marker"-Liste in SafetyRules (gebacken,
     überbacken, gegrillt, im Ofen, heiß, flambiert) - bei Treffer
     Warnung unterdrücken ODER in Beruhigungs-Form umformulieren.
     Plus parse_de Prompt-Hint: bei Erhitzt-Präfix den Hitze-Aspekt
     erwähnen statt pauschal warnen.
   - Pattern-Status: ausreichend (technischer Fix mit klarer Logik,
     keine UX-Entscheidung nötig).

3. **Lob auch bei Schokolade kommt gut an** (status: fixed, Konfirmation)
   - Positiver Datenpunkt für den per_meal-Coach 🟢 Stark-Zeile-Tone.
   - Keine Änderung, nur Bestätigung dass die nicht-judgemental-Linie
     bei pleasure foods ankommt.

4. **Jod systematisch zu niedrig** (status: waiting + in-progress)
   - Mehrere Hypothesen vor wir bauen:
     (a) Nimmt sie ein Schwangerschafts-Supplement (Femibion etc.) und
         hat es in den Settings eingetragen? Femibion enthält 150 µg Jod
         = 100% Tagesziel.
     (b) LLM schätzt Jod systematisch zu niedrig weil jodiertes Salz
         in industriell verarbeiteten Produkten unter Detection-Schwelle.
     (c) Tatsächlich jod-arme Ernährung (in DE statistisch häufig).
   - No-brainer geplant:
     - parse_de Jod-Plausibility-Anchor erweitern um jodiertes Salz
       in Brot/Pizza/etc.
     - Onboarding-Frage „nimmst du ein Schwangerschafts-Supplement?"
       (heute existiert das Feature, aber kein aktiver Push im Setup).
   - Pattern-basierte Trigger (wöchentlicher Hinweis bei chronischer
     Lücke, Mikronährstoff-Trends-Tab) auf zweite Stimme warten.
   - Rückfragen an T2 raus: Supplement aktiv? Donut täglich beachten?
     Wäre Wochen-Übersicht hilfreich?

### Antworten T2 auf Rückfragen · 2026-06-15

1. **Multi-Photo-Zeit**: Uhrzeit weiß sie grob. Bevorzugt:
   alle Fotos auf einmal speichern, dann einzeln editieren wo nötig
   → Option (b) Bulk-Queue mit Inline-Edit aus meinem Vorschlag.
   Festigt das Pattern: Task #98 (EXIF) ist nur Teil-Fix, echtes
   Feature ist Multi-Photo-Bulk-Flow. NEUER Task: #105.

2. **Jod-Supplement**: sie HAT ein Supplement im Onboarding
   eingetragen, das enthält nur einfach kein Jod. Also Werte
   sind ECHT. Aber: „App zeigt es dauernd an und das verunsichert
   sie." → NEUES Problem: Mikronährstoff-Lücken-Trigger (#47) ist
   zu nervig wenn der Nährstoff chronisch defizitär ist und die
   User bewusst keine Veränderung will. NEUER Task: #106 (Lücken-
   Nag-Cooldown / Opt-out per Mikronährstoff). Auch: Task #101
   (Active-Supplement-Push im Onboarding) ist NICHT der Fix für
   T2 (Supplement war schon eingetragen), bleibt aber general-
   purpose Verbesserung.

3. **Wochenübersicht**: „fände sie super." → bestätigt
   Mikronährstoff-Trends-Tab als wertvolles Feature. NEUER Task: #107.

4. **Donut sporadisch, nicht täglich**: bestätigt dass passive
   Benachrichtigung (Push? wöchentliche Coach-Bubble?) besser ist
   als sichtbar prominenter Donut-Status. Fließt in #107 ein.

---
