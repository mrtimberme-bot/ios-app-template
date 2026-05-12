# Fase 0 — Discovery & Scoping

> **Doel:** voorkomen dat je code schrijft voor een idee dat nog niet helder is.
> **Versie na afsluiten:** nog geen — dit is pre-code.
> **Vorige fase:** —
> **Volgende fase:** [01-feature-collection.md](./01-feature-collection.md)

---

## Activiteiten

### Vision-doc schrijven

Schrijf een **Vision-doc** (max 1 A4) in `/docs/vision.md` met:

- **Probleem** dat je oplost (één alinea)
- **Doelgroep** — wie heeft dit probleem?
- **Kernbelofte** in één zin
- **Succescriteria** — hoe weet je over 6 maanden of dit gewerkt heeft?

### Platform-eisen vastleggen

- Minimum iOS-versie (en waarom)
- Devices: iPhone, iPad, beide?
- Online/offline-vereisten
- Minimum hardware (camera nodig? GPS? NFC?)

### Concurrentie-onderzoek

Voer `/competitor-research` uit (of doe handmatig via `docs/competitor-research.md`).

Minimum voor discovery-exit-gate:
- 50 apps breed gescaneerd (brede scan)
- 8-10 directe concurrenten diep geanalyseerd (feature inventaris + review mining)
- Feature matrix gebouwd met Kano-classificatie + ICE scoring
- Positioneringsstatement vastgelegd in `docs/vision.md`

Output: `docs/research/` map met feature-matrix.md, review-insights.md, perceptual-map.md.

> Zie `docs/competitor-research.md` voor het volledige framework.

### JTBD — Jobs To Be Done (optioneel maar sterk aanbevolen)

Doe 5-8 interviews met potentiële gebruikers vóór Feature Collection.  
De centrale vraag is **niet** "welke features wil je?" maar:

> "Neem me mee naar de laatste keer dat je [probleem] tegenkwam. Wat deed je? Wat was frustrerend? Wat heb je geprobeerd?"

Synthesiseer naar 2-3 **core jobs**:

```
Job: [gebruiker] wil [functionele taak] zodat [emotioneel/sociaal resultaat].
```

Voeg de core jobs toe aan `docs/vision.md` onder "Jobs To Be Done."  
Features die geen van de core jobs dienen → direct naar "Nooit"-bucket in Feature Collection.

### Risico-inventarisatie

Top-3 risico's met mitigatie:

- **Technisch** — gebruik je nieuwe/onstabiele API's? On-device ML? Nieuwe iOS-features?
- **Juridisch** — privacy (GDPR/AVG), scraping, IP, content-moderation
- **Commercieel** — App Review hot topics (zie `app_store_readiness.md` §10)

### Distributie-keuze

Beslis nu:

- **App Store** — strenge compliance, brede distributie, review-cycli
- **Personal/sideload** — geen review, maar je bent de enige gebruiker
- **TestFlight-only** — middle ground voor closed beta

Deze keuze bepaalt hoe streng de latere fases zijn (Fase 7-9 zijn aanzienlijk lichter voor personal apps).

---

## Exit-gate

- [ ] `/docs/vision.md` bestaat en is gelezen door minimaal één ander persoon (kan AI zijn — laat het kritisch reviewen)
- [ ] Minimum iOS-versie + device-targets vastgelegd
- [ ] Top-3 risico's benoemd met mitigatie
- [ ] Distributie-keuze gemaakt en gedocumenteerd
- [ ] `/competitor-research` uitgevoerd: `docs/research/feature-matrix.md` bestaat
- [ ] Positioneringsstatement in `docs/vision.md` bijgewerkt
- [ ] Minimaal 5 JTBD-interviews gedaan (of bewust overgeslagen met reden)

**Geen git-tag** — er is nog geen code.

---

## Anti-patterns

- ❌ "Ik weet wat ik wil maken, ik begin gewoon te coden." → resultaat: in Fase 6 ontdekken dat de architectuur niet past bij wat je eigenlijk bouwt.
- ❌ Vision-doc van 5 pagina's. → Te lang = te vaag. Eén A4.
- ❌ Risico's negeren omdat "het wel zal lukken." → Apple rejection-cycles kosten weken.
