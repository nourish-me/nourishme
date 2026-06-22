# PostHog-Insights bauen (NourishMe) — Arbeitsauftrag

Queued als dritter Schritt (nach Lotte-Sortier-Bug + Parser-Phase-3). VORAUSSETZUNG,
die Vanessa einmalig erledigen muss, bevor Claude Code loslegen kann:

1. PostHog-MCP einrichten: im Projektordner `npx @posthog/wizard mcp add` ausführen
   und dem Assistenten folgen.
2. PostHog Personal API Key: PostHog → Settings → Personal API keys → "Create personal
   API key", Scopes mind. Insights + Dashboards (Read/Write) und Query (Read). Key dem
   MCP geben, wenn er danach fragt.
3. Dann Claude Code im Projektordner starten, dieser Auftrag kann ausgeführt werden.

Ohne den eingerichteten PostHog-MCP kann Claude Code das NICHT bauen (kein Zugriff).

---

## Projekt-Kontext
- PostHog-Instanz: EU (eu.posthog.com)
- Projekt-ID: 186469
- Ziel-Dashboard: "NourishMe Beta", Dashboard-ID 726451 (alle neuen Insights dort anhängen)
- App: NourishMe, iOS-Ernährungs-App. Kernaktion = `meal_logged`.

## Schon vorhanden – NICHT doppeln
- "Beta: Aktivierungs-Funnel (Onboarding bis Coach, 7T)"
- "Beta: Weekly Active Users (meal_logged)"
- "Beta: Tester-Retention (meal_logged)"

## Relevante Events
`onboarding_started`, `onboarding_completed`, `meal_logged`, `coach_reply`,
`coach_chat_sent`, `coach_chip_tapped`, `coach_session_fired`, `weight_logged`,
`barcode_scanned`, `safety_warning_shown`, `tips_shown`, `history_chip_tapped`,
`screen_view`.

## Globale Regeln für ALLE neuen Insights
- Standard-Zeitraum: letzte 90 Tage.
- Ausschließen (Rauschen, kommen vom Web): `$pageview`, `$pageleave`, `$autocapture`,
  `$web_vitals`, `setup_test_event`. Diese nie als Event verwenden.
- Wenn ein Filter "internal & test users" im Projekt existiert, respektieren. Falls
  nicht: prüfe, ob eine Property zum Ausschließen der eigenen Nutzung existiert
  (z.B. `is_internal`), und filtere sie raus, falls vorhanden.
- Namenskonvention: Präfix "Beta:".
- Aggregation grundsätzlich über unique users (person-level), außer anders angegeben.

## Zu bauende Insights

### 1. Beta: North Star – Wöchentlich aktive Loggerinnen (3+ Tage/Woche)
Trends/HogQL. Eindeutige Nutzerinnen, die in einer Woche an ≥ 3 verschiedenen Tagen
`meal_logged` ausgelöst haben.
```sql
SELECT week, count() AS weekly_active_loggers
FROM (
  SELECT person_id,
         toStartOfWeek(timestamp) AS week,
         count(DISTINCT toStartOfDay(timestamp)) AS days
  FROM events
  WHERE event = 'meal_logged'
    AND timestamp >= now() - INTERVAL 90 DAY
  GROUP BY person_id, week
  HAVING days >= 3
)
GROUP BY week
ORDER BY week
```

### 2. Beta: Retention nach Woche-1-Log-Anzahl ("magic number")
Bleiben Nutzerinnen, die in Woche 1 mehr loggen, besser? Buckets 1-2 / 3-5 / 6+;
"retained" = mind. 1 `meal_logged` in Tag 8–21 nach erstem Log. Spaltennamen validieren.
```sql
WITH first_seen AS (
  SELECT person_id, min(timestamp) AS first_ts
  FROM events WHERE event = 'meal_logged' GROUP BY person_id
),
wk1 AS (
  SELECT e.person_id, count(*) AS logs_week1
  FROM events e JOIN first_seen f ON e.person_id = f.person_id
  WHERE e.event = 'meal_logged'
    AND e.timestamp BETWEEN f.first_ts AND f.first_ts + INTERVAL 7 DAY
  GROUP BY e.person_id
),
ret AS (
  SELECT DISTINCT e.person_id
  FROM events e JOIN first_seen f ON e.person_id = f.person_id
  WHERE e.event = 'meal_logged'
    AND e.timestamp BETWEEN f.first_ts + INTERVAL 8 DAY AND f.first_ts + INTERVAL 21 DAY
)
SELECT
  multiIf(logs_week1 <= 2, '1-2', logs_week1 <= 5, '3-5', '6+') AS bucket,
  count(*) AS users,
  countIf(wk1.person_id IN (SELECT person_id FROM ret)) AS retained_users,
  round(100.0 * countIf(wk1.person_id IN (SELECT person_id FROM ret)) / count(*), 1) AS retention_pct
FROM wk1
GROUP BY bucket
ORDER BY bucket
```

### 3. Beta: Coach-Nutzung über Zeit
Trends, wöchentlich, eine Serie je Event: `coach_chat_sent`, `coach_reply`,
`coach_chip_tapped`. Math: unique users.

### 4. Beta: Coach-Nutzungsquote der Aktiven
Trends mit Formel. Zähler = unique users mit (`coach_chat_sent` ODER `coach_chip_tapped`),
Nenner = unique users mit `meal_logged`. Als Prozent. Wöchentlich.

### 5. Beta: Logs pro aktiver Nutzerin
Trends. Event `meal_logged`, Math = "average per user" (total ÷ unique users). Wöchentlich.

### 6. Beta: Safety-Warnungen (Monitoring)
Trends. Event `safety_warning_shown`, Math = total count UND unique users (zwei Serien).
Wöchentlich.

### 7. Beta: Feature-Nutzung (Monitoring)
Trends. Events `barcode_scanned` und `weight_logged`, unique users, wöchentlich.

## Vorgehen
1. Erst per MCP das Projekt prüfen: existierende Insights/Dashboards und das
   Event-/Property-Schema. Event-Namen bestätigen, bevor gebaut wird.
2. Insights 1–7 anlegen, jeweils mit "Beta:"-Präfix, an Dashboard 726451 hängen.
3. Für die HogQL-Insights (1, 2): Query ausführen, prüfen dass sie ohne Fehler Daten
   zurückgibt. Bei Fehler Spaltennamen/Funktionen anpassen (HogQL = ClickHouse-Dialekt)
   und erneut testen.
4. Am Ende: Liste der erstellten Insights (mit Links), und melden, falls eine wegen zu
   wenig Daten leer ist (kleine Beta, ok).

Nichts doppelt bauen, die drei bestehenden Insights nicht ändern.
