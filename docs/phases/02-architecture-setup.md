# Fase 2 — Architectuur & Projectopzet

> **Doel:** een leeg project dat compileert en de juiste vorm heeft.
> **Versie na afsluiten:** v0.2
> **Vorige fase:** [01-feature-collection.md](./01-feature-collection.md)
> **Volgende fase:** [03-core-domain.md](./03-core-domain.md)

---

## Activiteiten

### 1. Projecttooling kiezen

| Tool | Wanneer |
|------|---------|
| **Tuist** | Multi-module SPM, meerdere targets, team-werk |
| **XcodeGen** | Single-target, lichter alternatief, YAML-config |
| **SPM puur** | Klein project, geen iOS-app-target nodig |
| **Pure Xcode** | Alleen voor wegwerp-experimenten |

**Aanbeveling:** Tuist voor iOS-apps die naar de App Store gaan. Stelt je in staat features als modules te bouwen.

### 2. Mappenstructuur opzetten

Conform `architecture.md`:

```
AppName/
  App/
    AppNameApp.swift        # @main
    AppEnvironment.swift    # DI-container
    RootView.swift          # navigatie-root
  Core/
    Models/
    Protocols/
    UseCases/
    Errors/
    Utilities/
  Infrastructure/
    Network/
    Persistence/
    Keychain/
    Logging/
  Features/
    # vooralsnog leeg
  DesignSystem/
    Tokens/                 # kleuren, typo, spacing
    Components/             # herbruikbare views
    Modifiers/
  Resources/
    Assets.xcassets
    Localizable.xcstrings
  Tests/
    CoreTests/
    InfrastructureTests/
    Fakes/
```

### 3. AppEnvironment skelet

```swift
// App/AppEnvironment.swift
@MainActor
@Observable
final class AppEnvironment {
    // services worden hier geregistreerd in latere fases
    static let live = AppEnvironment()

    private init() {}
}
```

### 4. Feature flags (kill-switches vanaf dag 1)

Niet voor A/B-testen — als kill-switch en als TestFlight-only gating. Maak een simpele `FeatureFlags` in Core:

```swift
// Core/FeatureFlags.swift
public struct FeatureFlags: Sendable {
    public let enableStreaming: Bool
    public let enableExperimentalSearch: Bool
    public let enableJarvisBriefing: Bool

    public static let production = FeatureFlags(
        enableStreaming: true,
        enableExperimentalSearch: false,    // kapot in v1.1, uitgezet
        enableJarvisBriefing: false         // nog niet klaar voor App Review
    )

    public static let testFlight = FeatureFlags(
        enableStreaming: true,
        enableExperimentalSearch: true,
        enableJarvisBriefing: true          // testers mogen het zien
    )

    #if DEBUG
    public static let debug = FeatureFlags(
        enableStreaming: true,
        enableExperimentalSearch: true,
        enableJarvisBriefing: true
    )
    #endif
}
```

Selectie via build configuration of `Info.plist`:

```swift
// AppEnvironment.swift
let flags: FeatureFlags = {
    #if DEBUG
    return .debug
    #else
    return Bundle.main.isTestFlight ? .testFlight : .production
    #endif
}()
```

**Waarom dit nu en niet later:**

- Als feature X in productie kapot blijkt, zet je 'm uit met de volgende build — geen App Review-cyclus voor een hotfix-rollback.
- App Review-reviewers krijgen alleen `production` flags te zien — half-werkende features blijven onzichtbaar tot ze klaar zijn.
- TestFlight-testers krijgen meer dan productie — handig voor early feedback zonder risico.

Géén externe service (LaunchDarkly etc.) tenzij je het echt nodig hebt; één file in Core volstaat voor solo dev.

### 5. Code-kwaliteit tools

- **SwiftLint** — `.swiftlint.yml` in root
- **SwiftFormat** — `.swiftformat` in root
- **Pre-commit hook** — `.git/hooks/pre-commit` runt beide

### 6. CI-skelet

GitHub Actions of Xcode Cloud, minimaal:

- Trigger: push naar `main` + alle PR's
- Steps: build + test
- Cache: SPM dependencies

Voorbeeld GitHub Actions (`.github/workflows/ci.yml`):

```yaml
name: CI
on:
  push:
    branches: [main]
    paths-ignore: ['**.md', 'docs/**', '.github/ISSUE_TEMPLATE/**']
  pull_request:
    paths-ignore: ['**.md', 'docs/**']
jobs:
  build:
    runs-on: macos-15
    timeout-minutes: 30
    steps:
      - uses: actions/checkout@v4
      - uses: maxim-lobanov/setup-xcode@v1
        with: { xcode-version: latest-stable }
      - uses: actions/cache@v4
        with:
          path: |
            ~/Library/Developer/Xcode/DerivedData
            .build
          key: ${{ runner.os }}-spm-${{ hashFiles('**/Package.resolved') }}
      - run: xcodebuild test -scheme AppName -destination 'platform=iOS Simulator,name=iPhone 16'
```

#### CI usage-limits — let op je quota

macOS-runners op GitHub Actions verbruiken **10× zoveel minuten** als Linux-runners. Op het free tier (2.000 min/maand voor private repos) is dat effectief 200 macOS-minuten — die ben je sneller kwijt dan je denkt. Houd je quota klein door:

- **`paths-ignore`** voor docs- en config-changes (zie voorbeeld hierboven). Een commit naar `README.md` hoort geen 8 minuten CI te kosten.
- **`timeout-minutes: 30`** als hard plafond — voorkomt dat een hangende test je hele quota leegtrekt.
- **SPM cache** scheelt 30-60% per run.
- **Concurrency-cancelling** voor PR's: nieuwe push = oude run cancellen:
  ```yaml
  concurrency:
    group: ${{ github.workflow }}-${{ github.ref }}
    cancel-in-progress: true
  ```
- **Splits zware checks naar nightly:** UI-tests en integration tests hoef je niet bij elke push te draaien. Aparte workflow met `schedule: cron`.
- **Self-hosted runner** (eigen Mac) als je projecten veel bouwen — eenmalig setup, daarna gratis.

Houd één keer per maand `Settings → Billing → Plans and usage` open en kijk hoeveel je hebt verbruikt.

### 7. README.md

Minimaal:

- Project-omschrijving
- iOS-versie en Xcode-versie
- Setup-instructies (`tuist generate` of equivalent)
- Hoe tests draaien
- Architectuur-overzicht (link naar `docs/architecture.md`)

### 8. CHANGELOG.md

Keep a Changelog format. Eerste entry: v0.2 — Skeleton.

---

## Exit-gate

- [ ] `xcodebuild` slaagt zonder warnings
- [ ] `swiftlint` slaagt zonder errors
- [ ] Lege test draait groen
- [ ] CI is groen op een dummy commit
- [ ] Mappenstructuur conform `architecture.md`
- [ ] README.md bestaat en is up-to-date
- [ ] AppEnvironment-skelet aanwezig
- [ ] **`.gitignore`** compleet conform `architecture.md` §11 (Xcode + secrets)
- [ ] **`Info.plist`** baseline aanwezig: alleen permissions die je écht gaat gebruiken, met menselijke usage descriptions (`architecture.md` §12)
- [ ] **`FeatureFlags.swift`** in Core aanwezig met production/testFlight/debug varianten (kill-switch ready)
- [ ] **Branching-strategie** vastgelegd in README of `docs/architecture-decisions.md` (`architecture.md` §13)
- [ ] **`Package.resolved`** committen-of-ignoreren-keuze gemaakt conform `architecture.md` §14
- [ ] **Git-tag:** `v0.2-skeleton`
- [ ] CHANGELOG.md geüpdatet

---

## Anti-patterns

- ❌ "Ik configureer SwiftLint later." → Later komt niet. De regels die zich nu nestelen zijn moeilijker eruit te krijgen.
- ❌ Single Xcode-project zonder modules voor een groot project. → In Fase 6 heb je een onontwarbare kluwen.
- ❌ CI overslaan omdat je solo werkt. → CI vangt regression-bugs die jij in Fase 6 niet meer overziet.
- ❌ Tuist of XcodeGen niet committen. → Wat als je harde schijf crasht?

---

## Tips

- Een schoon skelet voelt traag, maar is in Fase 5-7 goud waard.
- Laat de pre-commit hooks vanaf dag 1 strict zijn — losser maken later kan, strenger maken later is pijnlijk.
