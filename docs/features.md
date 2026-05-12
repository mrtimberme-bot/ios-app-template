# features.md — [APP NAAM]

> **Project-specifiek bestand.** Kopieer dit template per nieuwe app en vul in tijdens Fase 1.
> Dit bestand wordt **niet** door make_app.md gedicteerd — het is het resultaat van Fase 1.

---

## App-context

- **App-naam:**
- **Eén-zin pitch:**
- **Doelgroep:**
- **Platform:** iOS [versie]+
- **Devices:** iPhone / iPad / beide
- **App Store of personal:**

---

## Feature-buckets

### MVP (vereist voor v0.9 — max 7 items)

Features zonder welke de app geen bestaansrecht heeft.

| # | Feature | User story | Acceptatiecriterium |
|---|---------|-----------|---------------------|
| 1 |  | Als [gebruiker] wil ik [actie] zodat [waarde]. |  |
| 2 |  |  |  |
| 3 |  |  |  |

### v1.0 (eerste echte release na MVP)

Belangrijk maar niet kritiek voor de eerste werkende versie.

- [ ]
- [ ]

### Later (nice-to-have, no commitment)

- [ ]
- [ ]

### Nooit (expliciet uitgesloten — voorkomt scope-creep)

Schrijf hier op wat je NIET bouwt en waarom. Dit bestand mag je raadplegen als je in de verleiding komt.

- ❌ [feature] — reden:
- ❌ [feature] — reden:

---

## Prioriteitsmatrix (voor twijfelgevallen)

|  | Lage effort | Hoge effort |
|---|-------------|-------------|
| **Hoge impact** | Direct doen | Plan zorgvuldig |
| **Lage impact** | Sneaken indien tijd | Skip |

| Feature | Effort (1-5) | Impact (1-5) | Bucket |
|---------|--------------|--------------|--------|
|  |  |  |  |

---

## Out-of-scope-statement

> Ik bevestig dat de "Nooit"-bucket door mijzelf is geschreven en dat ik tijdens deze
> ontwikkelcyclus geen items uit "Later" naar "MVP" verplaats zonder eerst een
> MVP-feature te schrappen.
>
> — [naam], [datum]

---

## Per-feature spec (gevuld in Fase 6)

Voor elke MVP-feature een eigen bestand: `docs/features/<feature-naam>.md` met:

- Input/triggers
- Output/resultaat
- Edge cases
- Foutsituaties
- UI-states (loading, empty, error, success)
- Afhankelijkheden (welke Core-protocols, welke andere features)
