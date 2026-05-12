# Fase 10 — Pre Go-to-Apple

> **Doel:** laatste poort vóór de daadwerkelijke App Store submission. Niet bouwen, niet polijsten — alleen verifiëren dat je niet voor een vermijdbare rejection-grond instuurt.
> **Versie na afsluiten:** v0.10 (= go-to-apple cleared)
> **Vorige fase:** [09-app-store-readiness.md](./09-app-store-readiness.md)
> **Volgende fase:** v1.0 = App Store submission

---

## Waarom deze fase apart staat

Fase 9 is "alle assets en compliance op orde". Fase 10 is "ik heb met mijn eigen ogen geverifieerd dat de submit-knop nu veilig is om in te drukken."

Dat klinkt dubbel, maar het is precies de fase waar solo devs het vaakst onderuit gaan: in Fase 9 vink je dingen af, in Fase 10 test je of die vinkjes ook in de praktijk kloppen. Eerste-keer-rejections kosten gemiddeld 1-2 weken doorlooptijd — déze fase is je verzekering daartegen.

---

## Activiteiten

### 1. External TestFlight review-cycle

**Niet overslaan, ook niet als je krap in de tijd zit.**

- Submit voor External TestFlight (Beta App Review).
- Wachttijd: meestal 24-48 uur.
- Bij approval: minimaal 3 dagen je app gebruiken in External TestFlight context.
- Bij rejection: lees Resolution Center notes, fix, resubmit. Pas dan door naar volgende stap.

Het kost je **maximaal een week**. Een rejection in App Review kost je **minimaal twee**.

### 2. Privacy policy verificatie

- Privacy Policy URL openen in een **incognito browser** (niet je eigen logged-in sessie).
- Bereikbaar? 200 OK?
- In de juiste taal?
- Dekt het écht wat je app doet? Loop je `docs/privacy-data-flow.md` (uit Fase 4) door en check dat elk dataflow-item terugkomt in de policy.
- Account deletion in policy beschreven (indien accounts ondersteund)?
- Werkt de URL ook over 30 dagen nog? (Geen Notion-link met expiry, geen tijdelijke Vercel-preview-URL.)

### 3. Demo-account live test

- Open de demo-account credentials uit App Store Connect.
- Log uit van je eigen account op een **schoon device** (of fresh simulator).
- Log in met **alleen de credentials uit App Store Connect** — kopieer-plak ze, type ze niet over uit geheugen.
- Doorloop alle features die de reviewer moet kunnen zien.
- Check: zit er geen feature achter een paywall, feature-flag, of regio-restrictie die voor de reviewer dichtzit?

### 4. Screenshots vs werkelijkheid

Voor élke screenshot in App Store Connect:

- Open de feature die de screenshot toont.
- Werkt de feature **exact zoals de screenshot suggereert**?
- Geen oude UI in screenshots? Geen features die je hebt verwijderd?
- Tekst in screenshots klopt met huidige copy?
- Niet alleen primaire taal — ook gelocaliseerde screenshots tegen de gelocaliseerde app houden.

**Guideline 2.3 (Accurate Metadata)** is een van Apple's top rejection-gronden. Klein detail in een screenshot kan een hele review-cyclus kosten.

### 5. Reviewer Notes lezen alsof je de reviewer bent

- Open de "App Review Information" notes in App Store Connect.
- Lees ze hardop voor.
- Kun je met **alleen deze notes + de demo-account** binnen 5 minuten alle key features bereiken?
- Staat er onnodige info in (interne notities, dev-context)?
- Zijn er dingen die de reviewer moet weten en niet in de notes staan? (Bv. "Voor feature X, ga naar Settings → Beta Features en zet 'Enable Foo' aan.")

### 6. Build sanity-check

- Build version is hoger dan elke eerdere upload.
- Marketing version klopt met je laatste git tag.
- Release configuration, niet Debug.
- Symbols geüpload voor crash reporting.
- Geen `print()` of debug-only code paths actief.

### 7. Final fresh-install test

Op een **fysiek device dat niet je dev-device is** (lenen mag):

- App van TestFlight verwijderen als hij erop staat.
- Schone install via TestFlight.
- Doorloop onboarding zonder uitleg vooraf.
- Check: zou een onbekende reviewer op dit device hetzelfde kunnen?

---

## Anti-patterns

- ❌ External TestFlight overslaan en direct submit. → Eerste rejection kost 1-2 weken extra.
- ❌ Privacy policy "we'll add it later". → Hard rejection-grond.
- ❌ Demo-account niet werken. → Hard rejection-grond.
- ❌ Screenshots tonen features die niet werken. → 2.3 violation.

---

## Exit-gate (= v0.10 bereikt = klaar voor submit)

- [ ] External TestFlight build heeft minstens één review-cycle doorlopen zonder rejection
- [ ] Privacy Policy URL is geopend in incognito browser en bereikbaar
- [ ] Privacy Policy dekt alle data-flows uit `docs/privacy-data-flow.md`
- [ ] Demo-account is getest op schoon device met alleen App Store Connect credentials
- [ ] Alle screenshots vs. werkelijkheid 1-op-1 gecontroleerd
- [ ] Reviewer Notes hardop voorgelezen en compleet bevonden
- [ ] Build version + marketing version + Release config geverifieerd
- [ ] Fresh-install test op een niet-dev device geslaagd
- [ ] Geen openstaande P0/P1-bugs
- [ ] **Git-tag:** `v0.10-go-to-apple-cleared`
- [ ] CHANGELOG.md geüpdatet

---

## Tips

- Doe deze fase op een andere dag dan Fase 9. Frisse blik vangt 80% meer issues.
- Laat als het kan iemand anders de demo-account-test doen. Wat voor jou vanzelfsprekend is, struikelt een vreemde over.
- Houd een persoonlijk "bijna-rejection-logboek" bij — wat had je bijna gemist? Volgende app vink je het sneller af.

---

## Naar v1.0

Pas ná een groene Fase 10 druk je op "Submit for Review":

1. App Store Connect → Submit for Review.
2. Wacht 24-48 uur op review.
3. Bij rejection: Resolution Center → fix → resubmit. (Zou nu zeldzaam moeten zijn.)
4. Bij approval: kies Manual Release of Automatic Release.
5. Tag `v1.0` zodra live in App Store.
