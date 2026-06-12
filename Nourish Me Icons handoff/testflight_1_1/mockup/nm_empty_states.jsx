// NourishMe — Empty states (4)
// Notebook tone — warm, never clinical. Uses custom icons from nm_icons.jsx.
// Each screen sits inside a "live" iOS chrome (top bar + bottom tab bar) so
// the empty state reads in real product context, not as a poster.

function NMTopBar({ title, subtitle }) {
  return (
    <div style={{ padding: '8px 22px 14px' }}>
      <OBEyebrow>{subtitle}</OBEyebrow>
      <h1 style={{
        fontFamily: NMOB.serif, fontStyle: 'italic', fontWeight: 700,
        fontSize: 38, lineHeight: 1.0, letterSpacing: -0.02,
        margin: '6px 0 0', color: NMOB.ink,
      }}>{title}</h1>
    </div>
  );
}

function NMTabBar({ active }) {
  const items = [
    { k: 'today',   label: 'Heute',     Ic: IcMeal },
    { k: 'log',     label: 'Tagebuch',  Ic: IcJournal },
    { k: 'coach',   label: 'Coach',     Ic: IcCoach },
    { k: 'safety',  label: 'Safety',    Ic: IcFoodSafety },
  ];
  return (
    <div style={{
      position: 'absolute', bottom: 0, left: 0, right: 0,
      paddingBottom: 22, // home indicator clearance
      background: 'linear-gradient(180deg, rgba(244,239,230,0) 0%, rgba(244,239,230,0.96) 30%)',
    }}>
      <div style={{
        margin: '0 14px', padding: '8px 6px 6px',
        background: NMOB.paperHi, borderRadius: 22,
        border: `1px solid ${NMOB.rule}`,
        display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 0,
        boxShadow: '0 8px 24px -10px rgba(31,27,22,0.18)',
      }}>
        {items.map(it => {
          const sel = it.k === active;
          return (
            <div key={it.k} style={{
              display: 'flex', flexDirection: 'column', alignItems: 'center',
              padding: '6px 4px 4px', gap: 4,
            }}>
              <div style={{ opacity: sel ? 1 : 0.45 }}>
                <it.Ic size={22} pine={sel ? NMOB.pine : NMOB.inkSoft}
                       amber={sel ? NMOB.amber : NMOB.inkMute}
                       plum={sel ? NMOB.plum : NMOB.inkSoft}/>
              </div>
              <span style={{
                fontFamily: NMOB.ui, fontSize: 10.5,
                fontWeight: sel ? 600 : 500,
                color: sel ? NMOB.pine : NMOB.inkMute,
              }}>{it.label}</span>
            </div>
          );
        })}
      </div>
    </div>
  );
}

function EmptyHero({ Icon, color = NMOB.pine }) {
  return (
    <div style={{
      width: 88, height: 88, borderRadius: 26,
      background: NMOB.paperHi, border: `1px solid ${NMOB.rule}`,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      margin: '0 auto 22px',
    }}>
      <Icon size={48}/>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Empty 1 — Tagebuch heute · "Tipp einfach drauf los."
// ─────────────────────────────────────────────────────────────
function EmptyToday() {
  return (
    <div data-screen-label="EM1 Heute leer" style={{
      minHeight: '100%', background: NMOB.paper, color: NMOB.ink,
      fontFamily: NMOB.ui, position: 'relative',
      display: 'flex', flexDirection: 'column',
    }}>
      <NMTopBar subtitle="Donnerstag · 20. Mai" title="Heute"/>

      {/* writable prompt card */}
      <div style={{ padding: '8px 16px 0', flex: 1 }}>
        <div style={{
          padding: '28px 22px 24px',
          background: NMOB.paperHi, borderRadius: 18,
          border: `1px dashed ${NMOB.rule}`,
        }}>
          <EmptyHero Icon={IcMeal}/>
          <h2 style={{
            margin: '0 0 8px', fontFamily: NMOB.serif, fontStyle: 'italic',
            fontWeight: 700, fontSize: 24, lineHeight: 1.15, color: NMOB.ink,
            textAlign: 'center', textWrap: 'pretty', letterSpacing: -0.01,
          }}>
            Was hast du heute gegessen?
          </h2>
          <p style={{
            margin: 0, fontFamily: NMOB.serif, fontSize: 15.5, lineHeight: 1.45,
            color: NMOB.inkSoft, textAlign: 'center', textWrap: 'pretty',
            maxWidth: 280, marginInline: 'auto',
          }}>
            Tipp einfach drauf los — ein Wort, ein Satz, eine Zutatenliste.
            Der Coach rechnet mit, sobald du tippst.
          </p>

          {/* notebook-style input affordance */}
          <div style={{
            marginTop: 22, padding: '14px 16px',
            background: NMOB.paper, border: `1px solid ${NMOB.rule}`,
            borderRadius: 12, display: 'flex', alignItems: 'center', gap: 10,
          }}>
            <span style={{
              fontFamily: NMOB.serif, fontStyle: 'italic',
              fontSize: 15.5, color: NMOB.inkMute,
            }}>Müsli mit Beeren …</span>
            <span style={{
              display: 'inline-block', width: 2, height: 18, background: NMOB.pine,
              marginLeft: -2, animation: 'nmblink 1.1s infinite step-end',
            }}/>
            <style>{`@keyframes nmblink{50%{opacity:0}}`}</style>
          </div>
        </div>

        <div style={{ textAlign: 'center', marginTop: 14 }}>
          <OBEyebrow>Tagesziel 2.880 kcal · noch nichts erfasst</OBEyebrow>
        </div>
      </div>

      <div style={{ height: 96 }}/>
      <NMTabBar active="today"/>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Empty 2 — Verlauf · noch nichts gesammelt
// ─────────────────────────────────────────────────────────────
function EmptyHistory() {
  return (
    <div data-screen-label="EM2 Verlauf leer" style={{
      minHeight: '100%', background: NMOB.paper, color: NMOB.ink,
      fontFamily: NMOB.ui, position: 'relative',
      display: 'flex', flexDirection: 'column',
    }}>
      <NMTopBar subtitle="Letzte 30 Tage" title="Verlauf"/>

      <div style={{ padding: '8px 16px 0', flex: 1 }}>
        {/* faint timeline placeholder — visual rhythm without filler data */}
        <div style={{
          padding: '22px 22px 18px', background: NMOB.paperHi,
          border: `1px solid ${NMOB.rule}`, borderRadius: 18,
        }}>
          <EmptyHero Icon={IcJournal}/>
          <h2 style={{
            margin: '0 0 8px', fontFamily: NMOB.serif, fontStyle: 'italic',
            fontWeight: 700, fontSize: 24, lineHeight: 1.15, color: NMOB.ink,
            textAlign: 'center', letterSpacing: -0.01,
          }}>Der Verlauf beginnt heute.</h2>
          <p style={{
            margin: 0, fontFamily: NMOB.serif, fontSize: 15.5, lineHeight: 1.45,
            color: NMOB.inkSoft, textAlign: 'center', textWrap: 'pretty',
            maxWidth: 280, marginInline: 'auto',
          }}>
            Sobald du die erste Mahlzeit erfasst, siehst du hier deine
            Nährstoff-Trends über die Woche.
          </p>

          {/* ghost week chart — same shape, no values */}
          <div style={{
            marginTop: 22, display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)',
            gap: 6, alignItems: 'end', height: 56,
          }}>
            {[0.35, 0.6, 0.45, 0.5, 0.7, 0.3, 0.55].map((h, i) => (
              <div key={i} style={{
                height: `${h * 100}%`, background: NMOB.surfLow,
                borderRadius: 4,
              }}/>
            ))}
          </div>
          <div style={{
            display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)', gap: 6,
            marginTop: 8,
          }}>
            {['M','D','M','D','F','S','S'].map((d,i) => (
              <div key={i} style={{
                fontFamily: NMOB.mono, fontSize: 10, color: NMOB.inkMute,
                textAlign: 'center', letterSpacing: 0.04,
              }}>{d}</div>
            ))}
          </div>
        </div>

        <div style={{ textAlign: 'center', marginTop: 14 }}>
          <OBEyebrow>Tipp: Erste Mahlzeit ergibt schon einen Trend.</OBEyebrow>
        </div>
      </div>

      <div style={{ height: 96 }}/>
      <NMTabBar active="log"/>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Empty 3 — Favoriten leer
// ─────────────────────────────────────────────────────────────
function StarOutline({ size = 48, color = NMOB.amber }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24">
      <path d="M12 2.5 L14.6 9.1 L21.5 9.6 L16.3 14.1 L18 21 L12 17.3 L6 21 L7.7 14.1 L2.5 9.6 L9.4 9.1 Z"
            fill="none" stroke={color} strokeWidth="1.7" strokeLinejoin="round"/>
    </svg>
  );
}

function EmptyFavorites() {
  return (
    <div data-screen-label="EM3 Favoriten leer" style={{
      minHeight: '100%', background: NMOB.paper, color: NMOB.ink,
      fontFamily: NMOB.ui, position: 'relative',
      display: 'flex', flexDirection: 'column',
    }}>
      <NMTopBar subtitle="Schnell wieder finden" title="Favoriten"/>

      <div style={{ padding: '8px 16px 0', flex: 1 }}>
        <div style={{
          padding: '28px 22px 24px', background: NMOB.paperHi,
          border: `1px solid ${NMOB.rule}`, borderRadius: 18,
        }}>
          <div style={{
            width: 88, height: 88, borderRadius: 26,
            background: NMOB.paper, border: `1px solid ${NMOB.rule}`,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            margin: '0 auto 22px',
          }}>
            <StarOutline size={44}/>
          </div>

          <h2 style={{
            margin: '0 0 8px', fontFamily: NMOB.serif, fontStyle: 'italic',
            fontWeight: 700, fontSize: 24, lineHeight: 1.15, color: NMOB.ink,
            textAlign: 'center', letterSpacing: -0.01,
          }}>
            Noch keine Favoriten.
          </h2>
          <p style={{
            margin: 0, fontFamily: NMOB.serif, fontSize: 15.5, lineHeight: 1.45,
            color: NMOB.inkSoft, textAlign: 'center', textWrap: 'pretty',
            maxWidth: 280, marginInline: 'auto',
          }}>
            Tippe in einer Mahlzeit auf den Stern, um sie zu speichern. Beim
            nächsten Mal reicht ein Klick.
          </p>

          {/* mini illustration of the gesture */}
          <div style={{
            marginTop: 20, padding: '14px 16px',
            background: NMOB.paper, border: `1px solid ${NMOB.rule}`,
            borderRadius: 12, display: 'flex', alignItems: 'center', gap: 12,
          }}>
            <div style={{
              width: 36, height: 36, borderRadius: 18, background: NMOB.surfLow,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontFamily: NMOB.serif, fontStyle: 'italic', fontWeight: 600,
              fontSize: 16, color: NMOB.pine,
            }}>L</div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 13.5, fontWeight: 500, color: NMOB.ink }}>Lachs-Bowl mit Quinoa</div>
              <div style={{ fontSize: 11.5, color: NMOB.inkMute }}>vorgestern · 540 kcal</div>
            </div>
            <StarOutline size={22}/>
          </div>
        </div>
      </div>

      <div style={{ height: 96 }}/>
      <NMTabBar active="log"/>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Empty 4 — Food Safety: alles unauffällig
// ─────────────────────────────────────────────────────────────
function EmptySafety() {
  return (
    <div data-screen-label="EM4 Safety unauffaellig" style={{
      minHeight: '100%', background: NMOB.paper, color: NMOB.ink,
      fontFamily: NMOB.ui, position: 'relative',
      display: 'flex', flexDirection: 'column',
    }}>
      <NMTopBar subtitle="Food Safety · BfR" title="Sicher."/>

      <div style={{ padding: '8px 16px 0', flex: 1 }}>
        <div style={{
          padding: '24px 22px 22px', background: NMOB.paperHi,
          border: `1px solid ${NMOB.rule}`, borderRadius: 18,
        }}>
          <EmptyHero Icon={IcFoodSafety}/>

          <h2 style={{
            margin: '0 0 8px', fontFamily: NMOB.serif, fontStyle: 'italic',
            fontWeight: 700, fontSize: 24, lineHeight: 1.15, color: NMOB.ink,
            textAlign: 'center', letterSpacing: -0.01,
          }}>
            Alles unauffällig.
          </h2>
          <p style={{
            margin: 0, fontFamily: NMOB.serif, fontSize: 15.5, lineHeight: 1.45,
            color: NMOB.inkSoft, textAlign: 'center', textWrap: 'pretty',
            maxWidth: 280, marginInline: 'auto',
          }}>
            Nichts aus deinen letzten Mahlzeiten triggert einen BfR-Hinweis.
            Weitermachen.
          </p>

          {/* last checks */}
          <div style={{ marginTop: 22 }}>
            <div style={{
              fontFamily: NMOB.mono, fontSize: 10.5, letterSpacing: 0.08,
              textTransform: 'uppercase', color: NMOB.inkMute, fontWeight: 500,
              marginBottom: 8,
            }}>Zuletzt geprüft</div>
            {[
              { name: 'Wildlachs',      ts: 'heute 13:42', ok: 'Quecksilber ok' },
              { name: 'Mozzarella',     ts: 'gestern',     ok: 'pasteurisiert ok' },
              { name: 'Espresso',       ts: 'gestern',     ok: '< 200 mg Koffein' },
            ].map(c => (
              <div key={c.name} style={{
                padding: '10px 14px', background: NMOB.paper,
                border: `1px solid ${NMOB.rule}`, borderRadius: 10,
                display: 'flex', alignItems: 'center', gap: 12, marginBottom: 6,
              }}>
                <div style={{
                  width: 8, height: 8, borderRadius: 4, background: NMOB.moss,
                  flexShrink: 0,
                }}/>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: 13.5, fontWeight: 500, color: NMOB.ink }}>{c.name}</div>
                  <div style={{ fontSize: 11.5, color: NMOB.inkMute }}>{c.ts}</div>
                </div>
                <span style={{
                  fontFamily: NMOB.mono, fontSize: 10.5, color: NMOB.moss,
                  letterSpacing: 0.04,
                }}>{c.ok}</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      <div style={{ height: 96 }}/>
      <NMTabBar active="safety"/>
    </div>
  );
}

Object.assign(window, {
  EmptyToday, EmptyHistory, EmptyFavorites, EmptySafety,
  NMTopBar, NMTabBar,
});
