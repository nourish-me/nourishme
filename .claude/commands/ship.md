---
description: Beim TestFlight-Build. Ruft pre-ship-checklist, sammelt fertige Items seit letztem Build, ruft write-release-notes. Upload mache ich selbst.
---

# /ship — Build fertig machen

Laeuft pro BUILD, nicht pro Item. Ein Build buendelt mehrere fertige Items.

1. Ruf den pre-ship-checklist-Agent auf (flutter analyze + test, Build-Nummer, keine
   WIP-TODOs).
2. Sammle, welche Items seit dem letzten Build auf fixed / fuer diesen Build stehen.
3. Ruf den write-release-notes-Skill auf und entwirf daraus die TestFlight-Notes
   (EN+DE, nutzernah). NUR ueber das sprechen, was tatsaechlich in diesem Build live
   geht. Keine geplanten/in-Arbeit-Items erwaehnen, kein Versprechen ueber Kuenftiges.
   Interne Tester-Kuerzel/Namen und Severity gehoeren NICHT in die oeffentlichen Notes.
4. Gib mir den Notes-Text aus. Den Upload nach TestFlight mache ICH von Hand.
5. Board: die in diesem Build gelieferten Karten nach "Shipped" schieben.
