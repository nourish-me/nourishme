# Datenschutzerklärung — NourishMe

Stand: 19. Mai 2026

## 1. Verantwortliche Stelle

Vanessa Heizmann
[Anschrift einfügen]
E-Mail: vanessa.heizmann5@gmail.com

## 2. Was die App tut

NourishMe hilft Müttern in Schwangerschaft und Stillzeit, ihre Ernährung
zu protokollieren und erhält wissenschaftlich fundiertes Coaching-Feedback
zu jeder Mahlzeit. Die App ist als persönliches Werkzeug konzipiert, nicht
als medizinisches Produkt.

## 3. Welche Daten verarbeitet werden

### 3.1 Lokal auf deinem Gerät gespeichert (Hive-Datenbank)

- **Profilangaben:** Alter, Größe, Gewicht, Aktivitätslevel,
  Schwangerschafts-/Stillzeit-Phase, Trimester, Anzahl der versorgten
  Kinder, geschätztes Milchvolumen.
- **Mahlzeit-Einträge:** Beschreibung, Portionsgröße, Kalorien, Makros
  (Protein, Kohlenhydrate, Fett), Zeitstempel, optionale Food-Safety-Hinweise.
- **Foto-Einträge:** Wenn du ein Foto deiner Mahlzeit aufnimmst, wird es
  einmalig zur Analyse an die Coaching-API gesendet (siehe 3.2). Das Foto
  selbst wird **nicht in der App gespeichert**, nur die strukturierten
  Ergebnisse (Kalorien, Makros, Beschreibung).
- **Coach-Verlauf:** Mahlzeit-Antworten und freie Fragen/Antworten zwischen
  dir und der Coaching-API.
- **Favoriten:** häufig genutzte Mahlzeiten als Vorlage.
- **Einstellungen:** Theme-Auswahl, ggf. eigener Makro-Split.

### 3.2 Übertragung an Drittanbieter

Wenn du eine Mahlzeit loggst oder dem Coach eine Frage stellst, wird der
folgende Inhalt an unseren API-Proxy gesendet, der ihn dann an die
Anthropic Claude API weiterleitet:

- Der Text deiner Eingabe (Beschreibung der Mahlzeit oder Frage)
- Optional: das Foto deiner Mahlzeit (bei Foto-Eingabe)
- Dein Profil (Alter, Gewicht, Größe, Aktivität, Phase, Kinder, Milchvolumen)
- Tageskontext (heutige kcal- und Makro-Summen)

Die Anthropic API nutzt diese Daten ausschließlich, um eine
Coaching-Antwort zu erzeugen. Anthropic speichert API-Anfragen für maximal
30 Tage zu Missbrauchs- und Sicherheitszwecken. Details:
https://www.anthropic.com/legal/privacy

Der Proxy (Cloudflare Worker) verarbeitet deine Anfragen
ausschließlich zur Weiterleitung, ohne Inhalte zu speichern. Cloudflare
speichert lediglich Verbindungs-Metadaten (IP, Zeitstempel) zur
Missbrauchsabwehr.

### 3.3 Keine Drittanbieter-Tracker

- Keine Analytics-SDKs (kein Firebase, Google Analytics, Sentry,
  Mixpanel etc.).
- Keine Werbe-IDs.
- Keine Crash-Reporting-Dienste.

### 3.4 Keine Benutzerkonten

NourishMe hat kein Login. Du brauchst keine E-Mail, kein Passwort. Alle
Daten bleiben anonym auf deinem Gerät.

## 4. Rechtsgrundlage

Die Verarbeitung erfolgt auf Basis deiner Einwilligung (Art. 6 Abs. 1
lit. a DSGVO), die du durch die Nutzung der App erteilst, sowie zur
Erfüllung des Vertrages über die Nutzung der App (Art. 6 Abs. 1 lit. b
DSGVO).

Gesundheitsbezogene Daten (Gewicht, Schwangerschaftsstatus, Stillzeit)
werden zu deinen eigenen Wellness-Zwecken verarbeitet. Eine Diagnose oder
medizinische Behandlung findet **nicht** statt. Konsultiere bei
medizinischen Fragen deinen Arzt oder deine Hebamme.

## 5. Speicherdauer

- **Lokale Daten:** so lange du die App auf deinem Gerät installiert hast.
  Bei Deinstallation oder „App zurücksetzen" in den Einstellungen werden
  alle Daten unwiderruflich gelöscht.
- **Anthropic API:** maximal 30 Tage Speicherung gemäß Anthropics
  Privacy Policy.
- **Cloudflare:** Verbindungs-Metadaten gemäß Cloudflare-Datenrichtlinien
  (typischerweise 24 h).

## 6. Deine Rechte

Du hast jederzeit das Recht auf:

- **Auskunft** über die in der App gespeicherten Daten (du siehst sie
  direkt in der App selbst).
- **Berichtigung** durch Bearbeiten deines Profils und einzelner Einträge.
- **Löschung** durch die Funktion „App zurücksetzen" in den Einstellungen
  oder durch Deinstallation der App.
- **Datenübertragbarkeit:** Die Daten liegen ausschließlich lokal. Eine
  Export-Funktion ist aktuell nicht implementiert, kann auf Anfrage per
  E-Mail bereitgestellt werden.
- **Widerspruch** gegen die Verarbeitung und **Beschwerde** bei einer
  Aufsichtsbehörde (z.B. dem Bayerischen Landesamt für Datenschutzaufsicht).

Anfragen bitte an: vanessa.heizmann5@gmail.com

## 7. Datensicherheit

- Alle Verbindungen zur API erfolgen über HTTPS/TLS.
- Lokale Daten werden im standardmäßigen App-Sandbox des Betriebssystems
  gespeichert und sind für andere Apps nicht zugänglich.

## 8. Änderungen dieser Datenschutzerklärung

Wir können diese Datenschutzerklärung anpassen, wenn sich die App
weiterentwickelt. Die aktuelle Version ist immer in der App und unter
[URL deiner Hosting-Stelle] verfügbar. Wesentliche Änderungen werden bei
einem App-Update angezeigt.

## 9. Kontakt

Bei Fragen zum Datenschutz oder zur Ausübung deiner Rechte:

Vanessa Heizmann
vanessa.heizmann5@gmail.com
