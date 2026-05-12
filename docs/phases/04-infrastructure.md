# Fase 4 — Infrastructuur & Integraties

> **Doel:** echte implementaties achter de Core-protocols.
> **Versie na afsluiten:** v0.4
> **Vorige fase:** [03-core-domain.md](./03-core-domain.md)
> **Volgende fase:** [05-vertical-slice.md](./05-vertical-slice.md)

> **Diepte-referenties voor deze fase:**
> - [`networking-resilience.md`](../networking-resilience.md) — retry, timeout, token refresh, offline queue
> - [`security.md`](../security.md) — Keychain, Data Protection, ATS exceptions
> - [`observability.md`](../observability.md) — analytics + crash + logging hygiëne
> - [`build-configurations.md`](../build-configurations.md) — env-specifieke endpoints en secrets
> - [`data-migration.md`](../data-migration.md) — als je persistence later gaat migreren

---

## Activiteiten

### 1. Network layer

Kies één approach en houd je eraan:

| Optie | Wanneer |
|-------|---------|
| **URLSession + thin wrapper** | Default, geen extra deps |
| **Alamofire** | Veel multipart, complex retry logic, team-bekendheid |
| **OpenAPI Generator** | API met OpenAPI-spec, type-safe clients |

Implementeer in `Infrastructure/Network/`:

```swift
// Infrastructure/Network/HTTPClient.swift
public protocol HTTPClient: Sendable {
    func send<T: Decodable>(_ request: URLRequest) async throws -> T
}

public actor URLSessionHTTPClient: HTTPClient {
    private let session: URLSession
    private let decoder: JSONDecoder

    public init(session: URLSession = .shared, decoder: JSONDecoder = .init()) {
        self.session = session
        self.decoder = decoder
    }

    public func send<T: Decodable>(_ request: URLRequest) async throws -> T {
        // implementatie + error mapping naar Core-errors
    }
}
```

### 2. Persistence layer

Kies één:

| Optie | Wanneer |
|-------|---------|
| **SwiftData** | iOS 17+, simpel datamodel, niet-extreem |
| **Core Data** | Legacy, complex datamodel, fine-grained control |
| **GRDB** | SQLite-power, predictable performance, query-control |
| **In-memory only** | Tijdelijke data, geen persistence nodig |

Implementeer als concrete classes die Core-protocols voldoen.

### 3. Externe SDK's / API's

Per externe service een wrapper in `Infrastructure/Providers/`:

```swift
// Infrastructure/Providers/OpenAIChatProvider.swift
public actor OpenAIChatProvider: ChatProvider {
    private let client: HTTPClient
    private let apiKey: String

    public init(client: HTTPClient, apiKey: String) {
        self.client = client
        self.apiKey = apiKey
    }

    public func send(_ messages: [ChatMessage]) async throws -> ChatMessage {
        // mapping naar OpenAI-API DTO's, call, mapping terug
    }

    public func stream(_ messages: [ChatMessage]) -> AsyncThrowingStream<String, Error> {
        // SSE-stream parsing
    }
}
```

**Belangrijk:** errors van de externe service → mapping naar je Core-errors. Niemand buiten Infrastructure mag een third-party error-type zien.

### 4. Keychain-wrapper

Voor secrets en auth-tokens:

```swift
// Infrastructure/Keychain/KeychainStore.swift
public protocol KeychainStore: Sendable {
    func set(_ value: String, for key: String) throws
    func get(_ key: String) throws -> String?
    func delete(_ key: String) throws
}
```

### 5. Logging-abstractie

Gebruik `os.Logger` of `swift-log`:

```swift
// Infrastructure/Logging/AppLogger.swift
import OSLog

public enum AppLogger {
    public static let network = Logger(subsystem: "com.app.AppName", category: "network")
    public static let persistence = Logger(subsystem: "com.app.AppName", category: "persistence")
    public static let ui = Logger(subsystem: "com.app.AppName", category: "ui")
}
```

### 6. Privacy-relevante calls documenteren

Houd een running list bij in `/docs/privacy-data-flow.md`:

- Welke API's stuur je data naartoe?
- Welke data staat in de request?
- Welke data komt terug en wordt opgeslagen?
- Reasons voor Required Reason API's die je gebruikt.

Deze lijst is goud waard in Fase 9 voor de privacy manifest.

### 7. Integration tests

`Tests/InfrastructureTests/` — tests met **echte endpoints** (sandbox/staging) of recorded responses (cassettes).

Markeer als `slow` of zet in aparte scheme zodat ze niet bij elke build draaien.

```swift
final class OpenAIChatProviderIntegrationTests: XCTestCase {
    func test_send_returnsAssistantMessage() async throws {
        try XCTSkipIf(ProcessInfo.processInfo.environment["INTEGRATION_TESTS"] != "1")
        // ...
    }
}
```

---

## Exit-gate

- [ ] Elke Core-protocol heeft minstens één concrete implementatie in `Infrastructure/`
- [ ] Integration tests slagen tegen sandbox/staging endpoints
- [ ] Geen hardcoded secrets — alles via Keychain of `xcconfig`
- [ ] Errors uit third-party SDK's worden gemapped naar Core-errors
- [ ] `/docs/privacy-data-flow.md` bestaat en is gevuld
- [ ] Logging-abstractie staat
- [ ] Network layer voldoet aan checklist in [`networking-resilience.md`](../networking-resilience.md) §11
- [ ] Security-checklist [`security.md`](../security.md) §11 doorlopen voor wat van toepassing is
- [ ] Analytics & crash reporting opgezet — checklist in [`observability.md`](../observability.md) §11
- [ ] Build-configuraties (Debug/Beta/Release) ingericht — [`build-configurations.md`](../build-configurations.md) §13
- [ ] **Git-tag:** `v0.4-infra`
- [ ] CHANGELOG.md geüpdatet

---

## Anti-patterns

- ❌ Third-party error-types lekken naar Features. → Niemand buiten Infrastructure mag `OpenAIError` zien.
- ❌ API-keys in code. → `xcconfig` + `.gitignore` of Keychain.
- ❌ `URLSession.shared` overal direct gebruiken. → Maak het injecteerbaar voor tests.
- ❌ Geen integration tests. → Eerste keer dat je het in Fase 5 gebruikt, gaat het stuk.

---

## Tips

- Bouw je network-wrapper rond `async/await` van dag 1 — geen completion handlers.
- Recorded HTTP-cassettes (zoals VCR-style) zijn handig voor stabiele integration tests in CI.
- Houd de surface van de wrapper klein — nu één implementatie, later makkelijk uitbreidbaar.
