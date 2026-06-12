// NourishMe — Onboarding 3/5 · Eckdaten
// Größe (Stepper), Gewicht (Stepper), Aktivitätslevel (Segmented).

function FieldRow({ label, sub, children }) {
  return (
    <div style={{
      padding: '18px 20px', background: NMOB.paperHi,
      border: `1px solid ${NMOB.rule}`, borderRadius: 16,
    }}>
      <div style={{
        fontFamily: NMOB.mono, fontSize: 10.5, letterSpacing: 0.08,
        textTransform: 'uppercase', color: NMOB.inkMute, fontWeight: 500,
      }}>{label}</div>
      {sub && (
        <div style={{
          fontFamily: NMOB.ui, fontSize: 12.5, color: NMOB.inkMute,
          marginTop: 4,
        }}>{sub}</div>
      )}
      <div style={{ marginTop: 12 }}>{children}</div>
    </div>
  );
}

function NumberStepper({ value, unit }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      gap: 16,
    }}>
      <div style={{
        display: 'flex', alignItems: 'baseline', gap: 6,
      }}>
        <span style={{
          fontFamily: NMOB.serif, fontStyle: 'italic', fontWeight: 700,
          fontSize: 36, color: NMOB.ink, lineHeight: 1, letterSpacing: -0.02,
        }}>{value}</span>
        <span style={{
          fontFamily: NMOB.mono, fontSize: 13, color: NMOB.inkMute,
        }}>{unit}</span>
      </div>
      <div style={{
        display: 'flex', border: `1px solid ${NMOB.rule}`, borderRadius: 22,
        background: NMOB.paper, overflow: 'hidden',
      }}>
        <button style={{
          width: 44, height: 40, border: 'none', background: 'transparent',
          color: NMOB.pine, fontSize: 22, fontWeight: 500,
        }}>−</button>
        <div style={{ width: 1, background: NMOB.rule }}/>
        <button style={{
          width: 44, height: 40, border: 'none', background: 'transparent',
          color: NMOB.pine, fontSize: 22, fontWeight: 500,
        }}>+</button>
      </div>
    </div>
  );
}

function Segmented({ options, selectedIdx = 1 }) {
  return (
    <div style={{
      display: 'grid', gridTemplateColumns: `repeat(${options.length}, 1fr)`,
      gap: 6, padding: 4, background: NMOB.surfLow, borderRadius: 12,
    }}>
      {options.map((o, i) => (
        <button key={o.k} style={{
          border: 'none', padding: '10px 4px', borderRadius: 9,
          background: i === selectedIdx ? NMOB.paperHi : 'transparent',
          boxShadow: i === selectedIdx ? '0 1px 3px rgba(31,27,22,0.08)' : 'none',
          fontFamily: NMOB.ui, fontSize: 13,
          fontWeight: i === selectedIdx ? 600 : 500,
          color: i === selectedIdx ? NMOB.ink : NMOB.inkSoft,
          display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4,
        }}>
          <span style={{ lineHeight: 1.1 }}>{o.label}</span>
          <span style={{
            fontFamily: NMOB.mono, fontSize: 10, color: NMOB.inkMute,
            letterSpacing: 0.04,
          }}>{o.k}</span>
        </button>
      ))}
    </div>
  );
}

function ScreenStats() {
  return (
    <div data-screen-label="OB3 Eckdaten" style={{
      minHeight: '100%', background: NMOB.paper, color: NMOB.ink,
      fontFamily: NMOB.ui, display: 'flex', flexDirection: 'column',
    }}>
      <div style={{ padding: '6px 22px 18px' }}>
        <OBEyebrow>Schritt 2 von 4</OBEyebrow>
        <OBHeadline size={34}>Ein paar Eckdaten.</OBHeadline>
        <p style={{
          margin: 0, fontSize: 15, lineHeight: 1.5, color: NMOB.inkSoft,
          fontFamily: NMOB.ui, maxWidth: 320,
        }}>Daraus berechnen wir deinen Grundumsatz nach Mifflin-St-Jeor — bleibt lokal auf deinem Gerät.</p>
      </div>

      <div style={{ padding: '0 16px', display: 'flex', flexDirection: 'column', gap: 12 }}>
        <FieldRow label="Größe">
          <NumberStepper value="168" unit="cm"/>
        </FieldRow>
        <FieldRow label="Gewicht" sub="Vor der Schwangerschaft — wir tracken den Verlauf separat.">
          <NumberStepper value="64,5" unit="kg"/>
        </FieldRow>
        <FieldRow label="Aktivitätslevel">
          <Segmented selectedIdx={1} options={[
            { k: '×1.2',  label: 'Sitzend' },
            { k: '×1.4',  label: 'Leicht' },
            { k: '×1.6',  label: 'Aktiv' },
            { k: '×1.8',  label: 'Sportlich' },
          ]}/>
        </FieldRow>
      </div>

      <div style={{ flex: 1 }}/>

      <div style={{ padding: '16px 22px 22px' }}>
        <div style={{ marginBottom: 16 }}>
          <OBStepDots step={1} total={4}/>
        </div>
        <OBPrimary>Weiter</OBPrimary>
      </div>
    </div>
  );
}

window.ScreenStats = ScreenStats;
