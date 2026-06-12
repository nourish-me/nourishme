// NourishMe — Icon Library legend (24px grid + 1x / 2x / 3x size sweep)

function IconCard({ entry }) {
  const { key, label, hint, C } = entry;
  return (
    <div style={{
      padding: '20px 18px 18px',
      background: NMOB.paperHi, border: `1px solid ${NMOB.rule}`,
      borderRadius: 14, display: 'flex', flexDirection: 'column', gap: 14,
      fontFamily: NMOB.ui,
    }}>
      {/* Big preview on a 24px grid */}
      <div style={{
        position: 'relative', alignSelf: 'center',
        width: 120, height: 120, padding: 16,
        background: NMOB.paper, border: `1px solid ${NMOB.rule}`,
        borderRadius: 12, boxSizing: 'border-box',
      }}>
        {/* faint grid overlay */}
        <div style={{
          position: 'absolute', inset: 16,
          backgroundImage:
            `linear-gradient(${NMOB.rule}55 1px, transparent 1px),
             linear-gradient(90deg, ${NMOB.rule}55 1px, transparent 1px)`,
          backgroundSize: 'calc(100% / 6) calc(100% / 6)',
          opacity: 0.6, pointerEvents: 'none',
        }}/>
        <div style={{
          position: 'relative', width: '100%', height: '100%',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <C size={88}/>
        </div>
      </div>

      {/* Label */}
      <div>
        <div style={{
          fontFamily: NMOB.serif, fontStyle: 'italic', fontWeight: 700,
          fontSize: 20, lineHeight: 1.1, color: NMOB.ink, letterSpacing: -0.01,
        }}>{label}</div>
        <div style={{
          fontFamily: NMOB.mono, fontSize: 10.5, letterSpacing: 0.06,
          color: NMOB.inkMute, marginTop: 4,
        }}>ic-nm-{key} · {hint}</div>
      </div>

      {/* Size sweep — 1x / 2x / 3x at 24pt base */}
      <div style={{
        display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between',
        padding: '12px 14px', background: NMOB.paper,
        border: `1px solid ${NMOB.rule}`, borderRadius: 10,
      }}>
        {[
          { px: 24, lbl: '24 · 1×' },
          { px: 48, lbl: '48 · 2×' },
          { px: 72, lbl: '72 · 3×' },
        ].map(s => (
          <div key={s.px} style={{
            display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6,
          }}>
            <div style={{
              width: s.px, height: s.px,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <C size={s.px}/>
            </div>
            <span style={{
              fontFamily: NMOB.mono, fontSize: 9.5, letterSpacing: 0.06,
              color: NMOB.inkMute,
            }}>{s.lbl}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

function NMIconLegend() {
  return (
    <div style={{
      width: 1140, padding: '32px 32px 28px', background: NMOB.paper,
      fontFamily: NMOB.ui, color: NMOB.ink, borderRadius: 18,
      border: `1px solid ${NMOB.rule}`, boxSizing: 'border-box',
    }} data-screen-label="ICONS Legend">
      <div style={{
        display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end',
        borderBottom: `1px solid ${NMOB.rule}`, paddingBottom: 16, marginBottom: 20,
      }}>
        <div>
          <div style={{
            fontFamily: NMOB.mono, fontSize: 10.5, letterSpacing: 0.1,
            textTransform: 'uppercase', color: NMOB.amber, fontWeight: 600,
          }}>NourishMe · Icon Library</div>
          <h2 style={{
            margin: '8px 0 0', fontFamily: NMOB.serif, fontStyle: 'italic',
            fontWeight: 700, fontSize: 32, lineHeight: 1, color: NMOB.ink,
            letterSpacing: -0.02,
          }}>8 Custom Icons</h2>
        </div>
        <div style={{
          textAlign: 'right', fontFamily: NMOB.mono, fontSize: 10.5,
          color: NMOB.inkMute, letterSpacing: 0.06, lineHeight: 1.7,
        }}>
          <div>24px base · flat-color, no stroke</div>
          <div>pine #1E4A45 · amber #C8884A · plum #6B4554</div>
          <div>max 2 colors per icon</div>
        </div>
      </div>

      <div style={{
        display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 14,
      }}>
        {NM_ICONS.map(e => <IconCard key={e.key} entry={e}/>)}
      </div>
    </div>
  );
}

window.NMIconLegend = NMIconLegend;
