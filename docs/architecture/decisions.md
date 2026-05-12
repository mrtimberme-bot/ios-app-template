# Architectuur Beslissingen — {{APP_NAME}}

## [ADR-001] State management keuze
- **Datum:** {{SETUP_DATE}}
- **Beslissing:** @Observable + SwiftUI
- **Reden:** Voldoende voor huidige complexiteit. TCA als expliciete keuze als dat verandert.
- **Alternatieven:** TCA (overwogen, te complex voor start), Redux (niet native)

## [ADR-002] Persistence keuze
- **Datum:** {{SETUP_DATE}}
- **Beslissing:** SwiftData
- **Reden:** Native iOS 17+, goede SwiftUI integratie, toekomstbestendig.

## [ADR-003] Backend strategie
- **Datum:** {{SETUP_DATE}}
- **Beslissing:** Geen backend bij lancering
- **Reden:** Zo min mogelijk complexity bij start. Backend toevoegen als product-markt fit bewezen.

---
*Voeg nieuwe ADRs toe als er architectuurkeuzes worden gemaakt.*
