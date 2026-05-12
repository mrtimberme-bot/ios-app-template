# Fase 1 — Feature-collectie & MVP-afbakening

> **Doel:** alle ideeën uit je hoofd op tafel, daarna meedogenloos snijden.
> **Versie na afsluiten:** v0.1
> **Vorige fase:** [00-discovery.md](./00-discovery.md)
> **Volgende fase:** [02-architecture-setup.md](./02-architecture-setup.md)

---

## Activiteiten

### 1. Brainstorm-dump

Schrijf alles wat je wilt op in `/docs/features.md`. **Geen filter.** Tien minuten timer, blijf typen.

Triggers om je geheugen aan te zetten:

- Wat moet de app doen op het hoofdscherm?
- Wat in instellingen?
- Wat als de gebruiker offline is?
- Welke notificaties?
- Welke integraties met andere apps/services?
- Onboarding-flow?
- Edge cases (eerste launch, geen data, error)?
- Toekomst-ideeën die je nu al ziet?

### 2. Categoriseer in vijf buckets

Gebruik het template uit `/docs/features.md`:

| Bucket | Definitie | Kano equivalent |
|--------|-----------|----------------|
| **Killer** | Differentieert — aanwezig bij 0-2 concurrenten, creëert "wow" | Delight |
| **Must Have** | Verwacht door gebruikers — afwezigheid = immediate uninstall | Basic |
| **Should Have** | Verbetert product significant, zichtbaar voor gebruikers | Performance |
| **Could Have** | Nice-to-have, weinig impact op activatie/retentie | Low Performance |
| **Won't Have** | Bewust weglaten — Indifferent of Reverse in de markt | Indifferent/Reverse |

**MVP = Killer + Must Have features, maximaal 7 items.**  
Features uit de feature matrix (`docs/research/feature-matrix.md`) hebben al een Kano-label — gebruik die als startpunt.

### 2b. ICE scoring voor twijfelgevallen

Als je twijfelt over de bucket van een feature, score op ICE:

```
ICE = Impact (1-10) × Confidence (1-10) × Ease (1-10)
```

- **Impact**: hoeveel verbetert dit activatie of D7-retentie?
- **Confidence**: heb je bewijs? (review mining = 8-10, aanname = 3-5)
- **Ease**: 10 = 1 dag, 5 = 1 week, 1 = 3+ weken

ICE < 100 → Could Have of Won't Have.  
ICE > 300 + Kano Basic/Delight → Must Have of Killer.

### 3. User stories per MVP-item

Format:
> Als **[gebruiker]** wil ik **[actie]** zodat **[waarde]**.

Voorbeeld:
> Als nieuwe gebruiker wil ik via mijn email een account maken zodat mijn data syncronizeert tussen devices.

### 4. Acceptatiecriteria per MVP-item

Concrete, testbare criteria:

- ✅ "Email-veld accepteert geldige emails, toont fout bij ongeldige."
- ❌ "Login werkt goed."

### 5. Out-of-scope-lijst

Schrijf expliciet op wat je NIET bouwt en waarom. Onderteken het stuk. Dit voorkomt dat je in Fase 6 stiekem features toevoegt.

### 6. Analytics tracking plan per MVP-feature

Vóór implementatie van elke MVP-feature, noteer:

- **Activatie event**: welk gebruikersgedrag bewijst dat de feature waarde levert?
- **Retentie signal**: welke actie correleert met D7/D30 retentie?
- **Privacy**: welke data wordt verzameld? Consent vereist?

Format (toevoegen aan user story):
```
Analytics: user_completed_[feature_name] → triggered when [concrete actie]
```

Features zonder gedefinieerd activatie event zijn niet klaar voor implementatie.

---

## Exit-gate

- [ ] `/docs/features.md` bestaat met alle vier buckets gevuld
- [ ] MVP heeft ≤7 features
- [ ] Out-of-scope-lijst is geschreven en ondertekend
- [ ] Voor elke MVP-feature is een user story + acceptatiecriterium genoteerd
- [ ] Twijfelgevallen door prioriteitsmatrix gehaald
- [ ] **Git-tag:** `v0.1-features-frozen` (op een lege commit als er nog geen code is)
- [ ] CHANGELOG.md aangemaakt met v0.1-entry

---

## Anti-patterns

- ❌ "Ik vul het in als ik bezig ben." → Je vult het nooit in. Doe het nu.
- ❌ MVP met 12 features. → Niet MVP. Maak twee apps of snij door de helft.
- ❌ "Misschien doe ik X ook nog." → Zet het in "Later" of "Nooit". Geen "misschien"-bucket.
- ❌ Geen acceptatiecriteria. → In Fase 6 weet je niet wanneer een feature klaar is.

---

## Tips

- Laat je MVP een week liggen, lees opnieuw, snij verder. Eerste-keer-MVP's zijn altijd te groot.
- Praat met één potentiële gebruiker. "Welke 3 dingen mis je het meest in bestaande apps?" Match dat met je MVP-bucket.
- Als je twijfelt of iets MVP is: stel je voor dat je v1.0 lanceert zonder die feature. Werkt de app dan? Ja → niet MVP.
