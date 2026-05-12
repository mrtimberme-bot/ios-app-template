# Fase 8 — Stabilisatie & Testing

> **Doel:** crash-vrij en bug-arm krijgen.
> **Versie na afsluiten:** v0.8
> **Vorige fase:** [07-polish-accessibility.md](./07-polish-accessibility.md)
> **Volgende fase:** [09-app-store-readiness.md](./09-app-store-readiness.md)

> **Diepte-referenties voor deze fase:**
> - [`testing-strategy.md`](../testing-strategy.md) — UI tests, snapshot tests, test-pyramid
> - [`data-migration.md`](../data-migration.md) — migration testing op gevulde stores
> - [`observability.md`](../observability.md) §5 — crash reporting setup

---

## Activiteiten

### 1. TestFlight Internal Build

- Archive maken: Product → Archive in Xcode (op fysiek device, niet simulator).
- Upload naar App Store Connect.
- Internal testers toevoegen (max 100, geen review nodig).
- Stabiele build draait minimaal 7 dagen bij intern gebruik vóór Fase 9.

### 2. Crash reporting

Kies één:

| Tool | Voordeel | Nadeel |
|------|----------|--------|
| **Xcode Organizer (MetricKit)** | Gratis, native | Beperkte info, vertraging |
| **Sentry** | Realtime, breadcrumbs | Privacy: data verlaat device |
| **Bugsnag** | Realtime, goede UI | Kost geld na gratis tier |
| **Firebase Crashlytics** | Gratis, breed | Google in je stack |

Voor privacy-bewuste apps: MetricKit + custom on-device aggregator.

### 3. Memory leaks checken

Instruments → **Leaks** template:

- Run de app, doe een complete user flow.
- Check op rode markers (leaks).
- Veelvoorkomende oorzaken in SwiftUI:
  - Strong reference cycles in closures (gebruik `[weak self]`)
  - Niet-geannuleerde `Task`s
  - Combine subscriptions niet opgeruimd

Instruments → **Allocations**:

- Memory-gebruik tijdens normale flow ≤200MB voor de meeste apps.
- Geen onbegrensde groei (memory leak signature).

### 4. Performance

- **App launch:** <2s op het oudste ondersteunde device.
- **Scroll-performance:** geen jank in lijsten met 1000+ items.
- **Heavy operations** op background queue, niet op main.

Tool: Instruments → **Time Profiler**.

### 5. Edge cases doorlopen

| Scenario | Wat te checken |
|----------|---------------|
| **Geen netwerk** | Error states, retry, cached data |
| **Slecht netwerk** | Network Link Conditioner — 3G/Edge/Loss |
| **Lege state** | Eerste install, niks geconfigureerd |
| **Max state** | Veel data, lange lijsten, grote files |
| **Achtergrond → voorgrond** | Tokens nog geldig? Refresh nodig? |
| **Low Battery / Low Power Mode** | Animaties uitzetten? Reduce sync? |
| **Storage vol** | Graceful failure |
| **Locale-switch** | App reageert op locale-verandering |
| **Time-switch** | App reageert op timezone-verandering |
| **Push-notificatie binnen app** | Correct gehandeld |

### 6. Bug-bash sessie

Solo-bug-bash:

- Eén uur expliciet je app proberen te breken.
- Tap dingen meermaals snel achter elkaar.
- Roteer mid-action.
- Force-quit en heropen tijdens lange operaties.
- Vlieg-mode aan/uit tijdens netwerk-call.
- Backgrounden tijdens upload.

Houd lijst bij in `/docs/bug-list.md` met categorisatie:

- **P0** — crash, dataverlies, kernfunctionaliteit kapot → fix nu
- **P1** — werkt niet zoals bedoeld in normale flow → fix vóór gate
- **P2** — edge case, cosmetisch → documenteer voor v1.0

### 7. Tests uitbreiden

- **UI-tests** voor primaire user flows (XCUITest of Xcode Cloud workflows).
- **Snapshot tests** voor key views (gebruikt swift-snapshot-testing of vergelijkbaar).
- Smoke test bij elke commit in CI.

### 8. Compatibility-tests

- Test op je minimum iOS-versie (haal een ouder device of gebruik simulator).
- Test op het kleinste device (iPhone SE).
- Test op het grootste device (iPad Pro indien ondersteund).
- Test op zowel ProMotion (120Hz) als 60Hz schermen.

---

## Exit-gate

- [ ] TestFlight-build draait minimaal 7 dagen zonder crash bij intern gebruik
- [ ] 0 P0-bugs
- [ ] ≤3 P1-bugs (gedocumenteerd voor v1.0)
- [ ] Geen memory leaks in core flows (Instruments-rapport schoon)
- [ ] App launch <2s op minimum-spec device
- [ ] **Main Thread Checker** geeft geen warnings tijdens primaire flows (`architecture.md` §15)
- [ ] **Time Profiler-run** uitgevoerd; geen functies >16ms op main thread tijdens scroll/transitions
- [ ] **Dependency-audit** uitgevoerd: changelogs gecheckt, security-advisories gescand, geen unused deps (`architecture.md` §14)
- [ ] Crash reporting actief en geverifieerd (test crash gestuurd en ontvangen)
- [ ] Edge cases uit tabel doorlopen
- [ ] UI-tests voor primaire flows aanwezig
- [ ] Compatibility getest op minimum iOS + smallest + largest device
- [ ] **Git-tag:** `v0.8-stable`
- [ ] CHANGELOG.md geüpdatet

---

## Anti-patterns

- ❌ "Bij mij werkt het." → Test op fysiek device, niet alleen simulator.
- ❌ Memory profiling overslaan. → SwiftUI is verraderlijk met retain cycles.
- ❌ Crash reporting pas na launch toevoegen. → Je mist de TestFlight-data.
- ❌ Edge cases negeren omdat ze "zelden voorkomen". → Reviewers vinden ze altijd.

---

## Tips

- Maak van bug-bash een wekelijkse gewoonte tot Fase 9.
- Vraag een vriend (niet-tech) je app te gebruiken zonder uitleg. Kijk wat ze doen. Vragen ze waar ze moeten klikken? Bug.
- Network Link Conditioner staat in Apple's "Additional Tools for Xcode" download.
