# Marktonderzoek — Gezins-klusjes & maandelijkse schoonmaakroutines (iOS)

**Datum:** 2026-06-11
**Concept:** iOS-app waarmee een gezin maandelijkse schoonmaakroutines en klusjes deelt en organiseert, zodat iedereen ziet wie wat doet en wat al gedaan is.
**Focusmarkt:** NL / EU / VS
**Methode:** 5 parallelle research-tracks (concurrenten, marktomvang, review mining, monetization, differentiatie), claims gelabeld met betrouwbaarheid. App Store-pagina's blokkeren geautomatiseerd ophalen (HTTP 403); ratings/prijzen komen deels uit zoeksnippets en aggregators en zijn gemarkeerd waar onbevestigd.

---

## TL;DR

- **De markt bestaat en groeit** (alle bronnen wijzen op 12–20% CAGR voor family/household-apps), maar is een niche: chore-specifieke apps zitten op ~1–2M downloads totaal; brede family organizers (Cozi, FamilyWall) op ~10M installs.
- **Niemand bezit "de maand" als planningseenheid.** Tody is interval-gedreven ("vuilheid groeit"), Sweepy en Nipto zijn dag/week-gedreven. Een maandbord dat het gezin één keer instelt en aan het einde van de maand reviewt, is onbezet terrein.
- **De kernbelofte van de categorie — gedeelde zichtbaarheid — is precies wat het vaakst kapot is**: sync achter een paywall die vervolgens niet werkt (Tody), serveruitval die gezinnen buitensloot (OurHome, sinds sept 2023), notificaties die maar bij de helft van het gezin aankomen (Nipto).
- **Prijsband:** chore-apps clusteren op €2–3/maand of €13–30/jaar; family organizers op $40–50/jaar. Eén abonnement voor het hele huishouden is de norm; Tody's Solo/Duo/Family-tiering is de uitzondering en bron van klachten.
- **Grootste gecombineerde kans:** maandritme als product + NL-first lokalisatie + eerlijke, zichtbare taakverdeling zonder betuttelende gamification. Geen enkele concurrent combineert deze drie.

---

## 1. Concurrentielandschap

### Tier 1 — Direct (huishoudelijke schoonmaakschema's voor het hele gezin)

| App | Kern | Prijs | Rating | NL? |
|-----|------|-------|--------|-----|
| **Sweepy** | Kamer-gebaseerd schema, auto-dagplan per gezinslid, punten + leaderboard | Freemium; premium ~€2,49/mnd of ~€13/jr (bronnen variëren — onbevestigd); gratis = 1 gebruiker | 4.7 iOS; 4.53 Play (~17K) | ✅ NL-gelokaliseerd ("Sweepy: Schoonmaakschema") |
| **Tody** | "Indicator-methode": vuilheidsmeters i.p.v. kalenderdata; FairShare-verdeling (2025) | Gratis solo; sync paywalled: Solo $9,99 / Duo $17,99 / **Family $29,99/jr** | 4.83 iOS (~8,5K) | NL-listing, UI-lokalisatie onbevestigd |
| **Nipto** | Wekelijkse puntencompetitie, kindaccounts | Gratis t/m 5 taakgroepen; premium ~€1,99/mnd of ~€13/jr | 4.64 Play (~6,2K) | ✅ NL-gelokaliseerd ("Nipto: Taken Verdelen") |
| **Flatastic** | Klusjes + boodschappen + kosten splitsen; roommate-focus | Gratis met ads; €1,99/mnd of €17,99/jr | Gemengd (count onbekend) | ❌ DE/FR-centrisch |
| **Home Tasker** | NL-talige utility; dagelijks/wekelijks/**maandelijks**/custom rotatie | Freemium | 4.67 (~9,4K), top House & Home in NL/BE/AT | ✅ de facto lokale leider, maar solo-utility |

### Tier 2 — Family organizers met klusjes als module

| App | Kern | Prijs | Schaal |
|-----|------|-------|--------|
| **Cozi** | Gezinskalender + lijsten + klusjes-checklists; geen recurring-engine | Gratis met ads; Gold ~$39/jr | ~30K downloads & ~$400K omzet/mnd (schatting); gedateerd, Trustpilot ~2.1 |
| **FamilyWall** | Kalender, locatie, chat, takenlijsten | $4,99/mnd of $44,99/jr, hele gezin | ~7–8M downloads; overgenomen door OurFamilyWizard (2024) |
| **Maple** | AI-gezinsassistent | ~$3–5/mnd (onbevestigd) | Klein, VS/Canada |

### Tier 3 — Kind-gericht klusjes + zakgeld (VS-centrisch, beperkt relevant voor NL)

- **OurHome**: was dé gratis optie (~720K downloads), maar serveruitval vanaf sept 2023 strandde gezinnen; eind 2025 opnieuw gelanceerd door Elusios mét premium-tier. Les: gratis gezins-sync bleek onhoudbaar.
- **Homey** ($49,99/jr), **BusyKid** ($48/jr, alleen VS-bankieren), **S'moresUp** ($79,99/jr, duurste), **Chorsee** (indie, $11,99–18,99/jr, bewust anti-gamification, flexibele schema's incl. maandelijks/alternerend). **ChoreMonster** is ter ziele (~2018).

Bronnen: App Store/Play-listings, AppBrain, Tidied-reviews, justuseapp, vendor-sites — volledige URL's in de research-tracks (zie voetnoot onderaan).

---

## 2. Marktomvang & vraag

**Betrouwbaar (hoog vertrouwen):**
- Sensor Tower: Productivity- en Lifestyle-categorieën behoren tot de snelst groeiende; non-game app-uitgaven +23% YoY ([Sensor Tower 2025](https://sensortower.com/blog/2025-state-of-mobile-consumers-usd150-billion-spent-on-mobile-highlights)).
- "Mental load" is academisch gevalideerd als pijnpunt: cognitieve huishoudarbeid is ongelijker verdeeld dan fysieke en taak-visualisatietools verlagen die last ([Daminger 2019, ASR](https://journals.sagepub.com/doi/10.1177/0003122419859007), [NCBI](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC12529999/)).
- NL: ~2,4M tweeverdienershuishoudens (CBS) — structureel grote coördinatielast-doelgroep ([CBS](https://www.cbs.nl/en-gb/our-services/methods/definitions/dual-income-households)).
- VC/M&A-validatie: Hearth Display haalde ~$14M op rond "mental load"; OurFamilyWizard kocht FamilyWall (2024).

**Onbetrouwbaar (laag vertrouwen):** alle absolute "$X miljard"-marktcijfers komen van report-mills (Market.us e.d., parenting apps ~$2B → $5,5B 2033, CAGR 12–20%). Richting klopt consistent (dubbelcijferige groei), absolute bedragen niet bruikbaar als business-case-anker.

**Plafonds ter referentie:** chore-niche ~1–2M downloads (Sweepy/Tody, ~14K/mnd elk); organizers ~10M (Cozi/FamilyWall); family-app met scherpe hook ~96M MAU (Life360, beursgenoteerd).

---

## 3. Review mining — terugkerende klachten & onvervulde behoeften

### Klachtenpatronen (3+ vermeldingen = significant)

1. **Sync paywalled én kapot** — Tody: household sync "regularly tells me I don't have premium" na betaling; Homey: app sluit op het ene device als het andere opent; Nipto: reminders komen maar bij een deel van het gezin aan. *De kernbelofte (gedeelde zichtbaarheid) faalt het vaakst.*
2. **Rigide herhaalschema's** — Nipto's "time extend" faalt bij 2–6-maandscycli; Sweepy kent geen retroactief afvinken; Flatastic toont pas op de dag zelf wiens beurt het is; "X dagen ná voltooiing" is een veelgevraagde recurrence-modus.
3. **Paywall-frustratie / subscription fatigue** — Cozi's "bait and switch" mei 2024 (gratis kalender beperkt tot 30 dagen, Trustpilot 2.1★); Nipto: "te veel achter premium om bruikbaar te zijn"; Flatastic: ad na elke twee afgevinkte taken.
4. **Gamification-verval bij kinderen** — nieuwigheid duurt "ongeveer elf dagen"; "reward fatigue"; volwassenen voelen zich door punten/competitie "als kinderen behandeld" (Flatastic).
5. **Abandonment-angst** — OurHome-uitval strandde gezinsdata op onbereikbare servers; hele alternatieven-pagina's ontstonden eromheen.
6. **Privacy & lock-in** — Cozi: Common Sense "Warning"-rating, data naar ad-tech, geen export; 73% van kids-apps verkoopt persoonsdata.
7. **De app verplaatst de mental load i.p.v. die te verlagen** — MIT Technology Review: setup en beheer landen bij dezelfde persoon (meestal moeder), partners "get defensive when notified" ([MIT TR](https://www.technologyreview.com/2022/05/10/1051954/chore-apps/)).

### Onvervulde behoeften (bouwlijst)

1. Eén abonnement = heel gezin, sync die gewoon werkt
2. Flexibele recurrence: maandelijks, 2–6-maandscycli, "X dagen na voltooiing", alternerend
3. Schuldvrije omgang met gemist werk: retroactief afvinken, geen rode overdue-muur
4. Vooruit zien wiens beurt wanneer komt (rotatie-zichtbaarheid)
5. Gedeelde setup (partnership-framing) i.p.v. één beheerder die nagt via de app
6. Intrinsieke motivatie voor kinderen (bijdrage/erbij-horen) i.p.v. uitdovende punten
7. Data-export + privacy zonder ad-tech
8. Local-first/offline zodat een serverstop geen gezinsdata strandt

---

## 4. Monetization-benchmarks

| Benchmark | Waarde | Bron |
|-----------|--------|------|
| Prijsband chore-apps | €2–3/mnd, €13–30/jr | App-listings (zie §1) |
| Prijsband family organizers | $40–50/jr | Cozi, FamilyWall |
| Markt-mediaan abonnement | $10/mnd, $34,80/jr | [RevenueCat SOSA 2026](https://www.revenuecat.com/state-of-subscription-apps/) |
| Freemium download→betaald (D35) | mediaan 2,1% (hard paywall: 10,7%) | RevenueCat SOSA 2026 |
| Trial→betaald | 25,5% (≤4 dgn) tot 42,5% (17–32 dgn) | RevenueCat SOSA 2026 |
| Maandelijkse eerste verlenging | 42–61% per categorie (Lifestyle laagste: 42%) | RevenueCat 2026 |
| Jaarlijkse eerste verlenging | 23–40% (Productivity laagste: 23%) | RevenueCat 2026 |
| Year-1 LTV per betaler | $23 globaal / $32 NA mediaan | RevenueCat SOSA 2026 |

**Dominante gating-strategieën in de categorie:** (a) leden-aantal (Sweepy gratis = 1 gebruiker), (b) tijdvenster/historie (Cozi 30 dagen), (c) ads in free tier, (d) sync/integraties achter premium, (e) usage-counters (Nipto "1/5").

**Patroon:** één abonnement dekt het hele huishouden (FamilyWall, Nipto, Life360, BusyKid). Tody's per-grootte-tiering (Solo/Duo/Family) is de uitzondering — en een klachtenbron. **Implicatie:** jaarlijks gezinsabonnement rond €15–30/jr met App Store Family Sharing is de logische opzet; langere trial (2–4 weken) converteert aantoonbaar beter.

---

## 5. Differentiatiekansen (gerangschikt)

1. **De maand als product** *(meest verdedigbaar)* — een maandbord voor het gezin: één keer inrichten, hele maand zichtbaar wie wat doet, checkmarks vullen zich, maandafsluiting met review. Tody = interval, Sweepy/Nipto = dag/week; alleen Home Tasker noemt maandrotatie en dat is een solo-utility zonder maand-ervaring.
2. **NL-first gezinspositionering** — NL UI + Nederlandse schoonmaakcultuur-presets ("grote schoonmaak", seizoensklussen). Home Tasker bewijst dat NL-talig top-ranking haalbaar is; Nipto/Sweepy zijn gelokaliseerd maar week-gedreven. NL-media (oudersvannu, dik.nl, id.nl) zoeken actief apps om aan te raden.
3. **Eerlijkheid zonder scorebord-wrok** — rotatie + gewogen balans die de gedocumenteerde klachten oplost (Sweepy's grove 1–3 punten, Tody's paywalled FairShare) en de "één persoon digitaliseert de mental load"-kritiek adresseert met gedeelde setup-flows.
4. **Diepe iOS-native laag** — interactieve (lock-screen) widgets per gezinslid, "schoonmaakdag" Live Activity (categorie is hier leeg), App Intents/Siri ("markeer badkamer als gedaan"), betrouwbare watchOS. Concurrenten zijn hier zwak, buggy of paywallen het.
5. **Family Sharing-vriendelijke pricing** — makkelijk te communiceren contrast met Tody; tactisch, geen moat.
6. **AI-maandschema's** (kamerscan → maandplan) — al in commoditisering (Cleaning Schedule AI, Home Tasker); hooguit onboarding-versneller.

### Perceptual map

```
        Maandritme / planbaar
                │
                │   ← WIT VLAK (onze positie)
   Home Tasker  │
────────────────┼──────────────── Gezins-zichtbaarheid →
   Tody         │      Sweepy
   (interval,   │      Nipto (week-competitie)
    solo-free)  │      Cozi/FamilyWall (breed, geen engine)
                │
        Dag/week-gedreven
```

### Positioneringsstatement (concept)

> Wij zijn de enige app die het **maandelijkse huishoudritme van het gezin** plant en zichtbaar maakt — wie doet wat, wat is gedaan — **zonder puntencompetitie, zonder per-persoon-abonnement en zonder dat één persoon de beheerder wordt**, terwijl we zakgeld-bankieren en brede organizer-features bewust weglaten.

---

## 6. Risico's

- **Klein nichevolume:** Sweepy/Tody doen ~14K downloads/mnd elk; reken niet op massamarkt zonder bredere hook.
- **Tody beweegt al richting fairness** (FairShare 2025) — kans 3 is kopieerbaar.
- **Lifestyle heeft de laagste verlengingscijfers** (42% maandelijks); retentie-ontwerp (maandafsluiting als ritueel) is geen nice-to-have maar de kern van het businessmodel.
- **Gratis-zonder-model is bewezen onhoudbaar** (OurHome) — kies vanaf dag 1 een duurzaam freemium-model.

---

## Voetnoot — bronnen & betrouwbaarheid

Belangrijkste bronnen: App Store/Google Play-listings, AppBrain, Sensor Tower, RevenueCat State of Subscription Apps 2026, MIT Technology Review, Trustpilot, justuseapp/Tidied review-aggregatie, CBS, peer-reviewed mental-load-literatuur. **Onbevestigd gebleven:** exacte actuele Sweepy-prijs (3 conflicterende bronnen), iOS-ratingaantallen voor de meeste apps (App Store blokkeert fetches), Tody's "1M actieve gebruikers"-claim, NL-UI van Tody/Flatastic/FamilyWall. Verifieer deze handmatig op de NL App Store vóór definitieve positionering.
