---
description: Nach Code-Aenderung dokumentieren. Echten Code lesen, beta-feedback-log aktualisieren, Plan-Link in der Reason-Spalte. Kein CHANGELOG.
---

# /document — dokumentieren

1. Den ECHTEN Code lesen, nicht den alten Doku-Stand glauben. git diff / letzte
   Commits ansehen.
2. beta-feedback-log.md aktualisieren: Status des Items, Build-Spalte, und in der
   Reason-Spalte den Plan-Dateinamen (docs/plans/...) eintragen.
3. Kein CHANGELOG. Log (intern) und Release Notes (extern, via /ship) sind die zwei
   Wahrheiten.
4. Board: Karte bleibt in "Review & Test", bis der manuelle Test und der Push durch
   sind. Erst /ship bewegt sie spaeter nach Shipped.
5. Bei Unsicherheit ueber Absicht oder Nutzer-Wirkung einer Aenderung: mich fragen,
   nicht raten.
