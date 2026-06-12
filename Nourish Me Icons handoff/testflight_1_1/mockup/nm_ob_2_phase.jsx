// NourishMe — Onboarding 2/5 · Lebensphase
// Three phase tiles, multi-select (Schwanger + Stillend possible).
// Uses IcPregnancy / IcNursing / IcPumping from nm_icons.jsx.

function PhaseCard({ Icon, title, sub, selected }) {
  return (
    <div style={{
      padding: '18px 18px 16px',
      background: selected ? NMOB.pineSoft : NMOB.paperHi,
      border: `1.5px solid ${selected ? NMOB.pine : NMOB.rule}`,
      borderRadius: 16,
      display: 'flex', alignItems: 'center', gap: 16,
      position: 'relative',
    }}>
      <div style={{
        width: 48, height: 48, borderRadius: 12,
        background: selected ? NMOB.paperHi : NMOB.surfLow,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        flexShrink: 0,
      }}>
        <Icon size={28}/>
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{
          fontFamily: NMOB.ui, fontSize: 17, fontWeight: 600,
          color: NMOB.ink, lineHeight: 1.15,
        }}>{title}</div>
        <div style={{
          fontFamily: NMOB.ui, fontSize: 13, color: NMOB.inkSoft,
          marginTop: 3, lineHeight: 1.35,
        }}>{sub}</div>
      </div>
      {/* checkbox */}
      <div style={{
        width: 24, height: 24, borderRadius: 6, flexShrink: 0,
        border: `1.5px solid ${selected ? NMOB.pine : NMOB.rule}`,
        background: selected ? NMOB.pine : 'transparent',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        {selected && (
          <svg width="13" height="10" viewBox="0 0 13 10">
            <path d="M1 5 L4.5 8.5 L12 1" fill="none" stroke="#fff" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        )}
      </div>
    </div>
  );
}

function ScreenPhase() {
  return (
    <div data-screen-label="OB2 Lebensphase" style={{
      minHeight: '100%', background: NMOB.paper, color: NMOB.ink,
      fontFamily: NMOB.ui, display: 'flex', flexDirection: 'column',
    }}>
      {/* Header */}
      <div style={{ padding: '6px 22px 18px' }}>
        <OBEyebrow>Schritt 1 von 4</OBEyebrow>
        <OBHeadline size={34}>In welcher Phase bist du gerade?</OBHeadline>
        <p style={{
          margin: 0, fontSize: 15, lineHeight: 1.5, color: NMOB.inkSoft,
          fontFamily: NMOB.ui, maxWidth: 320,
        }}>
          Mehrfachauswahl ist okay — z.&nbsp;B. <i style={{ color: NMOB.ink }}>schwanger und gleichzeitig noch stillend</i>.
        </p>
      </div>

      {/* Cards */}
      <div style={{ padding: '0 16px', display: 'flex', flexDirection: 'column', gap: 12 }}>
        <PhaseCard Icon={IcPregnancy} title="Schwanger"
          sub="Trimester wird im nächsten Schritt erfasst." selected={true}/>
        <PhaseCard Icon={IcNursing} title="Stillend"
          sub="Direkt anlegen, ggf. mit Zufütterung." selected={true}/>
        <PhaseCard Icon={IcPumping} title="Pumpend"
          sub="Mit echtem Milchvolumen statt Schätzung." selected={false}/>
      </div>

      {/* Spacer */}
      <div style={{ flex: 1 }}/>

      {/* Footer: dots + CTA */}
      <div style={{ padding: '16px 22px 22px' }}>
        <div style={{ marginBottom: 16 }}>
          <OBStepDots step={0} total={4}/>
        </div>
        <OBPrimary>Weiter</OBPrimary>
      </div>
    </div>
  );
}

window.ScreenPhase = ScreenPhase;
