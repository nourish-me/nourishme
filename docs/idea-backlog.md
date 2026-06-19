# Idea Backlog

Out-of-scope feature ideas that surfaced during beta or other research. Intentionally not built into the current product but kept here for future revisit.

See `../CLAUDE.md` → "Produkt-Scope (Phase-Test)" for the in-scope test that defines what's in and what's out.

Format per entry: brief description, source (who/when), the scope verdict and reasoning, and conditions under which we might revisit.

---

## Cycle / Period Awareness

**Source:** Corina (T3), beta feedback 2026-06-17 → 2026-06-18, WhatsApp voice + follow-up.

**Request:**

> „You retain more water in certain phases"
>
> „horrible PMS with crazy cravings"

She wants the app to know her cycle so it can adapt recommendations (cravings, water retention, food preferences). Could be manual entry or imported from Apple Health.

**Scope verdict:** Out. PMS-driven cravings technically pass the in-scope test (they would change food recommendations), but cycle is its own lifecycle phase with its own data type. During pregnancy and most of lactation the cycle is suppressed or absent, so the benefit is concentrated in the post-wean Maintenance phase where we have minimal product surface today.

**Revisit when:** the Maintenance phase becomes a primary product surface, OR there are 3+ tester voices asking for cycle context. Until then, point testers to specialised apps (Clue, Apple Health) if they ask.
