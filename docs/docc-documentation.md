# docc-documentation.md — DocC Documentation

> **Doel:** publieke API's documenteren met DocC zodat Claude Code, IDE's, en mensen weten hoe je code te gebruiken.
> **Wanneer raadplegen:** Fase 3 (Core protocols), Fase 4 (Infrastructure interfaces), elke nieuwe publieke API.
> **Hoort bij:** `architecture.md` §6 (code-kwaliteit, doc comments).

---

## 1. Wanneer DocC, wanneer niet

### ✅ Wel DocC genereren voor:
- Publieke Core-protocols en use cases (raken alle features)
- Reusable components in DesignSystem
- Cross-team libraries (als SPM dependency)
- Open source releases

### ❌ Niet:
- App-target zelf (intern code, comments zijn genoeg)
- Test-helpers, fixtures
- Deprecated code (verwijderen, niet documenteren)

**Solo dev nuance:** je bouwt vooral voor jezelf. DocC voor Core-laag is investering die zich terugbetaalt; DocC voor elke ViewModel is overkill.

---

## 2. Comment-conventies

### Triple-slash (`///`) voor publieke API's

```swift
/// A provider that sends conversation messages to a chat backend.
///
/// Implement this protocol to integrate with chat services like OpenAI, Anthropic,
/// or local models. The provider is stateless from the caller's perspective —
/// conversation history is passed in with each call.
///
/// ## Example
///
/// ```swift
/// let provider = OpenAIChatProvider(apiKey: "sk-...")
/// let response = try await provider.send([
///     ChatMessage(role: .user, content: "Hello")
/// ])
/// ```
///
/// ## Errors
///
/// Implementations should map provider-specific errors to ``ChatError``:
/// - Network failures → ``ChatError/networkUnavailable``
/// - 429 responses → ``ChatError/rateLimited(retryAfter:)``
/// - Auth failures → ``ChatError/authenticationFailed``
///
/// ## Topics
///
/// ### Sending messages
///
/// - ``send(_:)``
/// - ``stream(_:)``
public protocol ChatProvider: Sendable {
    /// Sends a synchronous message and waits for the complete response.
    ///
    /// - Parameter messages: The conversation history including the user's latest message.
    /// - Returns: The assistant's response message.
    /// - Throws: ``ChatError`` describing what went wrong.
    func send(_ messages: [ChatMessage]) async throws -> ChatMessage

    /// Streams the response as it's generated.
    ///
    /// Use this for long responses where you want to show progressive output.
    /// Each yielded string is an incremental token or chunk.
    ///
    /// - Parameter messages: The conversation history.
    /// - Returns: An async stream of response fragments.
    func stream(_ messages: [ChatMessage]) -> AsyncThrowingStream<String, Error>
}
```

### Symbol-references via double-backticks

- ``send(_:)`` — link naar method
- ``ChatError/rateLimited(retryAfter:)`` — link naar enum case
- ``ChatProvider`` — link naar type

DocC valideert deze references — broken links = build warnings.

---

## 3. DocC catalog (markdown documentation)

`Sources/Core/Core.docc/` folder:

```
Core.docc/
  Core.md                    # landing page
  Articles/
    GettingStarted.md
    Architecture.md
    ErrorHandling.md
  Resources/
    diagram.png
```

### Landing page (Core.md)

```markdown
# ``Core``

Domain models, protocols, and use cases — framework-agnostic.

## Overview

The Core layer contains the heart of the application: pure business logic
without dependencies on UI, networking, or persistence frameworks.

## Topics

### Essentials
- <doc:GettingStarted>
- <doc:Architecture>

### Protocols
- ``ChatProvider``
- ``MangaSource``
- ``KeychainStore``

### Models
- ``ChatMessage``
- ``Conversation``

### Use Cases
- ``SendMessage``
- ``CompactConversation``

### Errors
- <doc:ErrorHandling>
- ``ChatError``
- ``MangaSourceError``
```

### Article example (GettingStarted.md)

```markdown
# Getting Started with Core

Build your first feature using the Core domain.

## Overview

The Core layer is designed to be imported by feature modules and
tested in isolation.

## Implementing a feature

1. Identify the domain models you need
2. Define protocols for external dependencies
3. Write use cases as pure functions
4. Test with in-memory fakes

## Example: Adding a translation feature

First, define the domain model:

```swift
public struct Translation: Sendable {
    public let source: String
    public let target: String
    public let confidence: Double
}
```

[... article continues ...]
```

---

## 4. Code samples in docs

DocC syntaxhighlights Swift code blocks automatisch:

````markdown
## Example

```swift
let provider = OpenAIChatProvider(apiKey: "...")
let response = try await provider.send([msg])
```
````

**Best practices:**
- Houd voorbeelden kort (max 10 regels)
- Toon één concept per voorbeeld
- Geen "..." placeholders zonder uitleg
- Werkende code, niet pseudo-code

---

## 5. Generation & hosting

### Lokaal preview

```bash
xcodebuild docbuild -scheme Core -destination 'generic/platform=iOS'
# Of in Xcode: Product → Build Documentation
```

In Xcode → Window → Documentation → opent rendered docs.

### Static site export

```bash
xcrun docc convert Core.doccarchive \
    --output-path docs-site \
    --hosting-base-path /docs/core
```

Serveert als static site (GitHub Pages, Netlify, eigen server).

### CI integration

GitHub Actions workflow voor doc-builds:

```yaml
- name: Build documentation
  run: |
    xcodebuild docbuild -scheme Core -destination 'generic/platform=iOS'
    xcrun docc process-archive transform-for-static-hosting Core.doccarchive \
      --output-path docs

- name: Deploy to GitHub Pages
  uses: peaceiris/actions-gh-pages@v3
  with:
    github_token: ${{ secrets.GITHUB_TOKEN }}
    publish_dir: ./docs
```

---

## 6. Doc tests (compileerbare voorbeelden)

DocC ondersteunt geen executeerbare doc-tests zoals Rust, maar je kunt:
- Voorbeelden in unit-tests als reference houden
- "Test als documentatie" patroon:

```swift
final class ChatProviderUsageExamples: XCTestCase {
    /// Demonstrates basic send-and-receive flow.
    func test_basicUsage() async throws {
        let provider = FakeChatProvider()
        provider.sendStub = { _ in .fixture(content: "Hi") }

        let response = try await provider.send([
            ChatMessage.fixture(content: "Hello")
        ])

        XCTAssertEqual(response.content, "Hi")
    }
}
```

Test-bestand naar `Tests/Examples/` of in DocC-article inline.

---

## 7. Versioning docs

Per major release een doc-snapshot:

```
docs-site/
  v1/  # latest stable
  v0.9/  # previous
  next/  # in-development
```

DocC + Jekyll/Hugo voor versie-switching UI.

---

## 8. Aanvullende referentie-vormen

Naast DocC voor APIs:

### README.md (high-level)
- Wat is dit project?
- Quick start (5 minuten)
- Link naar DocC + andere docs

### CHANGELOG.md
- Per release: Added/Changed/Fixed/Removed
- Keep a Changelog format

### docs/architecture.md
- Hoog-over architectuur (deze workflow gebruikt al)
- Bedoeld voor mens, niet voor IDE

### Inline code comments
- "Why" niet "what"
- Workarounds met issue-link
- Niet-obvious complexity

---

## 9. Anti-patterns

- ❌ DocC voor elke private function. → Verspilde moeite.
- ❌ Doc comments die hetzelfde zeggen als de signature. → "Sends a message" voor `func send(_:)` is geen documentatie.
- ❌ Outdated voorbeelden in DocC. → Erger dan geen voorbeelden.
- ❌ Geen `## Topics` section. → Documentatie verspreid, moeilijk navigeerbaar.
- ❌ Broken symbol references. → Build warnings opstapelen.
- ❌ DocC-website hosten zonder version-info. → Users zien oude docs voor moderne API's.

---

## 10. Checklist

- [ ] `///` doc comments op alle publieke API's in Core
- [ ] DocC catalog in `Sources/Core/Core.docc/`
- [ ] Landing page met `## Topics` sections
- [ ] Minstens 1 "Getting Started" article
- [ ] Code-voorbeelden compileren (test als reference houden)
- [ ] Geen broken symbol references
- [ ] Lokale doc-build slaagt zonder warnings
- [ ] CI bouwt docs (en deploy't optioneel)
- [ ] README.md linkt naar DocC site
