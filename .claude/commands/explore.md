---
description: Beta-Item verstehen, NUR das Problem. Code-Scan ueber alle betroffenen Flows, investigative Rueckfragen an die Testerin zur Freigabe, kein Loesungsvorschlag.
---

# /explore — nur das Problem verstehen

Du arbeitest an EINEM Item vom Board (board.md). Ich nenne dir die Karte. Aufgabe ist
NICHT, eine Loesung zu finden, sondern das Problem vollstaendig zu verstehen.

## Ablauf

1. Karte lesen (Titel, Problembeschreibung, Tester-Stimmen-Links). Verfolge die Links
   ins beta-feedback-log.md und lies die Original-Stimmen. In zwei Saetzen
   zusammenfassen, was die Testerin erlebt.

2. PROBLEM-RECHERCHE im eigenen Code. Scanne, an WIE VIELEN Stellen das Problem sitzt,
   nicht nur an der gemeldeten. Beispiel: hakt ein Picker, finde alle Flows mit diesem
   Picker. Beispiel: ein Scroll-/Ordering-Bug, finde alle Stellen mit dem Muster.
   Ziel ist das volle Ausmass des Problems, bevor irgendwer an eine Loesung denkt.
   Optional eine kurze Websuche NUR zur Frage "ist das ein bekanntes, verbreitetes
   Problem", nicht "wie loest man es". Loesungsrecherche gehoert in /create-plan.

   Bei verhaltensweiten Items (Scroll, Ordering, Navigation, Timing, Fokus) reicht
   es NICHT, die Ausloeser im Code zu finden. Liste JEDEN User-Flow auf, in dem das
   Verhalten auftritt, und notiere pro Flow das IST (was passiert heute, welcher
   Ausloeser) UND das ERWARTETE Verhalten (was sollte passieren). Diese
   Flow-mal-Erwartung-Matrix ist die holistische Problem-Definition, nicht die
   Loesung (das WIE gehoert in /create-plan). Sie deckt fast immer mehr betroffene
   Flows auf als die eine gemeldete Stelle.

3. Im Code verifizieren, ob das Problem heute noch existiert.
   - Schon gefixt? Sagen, Karte auf Shipped vorschlagen, stoppen.
   - Existiert noch? Beschreiben, wo es sitzt, ohne zu reparieren.

4. Pattern-Regel pruefen. Einzelstimme? Explizit sagen: laut Vanessas Regel wird bei
   Einzelstimmen gesammelt, nicht gebaut, ausser No-Brainer (Sicherheit, klinische
   Korrektheit, klarer Bug fuer alle). Audit-Items (#code/#dsgvo/#safety/#test) haben
   keine Testerin und keine Pattern-Regel, die ueberspringen diesen Punkt.

5. Investigative Rueckfragen an die Testerin NUR WENN ABSOLUT NOETIG. Default: keine
   Frage. Wenn der Code oder bestehende Stimmen das Problem schon klar erklaeren,
   stell keine, Testerinnen werden NICHT mit Nachrichten ueberflutet. Ist eine Frage
   wirklich noetig, formuliere sie und leg sie mir zur FREIGABE vor, nicht selbst
   verschicken. Strenge Regeln:
   - REIN INVESTIGATIV: nach Erleben, Moment, Was-tust-du-dann fragen.
     Gut: "In welchem Moment merkst du, dass dir X fehlt, und was machst du dann?"
     Verboten: "Waere dir ein Wochenueberblick lieber?" (legt Loesung in den Mund).
   - KEINE Loesung, KEIN Feature-Name, KEINE Ja/Nein-Frage zu einer Funktion.
   - KEIN Versprechen ueber Zukuenftiges. Kein Datum, kein "kommt bald", kein "wir
     bauen das". In dieser Stage ist nichts live, also wird nichts in Aussicht
     gestellt.
   - Hat die Testerin selbst eine Loesung vorgeschlagen: diskutiere sie nicht, frag
     nach dem Beduerfnis dahinter.
   - In der Sprache der Testerin (meist Deutsch).
   - Selbst-Check pro Frage VOR der Ausgabe: enthaelt sie eine Loesung oder ein
     Versprechen? Wenn ja, umformulieren.

6. Board aktualisieren: Karte nach "Explore" schieben (bei Tester-Items). Keine
   Loesungsvorschlaege in dieser Stage. Stopp nach den Rueckfragen.

Naechster Schritt nach Klaerung: /create-plan.
