// NourishMe — TestFlight 1.1 Canvas wrapper
// Assembles the icons, onboarding screens, and empty states into one DesignCanvas.

const NM_W = 390;   // iPhone 16e logical width (pts)
const NM_H = 844;   // iPhone 16e logical height (pts)

function NMTestFlightCanvas() {
  return (
    <DesignCanvas>
      <DCSection
        id="nm-icons"
        title="Custom Icons · 24px grid"
        subtitle="8 Icons in der Bowl-Mark-Sprache — pine + amber, max zwei Farben pro Icon."
      >
        <DCArtboard id="legend" label="Icon Library" width={1140} height={720}>
          <NMIconLegend/>
        </DCArtboard>
      </DCSection>

      <DCSection
        id="nm-onboarding"
        title="Onboarding · 5 Screens"
        subtitle="Welcome → Lebensphase → Eckdaten → Kinder-Setup → Berechnung. iPhone 16e (390×844 pt)."
      >
        <DCArtboard id="ob-welcome" label="01 Welcome" width={NM_W} height={NM_H}>
          <IOSDevice width={NM_W} height={NM_H}><ScreenWelcome/></IOSDevice>
        </DCArtboard>
        <DCArtboard id="ob-phase" label="02 Lebensphase" width={NM_W} height={NM_H}>
          <IOSDevice width={NM_W} height={NM_H}><ScreenPhase/></IOSDevice>
        </DCArtboard>
        <DCArtboard id="ob-stats" label="03 Eckdaten" width={NM_W} height={NM_H}>
          <IOSDevice width={NM_W} height={NM_H}><ScreenStats/></IOSDevice>
        </DCArtboard>
        <DCArtboard id="ob-children" label="04 Kinder-Setup" width={NM_W} height={NM_H}>
          <IOSDevice width={NM_W} height={NM_H}><ScreenChildren/></IOSDevice>
        </DCArtboard>
        <DCArtboard id="ob-confirm" label="05 Berechnung" width={NM_W} height={NM_H}>
          <IOSDevice width={NM_W} height={NM_H}><ScreenConfirm/></IOSDevice>
        </DCArtboard>
      </DCSection>

      <DCSection
        id="nm-empty"
        title="Empty States · 4 Screens"
        subtitle="Notebook-Ton, nicht klinisch. Inkl. Top Bar + Tab Bar im echten App-Kontext."
      >
        <DCArtboard id="em-today" label="Heute (leer)" width={NM_W} height={NM_H}>
          <IOSDevice width={NM_W} height={NM_H}><EmptyToday/></IOSDevice>
        </DCArtboard>
        <DCArtboard id="em-history" label="Verlauf (leer)" width={NM_W} height={NM_H}>
          <IOSDevice width={NM_W} height={NM_H}><EmptyHistory/></IOSDevice>
        </DCArtboard>
        <DCArtboard id="em-favorites" label="Favoriten (leer)" width={NM_W} height={NM_H}>
          <IOSDevice width={NM_W} height={NM_H}><EmptyFavorites/></IOSDevice>
        </DCArtboard>
        <DCArtboard id="em-safety" label="Food Safety (ok)" width={NM_W} height={NM_H}>
          <IOSDevice width={NM_W} height={NM_H}><EmptySafety/></IOSDevice>
        </DCArtboard>
      </DCSection>
    </DesignCanvas>
  );
}

window.NMTestFlightCanvas = NMTestFlightCanvas;
