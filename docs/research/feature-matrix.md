# Feature Matrix — Gezins-klusjes & maandroutines app

Datum: 2026-06-11
Concurrenten geanalyseerd: Sweepy, Tody, Nipto, Flatastic, Home Tasker, Cozi, FamilyWall, OurHome (Elusios), Chorsee

## Classificatie

| Feature | Sweepy | Tody | Nipto | Flatastic | Home Tasker | Cozi | Kano | Prioriteit | Bron |
|---------|--------|------|-------|-----------|-------------|------|------|-----------|------|
| Terugkerende taken (dag/week) | ✓ | ✓ | ✓ | ✓ | ✓ | — | Basic | Must Have | Aanwezig bij alle directe concurrenten |
| Taak toewijzen per gezinslid | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | Basic | Must Have | Kern van de categorie |
| Afvink-historie ("wie heeft wat gedaan") | ✓ | ✓ | ✓ | ✓ | ✓ | — | Basic | Must Have | Kernbelofte concept |
| Multi-user sync die betrouwbaar werkt | ⚠ | ⚠ | ⚠ | ⚠ | ✓ | ✓ | Basic | Must Have | #1 klacht in review mining — kapot bij concurrenten |
| **Maandbord / maand als planningseenheid** | — | — | — | — | ~ | — | Delight | **Killer** | Ontbreekt in markt; alleen Home Tasker noemt maandrotatie |
| Flexibele recurrence (2–6 mnd, "X dgn na voltooiing", alternerend) | — | ~ | ✗ | — | ~ | — | Performance | Must Have | Veelgevraagd; Nipto's faalt expliciet |
| Rotatie met vooruitblik ("wiens beurt volgende keer") | — | — | — | ✗ | ✓ | — | Performance | Should Have | Flatastic-klacht: pas zichtbaar op de dag zelf |
| Retroactief afvinken / schuldvrij overdue | — | ✓ | — | — | — | — | Performance | Should Have | Sweepy-klacht; Tody's aanpak geprezen |
| Eerlijke verdeling / balansweergave | ~ (punten 1–3) | ✓ (FairShare, paywalled) | ✓ (competitie) | ✓ (flat points) | — | — | Performance | Should Have | Mental-load trend; zonder wrok-mechaniek |
| Gedeelde setup (geen één-beheerder-model) | — | — | — | — | — | — | Delight | Killer | MIT TR-kritiek; niemand lost dit op |
| Punten/leaderboard-gamification | ✓ | — | ✓ | ✓ | ✓ | — | Reverse | **Won't Have** | "Behandelt volwassenen als kinderen"; verval na ~11 dgn |
| Interactieve / lock-screen widgets | — | ✓ (paywalled) | — | — | ✓ | — | Delight | Should Have | Zwak bezet; Tody paywallt |
| Live Activity ("schoonmaakdag") | — | — | — | — | — | — | Delight | Killer (later) | Categorie volledig leeg |
| App Intents / Siri | — | — | — | — | — | — | Delight | Could Have | Concurrenten gebruiken Alexa/Google i.p.v. native |
| watchOS-app | ⚠ (buggy) | — | — | — | — | — | Delight | Could Have | Sweepy's is onbetrouwbaar |
| Eén abonnement = heel gezin (Family Sharing) | ? | ✗ (Solo/Duo/Family-tiers) | ✓ | ✓ | ? | ✓ | Performance | Must Have | Tody's tiering is klachtenbron |
| Data-export (CSV/ICS) | — | — | — | — | — | ✗ | Performance | Should Have | Cozi lock-in-klacht; vertrouwenssignaal |
| Local-first / offline | — | — | — | — | — | — | Performance | Should Have | OurHome-uitval; abandonment-angst |
| Boodschappenlijst / meal planning | — | — | — | ✓ | — | ✓ | Indifferent | Won't Have | Scope-creep; "Swiss Army knife"-overwhelm (OurHome) |
| Zakgeld / bankieren | — | — | — | — | — | — | Indifferent | Won't Have | VS-centrisch (BusyKid/Homey); niet NL-relevant |
| Foto-bewijs van klusjes | — | — | — | — | — | — | Indifferent | Won't Have | Politie-dynamiek; tegen partnership-framing |

Legenda: ✓ aanwezig · ~ gedeeltelijk · ⚠ aanwezig maar buggy/klachten · ✗ aanwezig maar faalt expliciet in reviews · — afwezig · ? onbevestigd

## ICE-scoring (top-features voor blokkenplanning)

| Feature | Impact | Confidence | Ease | ICE | Prioriteit |
|---------|--------|-----------|------|-----|-----------|
| Maandbord met per-persoon toewijzing + afvink-zichtbaarheid | 9 | 8 | 6 | 432 | P0 |
| Betrouwbare gezins-sync (CloudKit, één abonnement) | 9 | 9 | 5 | 405 | P0 |
| Flexibele recurrence-engine (maand/multi-maand/na-voltooiing) | 8 | 8 | 6 | 384 | P0 |
| Maandafsluiting / review-ritueel (retentie-driver) | 8 | 6 | 7 | 336 | P1 |
| Rotatie met vooruitblik | 6 | 7 | 7 | 294 | P1 |
| Gedeelde setup-flow (samen inrichten) | 7 | 6 | 6 | 252 | P1 |
| Interactieve widgets | 6 | 7 | 5 | 210 | P2 |
| Schuldvrij overdue / retroactief afvinken | 6 | 7 | 8 | 336 | P1 |
| Data-export | 4 | 8 | 8 | 256 | P2 |
| Live Activity schoonmaakdag | 5 | 5 | 4 | 100 | P3 |

## Onvervulde behoeften (uit review mining)

1. Sync die werkt na betaling — komt voor bij: Tody, Homey, Nipto
2. Maand-/multi-maand-recurrence — Nipto, Sweepy, Flatastic
3. Vooruit zien wiens beurt — Flatastic
4. Geen beheerder-/nag-dynamiek — categorie-breed (MIT TR)
5. Eén gezinsabonnement — Tody
6. Data-portabiliteit & privacy — Cozi
7. Overlevingsgarantie data (local-first) — OurHome

## Onze differentiatie

Wij zijn de enige die **het maandelijkse huishoudritme van het gezin** plannen en zichtbaar maken (wie doet wat, wat is gedaan) voor **Nederlandse gezinnen**, terwijl we puntencompetitie, zakgeld-bankieren en brede organizer-modules bewust weglaten.
