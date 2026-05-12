# Fase 3 — Core-domein modelleren

> **Doel:** je domein bestaat in code voordat er één UI-pixel getekend wordt.
> **Versie na afsluiten:** v0.3
> **Vorige fase:** [02-architecture-setup.md](./02-architecture-setup.md)
> **Volgende fase:** [04-infrastructure.md](./04-infrastructure.md)

> **Diepte-referenties voor deze fase:**
> - [`testing-strategy.md`](../testing-strategy.md) — wat te testen, builders, async patterns
> - [`docc-documentation.md`](../docc-documentation.md) — DocC voor publieke Core-protocols

---

## Belangrijke regel

In deze fase mag je **geen netwerk- of persistence-code schrijven** — alleen protocols + in-memory fakes voor tests. Dit dwingt je het domein zuiver te modelleren.

---

## Activiteiten

### 1. Domeinmodellen

`Core/Models/` — alleen `struct` en `enum`, geen `class` tenzij je ergens identity-semantiek nodig hebt.

```swift
// Core/Models/ChatMessage.swift
public struct ChatMessage: Identifiable, Sendable, Equatable {
    public let id: UUID
    public let role: Role
    public let content: String
    public let createdAt: Date

    public enum Role: String, Sendable {
        case user, assistant, system
    }
}
```

Vuistregel: kun je het serialiseren naar JSON en weer terug zonder informatieverlies? Dan klopt het.

### 2. Protocols voor externe afhankelijkheden

`Core/Protocols/` — één protocol per externe afhankelijkheid die in latere fases concreet wordt.

```swift
// Core/Protocols/ChatProvider.swift
public protocol ChatProvider: Sendable {
    func send(_ messages: [ChatMessage]) async throws -> ChatMessage
    func stream(_ messages: [ChatMessage]) -> AsyncThrowingStream<String, Error>
}
```

**Per MVP-feature uit Fase 1:** identificeer welke externe afhankelijkheden nodig zijn en maak een protocol.

### 3. Use cases / domain services

`Core/UseCases/` — pure logica, geen I/O. Testbaar zonder mocks.

```swift
// Core/UseCases/ConversationCompactor.swift
public struct ConversationCompactor {
    public init() {}

    public func compact(_ messages: [ChatMessage], maxTokens: Int) -> [ChatMessage] {
        // pure logica
    }
}
```

### 4. Errors als typed enums

`Core/Errors/` — één error-enum per domein, geen `Error`-strings.

```swift
// Core/Errors/ChatError.swift
public enum ChatError: Error, Equatable {
    case rateLimited(retryAfter: TimeInterval)
    case authenticationFailed
    case networkUnavailable
    case providerError(code: Int, message: String)
    case invalidResponse
}
```

### 5. In-memory fakes voor tests

`Tests/Fakes/` — voor elk Core-protocol een in-memory implementatie.

```swift
// Tests/Fakes/FakeChatProvider.swift
public final class FakeChatProvider: ChatProvider {
    public var sendStub: ([ChatMessage]) async throws -> ChatMessage = { _ in
        ChatMessage(id: UUID(), role: .assistant, content: "fake", createdAt: .now)
    }

    public func send(_ messages: [ChatMessage]) async throws -> ChatMessage {
        try await sendStub(messages)
    }

    public func stream(_ messages: [ChatMessage]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { _ in }
    }
}
```

### 6. Unit tests voor use cases

Coverage Core ≥80% line coverage. Test ook edge cases en errors.

---

## Exit-gate

- [ ] Core compileert standalone (geen Infrastructure-deps)
- [ ] Coverage Core ≥80%
- [ ] Alle MVP-features uit Fase 1 hebben minstens één protocol/usecase die hen dekt
- [ ] Elke `Core/Protocols/` heeft een fake in `Tests/Fakes/`
- [ ] Errors zijn typed enums, geen `Error`-strings
- [ ] Geen `import` van UI-frameworks of `Infrastructure` in Core
- [ ] **Git-tag:** `v0.3-core`
- [ ] CHANGELOG.md geüpdatet

---

## Anti-patterns

- ❌ Concrete URLSession-code in Core. → Core moet framework-agnostisch zijn.
- ❌ Protocols met methodes die alleen één implementatie ooit krijgt. → Skip de abstractie als er geen tweede implementatie denkbaar is.
- ❌ "Ik schrijf de tests later." → Je krijgt nooit Fase 3 op orde zonder tests.
- ❌ Force-unwraps in domeinmodellen. → Modeleer optionaliteit expliciet.

---

## Tips

- Schrijf eerst een use case-test, dan de implementatie. TDD past hier goed.
- Begin met de simpelste feature uit MVP, niet de complexste. Het patroon dat je hier vastlegt herhaal je in Fase 5.
- Als een protocol té veel methodes krijgt (>5), splits het op — Interface Segregation.
