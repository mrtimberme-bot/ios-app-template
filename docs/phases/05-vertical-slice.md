# Fase 5 — Eerste verticale slice

> **Doel:** één feature volledig werkend door alle lagen — bewijs dat de architectuur klopt.
> **Versie na afsluiten:** v0.5
> **Vorige fase:** [04-infrastructure.md](./04-infrastructure.md)
> **Volgende fase:** [06-features.md](./06-features.md)

---

## Activiteiten

### 1. Kies de slice-feature

Niet de complexste, niet de simpelste — de **meest representatieve**. Kies de feature waarvan het patroon zich het vaakst zal herhalen.

Voorbeeld voor een chat-app: "stuur een bericht en ontvang een antwoord" — niet de instellingen, niet de auth-flow.

### 2. Bouw alle lagen

```
View (Features/Chat/Views/ChatView.swift)
  └─→ Store (Features/Chat/Stores/ChatStore.swift)
       └─→ UseCase (Core/UseCases/SendMessage.swift)
            └─→ Protocol (Core/Protocols/ChatProvider.swift)
                 └─→ Concrete impl (Infrastructure/Providers/OpenAIChatProvider.swift)
```

#### View

```swift
// Features/Chat/Views/ChatView.swift
struct ChatView: View {
    @State private var store: ChatStore

    init(store: ChatStore) { self.store = store }

    var body: some View {
        // SwiftUI met DesignSystem-tokens
    }
}
```

#### Store

```swift
// Features/Chat/Stores/ChatStore.swift
@MainActor
@Observable
final class ChatStore {
    private(set) var messages: [ChatMessage] = []
    private(set) var isSending = false
    private(set) var error: ChatError?

    private let sendMessage: SendMessage

    init(sendMessage: SendMessage) {
        self.sendMessage = sendMessage
    }

    func send(_ text: String) async {
        isSending = true
        defer { isSending = false }
        do {
            let response = try await sendMessage.execute(text, history: messages)
            messages.append(response)
        } catch let error as ChatError {
            self.error = error
        } catch {
            self.error = .invalidResponse
        }
    }
}
```

### 3. DesignSystem-basics opzetten

Tijdens deze slice leg je de fundamenten:

- `DesignSystem/Tokens/Colors.swift` — semantic colors (`.surfaceBackground`, `.textPrimary`, `.accent`)
- `DesignSystem/Tokens/Typography.swift` — font-roles (`.titleLarge`, `.bodyDefault`, `.caption`)
- `DesignSystem/Tokens/Spacing.swift` — spacing-scale (`.xs`, `.sm`, `.md`, `.lg`, `.xl`)
- `DesignSystem/Components/` — eerste herbruikbare components (knop, input, card)

**Regel:** geen hardcoded colors of fonts in views. Alles via tokens.

### 4. Navigation-pattern kiezen

| Optie | Wanneer |
|-------|---------|
| **`NavigationStack` + `NavigationPath`** | Default, iOS 16+, simpele apps |
| **Coordinator pattern** | Veel cross-feature navigatie, deep links |
| **TabView met aparte stacks** | Tab-based apps |

Kies **één** en gebruik 'm in deze slice. Documenteer in `/docs/architecture-decisions.md` als ADR.

### 5. End-to-end demo

- Run op simulator → werkt
- Run op fysiek device → werkt
- Test met slecht netwerk (Network Link Conditioner)
- Test offline → toont passende error state

### 6. Self-review

Vraag jezelf af:

- **Zou een tweede feature dezelfde structuur kunnen volgen?** Zo ja → architectuur klopt.
- **Hoeveel werk was Infrastructure→Core→Feature?** Te veel friction → patroon vereenvoudigen vóór Fase 6.
- **Zijn er hooks die je nog mist** (analytics, logging, error reporting)? Voeg toe nu of nooit.

---

## Exit-gate

- [ ] Slice-feature werkt end-to-end op simulator
- [ ] Slice-feature werkt end-to-end op fysiek device
- [ ] Loading, empty, error states zijn aanwezig
- [ ] DesignSystem-tokens gedefinieerd en gebruikt
- [ ] Navigation-pattern is gekozen en gedocumenteerd
- [ ] Geen hardcoded colors/fonts in views
- [ ] **Lazy containers** gebruikt voor scrollbare data (`List` of `LazyVStack`, niet `VStack`) — zie `architecture.md` §15
- [ ] **Image caching strategie** gekozen indien slice remote images toont (Nuke / Kingfisher / `URLCache`) — gedocumenteerd in `docs/architecture-decisions.md`
- [ ] **Geen blocking work op main thread** — JSON parsing, file I/O en netwerkcalls zijn off-main (`architecture.md` §15)
- [ ] Coverage van slice-feature ≥70%
- [ ] **Git-tag:** `v0.5-slice`
- [ ] CHANGELOG.md geüpdatet

---

## Anti-patterns

- ❌ Slice zonder error states. → Fase 7 wordt twee keer zo groot.
- ❌ DesignSystem overslaan, "doen we later". → Fase 7 wordt drie keer zo groot.
- ❌ Hardcoded API-keys in slice-code. → Code review jezelf voor commit.
- ❌ Niet op fysiek device testen. → Performance-issues ontdek je pas in Fase 8.

---

## Tips

- De slice voelt aan als veel werk voor één feature. Klopt. Maar Fase 6 is daarna 5× zo snel.
- Houd de slice klein in scope. "Stuur bericht" is een slice; "stuur bericht + edit + delete + reactions" is geen slice meer.
- De DesignSystem-tokens uit deze fase zijn locked vanaf nu. Wijzigingen hier raken alle latere features.
