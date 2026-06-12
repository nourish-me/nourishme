// NourishMe — Onboarding screens (5)
// Field Manual palette · Newsreader italic for headlines · Inter for body
// JetBrains Mono for eyebrows. All screens use a 22px lateral gutter.

const NMOB = {
  paper:   '#F4EFE6',
  paperHi: '#FBF7EF',
  surfLow: '#F2ECDE',
  surf:    '#EDE6D7',
  pine:    '#1E4A45',
  pineDeep:'#0F2D2A',
  pineSoft:'#C6E2DC',
  amber:   '#C8884A',
  amberLt: '#FFE0B8',
  plum:    '#6B4554',
  plumLt:  '#F4D9E3',
  moss:    '#4B5A47',
  ink:     '#1F1B16',
  inkSoft: '#4F4A41',
  inkMute: '#847E72',
  rule:    '#D5CEC0',
  serif:   '"Newsreader", Georgia, serif',
  ui:      '-apple-system, "SF Pro Text", "Inter", system-ui, sans-serif',
  mono:    '"JetBrains Mono", "SF Mono", ui-monospace, monospace',
};

function OBEyebrow({ children, color = NMOB.inkMute, mb = 0 }) {
  return (
    <div style={{
      fontFamily: NMOB.mono, fontSize: 10.5, letterSpacing: 0.1,
      textTransform: 'uppercase', color, fontWeight: 500, marginBottom: mb,
    }}>{children}</div>
  );
}

function OBHeadline({ children, size = 36 }) {
  return (
    <h1 style={{
      fontFamily: NMOB.serif, fontStyle: 'italic', fontWeight: 700,
      fontSize: size, lineHeight: 1.02, letterSpacing: -0.02,
      margin: '10px 0 12px', color: NMOB.ink, textWrap: 'pretty',
    }}>{children}</h1>
  );
}

function OBPrimary({ children, onClick }) {
  return (
    <button onClick={onClick} style={{
      width: '100%', border: 'none', background: NMOB.pine, color: '#fff',
      padding: '16px 18px', borderRadius: 14, fontFamily: NMOB.ui,
      fontSize: 16, fontWeight: 600, letterSpacing: 0.1,
    }}>{children}</button>
  );
}

function OBSecondary({ children }) {
  return (
    <button style={{
      width: '100%', border: 'none', background: 'transparent', color: NMOB.inkSoft,
      padding: '12px 18px', fontFamily: NMOB.ui, fontSize: 14, fontWeight: 500,
    }}>{children}</button>
  );
}

function OBStepDots({ step, total = 5 }) {
  return (
    <div style={{ display: 'flex', gap: 6, alignItems: 'center', justifyContent: 'center' }}>
      {Array.from({ length: total }).map((_, i) => (
        <span key={i} style={{
          width: i === step ? 18 : 6, height: 6, borderRadius: 3,
          background: i === step ? NMOB.pine : NMOB.rule,
          transition: 'width .3s',
        }}/>
      ))}
    </div>
  );
}

Object.assign(window, { NMOB, OBEyebrow, OBHeadline, OBPrimary, OBSecondary, OBStepDots });
