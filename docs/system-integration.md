# system-integration.md — System Integration

> **Doel:** patterns voor diepe iOS-integraties — universal links, App Intents, Shortcuts, widgets, Live Activities, Spotlight, Handoff.
> **Wanneer raadplegen:** Fase 6 (welke integraties horen bij welke features), Fase 7 (UX-implementatie).
> **Hoort bij:** `architecture.md` §1 (modulaire features), `app_store_readiness.md`.

---

## 1. Beslissen wat je nodig hebt

Geen van deze is verplicht. Kies bewust:

| Integratie | Waarde voor app-soort | Effort |
|-----------|----------------------|--------|
| **Universal Links** | Apps met deelbare URL's (artikelen, profielen, conversaties) | Klein |
| **Custom URL scheme** | Cross-app workflows | Klein |
| **App Intents (Shortcuts)** | Apps met repeatable acties | Medium |
| **Widgets** | Apps met persistente state om te tonen | Medium |
| **Live Activities** | Apps met real-time updates (timers, deliveries, scores) | Hoog |
| **Spotlight** | Apps met doorzoekbare content | Klein-Medium |
| **Handoff** | Apps met state per device (lezen, formulier-invullen) | Klein |
| **Quick Actions** (3D Touch) | Top 3 acties bij icon-press | Klein |
| **Share Extension** | Apps die content uit andere apps verwerken | Medium |

**Vuistregel:** kies maximaal 2-3 voor v1.0. Rest in v1.x als gebruikers erom vragen.

---

## 2. Universal Links

**Waarom belangrijk:** App Review Guideline 4.5.4 — "Push notifications must not be required for the app to function." Universal links zijn vaak de juiste manier om gebruikers terug te halen, niet pushes.

### Setup

1. **Associated Domains**-entitlement: `applinks:yourdomain.com`
2. **`apple-app-site-association`** file op `https://yourdomain.com/.well-known/apple-app-site-association`:
```json
{
  "applinks": {
    "details": [
      {
        "appIDs": ["TEAMID.com.company.app"],
        "components": [
          { "/": "/conversation/*" },
          { "/": "/profile/*" }
        ]
      }
    ]
  }
}
```
3. **Handle in app:**

```swift
// In Scene
.onOpenURL { url in
    deepLinkRouter.handle(url)
}
.onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
    if let url = activity.webpageURL {
        deepLinkRouter.handle(url)
    }
}
```

### DeepLinkRouter pattern

```swift
@MainActor
@Observable
public final class DeepLinkRouter {
    public var pendingDestination: Destination?

    public enum Destination: Equatable {
        case conversation(id: UUID)
        case profile(username: String)
        case settings
    }

    public func handle(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return }

        switch components.path {
        case let path where path.hasPrefix("/conversation/"):
            let id = path.replacingOccurrences(of: "/conversation/", with: "")
            if let uuid = UUID(uuidString: id) {
                pendingDestination = .conversation(id: uuid)
            }
        case let path where path.hasPrefix("/profile/"):
            let username = path.replacingOccurrences(of: "/profile/", with: "")
            pendingDestination = .profile(username: username)
        default:
            pendingDestination = nil
        }
    }
}
```

**Test op fysiek device** met `xcrun simctl openurl` voor simulator, of via een email-link op device.

---

## 3. App Intents (Shortcuts integration)

iOS 16+ — vervangt het oudere Intents framework.

### Definieer een intent

```swift
import AppIntents

struct StartConversationIntent: AppIntent {
    static var title: LocalizedStringResource = "Start nieuwe conversatie"
    static var description: IntentDescription = "Begin een gesprek met de assistent."

    @Parameter(title: "Provider", default: "openai")
    var provider: String

    @Parameter(title: "Initieel bericht")
    var message: String

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let response = try await ConversationService.shared.start(
            provider: provider,
            message: message
        )
        return .result(dialog: "Antwoord: \(response.content)")
    }
}
```

### App Shortcuts (auto-suggested)

```swift
struct AppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartConversationIntent(),
            phrases: [
                "Vraag \(.applicationName) iets",
                "Start een conversatie in \(.applicationName)"
            ],
            shortTitle: "Conversatie starten",
            systemImageName: "bubble.left.and.bubble.right"
        )
    }
}
```

**Belangrijk:**
- Phrases moeten `\(.applicationName)` bevatten (Apple-vereiste).
- Test in Spotlight, Shortcuts-app, Siri.
- App Review test deze actief — werkt het niet, mogelijke rejection.

---

## 4. Widgets (WidgetKit)

**Wanneer:** als je app persistent state heeft die zonder openen waardevol is (recent activity, current task, weather).

### Widget extension target

1. Xcode → File → New → Target → Widget Extension
2. Beide targets moeten in dezelfde **App Group** voor data-deling
3. Keychain Sharing als widget user-data nodig heeft

### Timeline provider

```swift
struct ConversationTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> ConversationEntry {
        ConversationEntry(date: Date(), recentTitle: "Voorbeeld")
    }

    func getSnapshot(in context: Context, completion: @escaping (ConversationEntry) -> Void) {
        completion(.placeholder)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ConversationEntry>) -> Void) {
        let recent = SharedStore.shared.recentConversation
        let entry = ConversationEntry(date: Date(), recentTitle: recent?.title ?? "Niets recent")
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(900)))
        completion(timeline)
    }
}
```

**Performance-regel:** widget mag NIET zwaar werk doen in `getTimeline`. Lees uit shared App Group, geen netwerk.

### Reload triggers

Widget update triggers vanuit app:

```swift
import WidgetKit

WidgetCenter.shared.reloadTimelines(ofKind: "ConversationWidget")
```

---

## 5. Live Activities (iOS 16.1+)

Voor real-time updates op Lock Screen + Dynamic Island. Voorbeelden: bezorging, sport-score, timer, downloadprogressie.

### ActivityAttributes

```swift
import ActivityKit

struct DeliveryAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var status: String
        var estimatedArrival: Date
    }

    var orderID: String
    var driverName: String
}
```

### Start, update, end

```swift
let attributes = DeliveryAttributes(orderID: "12345", driverName: "Jan")
let initialState = DeliveryAttributes.ContentState(status: "Onderweg", estimatedArrival: .now.addingTimeInterval(1200))

let activity = try Activity.request(
    attributes: attributes,
    content: .init(state: initialState, staleDate: nil)
)

// Update
await activity.update(.init(
    state: DeliveryAttributes.ContentState(status: "Bijna er", estimatedArrival: .now.addingTimeInterval(180)),
    staleDate: nil
))

// End
await activity.end(.init(
    state: DeliveryAttributes.ContentState(status: "Afgeleverd", estimatedArrival: .now),
    staleDate: nil
), dismissalPolicy: .after(.now.addingTimeInterval(30)))
```

**Beperkingen:**
- Max 12 actieve activities per app
- 4 KB attributes + content state limiet
- Maximaal 8 uur (kan verlengd worden via push)

**Push-updates:** voor server-driven updates, gebruik APNs met `apns-push-type: liveactivity`.

---

## 6. Spotlight indexing

`CoreSpotlight` framework voor doorzoekbare content (notities, contacten, items).

```swift
import CoreSpotlight

func indexConversation(_ conversation: Conversation) {
    let attributes = CSSearchableItemAttributeSet(contentType: .text)
    attributes.title = conversation.title
    attributes.contentDescription = conversation.summary
    attributes.keywords = conversation.tags

    let item = CSSearchableItem(
        uniqueIdentifier: conversation.id.uuidString,
        domainIdentifier: "conversation",
        attributeSet: attributes
    )

    CSSearchableIndex.default().indexSearchableItems([item])
}

// Handle search-tap:
.onContinueUserActivity(CSSearchableItemActionType) { activity in
    guard let id = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String else { return }
    deepLinkRouter.handle(URL(string: "yourapp://conversation/\(id)")!)
}
```

**Privacy:** indexeer geen content waarvan user privacy verwacht. Geef expliciete toggle in Settings.

---

## 7. Handoff

Tussen iPhone en Mac/iPad continueren wat je deed.

```swift
// Op de view die handoff-able is:
.userActivity("com.company.app.viewing-conversation") { activity in
    activity.title = conversation.title
    activity.userInfo = ["conversationID": conversation.id.uuidString]
    activity.isEligibleForHandoff = true
    activity.requiredUserInfoKeys = ["conversationID"]
}

// In Scene: ontvang
.onContinueUserActivity("com.company.app.viewing-conversation") { activity in
    guard let id = activity.userInfo?["conversationID"] as? String else { return }
    deepLinkRouter.handle(URL(string: "yourapp://conversation/\(id)")!)
}
```

---

## 8. Quick Actions (Home Screen menu)

Voor de top-3 acties bij icon-press:

```xml
<!-- Info.plist -->
<key>UIApplicationShortcutItems</key>
<array>
    <dict>
        <key>UIApplicationShortcutItemType</key>
        <string>com.company.app.new-conversation</string>
        <key>UIApplicationShortcutItemTitle</key>
        <string>Nieuwe conversatie</string>
        <key>UIApplicationShortcutItemIconType</key>
        <string>UIApplicationShortcutIconTypeAdd</string>
    </dict>
</array>
```

```swift
// In App
.onChange(of: scenePhase) { _, newPhase in
    if newPhase == .active, let shortcut = pendingShortcut {
        handleShortcut(shortcut)
    }
}

// In SceneDelegate equivalent of via UIApplicationDelegateAdaptor
```

---

## 9. Share Extension

Voor "Deel via App" vanuit andere apps.

**Setup:** New Target → Share Extension. Beperkingen:
- 24 MB memory cap
- Korte uitvoering
- Geen volledig UIKit/SwiftUI environment

**App Group nodig** om data door te geven aan main app.

---

## 10. Beslissings-matrix per app-type

| App-type | Quick wins |
|----------|-----------|
| **AI/Chat-app** | App Intents (vraag-stellen via Siri), Spotlight (gespreksgeschiedenis), deep links naar conversaties |
| **Manga reader** | Quick Actions ("recent gelezen"), Spotlight (titel-search), widget (huidige read) |
| **Productivity** | App Intents (taken aanmaken), widgets (vandaag), Shortcuts |
| **Media-app** | Live Activity (huidige track), Lock Screen widget, Now Playing integratie |
| **Health/fitness** | Live Activity (workout in progress), HealthKit |

---

## 11. App Review hot topics

- **App Intents** moeten WERKEN als geadverteerd. Reviewers testen ze.
- **Universal Links** moeten echte content tonen, niet redirect-loops.
- **Widgets** moeten lege state hebben — niet alleen "log in om te zien".
- **Live Activities** mogen NIET als ad gebruikt worden (Guideline 4.0).

---

## 12. Anti-patterns

- ❌ Custom URL scheme zonder Universal Links. → Onveilig (kan gehijacked worden).
- ❌ Widget die elke minuut update via netwerk. → Battery drain + Apple beperkt frequentie.
- ❌ Live Activity die uren blijft hangen. → Gebruiker kan 'm niet wegswipen, irritant.
- ❌ App Intents die alleen UI tonen ipv echt iets uitvoeren. → Niet shortcut-able.
- ❌ Spotlight indexing van privé-data zonder toggle. → Privacy-bezwaar.

---

## 13. Checklist per integratie

### Universal Links
- [ ] Associated Domains entitlement
- [ ] `apple-app-site-association` op server (geen `.json` extension!)
- [ ] Handler in app voor `.onOpenURL` + `onContinueUserActivity`
- [ ] Getest met echte URL via email/Messages

### App Intents
- [ ] Intent definitie met phrases die `\(.applicationName)` bevatten
- [ ] AppShortcutsProvider geregistreerd
- [ ] Getest in Shortcuts-app + Siri

### Widgets
- [ ] App Group voor data-deling
- [ ] Timeline provider zonder netwerk-werk
- [ ] Empty state voor "nog niets" / "log in"
- [ ] Reload-triggers vanuit app

### Live Activities
- [ ] ActivityAttributes onder 4KB
- [ ] Auto-end binnen redelijke tijd
- [ ] Push-updates via APNs (indien server-driven)
