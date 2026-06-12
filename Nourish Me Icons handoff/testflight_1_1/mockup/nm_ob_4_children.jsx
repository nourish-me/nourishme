// NourishMe — Onboarding 4/5 · Kinder-Setup
// Multi-state demo: user is BOTH pregnant + nursing → both blocks render.
// Children count, trimester (if pregnant), milk volume (if nursing/pumping).

function ChildCounter({ value = 1 }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 10,
    }}>
      <div style={{
        display: 'flex', border: `1px solid ${NMOB.rule}`, borderRadius: 22,
        background: NMOB.paper, overflow: 'hidden',
      }}>
        <button style={{ width: 38, height: 38, border: 'none', background: 'transparent', color: NMOB.pine, fontSize: 20 }}>−</button>
        <div style={{
          minWidth: 64, display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontFamily: NMOB.serif, fontStyle: 'italic', fontWeight: 700, fontSize: 24,
          color: NMOB.ink, lineHeight: 1,
        }}>{value}</div>
        <button style={{ width: 38, height: 38, border: 'none', background: 'transparent', color: NMOB.pine, fontSize: 20 }}>+</button>
      </div>
      {value >= 2 && (
        <div style={{
          display: 'flex', alignItems: 'center', gap: 6,
          padding: '6px 10px', background: NMOB.amberLt, borderRadius: 12,
        }}>
          <IcMultiples size={16}/>
          <span style={{ fontFamily: NMOB.ui, fontSize: 12, fontWeight: 600, color: NMOB.pine }}>
            Mehrlinge
          </span>
        </div>
      )}
    </div>
  );
}

function TrimesterPicker({ selected = 1 }) {
  const items = [
    { k: 1, label: 'I',  hint: '1–13 W.' },
    { k: 2, label: 'II', hint: '14–27 W.' },
    { k: 3, label: 'III', hint: '28–40 W.' },
  ];
  return (
    <div style={{
      display: 'grid', gridTemplateColumns: 'repeat(3,1fr)', gap: 8,
    }}>
      {items.map(it => {
        const sel = it.k === selected;
        return (
          <button key={it.k} style={{
            border: `1.5px solid ${sel ? NMOB.pine : NMOB.rule}`,
            background: sel ? NMOB.pineSoft : NMOB.paperHi,
            borderRadius: 14, padding: '14px 8px',
            display: 'flex', flexDirection: 'column', alignItems: 'center',
            gap: 4, cursor: 'pointer',
          }}>
            <span style={{
              fontFamily: NMOB.serif, fontStyle: 'italic', fontWeight: 700,
              fontSize: 26, color: sel ? NMOB.pineDeep : NMOB.ink, lineHeight: 1,
            }}>{it.label}</span>
            <span style={{
              fontFamily: NMOB.mono, fontSize: 10.5, letterSpacing: 0.06,
              color: sel ? NMOB.pine : NMOB.inkMute,
            }}>{it.hint}</span>
          </button>
        );
      })}
    </div>
  );
}

function ScreenChildren() {
  return (
    <div data-screen-label="OB4 Kinder" style={{
      minHeight: '100%', background: NMOB.paper, color: NMOB.ink,
      fontFamily: NMOB.ui, display: 'flex', flexDirection: 'column',
    }}>
      <div style={{ padding: '6px 22px 16px' }}>
        <OBEyebrow>Schritt 3 von 4</OBEyebrow>
        <OBHeadline size={32}>Wen versorgst du gerade?</OBHeadline>
        <p style={{
          margin: 0, fontSize: 14.5, lineHeight: 1.5, color: NMOB.inkSoft,
          fontFamily: NMOB.ui, maxWidth: 320,
        }}>Wir berechnen daraus den zusätzlichen Bedarf an Kalorien und kritischen Nährstoffen.</p>
      </div>

      {/* Children count */}
      <div style={{ padding: '0 16px' }}>
        <div style={{
          padding: '16px 20px', background: NMOB.paperHi,
          border: `1px solid ${NMOB.rule}`, borderRadius: 16,
          display: 'flex', justifyContent: 'space-between', alignItems: 'center',
          gap: 12,
        }}>
          <div style={{ minWidth: 0 }}>
            <div style={{
              fontFamily: NMOB.mono, fontSize: 10.5, letterSpacing: 0.08,
              textTransform: 'uppercase', color: NMOB.inkMute, fontWeight: 500,
            }}>Anzahl Kinder</div>
            <div style={{
              fontFamily: NMOB.ui, fontSize: 12.5, color: NMOB.inkMute, marginTop: 3,
            }}>inkl. ungeborenes</div>
          </div>
          <ChildCounter value={2}/>
        </div>
      </div>

      {/* Pregnant block */}
      <div style={{ padding: '12px 16px 0' }}>
        <div style={{
          padding: '16px 20px 18px', background: NMOB.paperHi,
          border: `1px solid ${NMOB.rule}`, borderRadius: 16,
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 10 }}>
            <IcPregnancy size={20}/>
            <div style={{
              fontFamily: NMOB.mono, fontSize: 10.5, letterSpacing: 0.08,
              textTransform: 'uppercase', color: NMOB.pine, fontWeight: 600,
            }}>Schwanger · Trimester</div>
          </div>
          <TrimesterPicker selected={2}/>
        </div>
      </div>

      {/* Nursing block */}
      <div style={{ padding: '12px 16px 0' }}>
        <div style={{
          padding: '16px 20px 18px', background: NMOB.paperHi,
          border: `1px solid ${NMOB.rule}`, borderRadius: 16,
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 10 }}>
            <IcNursing size={20}/>
            <div style={{
              fontFamily: NMOB.mono, fontSize: 10.5, letterSpacing: 0.08,
              textTransform: 'uppercase', color: NMOB.pine, fontWeight: 600,
            }}>Stillen · Volumen pro Tag</div>
          </div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, marginBottom: 4 }}>
            <span style={{
              fontFamily: NMOB.serif, fontStyle: 'italic', fontWeight: 700,
              fontSize: 36, color: NMOB.ink, lineHeight: 1, letterSpacing: -0.02,
            }}>740</span>
            <span style={{ fontFamily: NMOB.mono, fontSize: 13, color: NMOB.inkMute }}>ml / Tag</span>
            <span style={{
              marginLeft: 'auto', fontFamily: NMOB.ui, fontSize: 12, color: NMOB.inkMute,
            }}>~ 6 Mahlzeiten</span>
          </div>
          {/* slider visualization */}
          <div style={{
            height: 6, background: NMOB.surfLow, borderRadius: 3, position: 'relative',
            marginTop: 14,
          }}>
            <div style={{
              position: 'absolute', left: 0, top: 0, height: '100%',
              width: '62%', background: NMOB.pine, borderRadius: 3,
            }}/>
            <div style={{
              position: 'absolute', left: 'calc(62% - 11px)', top: -7,
              width: 22, height: 22, borderRadius: 11, background: NMOB.paperHi,
              border: `2px solid ${NMOB.pine}`,
              boxShadow: '0 2px 6px rgba(31,27,22,0.18)',
            }}/>
          </div>
          <div style={{
            display: 'flex', justifyContent: 'space-between', marginTop: 8,
            fontFamily: NMOB.mono, fontSize: 10, color: NMOB.inkMute, letterSpacing: 0.06,
          }}>
            <span>0 ml</span><span>1200 ml</span>
          </div>
        </div>
      </div>

      <div style={{ flex: 1, minHeight: 16 }}/>

      <div style={{ padding: '12px 22px 22px' }}>
        <div style={{ marginBottom: 14 }}>
          <OBStepDots step={2} total={4}/>
        </div>
        <OBPrimary>Weiter</OBPrimary>
      </div>
    </div>
  );
}

window.ScreenChildren = ScreenChildren;
