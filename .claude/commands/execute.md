---
description: Plan phasenweise bauen, Plan-Datei als Task-Liste fortschreiben, nach jeder Phase berichten. Erst nach Plan-Freigabe.
---

# /execute — bauen, phasenweise

Voraussetzung: ein freigegebener Plan unter docs/plans/ existiert. Ohne mein OK zum
Plan baust du nicht.

## Regeln

1. Die Plan-Datei IST die Task-Liste, nicht ein internes Todo. Status und Fortschritt
   werden in der Plan-Datei fortgeschrieben, nirgends sonst.
2. Phase fuer Phase bauen (= die Schritte aus dem Plan). Nicht alles am Stueck.
3. Nach JEDER Phase kurz berichten, welche Dateien sich geaendert haben und was. Dann
   die naechste Phase, nicht vorgreifen.
4. 🟥 -> 🟨 -> 🟩 und den Fortschritt in Prozent oben in der Plan-Datei live
   aktualisieren, waehrend du arbeitest.
5. Strikt an bestehende Patterns, Konventionen und den vorhandenen Code-Stil halten.
6. Board: Karte nach "Bau" schieben, solange du arbeitest.
7. CRITICAL-markierte Schritte (Naehrwert/Kalorien/Sicherheit) mit dem im Plan
   vorgesehenen Verifikations-Schritt absichern, nicht ueberspringen.

Naechster Schritt nach dem Bauen: /review.
