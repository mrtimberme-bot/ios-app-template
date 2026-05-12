# dev-log.md — Daily Development Log

> **Verplicht artifact per project.** Drie regels per dag minimum: wat gedaan, wat blokt, wat morgen.
> **Locatie:** `docs/dev-log.md`
> **Commit:** ja, deze hoort bij je project-history.

---

## Waarom dit bestand bestaat

Solo dev = geen standup, geen team-update, geen wekelijkse sync. Maar projectgeheugen is geen luxe; het is wat je in week 8 nog terug laat zien wat je in week 2 besloot en waarom.

Praktische functies:

1. **Voor jezelf.** Na een weekend, vakantie, of context-switch open je `dev-log.md`, leest je laatste 3 entries, en je bent in 30 seconden weer in het project.
2. **Voor Claude Code.** Bij elke nieuwe sessie laad je deze file als eerste in context. Claude weet meteen waar je was en wat openstaat — geen ellenlange prompt nodig.
3. **Voor toekomstige jij.** Bij rare beslissingen 4 maanden later kun je terug zien waarom je iets deed.

---

## Entry-formaat

Drie regels minimum, maar voel je vrij meer te schrijven als de dag dat verdient.

```markdown
## 2026-05-06

**Gedaan:** Slice-feature (chat) werkt nu end-to-end op simulator. ChatStore + SendMessage usecase + OpenAIChatProvider gekoppeld. Tests voor SendMessage groen.

**Blokt:** Streaming responses werken niet — SSE-parsing krijgt lege chunks. Vermoed `URLSession.bytes` issue.

**Morgen:** Streaming uitzoeken. Begin met minimal repro in Playgrounds. Als Apple-bug → fallback naar non-streaming voor v0.5-gate.
```

### Optionele extra-velden

Voeg toe als relevant, niet verplicht:

- **Beslissingen:** korte ADR-achtige notities. Linkt naar `docs/architecture-decisions.md` voor de volledige.
- **Vragen:** dingen die je later wilt uitzoeken (niet blokkerend).
- **Win:** kleine successen. Goed voor moraal in week 6 als alles tegenzit.

---

## Frequentie-regel

- **Werkdag:** entry verplicht, ook als je 30 minuten hebt gewerkt.
- **Geen werk:** geen entry. Geen "vandaag niets gedaan"-regels.
- **Weekend / vakantie:** skip stilletjes.
- **Achterstand inhalen:** niet doen. Eén lege week is geen drama; gefingeerde entries zijn dat wel.

---

## Integratie met SOD/EOD-skills

Zie `skills.md` voor de Start-of-Day en End-of-Day flows die `dev-log.md` automatisch lezen en schrijven. In het kort:

- **`/sod`** leest de laatste 3 entries en stelt je dagdoel voor.
- **`/eod`** schrijft een nieuwe entry op basis van git history van die dag.

---

## Anti-patterns

- ❌ Te lange entries. → Het bestand wordt onhanteerbaar. Drie regels.
- ❌ Gefingeerde entries om "compleet" te lijken. → Je liegt tegen toekomstige jij.
- ❌ Beslissingen alleen hier vastleggen. → Belangrijke ADR's horen in `docs/architecture-decisions.md`.
- ❌ Vergeten te committen. → Stop dit bestand uit `.gitignore`. Het hoort in git.

---

## Voorbeeld over een week

```markdown
## 2026-05-06

**Gedaan:** ChatStore werkt, OpenAI integratie staat. Tests groen.
**Blokt:** Streaming SSE — lege chunks.
**Morgen:** SSE debuggen of fallback bouwen.

## 2026-05-07

**Gedaan:** SSE bug was timing-issue in test, niet in code. Streaming werkt nu. v0.5-gate haal ik vandaag.
**Blokt:** Niets.
**Morgen:** Tag v0.5-slice, beginnen met Fase 6 — feature 'Conversation history'.

## 2026-05-08

**Gedaan:** Conversation history models + persistence (SwiftData). UI nog niet.
**Blokt:** SwiftData migration-vraag voor later.
**Morgen:** UI voor history list.
**Vragen:** Moeten we conversation history end-to-end versleutelen? Check GDPR.
```
