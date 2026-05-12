# architecture.md — Universele Architectuur & Regels

> Deze regels gelden in **élke fase** van elk iOS-project. Ze zijn niet onderhandelbaar tenzij Fase 0 expliciet een uitzondering vastlegt.

---

## 1. Architectuurprincipes

**Pragmatisch protocol-oriented met expliciete Core en modulaire features.**

### Core-laag (verplicht & framework-agnostisch)

- Geen `import SwiftUI`, `import UIKit`, of `import Foundation`-types die UI-gerelateerd zijn (bv. `UIImage`).
- Bevat:
  - `Core/Models/` — domeinmodellen (`struct`, `enum`)
  - `Core/Protocols/` — abstracties voor externe afhankelijkheden
  - `Core/UseCases/` — pure business logic (geen I/O)
  - `Core/Errors/` — typed errors per domein
  - `Core/Utilities/` — pure helpers (formatters, validators)

### Features (modulair)

- Elke feature is een eigen folder of SPM-module.
- Standaard structuur per feature:
  ```
  FeatureName/
    Views/          # SwiftUI views
    Stores/         # @Observable state containers (of ViewModels)
    Services/       # feature-specifieke services
    Models/         # feature-specifieke models (DTO's, view-models)
    Tests/
  ```
- **Features mogen alleen importeren uit:** `Core`, `DesignSystem`, `Infrastructure` (alleen via Core-protocols).
- **Features mogen NIET importeren uit:** andere features.

### Infrastructure-laag

- Concrete implementaties van Core-protocols.
- Bevat: networking, persistence, keychain, externe SDK-wrappers.
- Mag wél `Foundation`/`URLSession`/SDK's importeren.

### DesignSystem-laag

- Kleuren, typografie, spacing-tokens, herbruikbare components.
- Geen business logic.
- Mag importeren uit `Core` (voor model-bound views), niet uit features.

### App-laag

- `@main`, `AppEnvironment` (DI-container), root navigation.
- Bindt alles samen, kent alle modules.

---

## 2. Dependency Injection

- **Via initializers.** Geen singletons behalve `AppEnvironment`.
- `AppEnvironment` is de enige globale state-bron, gemaakt in `@main`.
- Mocks moeten triviaal zijn: protocol → fake-implementatie in `Tests/Fakes/`.

```swift
// Goed
final class ChatStore {
    private let provider: ChatProvider
    init(provider: ChatProvider) { self.provider = provider }
}

// Fout
final class ChatStore {
    private let provider = OpenAIProvider.shared  // ❌
}
```

---

## 3. Concurrency

- Swift 6 strict concurrency aan vanaf dag 1 (`SWIFT_STRICT_CONCURRENCY = complete`).
- Geen `@unchecked Sendable` zonder rationale-comment.
- Async/await over Combine voor nieuwe code.
- `@MainActor` op stores/view-models die UI-state bezitten.
- Tasks expliciet annuleren in `onDisappear` of `deinit`.

---

## 4. State Management

- **`@Observable` (iOS 17+) is de default** voor state-containers.
- `ObservableObject` alleen als legacy of third-party-noodzaak.
- Geen state in views zelf behalve UI-only (`@State` voor toggles, focus, etc.).
- Stores bezitten state, services manipuleren niets buiten hun eigen scope.

---

## 5. Project-bestanden

- **Geen directe `.pbxproj` edits.** Gebruik:
  - **Tuist** (aanbevolen voor multi-module),
  - **XcodeGen** (lichter alternatief),
  - of pure **SPM** (voor kleinere projecten).
- `.pbxproj` wel committen, maar genereren via tooling.
- Capability-changes via entitlement-files, niet via Xcode-UI.

---

## 6. Code-kwaliteit

- **SwiftLint** + **SwiftFormat** als pre-commit hook.
- Alle publieke API's hebben `///` doc comments.
- Geen `TODO` zonder issue-referentie of datum (`// TODO(2026-01): refactor when API v2 ships`).
- Geen `print`-statements in productiecode — gebruik `os.Logger`.
- Geen force-unwraps (`!`) buiten tests, behalve voor IBOutlet-equivalenten met expliciete rationale.

---

## 7. Testing

| Laag | Coverage-eis | Type |
|------|-------------|------|
| Core | ≥80% line coverage | Unit |
| Infrastructure | ≥60% (integration) | Integration |
| Stores/ViewModels | gedragstest per actie | Unit |
| Views | smoke-test | Snapshot of XCUITest (vanaf Fase 8) |

- Test-bestanden naast hun target: `FeatureA/` ↔ `FeatureATests/`.
- Fakes in `Tests/Fakes/`, gedeeld tussen modules.
- Geen network calls in unit tests.

---

## 8. Versie-discipline

- **Semver vanaf v0.1.**
- Elke fase-afsluiting = minor bump (v0.1 → v0.2 …).
- Git tag per fase-afsluiting: `v0.X-phase-N` (bv. `v0.3-phase-3`).
- `CHANGELOG.md` verplicht per bump (Keep a Changelog format).

---

## 9. Commit-conventie

**Conventional Commits:**

```
<type>(<scope>): <korte beschrijving>

[optionele body]

[optionele footer]

Co-authored-by: Claude <noreply@anthropic.com>
```

- **Types:** `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `perf`, `style`
- **Scope:** feature-naam of laag (`core`, `infra`, `feature-chat`)
- Max 72 tekens op de eerste regel.
- Eén logische verandering per commit.
- Geen commits zonder geslaagde build + tests voor de geraakte module.

---

## 10. Documentatie per project

Elk project heeft minimaal in `/docs/`:

- `vision.md` — uit Fase 0
- `features.md` — uit Fase 1, met MVP/v1.0/later/nooit-buckets
- `architecture-decisions.md` — ADR's voor afwijkingen van deze defaults
- `features/<naam>.md` — per feature-spec uit Fase 6

---

## 11. Beveiliging & secrets

- Secrets nooit in code of git.
- Lokaal: `.env` (in `.gitignore`) + `xcconfig`-overlay.
- Productie: Keychain.
- API-keys voor third-party SDK's: via build-config, nooit hardcoded.
- `.gitignore` minimum (Xcode + secrets):
  ```
  # Xcode
  *.xcuserstate
  xcuserdata/
  DerivedData/
  *.xcworkspace/xcuserdata/
  *.xcodeproj/xcuserdata/
  *.xcodeproj/project.xcworkspace/xcuserdata/

  # macOS
  .DS_Store

  # Swift PM
  .build/
  .swiftpm/
  Packages/
  Package.resolved          # commit voor apps, ignore voor libraries

  # CocoaPods (indien gebruikt)
  Pods/

  # Tuist / XcodeGen
  *.generated.swift
  Derived/

  # Secrets
  .env
  .env.*
  *.p8
  *.p12
  AuthKey_*.p8
  *.mobileprovision
  fastlane/.env
  fastlane/Appfile
  ```

---

## 12. Info.plist privacy descriptions

**Hard rejection-grond als je een API gebruikt zonder bijbehorende usage description.**

Voor élke permission die je app aanvraagt MOET er een uitleg-string in `Info.plist` staan. De string wordt aan de gebruiker getoond in de system permission prompt en moet **menselijk en specifiek** zijn — geen "We need access to camera."

Veelvoorkomende keys:

| Key | Wanneer |
|-----|---------|
| `NSCameraUsageDescription` | Camera-toegang |
| `NSMicrophoneUsageDescription` | Microfoon |
| `NSPhotoLibraryUsageDescription` | Foto's lezen |
| `NSPhotoLibraryAddUsageDescription` | Foto's opslaan |
| `NSLocationWhenInUseUsageDescription` | Locatie tijdens gebruik |
| `NSLocationAlwaysAndWhenInUseUsageDescription` | Locatie altijd |
| `NSContactsUsageDescription` | Contacten |
| `NSCalendarsUsageDescription` | Kalender |
| `NSRemindersUsageDescription` | Herinneringen |
| `NSBluetoothAlwaysUsageDescription` | Bluetooth |
| `NSLocalNetworkUsageDescription` | Lokaal netwerk (printers, smart home) |
| `NSFaceIDUsageDescription` | Face ID |
| `NSSpeechRecognitionUsageDescription` | Speech recognition |
| `NSMotionUsageDescription` | Motion sensors |
| `NSUserTrackingUsageDescription` | App Tracking Transparency |

**Regels:**

- Specifiek en gebruikersgericht: ❌ "We need camera." → ✅ "Om je profielfoto te maken."
- In de juiste talen — als je app gelocaliseerd is, lokaliseer ook deze strings via `InfoPlist.strings`.
- Geen permission aanvragen die je niet daadwerkelijk gebruikt (rejection-grond).
- Beschrijving moet matchen met werkelijk gebruik (Privacy Manifest moet hiermee corresponderen — zie `app_store_readiness.md` §1).

---

## 13. Branching-strategie

Solo dev, dus geen team-overhead, maar wel discipline:

### Default: trunk-based met fase-tags

- `main` is altijd buildable.
- Werk direct op `main` voor kleine commits.
- Voor grotere fases of risicovolle refactors: feature branch `feat/<naam>` of `phase/<n>-<naam>`.
- Elke fase-afsluiting krijgt een git tag (zie §8 versie-discipline).

### Wanneer feature branches verplicht

- Refactors die >1 dag duren.
- Experimentele features waarvan je niet zeker weet of ze de eindversie halen.
- Wanneer CI op `main` rood mag zijn betekent het dat je niet zorgvuldig genoeg werkt — gebruik dan een branch.

### Merge-regels

- **Squash merges** voor feature branches (één commit per feature in main-history).
- **Rebase** vóór merge om history schoon te houden.
- Geen merge commits van trivial branches.
- Branch verwijderen na merge.

### Vóór elke commit op `main`

1. Build slaagt lokaal.
2. Tests slagen lokaal voor de geraakte module.
3. SwiftLint + SwiftFormat hebben gerund (pre-commit hook).
4. Geen secrets gestaged (`git diff --cached` even visueel checken).

---

## 14. Dependency-management

Minder dependencies = minder onderhoudslast, minder supply-chain risico, snellere builds, kleinere binary.

### Voorkeursvolgorde

1. **Standard library** — kun je het oplossen zonder dependency? Doe dat.
2. **Apple frameworks** — `Foundation`, `Combine`, `CryptoKit`, etc. Eerst Apple, dan derden.
3. **Swift Package Manager (SPM)** — voor third-party dependencies. Native, geïntegreerd in Xcode.
4. **CocoaPods / Carthage** — alleen als de dependency geen SPM-support heeft. Vermijden waar mogelijk.

### SPM-regels

- **Pin versies, geen "latest".** Gebruik `.upToNextMinor(from:)` of exacte versies.
  - ✅ `.package(url: "...", .upToNextMinor(from: "1.4.0"))`
  - ❌ `.package(url: "...", branch: "main")`
  - ❌ `.package(url: "...", .upToNextMajor(from: "1.0.0"))` (te losse pin voor productie)
- **Commit `Package.resolved`** voor app-targets (reproduceerbare builds).
- **Library-targets:** `Package.resolved` in `.gitignore`.

### Audit-cadans

Elke 4-6 weken:

1. `swift package update` op een test-branch.
2. Check changelogs van bumped packages — breaking changes? Security fixes?
3. Run de full test suite.
4. Check binary size impact (Xcode → Show Build Folder → Products → .app size).
5. Merge alleen als alle drie groen zijn.

### Voor elke nieuwe dependency afwegen

- **Onderhouden?** Laatste commit <12 maanden, open issues niet gestapeld.
- **Licentie?** MIT/Apache/BSD oké, GPL meestal niet voor App Store apps.
- **Bundle size impact?** >1MB voor één feature = nadenken.
- **Aantal transitive deps?** Eén SDK die er 20 meebrengt = rood vlag.
- **Vervangbaar?** Als de maintainer morgen stopt, hoeveel werk is migratie?

### Te vermijden patronen

- Een dependency voor één enkele functie die je in 50 regels zelf had geschreven.
- Twee dependencies die hetzelfde doen (bv. twee networking libraries).
- "Deze SDK is populair, dus we gebruiken 'm" — populariteit is geen architectuur-argument.

---

## 15. Performance-defaults

### Main thread

- **Geen blocking work op main.** UI-updates wel (`@MainActor`), data-fetching/parsing/I/O nooit.
- **Detection:** als de UI ooit hapert tijdens scrolling of view-transitions, je hebt main-thread-werk.
- Tools: **Instruments → Time Profiler** (zie Fase 8) en **MainThreadChecker** in scheme settings (default aan).

```swift
// ❌ Fout — JSON parsing op main
@MainActor
func load() async throws {
    let data = try await client.fetch()
    self.items = try JSONDecoder().decode([Item].self, from: data)
}

// ✅ Goed — parsing off-main, assignment on-main
@MainActor
func load() async throws {
    let items = try await Task.detached {
        let data = try await client.fetch()
        return try JSONDecoder().decode([Item].self, from: data)
    }.value
    self.items = items
}
```

### Lazy loading in lijsten

- **Default:** `List` voor scrollbare data (built-in laziness + recycling).
- **`LazyVStack` / `LazyHStack`** in een `ScrollView` als je meer layout-controle nodig hebt dan `List` biedt.
- **Nooit `VStack` voor >20 items** — die rendert alles tegelijk, ook off-screen.

```swift
// ❌ Fout voor lange lijsten
ScrollView {
    VStack {
        ForEach(items) { ItemRow(item: $0) }
    }
}

// ✅ Goed
ScrollView {
    LazyVStack {
        ForEach(items) { ItemRow(item: $0) }
    }
}
```

### Image loading & caching

- **Lokale assets:** `Image("name")` is automatisch gecached door system.
- **Remote URLs:** `AsyncImage` heeft géén caching — gebruik dat alleen voor wegwerp-images.
- **Voor remote images met caching, kies één:**
  - **Nuke** (SPM, lichtgewicht, snel).
  - **Kingfisher** (SPM, populair, breed feature-set).
  - **Custom met `URLCache`** voor minimale dependencies.
- **Decode op de juiste thread:** image decoding hoort niet op main. Bovenstaande libraries doen dit goed; `AsyncImage` ook.
- **Memory pressure handling:** observeer `UIApplication.didReceiveMemoryWarningNotification` of gebruik library die dit afhandelt.

### App launch time

- **Doel:** <2s op het oudste ondersteunde device.
- **Meet vanaf dag 1:** Xcode → Edit Scheme → Run → Diagnostics → "Performance Logging" of MetricKit `MXAppLaunchMetric`.
- **Veroorzakers van trage launch:**
  - Te veel werk in `App.init()` of `@main`-struct.
  - Synchroon laden van persistent store op main.
  - Veel dynamic libraries (elk kost startup-tijd).
  - Heavy `onAppear` op het rootscherm.
- **Strategie:** root-view rendert eerst skeleton/splash → echte data laadt erna in.

### Algemene regels

- **Profile, don't guess.** Geen optimalisatie zonder Instruments-meting.
- **Premature optimization is bug-bait.** Eerst werkend, dan profileren, dan optimaliseren — in die volgorde.
- **Performance-budget per feature:** "scherm X opent in <500ms" of "lijst Y scrollt jank-free met 1000 items." Zonder budget weet je niet wat snel genoeg is.

---

## 16. Wanneer afwijken?

Afwijken mag, maar leg het vast in `docs/architecture-decisions.md` als ADR:

```markdown
# ADR-001: TCA gebruiken voor de complexe editor-feature

## Context
[waarom de default niet voldoet]

## Beslissing
[wat we doen]

## Gevolgen
[wat dit betekent voor onderhoud, testing, dependencies]
```

---

## 17. Code Review met Jezelf (solo dev)

Je hebt geen team. Daarom moet je discipline pakken in plaats van peer-review. Drie tactieken:

### Pre-commit zelf-review checklist

Vóór elke commit, doorloop:
- [ ] Heb ik tests geschreven voor de bug/feature?
- [ ] Werkt de happy path én minstens één error path?
- [ ] Voldoet aan SwiftLint zonder warnings?
- [ ] Geen `print()`-statements of debug-comments achtergelaten?
- [ ] Heb ik secrets/PII per ongeluk gestaged?
- [ ] Past dit binnen de `architecture.md` regels (Core mag geen UIKit, etc.)?

### "Slaap er een nacht over" voor risico-werk

Risico-vol = migration, security-flow, payment-flow, complexe concurrency. Plan zo dat je 24 uur tussen "klaar" en "merge" kunt nemen. De volgende dag herlees je je eigen diff alsof iemand anders het schreef. Je vindt elke keer iets.

### Architecture retrospectives elke 2-3 fases

Aan het einde van elke fase: 15 minuten reflectie. Schrijf in `docs/dev-log.md`:
- Wat ging vlot?
- Welke patronen heb ik 3+ keer herhaald? (kandidaat voor extractie)
- Welke beslissing zou ik anders maken?

Dat geeft je een micro-review-cyclus die teams hebben in retrospectives.

### Tools die helpen

- **SwiftLint custom rules** — codifeer je conventies in `swiftlint.yml`. Zelfs op één-persoons-project is dit nuttig: vergeetachtigheid van vandaag-jij wordt gedetecteerd door rules van vorige-week-jij.
- **Periereview** met Claude Code: vraag eens per fase: "Review deze module zoals een senior iOS-engineer zou doen. Focus op: concurrency, dependency injection, edge cases."
- **Git diff lezen** vóór commit (`git diff --staged`). Niet `git commit -am "wip"`.

---

## 18. App Thinning, On-Demand Resources, App Clips

Korte referenties naar advanced topics — diepe behandeling alleen als relevant voor je app.

### App Thinning (default — niets te doen)

iOS levert per device alleen de juiste assets:
- **Slicing** — alleen relevante asset-resolutions per device.
- **Bitcode** (deprecated sinds Xcode 14, niet meer relevant).
- **On-Demand Resources** — zie hieronder.

**Wat jij doet:** gebruik Asset Catalog correct (1x/2x/3x of vector). Apple regelt de rest.

### On-Demand Resources (ODR)

Voor apps met grote optionele assets (game-levels, tutorials).
- Tag asset met `Resource Tag` in Asset Catalog of file inspector.
- Download tijdens runtime via `NSBundleResourceRequest`:

```swift
let request = NSBundleResourceRequest(tags: ["level-3"])
try await request.beginAccessingResources()
// Use resources
request.endAccessingResources()
```

**Wanneer overwegen:** je app is >150 MB en veel assets zijn optioneel.
**Niet voor:** elke kleine asset — overhead niet waard.

### App Clips

Lichte versie van je app (max 10 MB) die zonder install draait — via QR-code of NFC-tag.
- New Target → App Clip
- Aparte bundle ID (`com.company.app.Clip`)
- Subset van features
- Kan gebruiker vragen full app te installen

**Wanneer overwegen:** retail/restaurant/parking-apps waar één-tijdige snelle interactie waardevol is.

### StoreKit Test framework

Zie `storekit-iap.md` §9. Maakt unit-tests mogelijk voor IAP zonder echte StoreKit-server.

### Xcode Cloud

Apple's CI/CD-as-a-service. Voor- en nadelen:
- ✅ Native integration met App Store Connect.
- ✅ Geen eigen runners onderhouden.
- ❌ Compute-uren beperkt op gratis tier.
- ❌ Minder flexibel dan GitHub Actions / GitLab CI.

**Vuistregel:** GitHub Actions voor het meeste werk, Xcode Cloud alleen als je heel diep in Apple-ecosysteem zit.
