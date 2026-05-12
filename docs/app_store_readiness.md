# app_store_readiness.md — App Store Submissie-Referentie

> **Doel:** complete, herbruikbare checklist voor iedere iOS-app die naar de App Store gaat. Wordt geraadpleegd in Fase 9. Update bij elke major iOS-release of App Review Guidelines-wijziging.

---

## 1. Privacy Manifest (`PrivacyInfo.xcprivacy`)

**Verplicht sinds 2024 voor je eigen app + alle third-party SDK's.**

### Verplichte secties

- `NSPrivacyTracking` — boolean: doe je tracking?
- `NSPrivacyTrackingDomains` — domeinen die tracking doen
- `NSPrivacyCollectedDataTypes` — welke data verzamel je?
  - Per type: linked to user, used for tracking, purposes
- `NSPrivacyAccessedAPITypes` — Required Reason API's

### Required Reason API's (top 5 die je waarschijnlijk gebruikt)

| API | Reason codes |
|-----|--------------|
| `UserDefaults` | `CA92.1` (app functionality) |
| File timestamp APIs | `C617.1`, `0A2A.1` |
| System boot time | `35F9.1` |
| Disk space | `E174.1` |
| Active keyboards | `54BD.1` |

Vul de juiste reason-code in per gebruik.

### Validatie

- Xcode → Product → Archive → toont privacy-rapport.
- App Store Connect rejecteert builds waar privacy manifest mist of incompleet is.

**Bron:** [Apple — Describing data use](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files)

---

## 2. App Tracking Transparency (ATT)

**Vereist als je tracking-data verzamelt of deelt voor advertising.**

- `NSUserTrackingUsageDescription` in Info.plist met menselijke uitleg.
- `ATTrackingManager.requestTrackingAuthorization` aanroepen vóór tracking.
- Geen tracking als status ≠ `.authorized`.
- Niet aanvragen op app-launch zonder context (rejection-grond).

---

## 3. Encryption Export Compliance

In Info.plist:

```xml
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```

- `false` als je alleen Apple's standaard HTTPS gebruikt.
- `true` betekent: jaarlijkse self-classification report nodig (`https://snr.cbp.dhs.gov`).
- Bij twijfel: raadpleeg juridisch.

---

## 4. Account Deletion (verplicht sinds juni 2022)

**Als je apps accounts ondersteunt, MOET je in-app account-verwijdering bieden.**

- Niet "stuur een email naar support".
- Moet binnen redelijke tijd resulteren in échte verwijdering.
- Documenteer welke data wel/niet bewaard blijft (legal hold etc.).
- Plek: meestal in Settings/Profile-sectie.

---

## 5. Sign in with Apple

**Verplicht als je third-party social login (Google, Facebook, etc.) aanbiedt.**

- Niet vereist als je alleen email/password of geen accounts hebt.
- UI-positie: gelijkwaardig aan andere login-opties.

---

## 6. Age Rating

In App Store Connect:

- Vragenlijst doorlopen (geweld, profanity, gokken, user-generated content, etc.).
- Voor user-generated content: **content moderation + reporting + blocking** verplicht (Guideline 1.2).
- Klopt het niet → rejection.

---

## 7. App Store Connect — verplichte velden

### App Information

- [ ] Naam (max 30 tekens)
- [ ] Subtitle (max 30 tekens)
- [ ] Privacy Policy URL (live, bereikbaar, in juiste taal)
- [ ] Category (primary + optioneel secondary)
- [ ] Content Rights (eigen content of licentie-info)

### Pricing & Availability

- [ ] Prijs / gratis
- [ ] Beschikbare regio's
- [ ] Pre-order (optioneel)

### Version Information (per release)

- [ ] What's New (max 4000 tekens)
- [ ] Promotional Text (max 170 tekens, kan post-launch wijzigen)
- [ ] Description (max 4000 tekens)
- [ ] Keywords (max 100 tekens, **comma-separated, geen spaties na komma**)
- [ ] Support URL
- [ ] Marketing URL (optioneel)
- [ ] Copyright

### App Review Information

- [ ] Demo-account (username + password) als login vereist is
- [ ] Notes voor reviewer: hoe key features te bereiken, eventuele setup-stappen
- [ ] Contact info

---

## 8. Assets

### App-icoon

- 1024×1024 PNG voor App Store
- Geen alpha-channel
- Geen transparency
- Geen ronde hoeken (Apple voegt ze toe)
- Alle vereiste sizes voor verschillende contexten

### Screenshots (verplicht)

- **iPhone 6.9"** (15 Pro Max / 16 Pro Max) — 1290×2796
- **iPhone 6.5"** (Plus / Pro Max-modellen) — 1284×2778 of 1242×2688
- iPad-screenshots indien iPad ondersteund

Per device: minimaal 3, maximaal 10 screenshots.

### App Preview Video (optioneel maar sterk aanbevolen)

- 15-30 seconden
- Vertical 1080×1920 (iPhone) / horizontal voor iPad
- Audio mag, geen externe muziek zonder licentie

### Localized Assets

- Per ondersteunde taal eigen screenshots aanleveren als UI-tekst zichtbaar is.

---

## 9. Build-checks

Vóór upload:

- [ ] Build configuration: **Release**
- [ ] Code signing: distribution certificate
- [ ] Bitcode is sinds Xcode 14 deprecated, dus geen actie nodig
- [ ] Symbols upload aan voor crash-rapportage
- [ ] Build number is uniek en hoger dan alle eerdere
- [ ] Marketing version klopt met git tag

---

## 10. App Review Guidelines — top struikelpunten

| Guideline | Wat het inhoudt | Veelvoorkomende fout |
|-----------|----------------|---------------------|
| **2.1** Performance | Crashes, bugs | Crash bij eerste launch |
| **2.3** Accurate Metadata | Beschrijving = realiteit | Screenshots tonen features die niet werken |
| **2.5.1** Software Requirements | Geen private API's | Reflection-tricks die private symbols raken |
| **3.1.1** In-App Purchase | Digitale content via IAP | Externe payment-link voor digital goods |
| **3.2.2** Acceptable | Geen spam | Te lijken op bestaande populaire app |
| **4.0** Design | HIG volgen | Non-standard UI-patronen zonder reden |
| **4.2** Minimum Functionality | App moet meer doen dan een website | Pure webview-wrapper |
| **5.1.1** Data Collection | Privacy policy match werkelijkheid | Tracking zonder dat manifest het zegt |
| **5.1.5** Location Services | Alleen als noodzakelijk | Always-allow vragen zonder reden |

**Lees vóór elke submission:** [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

---

## 11. TestFlight

### Internal Testing (max 100 testers, snel beschikbaar)

- Geen review nodig
- Builds direct beschikbaar
- Voor jezelf en team

### External Testing (max 10.000 testers)

- **Beta App Review** vereist (1-2 dagen)
- Eerste external build per versie heeft strenger review
- Goede manier om guideline-issues vóór finale submit te ontdekken

**Aanbeveling:** elke v0.9-build minimaal door één external review-cycle laten gaan.

---

## 12. Submissie-flow (Fase 9 → v1.0)

1. Final TestFlight-build draait stabiel ≥7 dagen.
2. Alle bovenstaande checklist-items afgevinkt.
3. Build promoten in App Store Connect → "Submit for Review".
4. Status: `Waiting for Review` → `In Review` → `Pending Developer Release` of `Ready for Sale`.
5. Bij rejection: lees Resolution Center notes, fix, resubmit.
6. Gemiddelde review-tijd: 24-48 uur (in 2026).

---

## 13. Post-launch monitoring

- Crash reports via Xcode Organizer of third-party (Sentry, Bugsnag).
- App Store Connect Analytics: impressions, conversion, retention.
- App Store reviews — beantwoord binnen 7 dagen.
- Updates: blijf onder de impact-radar door geen grote breaking changes binnen 30 dagen post-launch.

---

## 14. Quick checklist voor v0.9-gate

- [ ] PrivacyInfo.xcprivacy compleet
- [ ] Account deletion werkt (indien accounts)
- [ ] Sign in with Apple aanwezig (indien third-party login)
- [ ] Encryption compliance gezet
- [ ] Privacy policy URL live
- [ ] Support URL live
- [ ] Alle App Store Connect-velden ingevuld
- [ ] Screenshots voor alle vereiste devices
- [ ] App-icoon 1024×1024 zonder alpha
- [ ] Demo-account werkt (indien login vereist)
- [ ] Reviewer notes ingevuld
- [ ] Build draait crashvrij in External TestFlight ≥7 dagen
- [ ] App Review Guidelines doorgelezen
- [ ] Git-tag `v0.9-submission-ready` gezet
