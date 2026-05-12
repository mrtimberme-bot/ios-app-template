# Wat Professionele App Builders Doen — En Wat Wij Missen

> Gebaseerd op: Shape Up (Basecamp/HEY), Jobs To Be Done, Kano Model, RICE/ICE scoring,
> ASO 2025-2026 best practices, en iOS product management bij Shopify/Basecamp/indie-teams.

---

## TL;DR

De template is uitstekend in **bouwen** (architectuur, CI/CD, code kwaliteit, tooling).  
Het ontbreekt volledig aan **ontdekken** — de productmanagement-activiteiten die bepalen of wat gebouwd wordt ook het juiste is.

---

## Wat professionele workflows hebben wat deze mist

### 1. Shape Up — Appetite, niet Estimation

**Wat het is:** Basecamps methodologie (gebruikt voor HEY iOS). Het kernidee: je besluit vooraf *hoeveel het waard is*, en past de scope aan — niet omgekeerd.

**Het gap:** In de huidige workflow gaat een feature van idee naar implementatie zonder een "shaping" stap. Er is geen expliciete vraag: *is dit het juiste probleem om op te lossen, en wat is een goede oplossing?*

**Wat toe te voegen:** De `/plan-feature` command heeft al een planning-stap, maar mist:
- **Appetite** — hoeveel tijd/effort is dit probleem waard?
- **Shaped pitch** — schets van aanpak vóór de details
- **Expliciete scope-afbakening** — wat doen we *niet*?

---

### 2. Gestructureerd User Research (JTBD)

**Wat het is:** Jobs To Be Done interviews. Geen "welke features wil je?" maar "neem me mee naar de laatste keer dat je probeerde X te doen."

**Het gap:** User research bestaat niet als formele fase. Vision.md heeft een "doelgroep" veld, maar er is geen protocol voor het valideren van aannames bij echte gebruikers vóór de bouw.

**Minimum viable versie voor indie dev:**  
5-8 interviews met potentiële gebruikers vóór Feature Collection.  
Kernvraag: "Wat deed je de laatste keer dat je [probleem] tegenkwam?"

---

### 3. Competitor Analysis — Van 3 Apps naar Systeem

**Het gap:** Huidige discovery-fase: "doe een concurrentie-scan van 3 apps."  
Professionele aanpak: 50 apps breed gescaneerd, 8-10 diep geanalyseerd, App Store review mining, feature matrix, perceptual map.

**Waarom het verschil uitmaakt:**
- Met 3 apps mis je de mid-tier waar differentiatie-inzicht zit
- Zonder review mining bouw je features op aannames i.p.v. bewijs
- Zonder perceptual map weet je niet waar je "witte vlak" is

**Toegevoegd:** `docs/competitor-research.md` — volledig framework  
**Toegevoegd:** `/competitor-research` command

---

### 4. Kano Model — De Emotionele Laag Boven MoSCoW

**Wat het is:** Feature-classificatie op basis van hoe gebruikers reageren op aanwezigheid vs. afwezigheid.

**Het gap:** "Killer/Must/Should/Could" is een prioritering — het vertelt niet *waarom* iets belangrijk is. Kano voegt toe:

| Kano | Wat het zegt |
|------|-------------|
| Basic | Zonder dit: extreme ontevredenheid (zelfs als aanwezig: niemand blij) |
| Performance | Meer = meer tevreden (lineair) |
| Delight | Onverwachte vreugde (en: degradeert met de tijd naar Basic) |
| Indifferent | Bouwt niemand blij — bouw het niet |
| Reverse | Aanwezigheid creëert frustratie |

**Praktisch:** Voeg Kano-categorie toe aan elke rij in de feature matrix.

---

### 5. ICE/RICE Scoring — Geen Intuïtie-Prioritering

**Het gap:** Huidige feature prioritering: intuïtie van de ontwikkelaar.  
Professioneel: ICE (Impact × Confidence × Ease) of RICE (+ Reach).

**Wanneer welke:**
- Pre-launch / geen gebruikersdata → ICE score
- Post-launch / met retentiedata → RICE score

**Praktisch:** Voeg ICE-kolom toe aan feature matrix vóór blokkenplanning.

---

### 6. Analytics als Feature-Definitie, Niet Achteraf

**Het gap:** Analytics (events, funnels) worden toegevoegd "later" of bij launch.  
Professioneel: tracking plan is onderdeel van de feature definitie.

**De centrale vraag vóór implementatie:**  
*Welk user behaviour bewijst dat deze feature waarde levert?*

**Minimum per feature blok:**
- Activatie event: "user heeft waarde gekregen als..."
- Retentie signal: welke actie correleert met D7/D30 retentie?
- Privacy implicaties: welke data wordt verzameld, consent nodig?

---

### 7. ASO Research — Pre-Development, Niet Pre-Submission

**Het gap:** App Store metadata (keywords, title, subtitle) wordt geschreven bij submission.  
Professioneel: keyword research is een input bij het **benoemen van de app**.

**Waarom pre-development:**
- App title en subtitle zijn de zwaarste ranking-signalen in App Store
- Keyword research toont welke termen zoekvolume + minder competitie hebben
- 2025-2026 realiteit: retention (D7+) is nu een ranking-factor — product kwaliteit en ASO zijn direct gekoppeld

**Minimum actie:** Doe keyword research vóór je de definitieve app naam vastlegt.  
Tools: App Store autocomplete, AppTweak free tier, Sensor Tower.

---

### 8. Monetization Beslissing — Framework, Niet Placeholder

**Het gap:** `{{MONETIZATION_STRATEGY}}` is een placeholder in CLAUDE.md.  
Er is geen document dat helpt de beslissing te maken vóór de architectuur.

**De beslissing beïnvloedt architectuur:**
- Subscription → paywall component, StoreKit 2 subscription management, trial logic
- One-time → eenvoudiger StoreKit setup
- Freemium → twee product tiers, feature gating

**Framework voor de beslissing:**

| Factor | Subscription | One-Time | Freemium |
|--------|-------------|---------|---------|
| Waarde is... | Continu, evoluerend | Statisch of duurzaam | Gelaagd |
| Friction bij download | Hoog | Medium | Nul |
| Benodigde downloads | Laag (MRR voorspelbaar) | Medium | Heel hoog (2-5% conversie) |
| Dev overhead | Hoog (trial, renewal, grace) | Laag | Hoogst |

**Minimum actie:** Besluit en documenteer vóór architectuurfase.  
Bestand: `docs/architecture/monetization.md`

---

## Nieuwe fases in de workflow

### Pre-fase: Market Research (vóór discovery)

```
/competitor-research    ← nieuw command
```

Output:
- `docs/research/broad-scan.csv` — 50 apps, basisgegevens
- `docs/research/feature-matrix.md` — alle features, Kano + ICE
- `docs/research/review-insights.md` — onvervulde behoeften
- `docs/research/perceptual-map.md` — positionering

### Discovery — uitgebreid met JTBD

Bestaande 00-discovery.md uitgebreid met:
- JTBD interview protocol (5-8 interviews minimum)
- Switch interview vragen
- Synthesistemplate naar 2-3 core jobs

### Feature Collection — uitgebreid met Kano + ICE

Bestaande 01-feature-collection.md uitgebreid met:
- Kano kolom in feature lijst
- ICE score per feature
- Expliciete "Won't Have" categorie

### Per feature blok — Analytics tracking plan

Toegevoegd aan blok-definitie in plan-feature.md:
- Activatie event definitie
- Retentie signal definitie
- Privacy implicaties

---

## Wat we goed doen (niet wijzigen)

| Onderdeel | Status |
|-----------|--------|
| CI/CD (SwiftLint, Gitleaks, Build, Tests) | ✅ Industrie-standaard |
| Code architectuur (@Observable, SwiftData, feature modules) | ✅ Solid |
| Security (Keychain, PrivacyInfo.xcprivacy, no secrets in code) | ✅ Goed |
| Accessibility (VoiceOver, Dynamic Type, contrast) | ✅ First-class citizen |
| ios-blok-workflow (één feature = één blok = één PR) | ✅ Shape Up-equivalent |
| Design tokens (DesignTokens.swift, dark mode dag 1) | ✅ Consistent |
| Release automation (Fastlane, GitHub Actions) | ✅ Professioneel |
| Pre-submission audit (`/audit`) | ✅ Comprehensive |

---

## Referenties

- [Shape Up — Basecamp](https://basecamp.com/shapeup)
- [Jobs To Be Done — Product School](https://productschool.com/blog/product-fundamentals/jtbd-framework)
- [Kano Model](https://productschool.com/blog/product-fundamentals/kano-model)
- [ICE vs RICE Scoring](https://www.productlift.dev/blog/rice-vs-ice)
- [ASO Best Practices 2025-2026](https://asomobile.net/en/blog/aso-in-2026-the-complete-guide-to-app-optimization/)
- [Mobile App Competitor Analysis — Devlight](https://devlight.io/blog/how-to-conduct-mobile-app-competitor-analysis/)
- [App Store Review Mining — AppFollow](https://appfollow.io/blog/how-to-use-a-competitive-matrix-for-mobile-apps/)
