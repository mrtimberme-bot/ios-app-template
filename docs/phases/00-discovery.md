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

### Concurrentie-scan

- 3 bestaande apps die hetzelfde of vergelijkbaars doen
- Wat doen zij goed?
- Wat doet jouw app anders?
- Is er ruimte in de markt of ben je een rebuild?

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
- [ ] Concurrentie-scan: minimaal 3 apps geanalyseerd

**Geen git-tag** — er is nog geen code.

---

## Anti-patterns

- ❌ "Ik weet wat ik wil maken, ik begin gewoon te coden." → resultaat: in Fase 6 ontdekken dat de architectuur niet past bij wat je eigenlijk bouwt.
- ❌ Vision-doc van 5 pagina's. → Te lang = te vaag. Eén A4.
- ❌ Risico's negeren omdat "het wel zal lukken." → Apple rejection-cycles kosten weken.
