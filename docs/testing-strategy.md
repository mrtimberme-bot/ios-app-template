# testing-strategy.md — Testing Strategy

> **Doel:** wat te testen, hoe te testen, en wat juist NIET te testen — zonder coverage-fetishisme.
> **Wanneer raadplegen:** Fase 3 (Core tests), Fase 5 (slice testing), Fase 8 (full test suite).
> **Hoort bij:** `architecture.md` §7 (testing requirements).

---

## 1. Test-pyramid voor iOS

```
                  /\
                 /  \      UI Tests (XCUITest)
                /----\     Klein aantal — primary flows
               /      \
              /--------\   Integration Tests
             /          \  Met echte/sandbox dependencies
            /------------\
           /              \  Unit Tests (overgrote meerderheid)
          /----------------\ Snel, geïsoleerd, deterministisch
```

**Verhouding voor de meeste apps:**
- 70% unit tests
- 20% integration tests (incl. snapshot tests)
- 10% UI tests

**Anti-pattern:** alleen UI-tests omdat ze "het meest realistisch zijn". Te traag, te flaky, te duur.

---

## 2. Wat WEL en NIET testen

### ✅ Test:

**Use cases / business logic** — pure functies in `Core/UseCases/`. Hoogste ROI.

```swift
func test_compactConversation_keepsRecentMessages() {
    let messages: [ChatMessage] = (0..<100).map { ChatMessage(id: UUID(), role: .user, content: "msg \($0)", createdAt: .now) }
    let result = ConversationCompactor().compact(messages, maxTokens: 1000)
    XCTAssertLessThan(result.count, messages.count)
    XCTAssertEqual(result.last, messages.last)  // recent behouden
}
```

**Store-gedrag** — gegeven actie X, wordt state Y? (Niet de implementatie testen, het gedrag.)

**Edge cases**:
- Lege input
- Maximum-size input
- Nil/optional handling
- Network errors → user-facing error states
- Concurrency (parallel acties op dezelfde store)

**Bug regressions** — elke gefixte bug krijgt een test die hem reproduceert.

### ❌ NIET testen:

- **SwiftUI views direct** — flaky, breaks bij styling-changes. Test gedrag via Store.
- **Apple frameworks** — `URLSession` werkt, ga niet testen of het GET'en kan.
- **Trivial getters/setters** — geen logica = geen test.
- **Implementatie-details** — als je test breekt bij refactor zonder gedragsverandering, test je de verkeerde laag.
- **Hardcoded delays** — `Thread.sleep(2)` is geen test.

---

## 3. Test-data builders (Object Mother / Builder pattern)

Schrijf NIET dit:

```swift
let conversation = Conversation(
    id: UUID(),
    title: "Test",
    createdAt: Date(),
    isPinned: false,
    provider: .openai,
    messages: [...],
    metadata: [:]
)
```

In 30 tests. Schrijf:

```swift
extension Conversation {
    static func fixture(
        id: UUID = UUID(),
        title: String = "Test Conversation",
        createdAt: Date = Date(timeIntervalSince1970: 0),
        isPinned: Bool = false,
        provider: Provider = .openai,
        messages: [ChatMessage] = [],
        metadata: [String: String] = [:]
    ) -> Conversation {
        Conversation(
            id: id, title: title, createdAt: createdAt,
            isPinned: isPinned, provider: provider,
            messages: messages, metadata: metadata
        )
    }
}

// In test:
let conversation = Conversation.fixture(title: "Specific")
let pinned = Conversation.fixture(isPinned: true)
```

**Plaatsing:** in `Tests/Fixtures/` of als extensies in `Tests/Helpers/`.

---

## 4. Async test-patronen

### Async/await tests

```swift
func test_send_returnsAssistantMessage() async throws {
    let provider = FakeChatProvider()
    provider.sendStub = { _ in
        ChatMessage.fixture(role: .assistant, content: "Hi")
    }

    let usecase = SendMessage(provider: provider)
    let response = try await usecase.execute(text: "Hello", history: [])

    XCTAssertEqual(response.role, .assistant)
    XCTAssertEqual(response.content, "Hi")
}
```

### Async expectations met timeout

```swift
func test_streaming_emitsAllChunks() async throws {
    let provider = FakeChatProvider()
    provider.streamChunks = ["Hel", "lo ", "world"]

    let store = ChatStore(provider: provider)
    let task = Task { await store.send("trigger") }

    // Wacht op state-verandering met timeout
    try await waitUntil(timeout: 1.0) {
        store.lastMessage?.content == "Hello world"
    }

    task.cancel()
}

// Helper
func waitUntil(timeout: TimeInterval, _ predicate: @escaping () -> Bool) async throws {
    let start = Date()
    while !predicate() {
        if Date().timeIntervalSince(start) > timeout {
            throw TimeoutError()
        }
        try await Task.sleep(for: .milliseconds(10))
    }
}
```

**Geen `XCTWaiter` met `expectation.fulfill()`** voor async/await — verouderd patroon.

---

## 5. Snapshot tests voor SwiftUI

Library: `swift-snapshot-testing` (Pointfree). Gebruik **niet** voor elke view — alleen voor:
- Reusable DesignSystem-components
- Complexe layouts (cards, list rows)
- Tabular data displays

```swift
import SnapshotTesting
import SwiftUI

func test_messageCard_inLight() {
    let view = MessageCard(message: .fixture(content: "Hello world"))
        .frame(width: 320, height: 100)

    assertSnapshot(of: view, as: .image(traits: .init(userInterfaceStyle: .light)))
}

func test_messageCard_inDark() {
    let view = MessageCard(message: .fixture(content: "Hello world"))
        .frame(width: 320, height: 100)

    assertSnapshot(of: view, as: .image(traits: .init(userInterfaceStyle: .dark)))
}
```

**Regels:**
- Eerste run: snapshot wordt opgeslagen, test faalt expliciet (forceer review).
- Snapshots in git committen.
- Bij intended UI-change: `record: true` aanzetten, run, commit nieuwe snapshots.

**Anti-pattern:** snapshot tests voor schermen die elke 2 weken redesignen — alleen ritueel.

---

## 6. UI tests met XCUITest

**Schrijf alleen voor primary flows** — login, key feature, payment.

```swift
final class OnboardingUITests: XCTestCase {
    func test_newUserCompletesOnboarding() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset-state"]
        app.launch()

        app.buttons["Get Started"].tap()
        app.textFields["Email"].tap()
        app.textFields["Email"].typeText("test@example.com")
        app.buttons["Continue"].tap()

        XCTAssertTrue(app.staticTexts["Welcome"].waitForExistence(timeout: 5))
    }
}
```

**Best practices:**
- Accessibility-identifiers in views: `.accessibilityIdentifier("login.email")` voor stabiele selectors.
- `--reset-state` launch arg om schone slate te garanderen.
- `--ui-testing` flag om analytics, animations, etc. uit te zetten.
- Page Object pattern voor herbruikbaar element-aanspreken:

```swift
struct OnboardingPage {
    let app: XCUIApplication

    func enterEmail(_ email: String) {
        app.textFields["onboarding.email"].tap()
        app.textFields["onboarding.email"].typeText(email)
    }

    func tapContinue() {
        app.buttons["onboarding.continue"].tap()
    }
}
```

---

## 7. Coverage — meet, maar fetishisme is dom

**Wat coverage WEL betekent:** "deze regel is gedraaid in een test."
**Wat coverage NIET betekent:** "deze regel is correct."

```swift
// 100% coverage, 0% nut
func test_addOne() {
    XCTAssertNotNil(addOne(1))  // pass — geeft niets terug behalve 'het crasht niet'
}

func addOne(_ n: Int) -> Int { n + 2 }  // BUG, niet gedetecteerd
```

**Doelen uit `architecture.md`:**
- Core ≥80%
- Overall ≥60%

**Maar:**
- 80% Core met goede assertions > 95% met `XCTAssertNotNil` overal.
- Mutatie-testen (Stryker, Muter) is betere kwaliteits-meting maar duur in tijd.
- Code review je tests ook — "wat zou ik kunnen breken zonder dat deze test stuk gaat?"

---

## 8. Testing pyramide per fase

### Fase 3 (Core domain)
- 100% unit tests op use cases
- Fakes voor alle Core-protocols
- Coverage Core ≥80%

### Fase 4 (Infrastructure)
- Integration tests met sandbox endpoints
- Test mapping van third-party errors → Core errors
- Coverage Infrastructure ≥60%

### Fase 5 (Vertical slice)
- Unit tests op de Store (gedrag-tests)
- Smoke test op simulator
- Eventueel snapshot test voor key view

### Fase 6 (Resterende features)
- Per feature: store-tests + smoke test
- Snapshot tests voor herbruikbare components

### Fase 7 (Polish)
- Snapshot tests voor key views in Light + Dark
- Accessibility tests met `XCTest`'s accessibility audit (iOS 17+)

### Fase 8 (Stabilisatie)
- UI tests voor primary flows (3-5 stuks max)
- Performance regression tests:
```swift
func test_messageList_renderingPerformance() {
    let messages = (0..<1000).map { ChatMessage.fixture(content: "msg \($0)") }
    measure(metrics: [XCTClockMetric()]) {
        // render heavy view
    }
}
```

---

## 9. Test-organisatie

```
Tests/
  CoreTests/
    UseCases/
      ConversationCompactorTests.swift
    Models/
      ChatMessageTests.swift
  InfrastructureTests/
    Network/
      OpenAIChatProviderTests.swift
  FeatureATests/
    Stores/
      ChatStoreTests.swift
    Views/
      ChatView_Snapshots/
  UITests/
    Flows/
      OnboardingUITests.swift
  Fakes/
    FakeChatProvider.swift
    FakeKeychainStore.swift
  Fixtures/
    ChatMessage+Fixture.swift
    Conversation+Fixture.swift
  Helpers/
    waitUntil.swift
    XCTestCase+Async.swift
```

**Ééen-naam-conventie:** `<SubjectUnderTest>Tests`. Niet `Test_ChatStore` of `ChatStoreTest` (singular).

---

## 10. Test-naamgeving

**`test_<scenario>_<expectedOutcome>`:**

```swift
func test_send_whenOffline_returnsCachedResponse()
func test_send_whenRateLimited_retriesAfterDelay()
func test_send_withEmptyHistory_includesSystemPrompt()
```

Niet:
- `func test1()` — geen idee wat dit test
- `func testSendMessage()` — wat is het scenario?
- `func testHappyPath()` — welk gedrag?

---

## 11. Anti-patterns

- ❌ `Thread.sleep(seconds: 2)` om async te wachten. → Use proper async waits.
- ❌ Tests met willekeurige UUIDs zonder seed. → Flaky over reruns.
- ❌ Tests die andere tests beïnvloeden via shared state. → Order-dependence.
- ❌ Mocks die alle methodes mocken. → Maak een Fake (working in-memory implementation).
- ❌ Coverage-cijfer als KPI. → Mensen schrijven `XCTAssertNotNil` om de bar te halen.
- ❌ Tests die je niet leest na het schrijven. → Kerngedrag-test moet leesbaar als spec zijn.
- ❌ Geen tests voor errors. → "Happy path werkt" zegt niets over edge cases.

---

## 12. Checklist per release

- [ ] Alle nieuwe code heeft tests
- [ ] Failing tests zijn geen `// TODO: fix later`
- [ ] Coverage Core ≥80%, overall ≥60%
- [ ] Geen `Thread.sleep` in tests
- [ ] Geen tests die productie-data nodig hebben
- [ ] Snapshot tests up-to-date (geen `record: true` per ongeluk gecommit)
- [ ] UI tests voor 3-5 primary flows aanwezig
- [ ] Tests draaien in CI binnen <5 minuten
