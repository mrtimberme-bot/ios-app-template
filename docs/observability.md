# observability.md — Analytics, Crash Reporting, Performance Metrics

> **Doel:** weten wat je app doet in productie zonder de privacy van gebruikers te schenden.
> **Wanneer raadplegen:** Fase 4 (instrumentation), Fase 7 (UX-meten), Fase 8 (validatie van metrics-pipeline).
> **Hoort bij:** `app_store_readiness.md` §1 (Privacy Manifest), `networking-resilience.md` §8 (logging hygiëne).

---

## 1. Drie pijlers

| Pijler | Wat | Voorbeeld-tools |
|--------|-----|----------------|
| **Crash reporting** | Onverwachte crashes en non-fatal errors | MetricKit (gratis, Apple), Sentry, Bugsnag, Crashlytics |
| **Analytics** | Wat doen gebruikers met je app | TelemetryDeck (privacy-first), Mixpanel, Amplitude, PostHog |
| **Performance metrics** | App launch, hangs, memory, energy | MetricKit (`MXMetricManager`), Firebase Performance |

**Privacy-first stack voor solo dev:** MetricKit + TelemetryDeck. Beide GDPR-vriendelijk, geen IDFA, geen ATT-prompts nodig.

---

## 2. Event-schema definiëren

**Schrijf eerst je events op, voor je code schrijft.** Een schema-document in `docs/analytics-events.md`:

```markdown
## conversation.created
**When:** Gebruiker start een nieuwe conversatie.
**Properties:**
  - source: "manual" | "from_template" | "shared_link"
  - provider: "openai" | "anthropic" | "perplexity"
**Used for:** funnel-analyse (hoeveel conversaties per actieve gebruiker).
**Privacy:** geen content, geen titel, alleen aggregates.
```

**Naming-conventie:**
- `<entity>.<action>` (snake_case): `conversation.created`, `chat.message_sent`, `paywall.shown`
- Geen kamelcase, geen spaties, max 40 tekens
- Properties ook snake_case

---

## 3. Wat WEL en NIET tracken

### ✅ Tracken (aggregaten, niet content):
- App launch (foreground, backgrounded)
- Feature-usage (`chat.started`, `settings.opened`)
- Funnel-stappen (onboarding completion rate)
- Errors die user-facing zijn (`payment.failed`, `sync.failed`)
- Performance metrics (response times)
- A/B variant assignments

### ❌ NIET tracken (privacy-violatie):
- Berichteninhoud / user-generated text
- Email-adressen, namen, telefoonnummers
- Locatie nauwkeuriger dan land (tenzij feature het vereist + opt-in)
- Device-IDs die persistent zijn over apps heen (IDFA = ATT-prompt = friction)
- Andere apps die gebruiker heeft geïnstalleerd

**Test:** kun je deze data per ongeluk publiceren zonder iemand pijn te doen? Zo niet, niet tracken.

---

## 4. Privacy-first analytics integration

### TelemetryDeck (aanbeveling voor solo)

```swift
import TelemetryClient

// In App.swift
init() {
    let config = TelemetryManagerConfiguration(appID: "<UUID>")
    TelemetryManager.initialize(with: config)
}

// Anywhere
TelemetryManager.send("conversation.created", with: [
    "source": "manual",
    "provider": "openai"
])
```

**Voordelen:**
- Geen ATT-prompt nodig
- GDPR-compliant out-of-box
- Geen persistent device-ID

### Custom abstraction laag

Wrap altijd je analytics-tool achter een protocol:

```swift
public protocol AnalyticsClient: Sendable {
    func track(_ event: String, properties: [String: String])
    func setUserProperty(_ key: String, value: String?)
}

public final class TelemetryDeckClient: AnalyticsClient { /* ... */ }
public final class FakeAnalyticsClient: AnalyticsClient {
    public var events: [(String, [String: String])] = []
    public func track(_ event: String, properties: [String: String]) {
        events.append((event, properties))
    }
}
```

Hierdoor:
- Tests kunnen events asserten zonder netwerk
- Analytics-tool wisselen vereist alleen één file aanpassen
- Per-environment kun je no-op implementeer (debug)

---

## 5. Crash reporting

### MetricKit (gratis, Apple-native)

```swift
import MetricKit

final class CrashSubscriber: NSObject, MXMetricManagerSubscriber {
    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        for payload in payloads {
            for crash in payload.crashDiagnostics ?? [] {
                let json = crash.jsonRepresentation()
                // Stuur naar je server of log lokaal
                CrashStore.save(json)
            }
        }
    }
}

// In App init:
MXMetricManager.shared.add(CrashSubscriber.shared)
```

**Trade-off MetricKit:**
- ✅ Gratis, Apple-native, privacy-vriendelijk
- ✅ Hangs, energy, disk-write volume
- ❌ 24-uur vertraging
- ❌ Alleen aggregaten, geen real-time

### Sentry/Crashlytics (real-time)

Voor real-time crashes:
- Sentry SDK: privacy-vriendelijker dan Firebase
- Configureer altijd:
  - `beforeSend` om PII te strippen
  - `tracesSampleRate` low (0.1) om kosten te besparen
  - User-ID hashed, niet email/UUID

```swift
SentrySDK.start { options in
    options.dsn = ProcessInfo.processInfo.environment["SENTRY_DSN"]
    options.tracesSampleRate = 0.1
    options.beforeSend = { event in
        event.user?.email = nil
        event.user?.ipAddress = nil
        return event
    }
}
```

---

## 6. Performance metrics

### App launch tracking

```swift
import MetricKit

extension MXAppLaunchMetric {
    var coldLaunchP90: Measurement<UnitDuration>? {
        histogrammedTimeToFirstDraw.bucketEnumerator
            .lazy
            .compactMap { $0 as? MXHistogramBucket<UnitDuration> }
            .first(where: { $0.bucketCount > 0 })?
            .bucketStart
    }
}
```

**Doel-metrics:**
- Cold launch p90: <2000ms
- Warm launch p90: <500ms
- Hang rate: <1% van foreground time

### Custom transactions

```swift
public actor PerformanceTracker {
    public func measure<T>(_ name: String, work: () async throws -> T) async rethrows -> T {
        let start = ContinuousClock.now
        let result = try await work()
        let duration = ContinuousClock.now - start
        analytics.track("perf.\(name)", properties: [
            "duration_ms": String(duration.components.seconds * 1000)
        ])
        return result
    }
}

// Usage
let messages = try await tracker.measure("chat.fetch_history") {
    try await provider.fetchHistory(limit: 50)
}
```

---

## 7. Logging-hygiëne (lokaal `os.Logger`)

```swift
import os

extension Logger {
    static let network = Logger(subsystem: "com.app.AI Hub", category: "network")
    static let storage = Logger(subsystem: "com.app.AI Hub", category: "storage")
}

// Gebruik privacy-modifiers!
Logger.network.info("Request to \(url, privacy: .public) with status \(code, privacy: .public)")
Logger.network.info("User \(userID, privacy: .private)")  // wordt redacted in non-debug
```

**Regels:**
- `privacy: .public` voor URLs (zonder tokens), status codes, enum values
- `privacy: .private` (default) voor alles met user-data
- `privacy: .sensitive` voor extra-gevoelig (medical, financial)

**Wat NOOIT loggen:**
- Auth tokens, API keys
- Wachtwoorden (ook niet "voor debug")
- Volledige request/response bodies
- User input

---

## 8. Privacy Manifest alignement

**Elk analytics-event moet kloppen met je `PrivacyInfo.xcprivacy`.**

Als je tracked welke "providers" gebruikt worden:
- Privacy Manifest: `NSPrivacyCollectedDataTypes` met `NSPrivacyCollectedDataTypeOtherUsageData`
- Privacy Policy moet vermelden dat je usage-data verzamelt
- Privacy Policy moet vermelden waar deze data heen gaat (jouw server, third-party)

**Inconsistentie = App Review rejection.**

Check vóór elke release: open je analytics dashboard, lijst alle events, vergelijk met privacy manifest. Mismatch? Fix vóór submission.

---

## 9. Dashboards en alerting

**Je hebt drie dashboards nodig:**

1. **Real-time errors** — crashes/non-fatals laatste 24u, gegroepeerd per type. Doel: P0 incidents binnen 1 uur ontdekken.
2. **Funnel-overview** — onboarding completion, key feature adoption. Doel: drop-offs identificeren.
3. **Performance** — p50/p90/p99 launch, key API latencies. Doel: regression-detectie tussen releases.

**Alerting (minimaal):**
- Crash-rate >0.5% van sessions in 1 uur
- API error-rate >5% in 15 minuten
- Cold launch p90 >3s in 1 uur

Tools: Sentry alerts, Datadog, of simpele cron-job die metrics-API checkt en push stuurt.

---

## 10. Anti-patterns

- ❌ Tracken zonder schema. → Na 6 maanden 47 events met inconsistente naming, niemand weet wat ze betekenen.
- ❌ Berichteninhoud loggen "voor debugging". → GDPR-violatie + App Review rejection.
- ❌ User-ID = email-adres. → Hash het, of gebruik anonymous UUID.
- ❌ Geen alerting. → Pas via App Store reviews ontdekken dat productie kapot is.
- ❌ Analytics in tests laten draaien. → Pollueert productie-data. Gebruik fake client.
- ❌ ATT-prompt zonder reden. → Vermijdbare friction; gebruik privacy-first analytics.

---

## 11. Checklist

- [ ] Event-schema in `docs/analytics-events.md`
- [ ] AnalyticsClient-protocol in Core, concrete in Infrastructure
- [ ] FakeAnalyticsClient voor tests
- [ ] MetricKit subscriber voor crashes en performance
- [ ] Crash reporter geconfigureerd met PII-stripping
- [ ] `os.Logger` met juiste privacy-modifiers
- [ ] Geen tokens of bodies in logs
- [ ] Privacy Manifest gealigneerd met events
- [ ] Real-time crash-rate dashboard
- [ ] Funnel-dashboard voor onboarding
- [ ] Alerting voor crash/error/performance regressions
- [ ] Documentatie wat WEL en NIET getracked wordt
