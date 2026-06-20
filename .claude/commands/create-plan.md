---
description: Muster-Recherche, dann 2-3 Loesungsoptionen mit Trade-Offs (du waehlst), dann Plan nach docs/plans/. Harter Stopp vor dem Bauen.
---

# /create-plan — Optionen, dann Plan

Voraussetzung: das Problem ist aus /explore verstanden. Jetzt darf ueber Loesungen
geredet werden, intern, nie mit Testerinnen.

## Ablauf

1. LOESUNGS-RECHERCHE. Bevor du Optionen entwirfst, sieh nach, wie das Muster
   etabliert geloest wird: Material 3 (m3.material.io), Apple HIG, Artikel ueber
   das konkrete Muster (Date Picker, rueckwirkendes Eintragen, Scroll-to-Verhalten
   usw.). Du kannst Docs und Artikel lesen, keine fremden Apps bedienen. Fasse die
   2-3 relevantesten Muster kurz zusammen.

2. Auf Basis der Recherche ZWEI BIS DREI Loesungsoptionen mit Trade-Off vorschlagen
   (Pro/Contra, Aufwand, Risiko). "Nichts tun / spaeter" als Option aufnehmen, wenn
   sinnvoll. Stopp und warte, bis ich eine waehle. Noch kein Plan.

3. Beruehrt die Aenderung Permissions/Datenfluesse/App-Store: security-dsgvo-review
   bzw. appstore-release-readiness zu Rate ziehen, Stolpersteine in die Trade-Offs.

4. Nach meiner Wahl: Plan schreiben nach docs/plans/JJJJ-MM-TT-slug.md (Ordner
   anlegen, falls fehlt). Struktur:

   # Plan: <Titel>
   **Fortschritt:** `0%`
   ## TLDR
   Was wird gebaut und warum (1-2 Saetze).
   ## Critical Decisions
   - Gewaehlt: <Option> — <Begruendung>
   - Verworfen: <Option> — <warum nicht>
   ## Rollback
   Wie nimmt man die Aenderung zurueck? Bei additiven, risikoarmen: "unkritisch,
   einzelner Commit".
   ## Schritte
   - [ ] 🟥 **Phase 1: <Name>**
     - [ ] 🟥 Teilschritt
   - [ ] 🟥 **Phase 2: <Name>**
     - [ ] 🟥 Teilschritt

   Modular, minimal, kein Scope ueber das Geklaerte hinaus. Alles, was eine
   Naehrwert-, Kalorien- oder Sicherheitsangabe beruehrt: als CRITICAL markieren
   und einen Verifikations-Schritt einplanen.

5. Board aktualisieren: auf die Karte einen Link zur Plan-Datei setzen
   ([[docs/plans/...]]), Karte nach "Geplant" schieben.

6. Plan zeigen. HARTER STOPP: kein Produktivcode, bevor ich freigegeben habe. Bauen
   passiert erst mit /execute.
