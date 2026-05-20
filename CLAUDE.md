# NourishMe

AI-powered nutrition coach for pregnancy and breastfeeding. Single-user MVP, built for Vanessa's own use first, beta-tested by other moms in this phase.

Project was originally called NurtureTrack and renamed to NourishMe on 2026-05-17. Internal Flutter package name and bundle ID still say `nurturetrack` (deliberately not changed: bundle ID is registered with Apple, package name rename would touch 30+ platform files for no real gain).

## Context

Vanessa is a stillende Mutter von Zwillingen (Carl und Leo, geboren Mitte Februar 2026, 36+0). Sie braucht eine App, die ihr hilft, ihre Ernährung beim Stillen im Blick zu behalten, primär Kalorien (Stillende brauchen mehr) und Food Safety (Quecksilber, Koffein, Alkohol, etc.).

Vorgängerversion ging verloren (kein Git-Backup). Dies ist Rebuild mit absichtlich abgespecktem Scope.

## Tech Stack

- Framework: Flutter 3.41.6 (stable channel)
- Sprache: Dart 3.11.4
- Bundle ID: com.vanessaheizmann.nurturetrack (NICHT umbenennen, Apple-registriert)
- Target: iOS (iPhone 16e Simulator primär, deployed auf echtes iPhone 13)
- Lokale DB: Hive (kein Supabase im MVP, kein Backend, kein Auth)
- AI: Anthropic Claude API via Cloudflare Worker Proxy, Model claude-haiku-4-5-20251001
- API Proxy: https://nourishme-api.vanessa-heizmann5.workers.dev (APP_SECRET shared-secret auth)
- Design: Material Design 3 mit hand-tuned "Field Manual" Palette (siehe `lib/theme/nourishme_colors.dart`)
- Landing: statische HTML/CSS in `docs/`, GitHub Pages

## MVP Scope (in dieser Reihenfolge)

1. Essen tracken via Freitext-Eingabe: Claude parsed Freitext oder Foto in strukturierte Daten (Kalorien, Makros) plus Food-Safety-Warnings.
2. Kalorien-Target basierend auf Lebenssituation: Mifflin-St Jeor plus Aufschlag fürs Stillen/Schwangerschaft, anpassbar an Anzahl Kinder und tatsächliches Milchvolumen.
3. Food Safety Hints: Quecksilberfisch, Koffein-Schwellen, Alkohol-Wartezeiten, rohe Milchprodukte, riskante Kräuter, alles aus offiziellen Quellen (DGE, BfR, EFSA, LactMed, FDA/EPA).
4. Tagebuch / Verlauf: durchscrollbare Tage mit Einträgen plus Kalorien-Summe vs. Target.

## Out of Scope (für später, nicht jetzt bauen)

- User-Accounts, Auth, Onboarding-Server-Sync
- Supabase / Backend (Worker reicht für API-Proxy)
- Deep Links / Password Reset
- Multi-User
- Mahlzeit-Editing (im MVP: löschen plus neu hinzufügen reicht)
- Push Notifications, Reminders
- Social Features, Sharing
- Material Design 2 Polish

## Architektur-Hinweise

- State Management: Riverpod
- API-Key: Anthropic-Key niemals committen. Nur APP_SECRET wird vom App-Client an Worker geschickt. Worker hält den echten Anthropic-Key in Cloudflare Secrets.
- HTTP: Standard http package
- Routing: einfacher Navigator-Stack, wenige Screens

## Workflow-Präferenzen

- Konsolidierte Multi-Step-Commands: Vanessa will nicht "Schritt 1, jetzt Schritt 2, jetzt Schritt 3". Mehrere Schritte zusammen ausführen, am Ende zeigen was passiert ist. Nachfragen nur bei echten Entscheidungen.
- Kritisch antworten: Wenn ein Vorschlag fragwürdig ist, sag das. Ehrliche Einschätzungen statt blindem Ja-Sagen.
- Designentscheidungen pragmatisch selbst treffen, kurz im Commit-Message dokumentieren.
- Keine Dashes in Outputs (Komma, Doppelpunkt, oder neue Sätze stattdessen).

## Git Workflow

- Branch: main
- Remote: git@github.com:nourish-me/nourishme.git
- GitHub Pages: https://nourish-me.github.io/nourishme/
- Lokale Identität: vanessa.heizmann5@gmail.com (NICHT die Personio-Email)
- Wichtig: Regelmäßig committen und pushen. Code-Verlust ist schon einmal passiert.
- Kleine, fokussierte Commits mit klaren Messages.

## Sprache

Code und Code-Kommentare auf Englisch. Commit-Messages auf Englisch. UI-Strings auf Deutsch. Kommunikation mit Vanessa: Deutsch.

## Wichtige Notizen für Claude Code

- Mac-Setup: Personio-Arbeitslaptop, daher 1Password als SSH-Agent für andere Hosts. Privater SSH-Key liegt in ~/.ssh/id_ed25519_private und wird über ~/.ssh/config für github.com automatisch benutzt. Nicht anfassen.
- Mental load: Vanessa hat zwei Neugeborene. Sessions können unterbrochen werden, Fokus kann schwanken. Lieber Fortschritt in kleinen klaren Schritten dokumentieren als große ungefährte Aktionen.
- Verloren gegangene Vorversion: Hatte komplexen Auth-Flow, Supabase-Integration, Deep Links. Bewusst entschieden, diese im MVP nicht zu replizieren.
- Lokaler Ordner heißt noch `~/Projects/nurturetrack/` (nicht umbenannt, weil Memory-Pfade und Apple-Bundle-Referenzen darauf basieren).
