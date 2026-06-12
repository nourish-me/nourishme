// NourishMe — Onboarding 5/5 · Confirmation
// Calculated daily target. Editorial pull-quote style. Two CTAs.

function NutrientRow({ name, value, unit, hl }) {
  return (
    <div style={{
      display: 'flex', justifyContent: 'space-between', alignItems: 'baseline',
      padding: '11px 0',
      borderBottom: `1px solid ${NMOB.rule}`,
    }}>
      <span style={{ fontFamily: NMOB.ui, fontSize: 14.5, fontWeight: 500, color: NMOB.ink }}>{name}</span>
      <span style={{
        fontFamily: NMOB.mono, fontSize: 12.5, color: hl ? NMOB.pine : NMOB.inkSoft,
        fontWeight: hl ? 700 : 500, letterSpacing: 0.02,
      }}>{value}<span style={{ color: NMOB.inkMute, fontWeight: 400 }}> {unit}</span></span>
    </div>
  );
}

function ScreenConfirm() {
  return (
    <div data-screen-label="OB5 Confirmation" style={{
      minHeight: '100%', background: NMOB.paper, color: NMOB.ink,
      fontFamily: NMOB.ui, display: 'flex', flexDirection: 'column',
    }}>
      <div style={{ padding: '6px 22px 8px' }}>
        <OBEyebrow>Schritt 4 von 4 · Berechnung</OBEyebrow>
      </div>

      {/* Editorial result card */}
      <div style={{ padding: '0 16px' }}>
        <div style={{
          padding: '24px 22px 22px', background: NMOB.paperHi,
          border: `1px solid ${NMOB.rule}`, borderRadius: 18,
          position: 'relative', overflow: 'hidden',
        }}>
          <div style={{
            fontFamily: NMOB.serif, fontStyle: 'italic', fontWeight: 700,
            fontSize: 30, lineHeight: 1.08, color: NMOB.ink, letterSpacing: -0.02,
            textWrap: 'pretty', marginBottom: 18,
          }}>
            Dein Tagesziel
          </div>

          {/* Big kcal */}
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, marginBottom: 4 }}>
            <span style={{
              fontFamily: NMOB.serif, fontStyle: 'italic', fontWeight: 700,
              fontSize: 64, lineHeight: 1, color: NMOB.pine, letterSpacing: -0.03,
            }}>2.880</span>
            <span style={{ fontFamily: NMOB.mono, fontSize: 14, color: NMOB.inkSoft }}>kcal</span>
          </div>
          {/* Pull quote */}
          <p style={{
            margin: '8px 0 0', fontFamily: NMOB.serif, fontSize: 17,
            lineHeight: 1.45, color: NMOB.inkSoft, fontStyle: 'italic',
            textWrap: 'pretty',
          }}>
            Du versorgst in dieser Phase mehr als dich allein —{' '}
            <span style={{ color: NMOB.ink, fontWeight: 600 }}>
              + 540&nbsp;kcal für Stillen, + 250&nbsp;kcal fürs zweite Trimester.
            </span>
          </p>

          {/* Hairline */}
          <div style={{ height: 1, background: NMOB.rule, margin: '20px 0 14px' }}/>

          {/* Critical nutrients breakdown */}
          <div style={{
            fontFamily: NMOB.mono, fontSize: 10.5, letterSpacing: 0.08,
            textTransform: 'uppercase', color: NMOB.inkMute, fontWeight: 500,
            marginBottom: 6,
          }}>Kritische Nährstoffe · Tagesbedarf</div>

          <NutrientRow name="Folsäure"   value="600" unit="µg" hl/>
          <NutrientRow name="Eisen"      value="20"  unit="mg" hl/>
          <NutrientRow name="DHA"        value="200" unit="mg" hl/>
          <NutrientRow name="Jod"        value="260" unit="µg"/>
          <NutrientRow name="Calcium"    value="1.000" unit="mg"/>
          <NutrientRow name="Eiweiß"     value="92"  unit="g"/>
        </div>
      </div>

      {/* Footnote */}
      <div style={{ padding: '14px 28px 0', textAlign: 'center' }}>
        <OBEyebrow>
          Referenzwerte DGE 2024 · jederzeit in Einstellungen anpassbar
        </OBEyebrow>
      </div>

      <div style={{ flex: 1 }}/>

      <div style={{ padding: '16px 22px 22px' }}>
        <OBPrimary>Tagebuch öffnen</OBPrimary>
        <OBSecondary>Werte später anpassen</OBSecondary>
      </div>
    </div>
  );
}

window.ScreenConfirm = ScreenConfirm;
