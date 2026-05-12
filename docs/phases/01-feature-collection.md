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

### 2. Categoriseer in vier buckets

Gebruik het template uit `/docs/features.md`:

| Bucket | Definitie |
|--------|-----------|
| **MVP** | Zonder dit geen v0.9 — kernfunctionaliteit |
| **v1.0** | Belangrijk, maar wacht tot eerste publieke release |
| **Later** | Nice-to-have, no commitment |
| **Nooit** | Impulsief idee dat scope sloopt |

**MVP-cap: maximaal 7 features.** Méér dan 7 = je MVP is geen MVP. Snij.

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

### 6. Prioriteitsmatrix voor twijfelgevallen

Effort (1-5) × Impact (1-5). Items met effort 4-5 én impact 1-2 → "Nooit" of "Later".

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
