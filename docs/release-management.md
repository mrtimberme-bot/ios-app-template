# release-management.md — Releases, Rollback & Incident Response

> **Doel:** veilig releasen, snel reageren als productie kapotgaat, en niet in paniek raken op vrijdagavond.
> **Wanneer raadplegen:** elke App Store release, elk productie-incident, certificate-rotation.
> **Hoort bij:** `phases/10-pre-go-to-apple.md`, `data-migration.md` (rollback), `observability.md` (alerting).

---

## 1. Phased Release Rollout

App Store Connect → Version → "Phased Release for Automatic Updates":

- Dag 1: 1% van users
- Dag 2: 2%
- Dag 3: 5%
- Dag 4: 10%
- Dag 5: 20%
- Dag 6: 50%
- Dag 7: 100%

**Wanneer wel:** elke release. Geen reden om uit te zetten behalve hotfixes (zie §4).

**Voordeel:** crash-piek bij 1% → pause vóór 50% geraakt is.

**Pause-knop:** App Store Connect → Version → Phased Release → Pause.

---

## 2. Pre-release checklist

Naast `phases/10-pre-go-to-apple.md`:

### Deployment readiness
- [ ] Crash-rate van vorige versie <0.5% (geen problemen overdragen)
- [ ] Gemiddelde rating >4.0 in laatste 30 dagen
- [ ] Geen openstaande P0-bugs in tracker
- [ ] Privacy Policy versie matchen met data-flow van deze release
- [ ] Migration tested op productie-database-kopie (zie `data-migration.md` §5)
- [ ] Feature flags ingesteld correct voor productie
- [ ] Backend-deployments voor deze release zijn al live (server vóór client!)

### Communication
- [ ] CHANGELOG.md committed
- [ ] What's New tekst klaar
- [ ] Support team / docs aangepast
- [ ] Social media / blog (indien relevant)

### Monitoring
- [ ] Dashboards open: crash-rate, error-rate, key metrics
- [ ] Alerting actief (zie `observability.md` §9)
- [ ] On-call beschikbaar tijdens initial rollout (eerste 24-48u)

---

## 3. Backend-vóór-client principe

**Regel:** server-side veranderingen MOETEN live zijn vóór de app-versie die ze gebruikt.

Reden: app-update reaches users over dagen/weken (Phased Release), maar oude versies blijven in productie.

**Patroon:**
1. Backend deployt nieuwe API endpoints (forward-compatible).
2. Backend test met staging-app dat het werkt.
3. Backend doet rolling deploy naar productie.
4. Wacht 24u — observeer.
5. *Daarna* app-release submission.

**Backwards compatibility:** als app v1.5 een endpoint aanroept dat in v1.6 verdwijnt, breken alle v1.5-users. Houd oude endpoints minstens 6 maanden in leven.

---

## 4. Hotfix flow

Wanneer een release kritieke bugs heeft:

### Stap 1: Pause Phased Release
App Store Connect → pause meteen. Voorkomt verdere blootstelling.

### Stap 2: Diagnose
- Open crash-dashboard
- Check error-rate per endpoint
- Reproduceer lokaal als mogelijk

### Stap 3: Quick fix
- Branch `hotfix/v1.5.1-critical-crash` van de released tag
- Minimaal mogelijke change om bug te fixen
- Geen extra features, geen refactor
- Test op fysiek device + TestFlight Internal

### Stap 4: Expedited Review
App Store Connect → submit met "Request Expedited Review":
- Korte uitleg: "Critical crash on launch affecting [percentage] of users."
- Apple keurt meestal binnen 24 uur goed.

### Stap 5: Resume Phased Release
Vervang oude version met hotfix. Phased rollout kan opnieuw aan, of zet 100% direct.

### Stap 6: Postmortem
Schrijf in `docs/postmortems/YYYY-MM-DD-incident.md`:
- Wat ging fout?
- Waarom is het door QA / Phased Release heen geslipt?
- Wat verandert er om dit te voorkomen?

---

## 5. Server-side kill-switch via feature flags

Combineer met `architecture.md` §15 (Feature Flags):

```swift
public struct RemoteFeatureFlags: Codable {
    public let enableSync: Bool
    public let enableExperimentalUI: Bool
    public let maintenanceMode: Bool
}

// Refreshed periodiek of bij app-launch:
let remote = try await api.fetchFlags()
FeatureFlags.applyRemote(remote)
```

**Wanneer kill-switch gebruiken:**
- Feature blijkt server-side issues te veroorzaken
- App Review wil tijdelijk uitgezet zien
- Privacy/legal-issue ontdekt

**Architectuur:**
- Default: feature aan (server unreachable = niet uitzetten)
- Cache laatste flags lokaal (offline werkt)
- Geen kill-switch op auth/onboarding/payment — als die kapot zijn moet hotfix release komen

---

## 6. Certificate & key rotation

### App Distribution certificate (jaarlijks)
- Verloopt 1 jaar na issue
- Verloop = geen builds meer ondertekenen
- App Store Connect waarschuwt 30 dagen vooraf
- Renew via Apple Developer Portal
- Update CI met nieuwe certificate (in secrets)

### APNs .p8 key
- Verloopt niet (in tegenstelling tot oudere certs)
- Bewaar offsite backup
- Rotate alleen bij vermoeden van compromittering

### Provisioning profiles
- Verlopen samen met certificate
- Auto-renew als je "Automatically manage signing" gebruikt
- Manual signing: regenerate na cert renewal

### App-specific passwords / API tokens (App Store Connect)
- Rotate elke 6 maanden
- Wanneer team-lid weggaat: revoke meteen

---

## 7. Verbreking van iOS-versie support

Als je deployment target verhoogt (iOS 17 → iOS 18):

### Communicatie
- 30 dagen vóór release: in-app banner "We bewegen naar iOS 18 — werk je device bij"
- What's New: "Vereist iOS 18 vanaf nu"

### iOS Connect handles legacy users
- App Store Connect: "Last Compatible Version" wordt automatisch gediend aan oudere iOS-users
- Nieuwe versie wordt alleen aangeboden aan compatible devices
- Oude users blijven op laatste compatible versie steken

---

## 8. App Store search ranking impact

Releases beïnvloeden ranking:

- **Crash-rate spike** → Apple verlaagt ranking
- **Negative reviews na update** → ranking impact
- **Frequent updates** (wekelijks) → soms positief, vaak negatief
- **Major version verhoging zonder echte changes** → suspect

**Tempo:** 2-4 weken tussen significante releases is gezond. Hotfixes mogen vaker.

---

## 9. Incident runbook template

`docs/runbook.md` per project:

```markdown
# Incident Runbook

## Symptoom: Crashes na recente release
1. Open Crashlytics / Sentry dashboard
2. Filter op huidige versie
3. Top crashes? → tag in tracker
4. Pause Phased Release
5. Hotfix branch
6. Expedited Review

## Symptoom: API rate limited
1. Check provider dashboard
2. Lokale cache aan via remote flag
3. Roll back recent backend deploy?
4. Communicate via status page

## Symptoom: Apple Developer cert verlopen
1. Renew in Apple Developer Portal
2. Download new cert
3. Update GitHub Actions secret
4. Re-sign + re-submit pending builds

## Contacts
- Apple Developer Support: ...
- Sentry status page: ...
- Server-side on-call: ...
```

---

## 10. Communication tijdens incidents

### Status page

Voor apps met server-component:
- Statuspage.io, Instatus.com, of self-hosted (Cachet)
- Update bij elke major status-change
- Incl. estimated time to resolution

### App-internal communication

```swift
struct StatusBanner: View {
    @Bindable var status: AppStatus

    var body: some View {
        if status.hasIncident {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                Text(status.message)
            }
            .padding()
            .background(Color.yellow.opacity(0.2))
        }
    }
}
```

Status-feed van server, getoond in app bij active incidents.

### App Store Reviews

- Beantwoord negatieve reviews binnen 7 dagen
- Niet defensief, ook bij oneerlijke reviews
- "We hebben dit gefixt in v1.5.2 — kun je updaten?"

---

## 11. Anti-patterns

- ❌ Vrijdag-namiddag releasen. → Weekend incident-response is moeilijker.
- ❌ "We mergen alles in één grote release." → Iedere bug is een mystery.
- ❌ Geen Phased Release. → Bij crash-piek is alles al uitgerold.
- ❌ Hotfix met "small extra change". → Verlengt review, verhoogt risico.
- ❌ Geen rollback-plan. → In paniek bij eerste echte incident.
- ❌ Geen on-call tijdens rollout. → Incidents pas dagen later opgemerkt.
- ❌ Backend-deploys parallel met app-release. → Race conditions in productie.

---

## 12. Checklist per release

### Vóór submit
- [ ] Phased Release ingesteld
- [ ] Backend live + getest 24u tevoren
- [ ] CHANGELOG, What's New, support docs klaar
- [ ] Migration getest (zie `data-migration.md`)
- [ ] Feature flags op juiste defaults

### Na submit (review periode)
- [ ] App Review status checken (kan in 24-48u beslist worden)
- [ ] Reviewer Notes bereikbaar voor vragen

### Bij approval
- [ ] Auto-release of manual? Manual aanbevolen voor controle.
- [ ] Eerste 24u: dashboards monitoren
- [ ] Eerste 7 dagen: niet weg op vakantie zonder hand-over

### Bij issues
- [ ] Pause Phased Release
- [ ] Hotfix flow
- [ ] Postmortem na resolutie

---

## 13. Quick reference — als productie nu kapot is

1. **Pause Phased Release**: App Store Connect → Version → Phased Release → Pause.
2. **Toggle feature flags**: zet problematische features uit via remote config.
3. **Hotfix branch** van laatste-good tag: `git checkout -b hotfix/v1.5.1 v1.5.0`.
4. **Minimal fix**: alleen de bug, niets anders.
5. **TestFlight Internal**: 1 uur testen.
6. **Expedited Review**: submit met uitleg van impact.
7. **Postmortem**: schrijf binnen 48u na resolutie.
