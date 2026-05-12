# push-notifications.md — Push Notifications & Background Tasks

> **Doel:** push notifications die niet irriteren, background refresh die werkt zonder battery-drain, en certificates die niet verlopen op vrijdagavond.
> **Wanneer raadplegen:** Fase 4 (APNs setup) als push noodzakelijk is, Fase 6 (notification features), Fase 7 (notification UX).
> **Hoort bij:** `onboarding.md` (permission priming), `architecture.md` §12 (Info.plist).

---

## 1. Wanneer push wel/niet

### ✅ Goede redenen voor push:
- Real-time content (chat, comments)
- Time-sensitive (deliveries, appointments)
- User waardevol (Jarvis Briefing, daily summary)

### ❌ Slechte redenen:
- Re-engagement campaigns ("kom terug!")
- Promoties ("50% korting!")
- Updates die user niet vroeg

App Review Guideline 4.5.4: "Push notifications must not be used for promotional, marketing, or other purposes... unless customers have explicitly opted in."

---

## 2. APNs setup

### Certificates / .p8 keys

**.p8 keys** (aanbevolen) — eenmalig genereren, werken voor alle apps van je team:
1. Apple Developer → Keys → Create
2. Enable "Apple Push Notifications service (APNs)"
3. Download `.p8` file (bewaar veilig — niet opnieuw downloadbaar)
4. Note Key ID + Team ID

**Server-side JWT signing** voor authenticatie:
```javascript
// Pseudo
const jwt = sign({
    iss: TEAM_ID,
    iat: Date.now() / 1000
}, p8PrivateKey, { algorithm: 'ES256', header: { alg: 'ES256', kid: KEY_ID } });
```

### Entitlements per environment

```xml
<!-- Debug + TestFlight -->
<key>aps-environment</key>
<string>development</string>

<!-- Release -->
<key>aps-environment</key>
<string>production</string>
```

Mismatch (sandbox vs production endpoint) = pushes "verstuurd" maar nooit aangekomen, geen error.

---

## 3. Permission priming

**Niet vragen bij launch.** Volg pattern uit `onboarding.md`:

```swift
// Eigen UI eerst:
struct NotificationPrimingView: View {
    var body: some View {
        VStack {
            Image(systemName: "bell.badge")
            Text("Mis geen update")
            Text("We sturen je alleen meldingen voor nieuwe berichten en je dagelijkse briefing. Geen reclame.")
            Button("Notificaties aanzetten") { Task { await requestPermission() } }
            Button("Later", action: { /* skip */ })
        }
    }

    func requestPermission() async {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            if granted {
                await UIApplication.shared.registerForRemoteNotifications()
            }
        } catch { }
    }
}
```

### Provisional authorization (iOS 12+)

Zonder system prompt — notifications komen in Notification Center maar zonder lock-screen alert:

```swift
try await center.requestAuthorization(options: [.alert, .badge, .sound, .provisional])
```

User kan later upgraden naar full permission via "Keep" button op een notification. Goede compromis voor niet-essentieel.

---

## 4. Device token & registratie

```swift
// In AppDelegate / SceneDelegate
func application(_ application: UIApplication,
                didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    let token = deviceToken.map { String(format: "%02x", $0) }.joined()
    Task { try? await api.registerPushToken(token) }
}

func application(_ application: UIApplication,
                didFailToRegisterForRemoteNotificationsWithError error: Error) {
    Logger.push.error("APNs registration failed: \(error.localizedDescription)")
}
```

**Belangrijk:**
- Token kan veranderen (app re-install, device restore, iCloud restore).
- Stuur ALTIJD nieuwe token naar server, ook als je denkt dat je 'm al hebt.
- Server moet stale tokens opruimen (response 410 Gone van APNs).

---

## 5. Notification payload

### Standard payload

```json
{
    "aps": {
        "alert": {
            "title": "Nieuw bericht",
            "body": "Jan: Hoi, hoe gaat het?"
        },
        "badge": 1,
        "sound": "default",
        "thread-id": "conversation-123",
        "category": "MESSAGE"
    },
    "conversation_id": "abc-123",
    "sender_id": "user-456"
}
```

### Notification categories & actions

```swift
let replyAction = UNTextInputNotificationAction(
    identifier: "REPLY",
    title: "Antwoord",
    options: [],
    textInputButtonTitle: "Verstuur",
    textInputPlaceholder: "Je bericht..."
)

let category = UNNotificationCategory(
    identifier: "MESSAGE",
    actions: [replyAction],
    intentIdentifiers: [],
    options: []
)

UNUserNotificationCenter.current().setNotificationCategories([category])
```

Server stuurt `"category": "MESSAGE"` in payload → user ziet reply-actie in notification.

### Rich notifications (Notification Service Extension)

Voor encrypted content of dynamic content:
1. New Target → Notification Service Extension
2. `mutable-content: 1` in payload
3. Extension krijgt 30 seconden om content te wijzigen

Use cases:
- E2E-encrypted message decryptie
- Image attachments downloaden + tonen
- Localization op device

---

## 6. Silent push (background-update)

```json
{
    "aps": {
        "content-available": 1
    },
    "type": "sync_required"
}
```

App krijgt achtergrond-callback, kan tot ~30 seconden iets doen.

```swift
func application(_ application: UIApplication,
                didReceiveRemoteNotification userInfo: [AnyHashable: Any]) async -> UIBackgroundFetchResult {
    if userInfo["type"] as? String == "sync_required" {
        do {
            try await SyncService.shared.sync()
            return .newData
        } catch {
            return .failed
        }
    }
    return .noData
}
```

**Beperkingen:**
- iOS prioriteert silent push **lager** dan visible push.
- Throttling kan kicks-ins, max ~2-3 silent pushes/uur.
- Geen garantie van delivery.

---

## 7. Background tasks (BGTaskScheduler)

Voor periodieke updates zonder server-push.

### Setup

```xml
<!-- Info.plist -->
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.company.app.refresh</string>
    <string>com.company.app.processing</string>
</array>
```

### Refresh task (kort, frequent)

```swift
// Register
BGTaskScheduler.shared.register(
    forTaskWithIdentifier: "com.company.app.refresh",
    using: nil
) { task in
    self.handleRefresh(task: task as! BGAppRefreshTask)
}

// Schedule
let request = BGAppRefreshTaskRequest(identifier: "com.company.app.refresh")
request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
try BGTaskScheduler.shared.submit(request)

// Handle
func handleRefresh(task: BGAppRefreshTask) {
    scheduleNextRefresh()  // chain — anders runt het maar 1x

    let operation = RefreshOperation()
    task.expirationHandler = { operation.cancel() }
    operation.completionBlock = { task.setTaskCompleted(success: !operation.isCancelled) }
    OperationQueue().addOperation(operation)
}
```

### Processing task (lang, infrequent)

`BGProcessingTask` — minuten ipv seconden, alleen als device idle + plugged in. Voor: bulk-sync, ML-training, database-cleanup.

**iOS regels:**
- Refresh: ~30s budget
- Processing: paar minuten, op systeem-discretie
- iOS leert: als je task vaak faalt → wordt minder gepland.

### Test in simulator

```bash
# Force-trigger refresh
e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.company.app.refresh"]
```

---

## 8. Notification handling in foreground

```swift
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler handler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Apptie open + relevant scherm? → onderdrukken
        if isShowingRelevantConversation(for: notification) {
            handler([])
        } else {
            handler([.banner, .sound, .badge])
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler handler: @escaping () -> Void
    ) {
        // User tikt op notification → deep link
        let userInfo = response.notification.request.content.userInfo
        if let conversationID = userInfo["conversation_id"] as? String {
            deepLinkRouter.handle(URL(string: "yourapp://conversation/\(conversationID)")!)
        }
        handler()
    }
}
```

---

## 9. Notification frequency & UX

### Anti-pattern: notification spam

User-rule: "1 push per uur of minder, behalve voor real-time content (chat)."

### Notification grouping

Use `thread-id` in payload:
```json
{ "aps": { "thread-id": "conversation-123", "alert": "..." } }
```
Notifications met zelfde thread-id worden gegroepeerd in Notification Center.

### Silent hours

Voor non-urgent: respecteer user's "Focus" / "Do Not Disturb". Server-side: stuur niet tussen lokale 22:00-08:00 voor user's tijdzone.

### Quiet times in app settings

Geef user controle:
```swift
struct NotificationSettingsView: View {
    @AppStorage("notif.quiet_hours_enabled") var quietHoursEnabled = false
    @AppStorage("notif.quiet_start") var quietStart = 22
    @AppStorage("notif.quiet_end") var quietEnd = 8

    // In toggle UI
}
```

Stuur deze prefs naar server, backend respecteert ze.

---

## 10. Notification Service Extension

Voor:
- E2E-encryption (content komt versleuteld binnen, wordt op device gedecrypt)
- Image attachments (download + cache)
- Personalisatie op device

```swift
class NotificationService: UNNotificationServiceExtension {
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttempt: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest,
                            withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttempt = request.content.mutableCopy() as? UNMutableNotificationContent

        // Decrypt body
        if let encrypted = request.content.userInfo["encrypted_body"] as? String {
            let decrypted = MessageDecryptor.decrypt(encrypted)
            bestAttempt?.body = decrypted
        }

        contentHandler(bestAttempt ?? request.content)
    }

    override func serviceExtensionTimeWillExpire() {
        if let bestAttempt = bestAttempt, let contentHandler = contentHandler {
            contentHandler(bestAttempt)
        }
    }
}
```

**Beperking:** 30 seconden hard limit, anders wordt extension gekilled.

---

## 11. App Review

- Reviewer test pushes — werkt het niet, mogelijke rejection.
- Notifications **moeten relevant zijn** voor app-purpose.
- Privacy Manifest moet "data verzameld voor notifications" benoemen indien je device tokens met PII koppelt.
- Geen pushes vóór user "essential functionality" heeft gezien (4.5.4).

---

## 12. Anti-patterns

- ❌ Permission-prompt bij launch zonder priming.
- ❌ Promotie-pushes zonder opt-in.
- ❌ Stale device tokens niet opruimen → APNs cap-rate.
- ❌ Silent push als enige update-mechanisme → throttled, onbetrouwbaar.
- ❌ Background task niet chaining → runs maar één keer.
- ❌ Encrypted content in plain payload → privacy-leak via notification preview.
- ❌ Geen quiet hours → user uitzet pushes helemaal.

---

## 13. Checklist

- [ ] APNs key (.p8) gegenereerd en veilig opgeslagen
- [ ] Entitlements per environment correct
- [ ] Permission priming UI vóór system prompt
- [ ] Device token registratie naar server
- [ ] Stale token cleanup server-side (410 Gone responses)
- [ ] Notification categories met actions waar relevant
- [ ] thread-id voor grouping
- [ ] Silent push handler met chaining
- [ ] Background task registered + scheduled in App.init
- [ ] Foreground notification handling (suppress when relevant)
- [ ] Deep link uit notification werkt
- [ ] Notification Service Extension (indien E2E of rich content)
- [ ] User-controlled quiet hours
- [ ] Privacy Manifest aligned met notification data flows
