# make_app.md — iOS App Workflow Index

> **Generieke workflow voor het bouwen van iedere nieuwe iOS-app van idee tot v1.0 (App Store live).**

Dit is de **index**. Lees voor elke nieuwe app eerst `architecture.md`, daarna doorloop je sequentieel de fases in `phases/`. Diepte-referenties (zoals `networking-resilience.md`, `security.md`) raadpleeg je per fase als specifieke onderwerpen aan de orde komen.

---

## Documentenstructuur

```
projectroot/
├── CLAUDE.md                      # ← project-specifieke Claude Code-instructies (uit CLAUDE.md.template)
└── docs/
    │
    │   # Index & per-project bestanden
    ├── make_app.md                # ← dit bestand (index)
    ├── features.md                # PROJECT-specifiek (uit features.md template)
    ├── dev-log.md                 # dagelijks log (3 regels: gedaan/blokt/morgen)
    ├── CLAUDE.md.template         # template — kopieer naar /CLAUDE.md per project
    │
    │   # Universele basis
    ├── architecture.md            # universele regels & architectuur-principes (18 secties)
    ├── app_store_readiness.md     # complete App Store submissie-checklist
    ├── autoagent.md               # Claude Code config (rate limits, push, permissions)
    ├── skills.md                  # slash-commands voor Claude Code (/sod, /eod, etc.)
    │
    │   # Diepte-referenties per onderwerp
    ├── networking-resilience.md   # retry, timeout, token refresh, offline queue
    ├── data-migration.md          # SwiftData/CoreData migrations + rollback
    ├── observability.md           # analytics, crash reporting, performance metrics
    ├── security.md                # Keychain, Data Protection, biometrics, ATS
    ├── testing-strategy.md        # test-pyramid, builders, snapshot, async
    ├── system-integration.md      # Universal Links, App Intents, widgets, Live Activities
    ├── localization.md            # plurals, RTL, locale-aware formatting
    ├── onboarding.md              # first-run, permission priming, empty states
    ├── build-configurations.md    # dev/staging/prod, xcconfig, schemes
    ├── storekit-iap.md            # IAP, subscriptions, restore, review prompts
    ├── push-notifications.md      # APNs, BGTasks, notification UX
    ├── release-management.md      # Phased Rollout, hotfix, certificate rotation
    ├── docc-documentation.md      # DocC voor Core/publieke API's
    │
    │   # Fasenwerk
    └── phases/
        ├── 00-discovery.md
        ├── 01-feature-collection.md
        ├── 02-architecture-setup.md
        ├── 03-core-domain.md
        ├── 04-infrastructure.md
        ├── 05-vertical-slice.md
        ├── 06-features.md
        ├── 07-polish-accessibility.md
        ├── 08-stabilisation.md
        ├── 09-app-store-readiness.md
        └── 10-pre-go-to-apple.md
```

---

## Fasenoverzicht

| # | Fase | Versie | Bestand | Diepte-refs |
|---|------|--------|---------|-------------|
| 0 | Discovery & scoping | — | `phases/00-discovery.md` | — |
| 1 | Feature-collectie | v0.1 | `phases/01-feature-collection.md` | — |
| 2 | Architectuur & projectopzet | v0.2 | `phases/02-architecture-setup.md` | `build-configurations.md` |
| 3 | Core-domein | v0.3 | `phases/03-core-domain.md` | `testing-strategy.md`, `docc-documentation.md` |
| 4 | Infrastructuur & integraties | v0.4 | `phases/04-infrastructure.md` | `networking-resilience.md`, `security.md`, `observability.md`, `data-migration.md` |
| 5 | Eerste verticale slice | v0.5 | `phases/05-vertical-slice.md` | `testing-strategy.md` |
| 6 | Resterende features | v0.6 | `phases/06-features.md` | `system-integration.md`, `push-notifications.md`, `storekit-iap.md` |
| 7 | UX-polish & accessibility | v0.7 | `phases/07-polish-accessibility.md` | `onboarding.md`, `localization.md` |
| 8 | Stabilisatie & testing | v0.8 | `phases/08-stabilisation.md` | `testing-strategy.md`, `data-migration.md` |
| 9 | App Store-readiness | v0.9 | `phases/09-app-store-readiness.md` + `app_store_readiness.md` | `release-management.md`, `storekit-iap.md`, `security.md` |
| 10 | Pre go-to-apple | v0.10 | `phases/10-pre-go-to-apple.md` | `release-management.md` |
| — | **App Store submission** | v1.0 | (geen bestand — direct in App Store Connect) | `release-management.md` |

---

## Hoe gebruik je dit pakket

### Bij start van een nieuw project

1. Kopieer hele `docs/` folder naar je nieuwe project.
2. Kopieer `CLAUDE.md.template` naar `<projectroot>/CLAUDE.md` en vul project-specifiek in.
3. Maak nieuwe `features.md` van template (of leeg, je vult tijdens Fase 1).
4. Lees `architecture.md` volledig — alleen één keer per project nodig.
5. Begin Fase 0 (`phases/00-discovery.md`).

### Per fase

1. Open de fase-md.
2. Check de "Diepte-referenties" lijst bovenaan — laad relevante extra docs in Claude Code.
3. Doorloop activiteiten + exit-gates.
4. Commit + tag bij gate-check.
5. Volgende fase.

### Bij specifieke uitdagingen

- **Network werkt niet stabiel?** → `networking-resilience.md`
- **Schema-wijziging?** → `data-migration.md`
- **Crash piek na release?** → `release-management.md` §13 quick reference
- **Permission-prompt design?** → `onboarding.md` §3
- **App Review rejection?** → check `app_store_readiness.md` § dat klopt met rejection-reason

---

## Werkprincipes

1. **Geen fase overslaan.** Fase 3 voelt traag, maar bespaart Fase 6 met factor 5.
2. **Geen fase samenvoegen.** Een gate is een gate. Fase 10 is geen formaliteit van Fase 9.
3. **Schrijf het op.** `/docs/` groeit per fase mee.
4. **Eén branch per fase** (`phase/3-core`, `phase/4-infra`) of main-trunk + tags.
5. **Bij twijfel: out-of-scope.** Elke nieuwe feature kost altijd 3× wat je denkt.
6. **Diepte-refs zijn niet optioneel als ze relevant zijn.** Push notifications zonder `push-notifications.md` lezen = bug-piek in Fase 8.

---

## Gebruik door Claude Code

- **Aan begin van sessie:** laad `architecture.md` + de fase waar je nu in zit.
- **Bij gate-check:** laad alleen het fase-bestand.
- **Bij specifiek onderwerp** (push, IAP, security): laad de bijbehorende diepte-ref.
- **Bij Fase 9 + 10:** laad `app_store_readiness.md` als volledige referentie + `release-management.md`.
- **Voor project-specifieke beslissingen:** raadpleeg `features.md` en `dev-log.md`.

Versie-discipline en commit-conventie staan in `architecture.md`.

---

## Snelle referentietabel: welk document voor welke vraag?

| Vraag | Document |
|-------|----------|
| Hoe doe ik retry met backoff? | `networking-resilience.md` §2 |
| Wanneer cert pinning gebruiken? | `networking-resilience.md` §6 |
| Hoe migreer ik mijn SwiftData-schema? | `data-migration.md` §2 |
| Welke events moet ik tracken? | `observability.md` §2-3 |
| Privacy Manifest events alignment? | `observability.md` §8 |
| Welke Keychain accessibility-class? | `security.md` §2 |
| Sign in with Apple implementatie? | `security.md` §6 |
| Hoe schrijf ik snapshot tests? | `testing-strategy.md` §5 |
| Hoe set ik Universal Links op? | `system-integration.md` §2 |
| App Intents voor Shortcuts? | `system-integration.md` §3 |
| Live Activity bouwen? | `system-integration.md` §5 |
| Pluralization in xcstrings? | `localization.md` §1 |
| RTL-support testen? | `localization.md` §3 |
| Permission priming pattern? | `onboarding.md` §3 |
| Empty state design? | `onboarding.md` §5 |
| dev/staging/prod scheidingen? | `build-configurations.md` §2-3 |
| StoreKit 2 implementatie? | `storekit-iap.md` §2 |
| Restore Purchases verplichting? | `storekit-iap.md` §3 |
| APNs setup met .p8 keys? | `push-notifications.md` §2 |
| BGTaskScheduler patroon? | `push-notifications.md` §7 |
| Phased Release strategy? | `release-management.md` §1 |
| Hotfix flow bij productie-incident? | `release-management.md` §4 |
| DocC catalog opzetten? | `docc-documentation.md` §3 |
