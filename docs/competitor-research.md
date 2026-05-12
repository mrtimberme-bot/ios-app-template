# Competitor Research Framework

> **Wanneer:** Vóór architectuur of implementatie — minimaal vóór fase 1 (Feature Collection).  
> **Output:** `docs/research/competitor-analysis.md` + `docs/research/feature-matrix.md`  
> **Command:** `/competitor-research`

---

## Waarom dit niet overgeslagen mag worden

De meeste developer workflows bevatten een "doe even een Google-check" stap. Dat is geen methode. Professionele teams doen competitor analysis omdat:

- App Store review mining geeft je **validated pain points** — geen aannames, maar bewijs
- Feature matrices voorkomen dat je bouwt wat de marktleider al perfect doet
- Positioneringsgaten zijn pas zichtbaar als je 20+ apps vergelijkt, niet 3
- ASO-strategie (keywords, title, screenshots) hangt direct af van wat concurrenten doen

---

## Stap 1 — Competitive Landscape Mapping

### Drie lagen

| Laag | Definitie | Aantal te onderzoeken |
|------|-----------|----------------------|
| **Direct** | Zelfde probleem, zelfde doelgroep, zelfde platform | 8-10 apps |
| **Indirect** | Zelfde probleem, andere aanpak (bijv. een notebook-app vs jouw productivity-app) | 5-8 apps |
| **Adjacent** | Wat doen gebruikers als jouw app niet bestaat? | 2-3 categorieën |

### Hoe vinden

```
# App Store zoekstrategie — gebruik je top 3-5 zoekwoorden
1. Zoek op je kern-keyword → noteer top 10 resultaten
2. Zoek op 2-3 synoniemen → noteer nieuwe resultaten
3. Check "Klanten kochten ook" en "Gerelateerde apps" per top competitor
4. Check rankings: Top Free + Top Paid in jouw categorie (top 100)
5. data.ai / Sensor Tower free tier voor download-schattingen

# Resultaat: lijst van 40-60 apps → filteren op relevantie
```

### Filtering naar top 50 voor scan

Filter op:
- Relevantiematch: lost het hetzelfde kernprobleem op?
- Zichtbaarheid: heeft het actieve downloads (ratings > 100) of strategische waarde?
- Platform: iOS-native (geen webwrappers)

Resultaat: ~50 apps voor brede scan, 8-10 apps voor diepte-analyse.

---

## Stap 2 — Brede Scan (top 50)

Voor elk van de 50 apps, noteer in 5 minuten per app:

| Veld | Wat vastleggen |
|------|---------------|
| App naam + developer | — |
| Rating (sterren) + reviews (aantal) | — |
| Laatste update | Signaal: actief of verlaten |
| Monetization model | Free / Freemium / Paid / Subscription |
| Prijs | Bedrag en tier |
| Screenshots (eerste 3) | Wat claimen ze als hoofdwaarde? |
| Beschrijving eerste zin | Kernpropositie |
| Top 3 features (uit beschrijving) | — |
| 1-ster reviews: meest genoemde klacht | — |
| 5-ster reviews: meest genoemde reden | — |

**Template voor brede scan** (sla op als `docs/research/broad-scan.csv`):

```
App Name,Developer,Rating,Reviews,Last Update,Monetization,Price,Feature1,Feature2,Feature3,Top Complaint,Top Praise
```

---

## Stap 3 — Diepte-analyse (top 8-10)

### 3a. Installeer en gebruik elke app op een clean test-account

Simuleer:
- Onboarding (compleet doorlopen)
- Core happy path (eerste succesvolle use van de main feature)
- Edge cases: empty state, error state, offine state
- Settings / account management
- Upgrade / paywall flow

Noteer:
- Onboarding: hoeveel stappen? Waarde vóór sign-up vereist?
- UX-kwaliteit (score 1-5): navigatie, consistentie, snelheid
- "Wow moment" (als aanwezig): wat is het?
- Grootste frustratie (als aanwezig)

### 3b. Volledige feature inventaris

List **alle** features van de app — geen aannames, geen interpretaties.  
Gebruik de app-beschrijving + release notes + in-app discovery.

Categoriseer per feature in de Kano-laag (zie Stap 4 voor definitie):

```markdown
## [App Naam] — Feature Inventaris

### Core Features
- [ ] Feature A — [Kano: Basic / Performance / Delight / Indifferent]
- [ ] Feature B — ...

### Secondary Features
...

### Unique/Differentiating Features
...
```

### 3c. App Store Review Mining

Sorteer reviews op **1 ster** en **5 sterren** apart.

**1-ster analyse** — zoek naar patronen (3+ mentions = significant):
- Wat crasht of werkt niet?
- Welke feature missen gebruikers?
- Welke beloftes worden niet nagekomen?
- Wat frustreert specifiek over UX?

**5-ster analyse** — zoek naar:
- Welke specifieke feature krijgt de meeste lof?
- Welk probleem heeft de app opgelost voor de gebruiker?
- Wat zou de gebruiker missen als de app verdwijnt?

**Output:** Een "onmet behoeften" lijst — dit zijn jouw bouwinstructies.

---

## Stap 4 — Feature Matrix met Kano-classificatie

### Kano model — de laag die MoSCoW mist

| Kano Categorie | Als aanwezig | Als afwezig | Vertaling |
|----------------|-------------|-------------|-----------|
| **Basic (Must-Be)** | Vanzelfsprekend | Extreme ontevredenheid | App mag niet crashen, data moet saven |
| **Performance** | Meer = meer tevreden | Minder = minder tevreden | Sync snelheid, zoekresultaten kwaliteit |
| **Delight (Excitement)** | Onverwachte vreugde | Geen ontevredenheid | Haptic feedback, widget, surprise animatie |
| **Indifferent** | Geen reactie | Geen reactie | Bouw dit niet |
| **Reverse** | Ontevredenheid | Tevredenheid | Te veel notificaties, te complex UI |

**Belangrijk: Delight features degraderen.** Wat vandaag een "wow" is, is volgend jaar een Basic. Dit betekent: Delight features moeten periodiek ververst worden.

### Mapping naar jouw classificatie

| Jouw label | Kano equivalent | Implicatie |
|------------|----------------|------------|
| **Killer** | Delight | Differentieert, creëert buzz, urgent voor positionering |
| **Must Have** | Basic + top Performance | Zonder dit: geen download of immediate uninstall |
| **Should Have** | Performance | Maakt het product beter, direct zichtbaar voor gebruikers |
| **Could Have** | Low Performance | Nice-to-have, bouwen als er tijd is |
| **Won't Have** | Indifferent + Reverse | Bewust uit scope houden |

### Feature Matrix Template

Maak `docs/research/feature-matrix.md`:

```markdown
# Feature Matrix — [App Naam]

Datum: YYYY-MM-DD
Concurrenten geanalyseerd: [lijst]

## Classificatie

| Feature | App A | App B | App C | App D | App E | Kano | Prioriteit | Bron |
|---------|-------|-------|-------|-------|-------|------|-----------|------|
| Feature 1 | ✓ | ✓ | ✓ | ✓ | ✓ | Basic | Must Have | Aanwezig bij alle |
| Feature 2 | ✓ | ✓ | — | — | — | Performance | Should Have | Top-2 apps |
| Feature 3 | — | — | — | — | — | Delight | Killer | Ontbreekt in markt |
| Feature 4 | ✓ | — | ✓ | — | — | Indifferent | Won't Have | Laag in reviews |

## Onvervulde behoeften (uit review mining)
1. [Behoefte uit 1-ster reviews App A] — voorkomen bij: A, B, C
2. ...

## Onze differentiatie
Wij zijn de enige die [X] bieden voor [doelgroep] terwijl we [Y] weglaten.
```

---

## Stap 5 — ICE Scoring voor feature prioritering

Voor elke feature in de matrix, score op:

**ICE = Impact × Confidence × Ease** (elk 1-10)

| Score | Betekenis |
|-------|-----------|
| **Impact** | Hoeveel verbetert dit de activatie of retentie? |
| **Confidence** | Hoe zeker ben je van de impact? (onderbouwing: review mining, interviews) |
| **Ease** | Hoe eenvoudig is de implementatie? (10 = 1 dag, 1 = weken) |

```markdown
| Feature | Impact | Confidence | Ease | ICE Score | Prioriteit |
|---------|--------|-----------|------|-----------|-----------|
| Feature A | 9 | 8 | 7 | 504 | P0 |
| Feature B | 7 | 6 | 4 | 168 | P1 |
```

**Eerste bouw:** sorteer op ICE score. De features met de hoogste score gaan als eerste in de blokkenplanning.

---

## Stap 6 — Perceptual Map

Plot de top 6-8 directe concurrenten op een 2×2 grid met de twee meest strategisch relevante assen voor jouw categorie.

Voorbeeldassen per categorie:
- Productivity: Complexiteit vs. Snelheid van setup
- Health/Fitness: Begeleiding vs. Vrijheid
- Finance: Automatisering vs. Controle
- Social: Privacy vs. Reach
- Utilities: Power-user features vs. Simplicity

```
           Hoog [As Y]
                │
    App C  App B │  ← jouw gat?
                │
App A           │         App D
────────────────┼─────────────── [As X]
                │             Hoog
    App E       │  App F
                │
```

Zoek een "wit vlak" waar geen sterke speler staat. Dat is jouw positie.

---

## Output documenten

Na voltooiing van deze fase heb je:

| Document | Locatie | Inhoud |
|----------|---------|--------|
| Brede scan | `docs/research/broad-scan.csv` | 50 apps, basisgegevens |
| Diepte-analyse | `docs/research/deep-analysis.md` | 8-10 apps, volledig |
| Feature matrix | `docs/research/feature-matrix.md` | Alle features, Kano + ICE |
| Review mining | `docs/research/review-insights.md` | Onvervulde behoeften |
| Perceptual map | `docs/research/perceptual-map.md` | Positionering |
| Positioneringsstatement | `docs/vision.md` | Bijgewerkt met differentiatie |

---

## Veelgemaakte fouten

| Fout | Waarom fout | Correctie |
|------|-------------|-----------|
| Alleen top 2-3 bekijken | Differentiatie-inzicht zit in mid-tier apps | Minimaal 8 in diepte |
| Features van zichzelf bedenken | Je mist wat al bestaat | Feature matrix van bestaande apps first |
| 5-ster reviews negeren | Dat is bewijs van wat wérkt | Mine beide richtingen |
| Matrix eenmalig | Markt verandert | Maandelijkse pulse check via `/competitor-research update` |
| "Onze app is uniek" zonder bewijs | Cognitieve bias | Perceptual map toont het pas |
