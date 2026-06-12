// NourishMe — Custom Icon Library
// 8 icons in the Bowl-Mark language: flat-color, no stroke, max 2 colors.
// Palette: pine #1E4A45, amber #C8884A, paper #F4EFE6, plum #6B4554 (food safety only).
// Source viewBox is 24×24 — the iOS app's base icon grid.
// Pine = primary shape, Amber = accent/emphasis. Plum overrides pine only for Food Safety.

const ICON_COLORS = {
  pine:  '#1E4A45',
  amber: '#C8884A',
  paper: '#F4EFE6',
  plum:  '#6B4554',
};

// ─────────────────────────────────────────────────────────────
// 01 — Pregnancy (trimester-neutral)
// A pine bowl-shape rotated 90° = the silhouette of a curved belly,
// with an amber dot (the sun/baby) nestled inside. Bowl-mark DNA, rotated.
// ─────────────────────────────────────────────────────────────
function IcPregnancy({ size = 24, pine = ICON_COLORS.pine, amber = ICON_COLORS.amber }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" style={{ display: 'block' }}>
      {/* belly: half-disc opening left, like a sideways bowl */}
      <path d="M 8 3 A 9 9 0 0 1 8 21 Z" fill={pine}/>
      {/* baby/sun */}
      <circle cx="12.5" cy="13" r="2.8" fill={amber}/>
    </svg>
  );
}

// ─────────────────────────────────────────────────────────────
// 02 — Nursing (direct breastfeeding)
// A pine cradling arc (mother) holding a smaller amber circle (baby's head).
// ─────────────────────────────────────────────────────────────
function IcNursing({ size = 24, pine = ICON_COLORS.pine, amber = ICON_COLORS.amber }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" style={{ display: 'block' }}>
      {/* cradle arc: thick crescent open to top-right */}
      <path d="M 4 12 A 8 8 0 1 1 18 17 L 14.5 14.5 A 4.5 4.5 0 1 0 7.5 12 Z" fill={pine}/>
      {/* baby head */}
      <circle cx="17" cy="9" r="3" fill={amber}/>
    </svg>
  );
}

// ─────────────────────────────────────────────────────────────
// 03 — Pumping
// Pine teardrop with an amber sun nested inside, sitting low like
// settled liquid. Same DNA as the Bowl-Mark (container + sun),
// rephrased as a drop. Reads "volume / liquid expressed" without
// showing any pump device or anatomy.
// ─────────────────────────────────────────────────────────────
function IcPumping({ size = 24, pine = ICON_COLORS.pine, amber = ICON_COLORS.amber }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" style={{ display: 'block' }}>
      {/* pine teardrop — point up, round bottom */}
      <path d="M 12 2 C 5.5 9 5.5 21 12 21 C 18.5 21 18.5 9 12 2 Z" fill={pine}/>
      {/* amber sun — sits low-center, like settled milk */}
      <circle cx="12" cy="14.5" r="3.4" fill={amber}/>
    </svg>
  );
}

// ─────────────────────────────────────────────────────────────
// 04 — Multiples (twins+)
// Two amber suns inside one shared pine bowl.
// ─────────────────────────────────────────────────────────────
function IcMultiples({ size = 24, pine = ICON_COLORS.pine, amber = ICON_COLORS.amber }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" style={{ display: 'block' }}>
      {/* two suns */}
      <circle cx="8.5" cy="9" r="3.2" fill={amber}/>
      <circle cx="15.5" cy="9" r="3.2" fill={amber}/>
      {/* shared bowl */}
      <path d="M 3 12.5 A 9 9 0 0 0 21 12.5 Z" fill={pine}/>
    </svg>
  );
}

// ─────────────────────────────────────────────────────────────
// 05 — Meal
// A pine bowl with an amber crescent (steam/warmth) curling above —
// distinct from the app icon: smaller, wider, with the crescent shifted off-center.
// ─────────────────────────────────────────────────────────────
function IcMeal({ size = 24, pine = ICON_COLORS.pine, amber = ICON_COLORS.amber }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" style={{ display: 'block' }}>
      {/* content disc tucked into the bowl */}
      <circle cx="12" cy="11.5" r="3.4" fill={amber}/>
      {/* bowl — wider, shallower than the app mark */}
      <path d="M 2.5 13 A 9.5 9.5 0 0 0 21.5 13 Z" fill={pine}/>
    </svg>
  );
}

// ─────────────────────────────────────────────────────────────
// 06 — Food Safety
// Plum diamond (rotated square) — a quiet, editorial caution.
// Amber dot at the center = the alert. Plum replaces pine here per brief.
// ─────────────────────────────────────────────────────────────
function IcFoodSafety({ size = 24, plum = ICON_COLORS.plum, amber = ICON_COLORS.amber }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" style={{ display: 'block' }}>
      {/* diamond */}
      <path d="M 12 2.5 L 21.5 12 L 12 21.5 L 2.5 12 Z" fill={plum}/>
      {/* dot */}
      <circle cx="12" cy="12" r="2.6" fill={amber}/>
    </svg>
  );
}

// ─────────────────────────────────────────────────────────────
// 07 — Coach Hint
// The bowl-mark, compressed: a pine half-disc with an amber sun sitting
// above the rim, leaving a thin amber crescent visible. This is the
// canonical Bowl-Mark in icon scale — used as the Coach badge.
// ─────────────────────────────────────────────────────────────
function IcCoach({ size = 24, pine = ICON_COLORS.pine, amber = ICON_COLORS.amber }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" style={{ display: 'block' }}>
      <circle cx="12" cy="10.5" r="3.6" fill={amber}/>
      <path d="M 3 12.2 A 9 9 0 0 0 21 12.2 Z" fill={pine}/>
    </svg>
  );
}

// ─────────────────────────────────────────────────────────────
// 08 — Journal / History
// Three pine horizontal bars (stacked entries) with an amber dot
// on the top-most row = "today, written down".
// ─────────────────────────────────────────────────────────────
function IcJournal({ size = 24, pine = ICON_COLORS.pine, amber = ICON_COLORS.amber }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" style={{ display: 'block' }}>
      <rect x="3"  y="5"  width="18" height="2.5" rx="1.25" fill={pine}/>
      <rect x="3"  y="11" width="18" height="2.5" rx="1.25" fill={pine}/>
      <rect x="3"  y="17" width="18" height="2.5" rx="1.25" fill={pine}/>
      <circle cx="5.5" cy="6.25" r="2" fill={amber}/>
    </svg>
  );
}

// ─────────────────────────────────────────────────────────────
// Registry — keyed for lookup in the legend grid + SVG export
// ─────────────────────────────────────────────────────────────
const NM_ICONS = [
  { key: 'pregnancy',   label: 'Schwangerschaft',  hint: 'trimester-neutral',         C: IcPregnancy },
  { key: 'nursing',     label: 'Stillen',          hint: 'direkt anlegen',            C: IcNursing },
  { key: 'pumping',     label: 'Pumpen',           hint: 'milk_volume_input',         C: IcPumping },
  { key: 'multiples',   label: 'Mehrlinge',        hint: 'children_count ≥ 2',        C: IcMultiples },
  { key: 'meal',        label: 'Mahlzeit',         hint: 'log_entry',                 C: IcMeal },
  { key: 'food-safety', label: 'Food Safety',      hint: 'BfR-Hinweis · plum',        C: IcFoodSafety },
  { key: 'coach',       label: 'Coach-Hinweis',    hint: 'live coach badge',          C: IcCoach },
  { key: 'journal',     label: 'Tagebuch',         hint: 'history / log tab',         C: IcJournal },
];

Object.assign(window, {
  IcPregnancy, IcNursing, IcPumping, IcMultiples,
  IcMeal, IcFoodSafety, IcCoach, IcJournal,
  NM_ICONS, ICON_COLORS,
});
