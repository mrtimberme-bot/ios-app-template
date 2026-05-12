# iOS App Development Workflow

> De volledige lifecycle van idee tot App Store, en verder.  
> Elke fase heeft een Claude Code commando. 99% van het werk is geautomatiseerd.

## Documentatie

De volledige workflow-documentatie staat in `docs/`:

| Document | Doel |
|---------|------|
| [`docs/make_app.md`](docs/make_app.md) | **Start hier** — index van alle fases en docs |
| [`docs/architecture.md`](docs/architecture.md) | Universele architectuurregels (lees vóór fase 0) |
| [`docs/phases/`](docs/phases/) | 11 fases (00-discovery t/m 10-pre-go-to-apple) |
| [`docs/autoagent.md`](docs/autoagent.md) | Claude Code autonome permissions + rate limit handling |
| [`docs/skills.md`](docs/skills.md) | Alle slash-commands en hoe ze werken |
| [`docs/app_store_readiness.md`](docs/app_store_readiness.md) | Complete App Store compliance checklist |
| [`docs/features.md`](docs/features.md) | Template voor feature-collectie (Fase 1) |
| [`docs/dev-log.md`](docs/dev-log.md) | Dagelijks 3-regels log (gedaan/blokt/morgen) |

**Diepte-referenties** (raadplegen per fase als onderwerp aan de orde komt):

`networking-resilience.md` · `security.md` · `testing-strategy.md` · `data-migration.md` ·
`observability.md` · `system-integration.md` · `localization.md` · `onboarding.md` ·
`build-configurations.md` · `storekit-iap.md` · `push-notifications.md` ·
`release-management.md` · `docc-documentation.md`

---

---

## Overzicht

```
FASE 1  Initiation      /new-app          ~30 min   90% auto
FASE 2  Architecture    /plan-feature     ~2u       85% auto
FASE 3  Development     dagelijkse loop   doorlopend 95% auto
FASE 4  Pre-submission  /audit            ~2u       98% auto
FASE 5  Publication     /ship             ~1u       85% auto
FASE 6  Post-launch     /post-launch      dag 1/7/30 70% auto
FASE 7  Update cycle    → terug naar fase 3         95% auto
        Template sync   /template-sync    maandelijks 80% auto
```

---

## PRE-FASE — Market Research

**Doel:** Vóór je begint te bouwen: weten of je het juiste probleem oplost en waar de markt open ligt.

```
/competitor-research    ← top 50 apps analyseren, feature matrix, review mining
```

Output:
- `docs/research/feature-matrix.md` — alle features van concurrenten, Kano + ICE geclassificeerd
- `docs/research/review-insights.md` — onvervulde behoeften uit App Store reviews
- `docs/research/perceptual-map.md` — positionering ten opzichte van markt

Zie `docs/competitor-research.md` voor het volledige framework.  
Zie `docs/workflow-gaps-analysis.md` voor de volledige analyse van wat professionele workflows extra doen.

---

## FASE 1 — Initiation

**Doel:** Nieuwe app in ~30 minuten klaarstaat om aan te werken.

### Start

```
claude        ← open Claude Code in de Template directory
/new-app
```

Claude vraagt:
1. Wat lost de app op? (1 zin)
2. Voor welke gebruiker specifiek?
3. Wat is het één-dag succescriterium?
4. App naam, bundle ID, team ID

Daarna volledig automatisch:
- GitHub repo aanmaken vanuit `ios-app-template`
- Repo clonen naar `~/Development/<AppNaam>`
- Alle `{{placeholders}}` vervangen via `scripts/setup.sh`
- CLAUDE.md configureren
- GitHub Actions secrets instructies

### Handmatig (niet te automatiseren)

| Stap | Waar | Waarom handmatig |
|------|------|-----------------|
| Bundle ID registreren | developer.apple.com → Identifiers | Apple vereist MFA |
| Xcode project genereren | `xcodegen generate` dan `open *.xcodeproj` | GUI-actie |
| Signing instellen | Xcode → Target → Signing & Capabilities | Apple-account vereist |

### Daarna

```
/setup-certs     ← code signing (eenmalig per app)
```

---

## FASE 2 — Architecture Decision

**Doel:** Technische keuzes vastleggen vóór je begint te bouwen.

```
/plan-feature    ← gebruik dit voor de eerste architectuursessie
```

Leg vast in `docs/architecture/decisions.md`:
- State management: @Observable voldoende? Of TCA nodig?
- Persistence: SwiftData (standaard) of iets anders?
- Externe services: API-integraties, Claude API, backend?
- Monetization: gratis, StoreKit IAP, of subscriptions?
- Onboarding: nodig of direct naar content?

**StoreKit 2 activeren** (als gekozen):
- Verwijder de commentaar in `Services/StoreKit/PurchaseService.swift`
- Voeg StoreKit toe aan Xcode capabilities
- Update `PrivacyInfo.xcprivacy`

---

## FASE 3 — Development Loop

**Doel:** Features bouwen in beheerbare blokken. Eén blok = één feature = één branch = één PR.

### Dagelijkse routine

```
/sod              ← begin van de dag: context laden, CI status, app store check
```

Claude toont:
- Waar je gisteren was gebleven
- Open PRs en CI status
- App Store review status (als app live is)
- Aanbeveling voor vandaag

```
/plan-feature     ← plan één feature (output → docs/tasks/<naam>-plan.md)
/start-feature    ← maak feature branch aan
```

Dan: implementeer de feature. Claude Code doet het zware werk.

```
/wrap-feature     ← audit, commit, push, PR aanmaken
/eod              ← dag afsluiten: daily log, uncommitted check, notificatie
```

### Blok-grootte richtlijn

| Blok-omvang | Actie |
|-------------|-------|
| 2-6 uur werk | ✅ Normaal blok |
| > 6 uur | ✂️ Splitsen in sub-blokken |
| < 30 min | 🔗 Samenvoegen met ander blok |

### Handige commando's tussendoor

| Commando | Wanneer |
|---------|---------|
| `/quick-audit` | Snelle check tijdens development |
| `/fix-ci` | CI faalt en je weet niet waarom |
| `/design-review` | UI klaar, wil feedback |
| `/accessibility-check` | Accessibility review |
| `/cost-check` | Claude API kosten controleren |
| `/notify "bericht"` | Push notificatie naar iPhone |

### CI draait automatisch

Bij elke push:
- SwiftLint (strict)
- Gitleaks (secret scan)
- Build (alle branches)
- Tests (alleen op `main`)

---

## FASE 4 — Pre-submission

**Doel:** App klaarstomen voor App Store Review. Claude doet de volledige audit.

```
/audit
```

Controleert automatisch:
- App Store Review Guidelines
- Privacy manifest (`PrivacyInfo.xcprivacy`)
- Accessibility (VoiceOver, Dynamic Type, contrast)
- HIG compliance
- Security (Keychain, network, secrets)
- SwiftLint clean

Bij **CRITICAL** issues: blokkade, moet opgelost voor je verder gaat.  
Bij **MEDIUM** issues: keuze — fix nu of accepteer het risico.

### Handmatig

| Stap | Actie |
|------|-------|
| Screenshots | Genereer via `fastlane screenshots` of handmatig |
| App Store metadata | Controleer `fastlane/metadata/` (beschrijving, keywords) |
| Privacy policy URL | Moet ergens gehost zijn (bijv. GitHub Pages) |
| What's New tekst | Schrijf voor elke versie |

---

## FASE 5 — Publication

**Doel:** App in de App Store krijgen.

```
/ship
```

Volledig automatisch:
1. `/audit` uitvoeren (blokkeert bij failures)
2. Version bump (patch/minor/major — jij kiest)
3. CHANGELOG.md updaten
4. `fastlane match appstore` (certificaten refreshen)
5. `fastlane gym` (archive build)
6. `fastlane pilot` (TestFlight upload)
7. Poll tot build verwerkt is

Dan: **⏸ pauze — test de TestFlight build handmatig**

Na jouw goedkeuring:
8. `fastlane deliver` (App Store submission)
9. Git tag aanmaken (`v1.0.0`)
10. GitHub Release aanmaken

### Tijdlijn na submission

| Stap | Gemiddelde tijd |
|------|----------------|
| Apple Review | 1-3 werkdagen |
| Expedited review (bij bugs) | ~24u (aanvragen via App Store Connect) |

---

## FASE 6 — Post-launch

**Doel:** Stabiliteit bewaken en gebruikersfeedback verwerken.

```
/post-launch dag1
/post-launch dag7
/post-launch dag30
```

### Dag 1 — Stabiliteitscheck

Focus: is er niks kapot?

| Crash rate | Actie |
|-----------|-------|
| > 5% | Hotfix vandaag, overweeg intrekken |
| 2-5% | Hotfix binnen 24 uur |
| 1-2% | Monitor 24u, hotfix als aanhoudend |
| < 1% | ✅ Goed, niets te doen |

### Dag 7 — Gebruikerssignalen

- Lees alle reviews van de eerste week
- Patronen identificeren (3+ gelijkaardige opmerkingen = actie)
- GitHub issues aanmaken voor bugs
- Feature requests toevoegen aan backlog

### Dag 30 — Update planning

- App Analytics bekijken: welke features worden gebruikt?
- Feedback samenvatten → volgende versie plannen
- Beslis: patch (bugfixes) / minor (features) / niks

---

## FASE 7 — Update Cycle

Na lancering ga je terug naar **Fase 3** voor elke update.

**Verschil met eerste lancering:**
- App Store reviews geven richting aan wat er gebouwd wordt
- `/post-launch` informeert de backlog-prioritering
- `/ship patch` voor hotfixes (geen audit nodig voor kleine bugfixes)
- `/ship minor` voor feature updates (wel audit)

---

## Template Evolutie

**Doel:** Verbeteringen die je leert terugbrengen naar de template zodat de volgende app er automatisch van profiteert.

```
/template-sync    ← wekelijks (maandag, via /sod geïntegreerd)
```

Wat het doet:
- Kijkt welke updates er in `ios-app-template` zijn since laatste sync
- Toont diff per categorie (CI, commands, skills, CLAUDE.md)
- Vraagt selectief welke updates toe te passen
- Commit als `chore: sync with ios-app-template`

### Verbetering terugsturen

Als je iets beters ontdekt in je app:
1. Open een issue op `github.com/mrtimberme-bot/ios-app-template`
2. Of maak een PR met de verbetering
3. Na merge → volgende `/template-sync` brengt het naar andere apps

---

## Alle commando's op één plek

### Lifecycle commando's

| Commando | Fase | Wat het doet |
|---------|------|-------------|
| `/competitor-research` | Pre-fase | Top 50 apps analyseren, feature matrix, Kano + ICE |
| `/new-app` | Initiation | Nieuwe app aanmaken vanuit template |
| `/setup-certs` | Initiation | Fastlane match code signing instellen |
| `/plan-feature` | Development | Feature plannen met ultrathink |
| `/start-feature` | Development | Feature branch aanmaken |
| `/wrap-feature` | Development | Feature afronden, PR aanmaken |
| `/audit` | Pre-submission | Volledige App Store audit |
| `/ship` | Publication | Build → TestFlight → App Store |
| `/post-launch` | Post-launch | Dag 1/7/30 monitoring |
| `/template-sync` | Ongoing | Template verbeteringen binnenhalen |

### Dagelijkse commando's

| Commando | Wanneer |
|---------|---------|
| `/sod` | Elke ochtend als eerste |
| `/eod` | Elke avond als laatste |
| `/morning-brief` | Snelle status zonder actieplan |

### Hulp commando's

| Commando | Wanneer |
|---------|---------|
| `/quick-audit` | Snelle check tijdens development |
| `/fix-ci` | CI faalt |
| `/design-review` | UI feedback vragen |
| `/accessibility-check` | Accessibility review |
| `/cost-check` | API kosten bekijken |
| `/remove-feature` | Feature veilig verwijderen |
| `/autonomous-feature` | Feature volledig autonoom bouwen |
| `/notify "tekst"` | Push notificatie naar iPhone |

---

## Handmatige stappen (onvermijdelijk)

Deze stappen **kunnen nooit worden geautomatiseerd** vanwege Apple-beleid of veiligheid:

| Stap | Fase | Reden |
|------|------|-------|
| Bundle ID registreren | Initiation | Apple Developer Portal vereist MFA |
| Xcode signing instellen | Initiation | Apple-account in GUI vereist |
| App Store screenshots | Pre-submission | Visuele content, menselijk oordeel |
| TestFlight build testen | Publication | Functionele verificatie door mens |
| App Review afwachten | Publication | Apple-proces, niet te beïnvloeden |
| Privacy policy URL | Pre-submission | Extern document, extern gehost |
| Eerste certificaten aanmaken | Initiation | Apple PKI vereist eenmalige GUI-actie |

---

## Mapstructuur na setup

```
~/Development/
└── <AppNaam>/
    ├── <AppNaam>/              Xcode app target
    │   ├── App/                @main entry, root views
    │   ├── Features/           Feature modules (zelfstandig)
    │   ├── Services/           Cross-feature services, Keychain, StoreKit
    │   ├── DesignSystem/       Tokens + reusable components
    │   ├── Models/             Shared data models
    │   ├── Utilities/          Helpers + Logger setup
    │   └── Resources/          Assets, PrivacyInfo.xcprivacy
    ├── Packages/
    │   ├── AppUI/              Lokaal SPM package (UI components)
    │   └── CoreKit/            Lokaal SPM package (utilities)
    ├── fastlane/               Release automation
    │   └── metadata/en-US/     App Store teksten
    ├── docs/
    │   ├── tasks/              Plans + daily-log
    │   ├── architecture/       Architectuur beslissingen (ADRs)
    │   ├── design/             Design beslissingen
    │   ├── audit/              Pre-submit rapporten
    │   └── release/            Checklists + post-launch log
    ├── .github/workflows/      CI/CD (SwiftLint + Build + Test)
    ├── scripts/setup.sh        Post-clone setup script
    ├── project.yml             XcodeGen configuratie
    ├── CLAUDE.md               Claude Code instructies voor dit project
    ├── AGENTS.md               Codex agent instructies
    └── WORKFLOW.md             Dit document
```

---

## Snelstart voor nieuwe app (TL;DR)

```bash
# 1. Open Claude Code
claude   # in ~/Development/Template of een lege map

# 2. Start de wizard
/new-app

# 3. Volg de instructies (Bundle ID handmatig in Apple portal)

# 4. Signing + certs
/setup-certs

# 5. Begin ontwikkelen
/sod
/plan-feature
```

Klaar. De rest doet de workflow.
