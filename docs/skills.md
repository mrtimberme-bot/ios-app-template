# skills.md — Claude Code Slash-Commands & Skills

> **Generieke set commando's** die in elk iOS-project werken dat de `make_app.md`-workflow volgt. Plaats elk command als losse file in `.claude/commands/<naam>.md` per project, of in `~/.claude/commands/` voor globaal gebruik.

---

## Categorieën

1. **Daily flow** — `/sod`, `/eod`, `/status`
2. **Phase flow** — `/phase-start`, `/phase-gate`, `/phase-close`
3. **Feature flow** — `/feature-spec`, `/feature-start`, `/feature-wrap`
4. **Quality** — `/audit`, `/lint`, `/test`, `/perf-check`
5. **Pre-submit** — `/pre-submit-check`, `/screenshot-audit`
6. **Utility** — `/dev-log`, `/changelog`, `/find-todos`

---

## 1. Daily flow

### `/sod` — Start of Day

**Doel:** dagstart-ritueel dat je in 30 seconden in het project zet.

**Wat het doet:**
1. Leest `docs/dev-log.md` (laatste 3 entries)
2. Leest `docs/make_app.md` voor huidige fase-context
3. Leest `CLAUDE.md` voor project-specifics
4. Toont `git status` + `git log --oneline -5`
5. Leest huidige fase-bestand uit `docs/phases/`
6. Vraagt: "Wat wil je vandaag bereiken? Welk exit-gate-item ga je sluiten?"
7. Wacht op antwoord, stelt implementatievolgorde voor
8. Wacht op bevestiging vóór code-werk

**Implementatie — `.claude/commands/sod.md`:**

```markdown
# /sod — Start of Day

Voer aan begin van elke werksessie uit.

Stappen:
1. Lees deze files in volgorde:
   - `docs/dev-log.md` (laatste 3 entries)
   - `CLAUDE.md` (project-specifieke instructies)
   - `docs/make_app.md` (om huidige fase te bepalen)
   - `docs/phases/0X-*.md` voor de actieve fase
2. Run `git status` en `git log --oneline -5`
3. Identificeer:
   - In welke fase zitten we?
   - Welke exit-gate-items staan nog open?
   - Wat was de laatste blocker uit dev-log?
4. Vraag de user: "Wat wil je vandaag bereiken?
   Open exit-gate items zijn: [lijst]. Vorige blocker was: [...]."
5. Wacht op antwoord. Stel implementatievolgorde voor: 1) X, 2) Y, 3) Z.
6. Wacht op bevestiging vóór code-wijzigingen.

Output: korte recap + voorgesteld dagplan.
Notify de user als plan klaar is voor review.
```

---

### `/eod` — End of Day

**Doel:** schone afsluiting met logging zodat morgen vlot start.

**Wat het doet:**
1. Toont `git status` — uncommitted changes?
2. Vraagt of die nog gecommit moeten worden
3. Schrijft entry in `docs/dev-log.md`:
   - Datum
   - Wat bereikt (uit git log van vandaag)
   - Wat blokt
   - Wat morgen
4. Update `CHANGELOG.md` als er een fase-gate gehaald is
5. Verifieert dat alles op remote staat (alleen melden, niet pushen — push gaat via `permissions.ask`)

**Implementatie — `.claude/commands/eod.md`:**

```markdown
# /eod — End of Day

Voer uit vóór sessie sluit.

Stappen:
1. Run `git status`. Als uncommitted changes: vraag of die gecommit moeten.
2. Run `git log --since="midnight" --oneline` voor de dagelijkse delivery.
3. Schrijf nieuwe entry in `docs/dev-log.md`:
   ## YYYY-MM-DD
   **Gedaan:** [bullet uit git log, in eigen woorden]
   **Blokt:** [vraag aan user, of skip als niets]
   **Morgen:** [vraag aan user, of leid af uit openstaande exit-gate items]
4. Als een fase-gate vandaag is afgesloten: update CHANGELOG.md.
5. Run `git status` op remote (`git fetch && git status`). Als lokaal vooruit:
   meld dit, vraag of we moeten pushen (gaat via permissions.ask).
6. Notify: "✅ EOD klaar — entry in dev-log.md, tot morgen."

Output: dev-log entry + status of remote sync.
```

---

### `/status` — Snelle status

**Doel:** waar staan we, zonder volledige SOD-flow.

**Implementatie — `.claude/commands/status.md`:**

```markdown
# /status

Korte status zonder volledige context-load.

Stappen:
1. Toon huidige fase + versie uit `docs/make_app.md` of laatste git tag.
2. Toon `git log --oneline -5`.
3. Toon `git status` (uncommitted, branch).
4. Toon laatste dev-log entry.
5. Toon openstaande exit-gate items voor huidige fase.

Output: kort overzicht in <15 regels.
```

---

## 2. Phase flow

### `/phase-start` — Begin nieuwe fase

**Doel:** structuur aan het begin van een fase.

**Implementatie:**

```markdown
# /phase-start [fase-nummer]

Stappen:
1. Lees `docs/phases/<fase-nummer>-*.md`.
2. Lees `docs/architecture.md` voor universele regels.
3. Maak optioneel een feature branch `phase/<n>-<slug>`.
4. Voeg dev-log entry toe met "Begin Fase X" en de exit-gate items.
5. Vraag de user: "Welk activiteit beginnen we mee uit fase X?"

Output: fase-overzicht + suggestie voor eerste activiteit.
```

---

### `/phase-gate` — Check exit-gate

**Doel:** verifieer alle exit-criteria voor de huidige fase voordat je `/phase-close` doet.

**Implementatie:**

```markdown
# /phase-gate

Stappen:
1. Bepaal huidige fase uit laatste git tag of dev-log.
2. Lees exit-gate van `docs/phases/<huidig>-*.md`.
3. Voor elk item: check daadwerkelijk of het klopt:
   - Build slaagt? Run `xcodebuild`.
   - Tests groen? Run `xcodebuild test`.
   - Coverage threshold? Parse xcresult.
   - File bestaat? Check filesystem.
   - Tag bestaat? Run `git tag`.
4. Per item: ✅ klaar / ❌ open + wat ontbreekt.
5. Als alles ✅: meld "Klaar voor /phase-close."
6. Als items open: lijst de opens, vraag welke we vandaag aanpakken.

Output: gate-rapport.
```

---

### `/phase-close` — Sluit fase af

**Doel:** alleen draaien als `/phase-gate` 100% groen is.

**Implementatie:**

```markdown
# /phase-close

Stappen:
1. Run `/phase-gate` eerst. Als niet 100% groen → STOP, refer naar /phase-gate output.
2. Bepaal nieuwe versie (minor bump van laatste tag).
3. Update CHANGELOG.md met nieuwe versie en samenvatting.
4. Vraag de user via Notification-hook of we git tag mogen zetten.
5. Bij confirm: maak git tag `v0.X-phase-N` met annotatie uit CHANGELOG.
6. Schrijf dev-log entry: "Fase X afgesloten, op naar fase X+1."

Output: tag + dev-log + suggestie om /phase-start [X+1] te draaien.
```

---

## 3. Feature flow

### `/feature-spec` — Maak feature spec

**Doel:** voor Fase 6, één spec-file per feature volgens template.

**Implementatie:**

```markdown
# /feature-spec [feature-naam]

Stappen:
1. Check of `docs/features.md` deze feature in MVP-bucket heeft.
   Zo niet: STOP, vraag user of we feature toevoegen aan bucket.
2. Maak `docs/features/<feature-naam>.md` met template:
   - User story
   - Input/triggers
   - Output/resultaat
   - UI-states (loading, empty, error, success)
   - Edge cases
   - Foutsituaties
   - Afhankelijkheden (Core protocols, andere features, externe services)
3. Vul aan op basis van wat we al weten uit conversation context.
4. Vraag user om gaten in te vullen.

Output: spec-file met TODO-markers voor user.
```

---

### `/feature-start` — Begin feature implementatie

**Implementatie:**

```markdown
# /feature-start [feature-naam]

Stappen:
1. Lees `docs/features/<feature-naam>.md`. Als afwezig → suggereer /feature-spec.
2. Maak optioneel feature branch `feat/<feature-naam>`.
3. Volg slice-patroon uit Fase 5:
   - Core protocols/use cases (uitbreiden indien nodig)
   - Infrastructure-implementatie
   - `Features/<FeatureName>/` folder met Models, Stores, Views
   - Tests
4. Stel implementatie-volgorde voor als 3-5 stappen.
5. Wacht op bevestiging.

Output: implementatieplan + suggestie voor stap 1.
```

---

### `/feature-wrap` — Sluit feature af

**Implementatie:**

```markdown
# /feature-wrap [feature-naam]

Stappen:
1. Run `/lint` en `/test` voor de feature.
2. Check exit-criteria uit feature-spec:
   - Alle UI-states aanwezig?
   - Tests groen?
   - Smoke test op simulator?
3. Update dev-log.md met "feature-naam afgesloten".
4. Vraag user via Notification-hook of we squash-mergen naar main.
5. Bij confirm: squash merge + delete branch.

Output: merge-status + suggestie volgende feature uit MVP-lijst.
```

---

## 4. Quality

### `/audit` — Volledige audit

**Implementatie:**

```markdown
# /audit

Stappen:
1. Run SwiftLint, SwiftFormat (check-only).
2. Run alle tests.
3. Check coverage thresholds:
   - Core ≥80%
   - Overall ≥60%
4. Scan op TODO/FIXME zonder issue-referentie.
5. Scan op hardcoded secrets (API-key patronen).
6. Scan op force-unwraps (`!`) buiten tests.
7. Check Info.plist permissions vs daadwerkelijk gebruik.
8. Genereer rapport.

Output: audit-rapport met categorieën en counts.
```

---

### `/perf-check` — Performance audit

**Implementatie:**

```markdown
# /perf-check

Stappen:
1. Build in Release config voor fysiek device.
2. Adviseer Time Profiler-run via Instruments (kan Claude niet zelf doen).
3. Check `Main Thread Checker` is aan in scheme.
4. Scan code op patterns die main-thread kunnen blokkeren:
   - JSONDecoder op @MainActor zonder Task.detached
   - Synchrone file I/O op main
   - VStack zonder Lazy in lange lijsten
5. Scan op AsyncImage zonder caching wrapper.
6. Genereer rapport met findings + verwijzingen naar architecture.md §15.

Output: lijst van risicogebieden + hoe te valideren met Instruments.
```

---

## 5. Pre-submit

### `/pre-submit-check` — Fase 10 verificatie

**Doel:** voert de checklist uit `docs/phases/10-pre-go-to-apple.md` uit.

**Implementatie:**

```markdown
# /pre-submit-check

Stappen:
1. Lees `docs/phases/10-pre-go-to-apple.md`.
2. Voor elk verifieerbaar item: check daadwerkelijk:
   - Privacy Policy URL: HTTP HEAD request → 200?
   - Demo-account credentials: bestaan in App Store Connect notes?
   - Reviewer Notes: lengte >50 chars?
   - Build version: hoger dan vorige upload?
   - Release config: niet Debug?
3. Voor handmatige checks: vraag user expliciet bevestiging:
   - "Heb je privacy policy in incognito getest?"
   - "Heb je demo-account op schoon device getest?"
   - "Heb je screenshots vs werkelijkheid 1-op-1 gecheckt?"
4. Output gate-rapport.

Output: fase 10 gate-status.
```

---

### `/screenshot-audit` — Vergelijk screenshots met werkelijkheid

**Implementatie:**

```markdown
# /screenshot-audit

Stappen:
1. Lijst alle screenshots in /assets/screenshots/.
2. Voor elke screenshot: vraag user om de feature/scherm te beschrijven.
3. Check of die feature in huidige codebase bestaat:
   - Grep op kernteksten uit screenshot
   - Check view-bestanden
4. Flag mismatches (oude UI, verwijderde features, gewijzigde copy).
5. Per mismatch: suggestie om screenshot te vernieuwen of feature te herstellen.

Output: mismatch-rapport.
```

---

## 6. Utility

### `/dev-log` — Schrijf dev-log entry

**Implementatie:**

```markdown
# /dev-log

Stappen:
1. Run `git log --since="midnight" --oneline` voor vandaag.
2. Vraag user: "Blokt er iets?" en "Wat morgen?"
3. Schrijf entry in `docs/dev-log.md`.

Output: nieuwe entry + bevestiging.
```

---

### `/changelog` — Update CHANGELOG

**Implementatie:**

```markdown
# /changelog [version]

Stappen:
1. Lees commits sinds laatste git tag.
2. Categoriseer in Added/Changed/Fixed/Removed.
3. Stel concept-entry voor.
4. Update CHANGELOG.md na confirm.

Output: changelog entry concept.
```

---

### `/find-todos` — Vind alle TODO's

**Implementatie:**

```markdown
# /find-todos

Stappen:
1. Grep op `TODO`, `FIXME`, `HACK`, `XXX` in alle Swift-files.
2. Categoriseer op leeftijd (uit git blame).
3. Flag TODO's zonder issue-referentie of datum (architecture.md §6).
4. Genereer lijst met file:line + context.

Output: TODO-rapport gesorteerd op leeftijd.
```

---

## Setup-instructies

### Per-project (aanbevolen)

```bash
# In project root
mkdir -p .claude/commands
# Kopieer de commands die je voor dit project wilt
cp ~/Templates/claude-commands/*.md .claude/commands/
```

### Globaal (handig als je meerdere projecten hebt)

```bash
mkdir -p ~/.claude/commands
# Plaats hier de generieke commands
# Per-project commands kunnen alsnog in .claude/commands/ staan
```

Claude Code laadt **eerst** project-specifieke commands, dan globale. Dus per-project kun je generieke commands overrulen.

---

## Welke skills heb je echt nodig?

**Minimum-set voor solo dev:**

- `/sod`
- `/eod`
- `/phase-gate`
- `/audit`

**Plus-set voor productiviteit:**

- `/status`
- `/feature-start`
- `/feature-wrap`
- `/dev-log`

**Volledig pakket** voor wie alles wil automatiseren: alle 14 commands.

Begin met de minimum-set. Voeg pas iets toe als je het wekelijks zou gebruiken.

---

## Onderhoud

- Update commands wanneer `make_app.md` of `architecture.md` wijzigt — anders verwijst Claude naar verouderde regels.
- Test commands handmatig na elke major Claude Code release — slash command-syntax kan veranderen.
- Houd commands kort. >100 regels = je doet te veel in één command.
