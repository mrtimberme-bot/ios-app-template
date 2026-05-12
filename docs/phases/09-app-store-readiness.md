# Fase 9 — App Store-readiness

> **Doel:** alle compliance-eisen + alle assets compleet. Geen code-werk meer; alleen vinkjes.
> **Versie na afsluiten:** v0.9 (= submission-ready)
> **Vorige fase:** [08-stabilisation.md](./08-stabilisation.md)
> **Volgende fase:** [10-pre-go-to-apple.md](./10-pre-go-to-apple.md)

> **Diepte-referenties voor deze fase:**
> - [`app_store_readiness.md`](../app_store_readiness.md) — volledige compliance checklist
> - [`release-management.md`](../release-management.md) — Phased Rollout, hotfix flow
> - [`storekit-iap.md`](../storekit-iap.md) — als je IAP/subscriptions hebt
> - [`security.md`](../security.md) §7 — account deletion implementation

---

## Scope-afbakening

- **Fase 9** = alles ingericht en aangeleverd. Privacy manifest, screenshots, App Store Connect-velden, demo-account aangemaakt.
- **Fase 10** = laatste verificatie dat het ook écht werkt zoals aangeleverd, plus External TestFlight review-cycle.

Doe Fase 10 niet op dezelfde dag als Fase 9 — frisse blik is een feature.

---

## Activiteiten

> **Volledige checklist** met alle compliance-details staat in [`app_store_readiness.md`](../app_store_readiness.md). Deze fase is in essentie het systematisch afwerken van dat document.

### 1. Compliance

Werk de checklist uit `app_store_readiness.md` af, in volgorde:

- §1 Privacy Manifest (`PrivacyInfo.xcprivacy`)
- §2 App Tracking Transparency (indien relevant)
- §3 Encryption export compliance
- §4 Account deletion (indien accounts ondersteund)
- §5 Sign in with Apple (indien third-party login)
- §6 Age rating

### 2. Assets aanleveren

Alles in `app_store_readiness.md` §8:

- App-icoon 1024×1024 (zonder alpha)
- Screenshots voor vereiste device-sizes
- App preview video (optioneel)
- Localized assets per ondersteunde taal

Bewaar bron-bestanden (Sketch/Figma/Photoshop) in `/assets/` van het project.

### 3. App Store Connect-velden invullen

Alles in `app_store_readiness.md` §7:

- App Information
- Pricing & Availability
- Version Information (description, keywords, what's new)
- App Review Information (demo-account, notes voor reviewer)

### 4. Juridisch

- **Privacy Policy URL** — moet live, bereikbaar, en in juiste taal zijn. Gebruik je een tool (Termly, iubenda) of schrijf je 'm zelf?
- **Support URL** — kan een GitHub Issues-pagina zijn, eigen support-site, of een Notion-pagina.
- **Marketing URL** (optioneel) — landing page voor de app.
- **EULA** — alleen aanleveren als je afwijkt van Apple's standaard.

### 5. Account deletion-flow inrichten

Indien van toepassing:

- Gebruiker kan account verwijderen vanuit de app.
- Verwijdering is binnen redelijke tijd compleet.
- Wat blijft bewaard (legal hold, geanonimiseerde analytics) is in privacy policy benoemd.

### 6. Demo-account aanmaken

- Maak een dedicated demo-account aan (geen persoonlijke account).
- Voorzie het van representatieve test-data.
- Documenteer credentials in App Store Connect → App Review Information.
- *Verificatie of het werkt komt in Fase 10.*

### 7. Reviewer Notes schrijven

- Hoe bereikt de reviewer key features?
- Welke setup-stappen zijn nodig?
- Eventuele beta-flags die aangezet moeten worden?
- Contact-info voor vragen.

---

## Exit-gate

- [ ] Privacy Manifest gevalideerd via Xcode (geen warnings)
- [ ] **`Info.plist` permissions audit:** elke aangevraagde permission heeft een menselijke usage description, geen permissions aangevraagd die niet daadwerkelijk gebruikt worden, beschrijvingen matchen Privacy Manifest (`architecture.md` §12)
- [ ] Alle App Store Connect-velden ingevuld
- [ ] Privacy Policy URL en Support URL zijn live (verificatie volgt in Fase 10)
- [ ] Demo-account aangemaakt en gedocumenteerd
- [ ] App-icoon, screenshots, beschrijving — allemaal compleet
- [ ] Reviewer Notes geschreven
- [ ] App Review Guidelines doorgelezen (zie `app_store_readiness.md` §10)
- [ ] **Git-tag:** `v0.9-submission-ready`
- [ ] CHANGELOG.md geüpdatet

---

## Anti-patterns

- ❌ Privacy policy schrijven nadat je 'm aanlevert in App Store Connect. → Mismatch tussen policy en werkelijke app-gedrag.
- ❌ Demo-account met je persoonlijke data. → Privacy-issue voor jezelf en je echte gebruikers.
- ❌ Screenshots maken voordat alle features echt af zijn. → Mismatch met werkelijkheid (bevestiging volgt in Fase 10).
- ❌ Reviewer Notes leeg laten omdat "het is toch wel duidelijk". → Reviewers krijgen elke dag honderden apps.

---

## Naar Fase 10

Na het afsluiten van deze fase: **stop**. Niet nog snel even submitten.

[Fase 10](./10-pre-go-to-apple.md) is de verificatie-poort die alle Fase 9-output tegen de werkelijkheid houdt. Dat is geen formaliteit; dat is je verzekering tegen vermijdbare rejections.
