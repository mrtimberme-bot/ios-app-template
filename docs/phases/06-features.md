# Fase 6 — Resterende MVP-features

> **Doel:** alle MVP-features bouwen volgens het slice-patroon uit Fase 5.
> **Versie na afsluiten:** v0.6
> **Vorige fase:** [05-vertical-slice.md](./05-vertical-slice.md)
> **Volgende fase:** [07-polish-accessibility.md](./07-polish-accessibility.md)

> **Diepte-referenties voor deze fase:**
> - [`system-integration.md`](../system-integration.md) — Universal Links, App Intents, widgets, Live Activities
> - [`push-notifications.md`](../push-notifications.md) — APNs setup, BGTasks, notification UX
> - [`storekit-iap.md`](../storekit-iap.md) — als één van je features paid is

---

## Activiteiten

### 1. Per feature een spec schrijven

Voor elke MVP-feature uit Fase 1: maak `docs/features/<feature-naam>.md`:

```markdown
# Feature: [naam]

## User story
Als [...] wil ik [...] zodat [...]

## Input / triggers
- [...]

## Output / resultaat
- [...]

## UI-states
- Loading
- Empty
- Error
- Success

## Edge cases
- [...]

## Foutsituaties
- [...]

## Afhankelijkheden
- Core protocols: [...]
- Andere features: [...] (zou idealiter leeg zijn)
- Externe services: [...]
```

### 2. Volgorde bepalen

Implementeer in volgorde van **afhankelijkheid**:

- Features waar andere features op leunen → eerst
- Onafhankelijke features → in volgorde van impact
- Auth/onboarding meestal eerst

Maak een mini-DAG in `/docs/feature-dependencies.md`.

### 3. Per feature implementeren

Volg het patroon van de slice uit Fase 5:

1. Core protocols/use cases (waarschijnlijk al deels in Fase 3 gedaan — uitbreiden)
2. Infrastructure-implementatie (waarschijnlijk al in Fase 4 — uitbreiden)
3. Feature-folder aanmaken: `Features/FeatureName/`
4. Models, Stores, Views
5. Unit tests voor Store-gedrag
6. Integratie in `RootView` / navigation
7. Smoke test op simulator

**Per feature een eigen branch** is netjes maar voor solo dev kan main-trunk + commits per feature ook.

### 4. PR/commit-discipline

Klein en feature-gescoped:

- ✅ `feat(chat): voeg streaming responses toe`
- ❌ `feat: chat + settings + onboarding samen`

### 5. Scope-creep alarm

Als een feature uitloopt:

1. **Stop**.
2. Check `features.md` — is dit nog MVP-scope?
3. Zo ja: snij feature in stukken, lever het simpelste deel op.
4. Zo nee: zet de extra scope in `v1.0`-bucket en commit dat.
5. Lever de oorspronkelijke MVP-versie op.

**Nooit** stiekem extra dingen meenemen "omdat ik er toch mee bezig ben." Dit is hoe Fase 6 30% groter wordt dan gepland.

### 6. Coverage en kwaliteit

- Per feature: unit tests op Store-niveau
- Per feature: smoke test op simulator
- Coverage gemiddeld ≥60% over alle modules
- Geen warnings in build-output

### 7. App start clean install

Test bij elke nieuwe feature:

- App verwijderen van simulator/device
- Schone install
- App start zonder crashes
- First-run flow werkt

---

## Exit-gate

- [ ] Alle MVP-features uit Fase 1 zijn geïmplementeerd
- [ ] Per feature een spec in `docs/features/`
- [ ] Geen feature heeft openstaande P0-bugs
- [ ] App start op een schone install zonder crashes
- [ ] Coverage gemiddeld ≥60% over alle modules
- [ ] Geen build warnings
- [ ] Alle features zijn smoke-getest
- [ ] **Git-tag:** `v0.6-features`
- [ ] CHANGELOG.md geüpdatet

---

## Anti-patterns

- ❌ Features samen mergen om "tijd te besparen". → Debugging wordt een hel.
- ❌ Specs overslaan. → In Fase 8 weet je niet meer wat de bedoeling was van die feature.
- ❌ Cross-feature imports. → Refactor naar Core of een gedeelde module.
- ❌ Tests overslaan voor "snelle" features. → Geen feature is te klein voor minstens één test.

---

## Tips

- Werk één feature volledig af voordat je aan de volgende begint. Half-werk stapelt op.
- Houd een dagelijks "wat heb ik gedaan + wat is volgende" log in `/docs/dev-log.md` — voor jezelf én voor Claude Code-sessies.
- Bij twijfel of iets nu of later moet: check `features.md`. Als het in MVP staat, doen. Anders uitstellen.
