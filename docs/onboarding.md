# onboarding.md — First-Run Experience

> **Doel:** patterns voor onboarding die niet irriteren, permissions die niet abrupt komen, en acceptable empty states.
> **Wanneer raadplegen:** Fase 7 (UX-polish), elke nieuwe major feature die introductie nodig heeft.
> **Hoort bij:** `app_store_readiness.md` §10 (Guideline 4.2 Minimum Functionality).

---

## 1. De drie 30-secondes regel

- **Eerste 3 seconden:** kan ik dit waarderen? (App icoon, splash, eerste screen)
- **Eerste 30 seconden:** snap ik wat het doet? (Een eerste interactie geslaagd)
- **Eerste 30 minuten:** zie ik mezelf dit blijvend gebruiken? (Eerste echte waarde gehaald)

70% van app-uninstalls gebeurt binnen de eerste 24 uur. Onboarding is waar je dat afvlakt.

---

## 2. Onboarding-archetypes

### A. **Geen onboarding** (aanbevolen voor utility-apps)

App opent → meteen functioneel. Voorbeeld: rekenmachine, notitie-app.

**Voordeel:** time-to-value = 0.
**Nadeel:** complexere features ontdekt user mogelijk niet.

### B. **Sample data** (aanbevolen voor content-apps)

App opent → je ziet voorbeelddata om mee te spelen. Voorbeeld: chat-app met sample conversation, weather-app met current location.

**Voordeel:** geen lege state, gebruiker leert door interactie.
**Nadeel:** moet lijken op echte data, niet "Hallo, test123".

### C. **Progressive disclosure**

App opent → minimaal scherm → features worden uitgelegd wanneer relevant. Voorbeeld: long-press tooltip de eerste keer.

**Voordeel:** geen info-dump.
**Nadeel:** vereist state-tracking ("user heeft tip X gezien").

### D. **Carousel intro** (alleen als noodzakelijk)

3-5 schermen die wisselen met "Volgende"-knop voordat user iets kan doen.

**Voordeel:** kan complete waarde-prop laten zien.
**Nadeel:** wordt genegeerd, voelt als reclame, irriteert.

**Wanneer wel:** apps die fundamenteel onthousiast werken zonder context (een meditatie-app die uitlegt waarom 5 minuten/dag).

### E. **Account-first**

Login/signup voordat user iets ziet. **Vermijden waar mogelijk.**

**Wanneer wel:** apps waar account essentieel is (bank-app, social).
**Anti-pattern:** account vragen voor een lokale notitie-app.

---

## 3. Permission priming

**Het probleem:** Apple's system prompt voor camera-toegang is een eenmalige kans. Tikt user "Don't Allow" → permission permanent geweigerd → workaround alleen via Settings.

**De oplossing — priming:**

1. **Eigen UI** vóór de system prompt die uitlegt waarom je toegang vraagt.
2. **Toestemming pas vragen** wanneer de feature actief gebruikt wordt, niet bij launch.
3. **Bij weigering:** graceful degradation, niet hard-blockeren.

### Voorbeeld: camera priming

```swift
struct CameraPrimingView: View {
    let onAccept: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "camera.fill")
                .font(.system(size: 60))

            Text("Maak je profielfoto")
                .font(.title)

            Text("We gebruiken je camera alleen voor de profielfoto die jij kiest. We slaan geen foto's op zonder je actie.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button("Camera toestaan") { onAccept() }
                .buttonStyle(.borderedProminent)

            Button("Later", action: onSkip)
                .buttonStyle(.plain)
        }
        .padding()
    }
}

// Pas NA "Camera toestaan"-tap:
AVCaptureDevice.requestAccess(for: .video) { granted in
    // ...
}
```

**Regel:** als user op "Later" tikt, vraag NIET de system prompt. Bewaar voor wanneer ze het echt willen.

---

## 4. Permission-types waar priming meest helpt

| Permission | Waarom prime |
|-----------|--------------|
| **Camera** | Voor profielfoto's, scans — feature-gekoppeld |
| **Location** | "Always" lijkt invasief zonder uitleg |
| **Push notifications** | Zonder context = automatisch "Don't Allow" |
| **Photo Library** | Vol vs. selected — wat exact? |
| **Contacts** | Privacy-zorgen ten top |
| **Calendar** | Wat ga je toevoegen? |

| Permission | Geen priming nodig |
|-----------|-------------------|
| **Face ID** | Meestal duidelijk uit context (login-knop) |
| **Local Network** | Onbekend voor users, system prompt is meestal genoeg |

---

## 5. Empty states ≠ leeg

App Review Guideline 4.2: "Apps must offer some level of functionality." Lege state mag NIET zijn:

```
[gewoon leeg scherm]
```

Wel:

```
🎯 Niets te zien hier... nog!

Begin je eerste conversatie om de assistent te leren kennen.

[ Nieuwe conversatie starten ]
```

**Drie elementen verplicht:**
1. **Visueel** — een illustratie of icoon (geen blinkende reclame)
2. **Uitleg** — waarom is het leeg + wat de user kan doen
3. **Action** — een primary button die naar de fix leidt

**Anti-pattern:** "Loading..." die niet eindigt = lege state. Loading is niet hetzelfde als empty.

---

## 6. Re-onboarding na grote updates

Wanneer:
- Major UI-redesign (v2.0)
- Nieuwe key features die niet self-explanatory zijn
- Account-migration of paid-tier wijzigingen

Hoe:
- Eén-tijdige sheet bij eerste open na update
- "What's new" met max 3 highlights
- "Skip" altijd beschikbaar
- Nooit blockerend

```swift
@AppStorage("lastSeenWhatsNewVersion") var lastSeen = "0.0"

if currentVersion > lastSeen {
    // toon what's new sheet
}
```

---

## 7. Account creation friction

### Sign in with Apple (preferred)

```swift
SignInWithAppleButton(onRequest: { req in
    req.requestedScopes = [.fullName, .email]
}, onCompletion: handleAuth)
```

- Een tap, geen wachtwoord, privacy-relay-email
- Verplicht als je third-party social login hebt
- **Niet** verplicht als enige optie

### Magic links

Email-only, geen wachtwoord:
1. User typt email
2. App stuurt link
3. User klikt link in mail-app
4. Universal Link opent app, logged in

Voordeel: geen wachtwoord-stress. Nadeel: vereist email check.

### Anonymous accounts

Voor apps die data lokaal kunnen houden tot user wil syncen:
- Eerste open: lokale anonieme ID
- Sync optioneel later
- Account-creation moment uitgesteld tot ze waarde gezien hebben

---

## 8. Tutorial vs. progressive disclosure

### Tutorial (één keer alles uitleggen)
- Werkt voor: simple apps met 3-5 features
- Anti-pattern: 7-stappen tutorial voor complexe apps

### Progressive disclosure (just-in-time)
- Tooltip de eerste keer een feature gebruikt wordt
- Hint pas zichtbaar als context relevant is
- Onthouden welke je gezien hebt

```swift
@AppStorage("seen_swipe_to_delete_hint") var seenSwipeHint = false

// In view
if !seenSwipeHint {
    HintBubble(text: "Veeg om te verwijderen") {
        seenSwipeHint = true
    }
}
```

---

## 9. Onboarding-metrics (zie ook `observability.md`)

Track funnel:
- `onboarding.started`
- `onboarding.step_completed` (with step number/name)
- `onboarding.abandoned` (with last step)
- `onboarding.completed`
- `first_value_moment` (eerste echte gebruik van core feature)

**Wat zoek je:**
- Drop-off > 30% op één stap = je vraagt te veel of legt het slecht uit
- Time-to-first-value > 2 minuten = onboarding te lang

---

## 10. App Review aandachtspunten

- **Geen onboarding die feature gebruik blokkeert** zonder login. Apple Guideline 5.1.1(v): "If your app doesn't include significant account-based features, let people use it without a login."
- **Camera/locatie/contacts permissions met duidelijke usage descriptions** — niet generic.
- **Empty states moeten functioneel zijn** — niet alleen tekst.
- **Account deletion vanuit eerste 5 schermen bereikbaar** indien account verplicht.

---

## 11. Anti-patterns

- ❌ Splash screen met "Even geduld" 5 seconden lang.
- ❌ 7 carousel-schermen voordat user iets kan doen.
- ❌ Permission-prompt bij launch zonder priming.
- ❌ "Maak een account aan om verder te gaan" als enige optie.
- ❌ Lege state met alleen "Geen items".
- ❌ Tooltip die niet weggeklikt kan worden.
- ❌ Nieuwe gebruiker wordt direct naar betaalmuur geleid.
- ❌ Onboarding die elke launch verschijnt (no `@AppStorage` voor "seen").

---

## 12. Checklist

- [ ] Onboarding-archetype gekozen en gedocumenteerd
- [ ] Permission priming voor camera/location/contacts/notifications
- [ ] Geen system permission prompts bij launch
- [ ] Elke empty state heeft visueel + uitleg + action
- [ ] Sign in with Apple beschikbaar (indien social login)
- [ ] Account-creation uitstelbaar (anonymous start)
- [ ] Onboarding-funnel events getrackt
- [ ] What's New sheet voor major versions
- [ ] Account deletion bereikbaar binnen 3 taps
- [ ] Reviewer kan app gebruiken zonder account (waar mogelijk)
