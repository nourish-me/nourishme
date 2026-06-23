# Explore: Final-Sign-off Safety-Grenzfälle

Audit item (#safety), no tester voice, no pattern rule. Goal of this explore: a
**closed list** of every deliberate borderline call in the deterministic safety
layer, so a nutritionist (Patrizia, T13) can sign each one off (confirm / adjust)
before launch. **No solution, no rule change here.** All items verified against
`assets/safety-rules.json` + `lib/services/safety_rules.dart` on 2026-06-23; the
rule data's own `lastReviewedAt` is 2026-06-15 (sources: DGE, BfR, EFSA, LactMed,
Diätassistentin June 2026).

How the layer works (context for the reviewer): nine pure rules run on every
logged food string plus a phase (pregnant / trimester / lactating). Matching is
either whole-word (`_containsWord`, avoids the "Tomate→mate" trap) or
token-substring (`_tokenContains`, for German head-compounds like
"Thunfischsalat"). Over-warning is the deliberate default (over-warn > under-warn).

---

## A. Bewusst INKLUSIV (warnt absichtlich breit — bitte bestätigen)

1. **Salami** → löst in der Schwangerschaft die Listerien/Roh-vom-Tier-Warnung aus
   (`rawAnimal` keyword). Gepökelt/fermentiert, Listerienrisiko fachlich debattiert;
   bewusst konservativ inkludiert. (Auf der Karte als Beispiel genannt.)
2. **Rohe/luftgetrocknete Schinken**: Parmaschinken, Serrano, Prosciutto, Coppa,
   Bresaola, Bündnerfleisch, Pancetta, Lachsschinken → Schwangerschafts-Listerien-
   Warnung. Gepökelt, nicht erhitzt; bewusst inkludiert.
3. **Geräucherter/gebeizter Fisch**: Räucherlachs, graved/Gravlax, Matjes,
   Bismarckhering, Rollmops, Bückling → Schwangerschafts-Listerien-Warnung. Kalt-
   vs. heißgeräuchert wird NICHT unterschieden, alles inkludiert.
4. **Harte/lang gereifte Käse** im selben Roh-vom-Tier-Topf: Gruyère, Comté,
   Parmigiano Reggiano, Pecorino, Manchego, Beaufort, Bergkäse, Cantal, Appenzeller
   → lösen die Schwangerschafts-„Weichkäse/roh meiden"-Warnung aus, obwohl harte,
   lang gereifte (meist pasteurisierte) Käse i.d.R. als unbedenklich gelten.
   **Wahrscheinlich ÜBER-inklusiv, höchste Priorität zur Klärung.**
5. **Rohe-Ei-Speisen/Saucen**: Tiramisu, Mousse, Hollandaise, Béarnaise,
   Feinkostsalat → Schwangerschaftswarnung, auch wenn kommerziell mit
   pasteurisiertem Ei. Bewusst inkludiert.
6. **Rohe Sprossen**: Sprossen, Alfalfa(-sprossen), Mungo(-sprossen) → liegen im
   `rawAnimal`-Topic (sind Pflanzen, aber Rohverzehr-Risiko Salmonellen/Listerien/
   E. coli), lösen die Schwangerschaftswarnung aus. Klassifikation bewusst, Wording
   spricht aber von „roh vom Tier".
7. **Butterfisch** in der Quecksilber-Liste → wird als Quecksilber-Risiko markiert,
   obwohl das Hauptproblem von Butterfisch/Escolar Gempylotoxin (Verdauung) ist, nicht
   Quecksilber. Warnen ist richtig, der Topf (Begründung) ist fachlich fragwürdig.

## B. Bewusst WEICH (sanfter Hinweis statt harter Warnung — bitte bestätigen)

8. **Salbei/Pfefferminze (Milchbildung)**: warnt nur in der Stillzeit UND nur wenn
   zusätzlich ein Große-Mengen-Marker im Text steht (literweise, abstill, Konzentrat,
   Tinktur, Extrakt, ätherisch, hochdosiert, Salbeiöl, Pfefferminzöl), und selbst dann
   nur ein weicher Hinweis („in großen Mengen theoretisch milchdämpfend, Alltagsmengen
   unkritisch"). Schwache Evidenz, bewusst soft. (Auf der Karte als Beispiel genannt.)
9. **Hitze-Ausnahme (Beruhigungs-Variante)**: steht bei einem Roh-vom-Tier-Treffer
   ein Hitze-Marker im Text (gebacken, überbacken, Ofen, back, gegrillt, **flambiert**,
   **frittiert**, baked/broiled/grilled/fried/oven), kippt die Warnung von „meiden" auf
   „roh wäre Listerien-Sorge, durchgegart ist sicher". Bitte die Marker-Liste prüfen,
   speziell **„flambiert"** (kurzes Abflammen erhitzt evtl. nicht durch → mögliche
   Falsch-Entwarnung) und Grenzfälle wie „gegrillt"/„frittiert". Zusatz: die
   Beruhigungs-Variante feuert auch für STILLENDE, der Text nennt aber Listerien/
   Schwangerschaft (im Code bewusst so, leicht off-context für die Stillende).
10. **Leber T2/T3 abgeschwächt**: 1. Trimester „meiden", ab dem 2. Trimester nur noch
    „sehr zurückhaltend". Der BfR empfiehlt Verzicht über die GESAMTE Schwangerschaft;
    die App mildert ab T2 bewusst das Wording (Ton statt Alarm). Spannung Leitlinie vs.
    Ton, bitte abzeichnen.

## C. Phase-Scoping (in bestimmten Phasen bewusst STILL — bitte bestätigen)

11. **Roh-vom-Tier in der Stillzeit weitgehend STILL**: eine stillende (nicht
    schwangere) Userin bekommt für Rohmilchkäse, rohen Schinken, Räucherfisch KEINE
    Warnung (Listerien/Toxoplasmose gehen nicht in die Milch über). Nur **rohe
    Schalentiere** (Muscheln/Austern/Venus-/Jakobsmuscheln, Norovirus/Hep A/Vibrio)
    warnen in der Stillzeit. Bitte bestätigen, dass eine maternale Listeriose in der
    Stillzeit bewusst out-of-scope sein darf.
12. **Quecksilberfisch in der Stillzeit „einschränken" statt „meiden"** (in der
    Schwangerschaft „meiden"). Bewusst weicher in der Stillzeit.
13. **Algen und Chinin: nur Schwangerschaft**, in der Stillzeit still. Bitte bestätigen,
    dass Jod-Überschuss durch Algen in der Stillzeit (geht in die Milch) bewusst nicht
    abgedeckt wird.
14. **Wildschwein-Innereien: feuert in Schwangerschaft UND Stillzeit** (BfR nennt auch
    Stillende/Frauen im gebärfähigen Alter). Bewusst auf die Stillzeit ausgeweitet.
15. **Koffein: nennt bei JEDER Koffein-Quelle die 200-mg-Tagesgrenze**, ohne mg zu
    summieren (keine Portionsdaten), also auch bei einem einzelnen kleinen Kaffee.
    Informativ gemeint, bewusst so.
16. **Energy-Drinks „komplett meiden" nur in der Schwangerschaft**; in der Stillzeit
    nur der normale 200-mg-Koffein-Hinweis.

## D. Bewusste AUSSCHLÜSSE (warnt absichtlich NICHT — bitte bestätigen)

17. **Alkoholfrei-Marker** (alkoholfrei, alcohol-free, non-alcoholic, „0,0", „0.0") →
    keine Alkohol-Warnung. Hinweis: „alkoholfreies" Bier darf bis 0,5 % Restalkohol
    enthalten und würde dann nicht warnen.
18. **Kombucha** aus der Algen-Regel ausgeschlossen (enthält Substring „kombu", ist aber
    fermentierter Tee). Nebenbefund: Kombucha bekommt überhaupt keine Warnung, obwohl
    fermentierter Tee Spuren von Alkohol und Koffein enthält.
19. **Algenöl** aus der Algen-Regel ausgeschlossen (raffiniertes DHA-Öl, nicht der
    Jod/Arsen-Träger ganzer Algen). Eigene Karte (Patricia); hier nur der Vollständigkeit
    halber.
20. **Muschelnudeln / Conchiglie / shell pasta** aus der Roh-Schalentier-Regel
    ausgeschlossen (Pasta-Form, kein Meerestier).
21. **Leberkäse** aus der Leber/Vitamin-A-Regel ausgeschlossen (enthält Substring
    „leber", ist aber Brät, keine Leber).

---

## Nicht für den fachlichen Sign-off (gehört zur Karte „Scalable safety matching")

Reine Match-Logik-Risiken, keine klinische Entscheidung: kurze Substring-Needles im
`_tokenContains`-Pfad können fehlmatchen, z.B. Quecksilber-Token **„hai"** triggert in
„Shanghai-Nudeln". Das ist ein False-Positive-Mechanismus, kein bewusster Grenzfall, und
wird über die separate `#P2 #safety`-Karte (skalierbares Matching) adressiert, nicht hier.

## Status

Geschlossene Liste, im Code verifiziert (Stand 2026-06-23). Nächster Schritt: fachlicher
Sign-off pro Punkt durch Patrizia (bestätigen / anpassen). Erst danach ggf. /create-plan,
falls einzelne Calls geändert werden sollen.
