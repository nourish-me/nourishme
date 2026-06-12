// NourishMe — Onboarding 1/5 · Welcome
// Bowl logo · tagline · primary CTA.
// Full-bleed paper. The Bowl-Mark gets ~36% of the screen, centered upper half.

function ScreenWelcome() {
  return (
    <div data-screen-label="OB1 Welcome" style={{
      minHeight: '100%', background: NMOB.paper, color: NMOB.ink,
      fontFamily: NMOB.ui, display: 'flex', flexDirection: 'column',
    }}>
      {/* Top: brand mark + wordmark */}
      <div style={{
        flex: '1 1 auto', display: 'flex', flexDirection: 'column',
        alignItems: 'center', justifyContent: 'center', padding: '0 28px',
      }}>
        {/* Bowl-Mark: production SVG values, scaled. */}
        <svg width="148" height="148" viewBox="0 0 1024 1024" style={{ marginBottom: 28 }}>
          <circle cx="512" cy="430" r="150" fill={NMOB.amber}/>
          <path d="M 220 500 A 292 292 0 0 0 804 500 L 220 500 Z" fill={NMOB.pine}/>
        </svg>

        <div style={{
          fontFamily: NMOB.serif, fontStyle: 'italic', fontWeight: 700,
          fontSize: 40, lineHeight: 1, color: NMOB.ink, letterSpacing: -0.02,
          display: 'flex', alignItems: 'baseline', gap: 2,
        }}>
          NourishMe<span style={{ color: NMOB.amber }}>.</span>
        </div>

        <p style={{
          margin: '14px 0 0', maxWidth: 280, textAlign: 'center',
          fontFamily: NMOB.serif, fontStyle: 'italic', fontSize: 21,
          lineHeight: 1.3, color: NMOB.inkSoft, fontWeight: 400,
          textWrap: 'pretty',
        }}>Ernährung, die mitdenkt.</p>
      </div>

      {/* Bottom: copy block + CTA + footnote */}
      <div style={{ padding: '0 22px 28px' }}>
        <p style={{
          margin: '0 0 22px', fontFamily: NMOB.ui, fontSize: 14.5,
          lineHeight: 1.55, color: NMOB.inkSoft, textAlign: 'center',
          maxWidth: 320, marginInline: 'auto',
        }}>
          Ein Live-Coach für Schwangerschaft und Stillzeit. Du tippst, was du
          isst — wir rechnen mit.
        </p>
        <OBPrimary>Los geht's</OBPrimary>
        <div style={{ marginTop: 14, textAlign: 'center' }}>
          <OBEyebrow>Single user · läuft lokal auf deinem Gerät</OBEyebrow>
        </div>
      </div>
    </div>
  );
}

window.ScreenWelcome = ScreenWelcome;
