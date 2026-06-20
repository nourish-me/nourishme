---
name: manual-test-plan
description: >-
  Erzeugt eine manuelle Geraete-Testplan-Checkliste (zum Durchklicken am iPhone)
  fuer eine gebaute Aenderung. Getrennt von test-critical-flows (das automatisierte
  Unit-Tests schreibt). Trigger: aus /review heraus, oder "manuellen Testplan fuer X".
  Schreibt nach docs/test-plans/build-XX-test-plan.md im etablierten Stil.
---

# Skill: Manueller Geraete-Testplan

Ziel: eine kurze, abhakbare Checkliste, die Vanessa am echten iPhone durchgeht,
nachdem eine Aenderung gebaut und automatisiert getestet wurde. KEINE Unit-Tests
(das macht test-critical-flows), sondern was-tippe-ich-und-was-muss-passieren.

## Ablauf

1. Die gebaute Aenderung ansehen (Plan-Datei + git diff), um zu wissen, welche
   Screens und Flows betroffen sind.
2. Bestehende Testplaene in docs/test-plans/ ansehen und deren Stil uebernehmen.
3. Pro betroffenem Flow konkrete Schritte schreiben:
   - Ausgangslage (welcher Screen, welches Profil/welche Daten)
   - Aktion (was genau tippen/eingeben/fotografieren)
   - Erwartetes Ergebnis (was muss erscheinen)
   Als abhakbare Liste (- [ ]).
4. Grenzfaelle bewusst aufnehmen, die im Code-Review als riskant auffielen
   (z.B. leere Eingabe, sehr grosse Werte, Sprachwechsel).
5. DOMAENEN-FOKUS: bei allem, was Naehrwert-/Kalorien-/Sicherheitsangaben zeigt, einen
   expliziten Pruefschritt "Zahl/Tag stimmt fachlich" einbauen, weil falsche Werte
   hier sicherheitsrelevant sind.
6. Schreib den Plan nach docs/test-plans/build-XX-test-plan.md (XX = aktuelle
   Build-Nummer, frag wenn unklar).

## Anti-Pattern
- Keine vagen Schritte ("teste das Feature"). Immer konkrete Aktion + erwartetes
  Ergebnis.
- Keine automatisierten Tests vorschlagen, dafuer ist test-critical-flows da.
- Nicht jeden Screen abdecken, nur die von der Aenderung betroffenen.
