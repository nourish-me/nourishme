# NurtureTrack

AI-powered nutrition tracker for breastfeeding mothers. Single-user MVP, built for Vanessa's own use first.

## Context

Vanessa is a stillende Mutter von Zwillingen (Carl & Leo, geboren Mitte Februar 2026, 36+0). Sie braucht eine App, die ihr hilft, ihre Ernährung beim Stillen im Blick zu behalten, primär Kalorien (Stillende brauchen mehr) und Food Safety (Quecksilber, Koffein, Alkohol, etc.).

Vorgängerversion ging verloren (kein Git-Backup). Dies ist Rebuild mit absichtlich abgespecktem Scope.

## Tech Stack

- Framework: Flutter 3.41.6 (stable channel)
- Sprache: Dart 3.11.4
- Bundle ID: com.vanessaheizmann.nurturetrack
- Target: iOS (iPhone 16e Simulator primär, eventuell echtes Gerät später)
- Lokale DB: Hive (kein Supabase im MVP, kein Backend, kein Auth)
- AI: Claude API für Food-Parsing, Model claude-haiku-4-5-20251001
- Design: Material Design 3 (Def
cd ~/Projects/nurturetrack && cat > CLAUDE.md << 'EOF'
# NurtureTrack

AI-powered nutrition tracker for breastfeeding mothers. Single-user MVP, built for Vanessa's own use first.

## Context

Vanessa is a stillende Mutter von Zwillingen (Carl & Leo, geboren Mitte Februar 2026, 36+0). Sie braucht eine App, die ihr hilft, ihre Ernährung beim Stillen im Blick zu behalten, primär Kalorien (Stillende brauchen mehr) und Food Safety (Quecksilber, Koffein, Alkohol, etc.).

Vorgängerversion ging verloren (kein Git-Backup). Dies ist Rebuild mit absichtlich abgespecktem Scope.

## Tech Stack

- Framework: Flutter 3.41.6 (stable channel)
- Sprache: Dart 3.11.4
- Bundle ID: com.vanessaheizmann.nurturetrack
- Target: iOS (iPhone 16e Simulator primär, eventuell echtes Gerät später)
- Lokale DB: Hive (kein Supabase im MVP, kein Backend, kein Auth)
- AI: Claude API für Food-Parsing, Model claude-haiku-4-5-20251001
- Design: Material Design 3 (Default von Flutter), keine custom UI-Lib

## MVP Scope (in dieser Reihenfolge)

1. Essen tracken via Freitext-Eingabe: User tippt z.B. "Müsli mit Joghurt und Beeren, ca. 1 Schüssel". Claude API parsed das in strukturierte Daten (Kalorien, Makros) und gibt Food-Safety-Warnings zurück, falls relevant.
2. Kalorien-Target basierend auf Stillen: Mifflin-St Jeor Formel + Aufschlag fürs Stillen (Zwillinge: ca. 500 kcal extra pro Tag, anpassbar). Tagesziel sichtbar mit aktuellem Stand.
3. Food Safety Hints: Claude API erkennt riskante Lebensmittel (hoher Quecksilbergehalt, Koffein, Alkohol, rohe Milchprodukte, bestimmte Kräuter) und zeigt Warnungen.
4. Tagebuch / Verlauf: Letzte 7-14 Tage durchscrollbar, pro Tag: Liste der Einträge + Kalorien-Summe vs. Target.

## Out of Scope (für später, nicht jetzt bauen)

- User-Accounts, Auth, Onboarding
- Supabase / Backend
- Deep Links / Password Reset
- Multi-User
- Mahlzeit-Editing (im MVP: löschen + neu hinzufügen reicht)
- Push Notifications, Reminders
- Social Features, Sharing
- Material Design 2 Polish (bleibt MD3 default)

## Architektur-Hinweise

- State Management: Riverpod oder Provider, Claude entscheidet. Kein BLoC (zu viel Boilerplate für MVP).
- API-Key: Anthropic-Key kommt in .env, niemals committen. .env muss in .gitignore.
- HTTP: Standard http package oder dio, Claude entscheidet.
- Routing: go_router oder einfaches Navigator-Stack, Claude entscheidet. Wenige Screens, also auch okay simpel.

## Workflow-Präferenzen

- Konsolidierte Multi-Step-Commands: Vanessa will nicht "mach Schritt 1, jetzt Schritt 2, jetzt Schritt 3". Stattdessen mehrere Schritte zusammen ausführen, dann am Ende zeigen was passiert ist. Erst nachfragen, wenn es wirklich Entscheidungen gibt.
- Kritisch antworten: Wenn ein Vorschlag von ihr fragwürdig ist, sag das. Sie schätzt ehrliche Einschätzungen statt blindem Ja-Sagen.
- Bei Designentscheidungen: Triff sie pragmatisch selbst, dokumentiere kurz im Code-Kommentar oder Commit-Message warum.
- Keine Dashes in Outputs verwenden. Komma, Doppelpunkt, oder neue Sätze stattdessen.

## Git Workflow

- Branch: main
- Remote: git@github.com:vanessaheizmann5-ctrl/nurturetrack.git
- Lokale Identität: vanessa.heizmann5@gmail.com (NICHT die Personio-Email)
- Wichtig: Regelmäßig committen und pushen. Code-Verlust ist schon einmal passiert.
- Kleine, fokussierte Commits mit klaren Messages.

## Setup-Status

- Done: Flutter-Projekt initialisiert (Stand: 14. Mai 2026)
- Done: Git-Repo mit privatem GitHub verbunden
- Done: Hive, flutter_riverpod, http, flutter_dotenv in pubspec.yaml (Stand: 15. Mai 2026)
- Done: Claude API Client (haiku-4-5) plus .env Setup
- Done: MVP komplett, alle 4 Features implementiert und auf iPhone 16e Simulator getestet (Stand: 15. Mai 2026)

## Sprache

Code und Code-Kommentare auf Englisch. Commit-Messages auf Englisch. UI-Strings auf Deutsch (Vanessa nutzt die App selbst auf Deutsch). Kommunikation mit Vanessa: Deutsch.

## Wichtige Notizen für Claude Code

- Mac-Setup: Personio-Arbeitslaptop, daher 1Password als SSH-Agent für andere Hosts. Privater SSH-Key liegt in ~/.ssh/id_ed25519_private und wird über ~/.ssh/config für github.com automatisch benutzt. Nicht anfassen.
- Mental load: Vanessa hat zwei Neugeborene. Sessions können unterbrochen werden, Fokus kann schwanken. Lieber Fortschritt in kleinen klaren Schritten dokumentieren als große ungefährte Aktionen.
- Verloren gegangene Vorversion: Hatte komplexen Auth-Flow, Supabase-Integration, Deep Links. Bewusst entschieden, diese im MVP nicht zu replizieren.
