# Privacy Policy — NourishMe

Effective: 19 May 2026

## 1. Data Controller

Vanessa Heizmann
[Address]
Email: vanessa.heizmann5@gmail.com

## 2. What the app does

NourishMe helps mothers during pregnancy and breastfeeding track their
nutrition and receive evidence-based coaching feedback on each meal. The
app is a personal wellness tool, not a medical device.

## 3. What data is processed

### 3.1 Stored locally on your device (Hive database)

- **Profile information:** Age, height, weight, activity level,
  pregnancy / breastfeeding status, trimester, number of children being
  nursed, estimated daily milk volume.
- **Meal entries:** Description, portion, calories, macronutrients
  (protein, carbs, fat), timestamps, optional food-safety flags.
- **Photo entries:** If you take a photo of your meal, the photo is sent
  to the coaching API once for analysis (see 3.2). The photo itself is
  **not retained in the app**, only the structured results.
- **Coach history:** Per-meal coach responses and free Q&A turns between
  you and the coaching API.
- **Favorites:** frequently used meals saved as shortcuts.
- **Settings:** theme choice, optional custom macro split.

### 3.2 Transmission to third parties

When you log a meal or ask the coach a question, the following is sent to
our API proxy, which forwards it to the Anthropic Claude API:

- The text of your input (meal description or question)
- Optional: the photo of your meal (for photo input)
- Your profile (age, weight, height, activity, phase, children, milk volume)
- Today's context (running kcal and macro totals)

Anthropic uses these data only to generate a coaching response. Anthropic
stores API requests for up to 30 days for abuse and safety review:
https://www.anthropic.com/legal/privacy

The proxy (Cloudflare Worker) processes requests for forwarding only,
without storing payloads. Cloudflare retains connection metadata (IP,
timestamp) for abuse prevention.

### 3.3 No third-party trackers

- No analytics SDKs (no Firebase, Google Analytics, Sentry, Mixpanel etc.)
- No advertising IDs.
- No crash-reporting services.

### 3.4 No user accounts

NourishMe has no login. No email, no password. All data is anonymous and
stays on your device.

## 4. Legal basis (GDPR)

Processing is based on your consent (Art. 6(1)(a) GDPR), given by your
use of the app, and on contract performance (Art. 6(1)(b) GDPR).

Health-related data (weight, pregnancy, lactation status) is processed
for your personal wellness purposes. NourishMe does **not** provide
medical diagnosis or treatment. For medical questions, consult your
physician or midwife.

## 5. Data retention

- **Local data:** as long as the app is installed on your device.
  Uninstalling or using "Reset App" in Settings permanently deletes all
  local data.
- **Anthropic API:** up to 30 days per Anthropic's privacy policy.
- **Cloudflare:** connection metadata per Cloudflare's data policies
  (typically 24 h).

## 6. Your rights

You have the right to:

- **Access** the data stored in the app (visible directly in the UI).
- **Rectification** by editing your profile and individual entries.
- **Erasure** via "Reset App" in Settings or by uninstalling the app.
- **Portability:** data is local-only. An export function is not
  currently implemented; available on request via email.
- **Object** to processing and **lodge a complaint** with a supervisory
  authority (e.g. the Bavarian Data Protection Authority).

Requests: vanessa.heizmann5@gmail.com

## 7. Data security

- All API connections use HTTPS / TLS.
- Local data is stored in the OS-standard app sandbox, isolated from
  other apps.

## 8. Changes to this policy

We may update this policy as the app evolves. The current version is
always available in the app and at [your hosting URL]. Material changes
will be surfaced on app update.

## 9. Contact

For privacy questions or to exercise your rights:

Vanessa Heizmann
vanessa.heizmann5@gmail.com
