# networking-resilience.md — Networking & API-resilience

> **Doel:** patterns voor robuuste networking die productie-realiteit aankunnen — slechte verbindingen, server-fouten, token-expiratie, race conditions.
> **Wanneer raadplegen:** Fase 4 (Infrastructure) bij het bouwen van de network layer.
> **Hoort bij:** `architecture.md` §11 (secrets), `observability.md` (logging requests).

---

## 1. Timeouts — geen requests zonder grenzen

```swift
let config = URLSessionConfiguration.default
config.timeoutIntervalForRequest = 30        // tijd tussen bytes
config.timeoutIntervalForResource = 120      // totale tijd voor request+response
config.waitsForConnectivity = true           // wacht op netwerk i.p.v. fail
```

**Regels:**

- `timeoutIntervalForRequest` (30s default) — per byte ontvangst.
- `timeoutIntervalForResource` (120s default) — totale request lifetime, incl. retries.
- **Per-call override** mogelijk via `URLRequest.timeoutInterval` voor specifieke endpoints.
- **Streaming endpoints** (SSE, downloads): `timeoutIntervalForResource` op `.infinity` of zeer hoog.
- `waitsForConnectivity = true` is meestal wat je wilt: als gebruiker offline is, wacht op terugkeer i.p.v. fail.

---

## 2. Retry-strategie met exponential backoff + jitter

**Wanneer wel retryen:**
- Netwerk-fouten (`URLError.timedOut`, `.notConnectedToInternet`)
- HTTP 5xx (server error)
- HTTP 429 (rate limited) — gebruik `Retry-After` header indien aanwezig
- HTTP 408 (request timeout)

**Wanneer NIET retryen:**
- HTTP 4xx behalve 408, 429
- Authenticatie-fouten (401, 403) — dat moet refresh of re-login worden
- Validation-fouten (400, 422)

**Implementatie:**

```swift
public struct RetryPolicy {
    public let maxAttempts: Int
    public let baseDelay: TimeInterval
    public let maxDelay: TimeInterval

    public static let `default` = RetryPolicy(
        maxAttempts: 3,
        baseDelay: 0.5,
        maxDelay: 30
    )

    /// Exponential backoff met full jitter
    public func delay(for attempt: Int) -> TimeInterval {
        let exponential = baseDelay * pow(2, Double(attempt))
        let capped = min(exponential, maxDelay)
        return TimeInterval.random(in: 0...capped)
    }
}

public actor ResilientHTTPClient {
    private let session: URLSession
    private let policy: RetryPolicy

    public func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        var lastError: Error?

        for attempt in 0..<policy.maxAttempts {
            do {
                let (data, response) = try await session.data(for: request)
                guard let http = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }

                if http.statusCode == 429 {
                    let retryAfter = http.value(forHTTPHeaderField: "Retry-After")
                        .flatMap(TimeInterval.init) ?? policy.delay(for: attempt)
                    try await Task.sleep(for: .seconds(retryAfter))
                    continue
                }

                if (500...599).contains(http.statusCode) {
                    if attempt < policy.maxAttempts - 1 {
                        try await Task.sleep(for: .seconds(policy.delay(for: attempt)))
                        continue
                    }
                }

                return (data, http)
            } catch let error as URLError where error.isRetriable {
                lastError = error
                if attempt < policy.maxAttempts - 1 {
                    try await Task.sleep(for: .seconds(policy.delay(for: attempt)))
                }
            }
        }

        throw lastError ?? NetworkError.unknown
    }
}

extension URLError {
    var isRetriable: Bool {
        [.timedOut, .networkConnectionLost, .notConnectedToInternet, .dnsLookupFailed].contains(code)
    }
}
```

**Jitter is geen luxe.** Zonder jitter retryen 1000 clients tegelijk en hameren je server. Met jitter spreiden ze over een venster.

---

## 3. Token refresh zonder race conditions

Het meest voorkomende productie-bug: 5 parallelle requests krijgen 401, alle 5 starten een refresh, server maakt 5 nieuwe tokens, 4 worden direct geinvalideerd, 4 calls falen.

**Oplossing: één refresh tegelijk, anderen wachten:**

```swift
public actor TokenManager {
    private var currentToken: String?
    private var refreshTask: Task<String, Error>?

    public func validToken() async throws -> String {
        if let token = currentToken, !isExpired(token) {
            return token
        }

        // Als er al een refresh loopt: wacht erop, geen nieuwe starten.
        if let existing = refreshTask {
            return try await existing.value
        }

        let task = Task<String, Error> {
            defer { refreshTask = nil }
            let newToken = try await performRefresh()
            currentToken = newToken
            return newToken
        }

        refreshTask = task
        return try await task.value
    }

    private func performRefresh() async throws -> String {
        // call refresh endpoint
    }
}
```

`actor` garandeert dat de check-or-create-task atomair is.

---

## 4. Offline-queue voor schrijfacties

Wat moet gebeuren als gebruiker offline is en op "verstuur" drukt?

**Strategieën:**

| Type actie | Strategie |
|-----------|-----------|
| Idempotente schrijf (PUT met client-ID) | Queue + retry bij reconnect |
| Niet-idempotente (POST zonder dedup-key) | Vraag server om idempotency-key support, of waarschuw user |
| Read-only | Cache lezen, niet queue |

**Patroon:**

```swift
public struct PendingOperation: Codable, Sendable {
    public let id: UUID
    public let endpoint: String
    public let method: String
    public let body: Data?
    public let createdAt: Date
    public var attempts: Int
}

public actor OperationQueue {
    private var pending: [PendingOperation] = []
    private let storage: PersistedQueue
    private let client: ResilientHTTPClient

    public func enqueue(_ op: PendingOperation) async throws {
        pending.append(op)
        try await storage.save(pending)
    }

    public func drain() async {
        // Aangeroepen bij netwerk-restore
        while let op = pending.first {
            do {
                _ = try await client.send(URLRequest(operation: op))
                pending.removeFirst()
                try? await storage.save(pending)
            } catch {
                // Behoud in queue, probeer later
                break
            }
        }
    }
}
```

**Belangrijk:** queue moet persistent zijn (overleeft app-restart). Queue moet leesbaar zijn voor user ("Je hebt 3 berichten in de wachtrij").

---

## 5. Reachability — modern patroon

`Network.framework`'s `NWPathMonitor` (iOS 12+):

```swift
import Network

public actor Reachability {
    private let monitor = NWPathMonitor()
    private var continuation: AsyncStream<Bool>.Continuation?

    public lazy var stream: AsyncStream<Bool> = {
        AsyncStream { continuation in
            self.continuation = continuation
            monitor.pathUpdateHandler = { path in
                continuation.yield(path.status == .satisfied)
            }
            monitor.start(queue: .global(qos: .background))
        }
    }()
}
```

**Niet gebruiken:** `Reachability.swift` library — vervangen door bovenstaande in moderne Swift.

**Regel:** UI-state ("offline-banner") luistert naar deze stream. Networking-laag doet GEEN preflight reachability-check — gewoon proberen, falen, retry.

---

## 6. Certificate pinning — alleen waar nodig

Pinning is een **trade-off**:
- ✅ Beschermt tegen MITM zelfs als CA gecompromitteerd is
- ❌ App breekt als certificaat roteert (en dat doet het, elke 12 maanden)

**Alleen pinnen voor:**
- Banking, healthcare, identity-apps
- Endpoints met gevoelige PII
- Niet voor algemene API's

**Implementatie:** gebruik public key pinning (overleeft cert rotation), niet certificate pinning. Library: `TrustKit`. **Vergeet niet een fallback-mechanisme** voor noodgevallen (remote config flag om pinning uit te zetten).

---

## 7. Foutmapping naar Core-errors

**Regel uit `architecture.md`:** geen `URLError` of third-party errors lekken naar features.

```swift
public enum NetworkError: Error, Equatable {
    case offline
    case timeout
    case rateLimited(retryAfter: TimeInterval?)
    case authenticationFailed
    case forbidden
    case notFound
    case serverError(statusCode: Int)
    case decodingFailed(underlying: String)
    case unknown
}

func map(_ error: Error) -> NetworkError {
    if let urlError = error as? URLError {
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost: return .offline
        case .timedOut: return .timeout
        default: return .unknown
        }
    }
    return .unknown
}
```

User-facing messages dan in feature-laag, want lokalisatie + context bepalen daar de copy.

---

## 8. Logging — wat wel, wat niet

Zie `observability.md` voor volledige guidance. Korte regels:

- ✅ Endpoint URL (zonder query params met PII)
- ✅ HTTP status, latency, retry count
- ✅ Request-ID (`x-request-id` header) voor server-side correlatie
- ❌ Request bodies (kan tokens, passwords bevatten)
- ❌ Authorization headers
- ❌ Response bodies (kan PII bevatten)
- ❌ Cookies

---

## 9. Testing networking

- **Unit tests:** mock de `HTTPClient`-protocol, test feature-logic.
- **Integration tests:** echte sandbox endpoints, gemarkeerd `slow`.
- **VCR-style cassettes** voor stabiele reproductie:
  - Library: `Mocker` (SPM)
  - Of custom met `URLProtocol`-subclass.

```swift
final class MockHTTPClient: HTTPClient {
    var stubbedResponses: [URL: Result<Data, Error>] = [:]
    var capturedRequests: [URLRequest] = []

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        capturedRequests.append(request)
        guard let url = request.url, let response = stubbedResponses[url] else {
            throw NetworkError.notFound
        }
        switch response {
        case .success(let data):
            let http = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (data, http)
        case .failure(let error):
            throw error
        }
    }
}
```

---

## Checklist voor je networking layer

- [ ] Timeouts gezet (request + resource)
- [ ] Retry policy met exponential backoff + jitter
- [ ] 429 handling met `Retry-After`
- [ ] Token refresh actor-based (geen race conditions)
- [ ] Offline queue voor schrijfacties (indien applicable)
- [ ] `NWPathMonitor` voor UI offline-state
- [ ] Cert pinning afweging gemaakt en gedocumenteerd
- [ ] Errors gemapped naar Core-errors
- [ ] Logging hygienisch (geen secrets, geen PII)
- [ ] Mock HTTPClient voor unit tests
- [ ] Integration tests met sandbox/staging
