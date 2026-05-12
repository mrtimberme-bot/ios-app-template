# security.md — Security Beyond Secrets

> **Doel:** beveiligingspatronen die verder gaan dan API-keys verbergen — biometrische auth, data protection, jailbreak detection, ATS, Keychain sharing.
> **Wanneer raadplegen:** Fase 4 (infrastructure security), apps met financial/medical/identity-data.
> **Hoort bij:** `architecture.md` §11 (secrets), `app_store_readiness.md` §4 (account deletion).

---

## 1. Threat model — kies bewust

Niet elke app heeft alle beveiliging nodig. Definieer in `docs/threat-model.md`:

| Asset | Threat | Mitigation |
|-------|--------|-----------|
| API-tokens | Diefstal van device | Keychain met `kSecAttrAccessible*` |
| User-content | Forensische analyse | Data Protection class B/C |
| Authentication | Phishing | Sign in with Apple |
| Premium features | Reverse engineering | StoreKit receipt validation server-side |

**Solo dev rule of thumb:**
- Standaard chat/utility-app: alleen Keychain + ATS volstaan.
- Auth-vereist + persistent data: + Data Protection + biometric reauthentication.
- Financial/healthcare/identity: + alle bovenstaande + cert pinning + jailbreak detection.

---

## 2. Keychain — de basics goed doen

### Accessibility-classes

```swift
// Default — ontoegankelijk wanneer device locked, geen iCloud-sync, niet over restore te krijgen
kSecAttrAccessibleWhenUnlockedThisDeviceOnly  // ✅ AANBEVOLEN

// Toegankelijk na eerste unlock (background tasks)
kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

// Synced via iCloud Keychain
kSecAttrAccessibleWhenUnlocked                 // ⚠️ alleen als sync gewenst
```

**Vuistregel:** `*ThisDeviceOnly` tenzij je expliciet sync wilt. Voorkomt dat tokens van een gestolen geünlockte iPhone ergens anders bruikbaar zijn.

### Keychain wrapper

```swift
public protocol KeychainStore: Sendable {
    func set(_ value: String, for key: String) throws
    func get(_ key: String) throws -> String?
    func delete(_ key: String) throws
    func deleteAll() throws  // voor account deletion!
}

public final class SystemKeychainStore: KeychainStore {
    private let service: String

    public init(service: String = Bundle.main.bundleIdentifier ?? "app") {
        self.service = service
    }

    public func set(_ value: String, for key: String) throws {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        SecItemDelete(query as CFDictionary)  // overwrite-pattern
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.unhandled(status) }
    }

    // get, delete vergelijkbaar
}
```

### Keychain sharing tussen app + extensions

Voor Share Extensions, Widgets, Notification Service Extensions:

1. Beide targets in dezelfde Keychain Access Group.
2. Entitlement: `keychain-access-groups` → `$(AppIdentifierPrefix)com.company.app.shared`
3. Wrapper:
```swift
let query: [String: Any] = [
    // ...
    kSecAttrAccessGroup as String: "$(AppIdentifierPrefix)com.company.app.shared"
]
```

---

## 3. Data Protection (file-level encryption)

iOS encrypteert files op disk. Je controleert WANNEER ze ontsleutelbaar zijn:

| Class | Constant | Wanneer toegankelijk |
|-------|----------|---------------------|
| A | `.complete` | Alleen wanneer device unlocked (default voor user data) |
| B | `.completeUnlessOpen` | Open files blijven leesbaar na lock |
| C | `.completeUntilFirstUserAuthentication` | Na eerste unlock (background tasks) |
| D | `.none` | Altijd toegankelijk (default voor sommige system files) |

**Zet expliciet voor je persistent stores:**

```swift
let storeURL = /* ... */
try FileManager.default.setAttributes(
    [.protectionKey: FileProtectionType.completeUnlessOpen],
    ofItemAtPath: storeURL.path
)
```

**SwiftData/Core Data:** zet `protectionKey` op de container directory.

**Vuistregel:** Class A voor PII, Class B voor algemene user-data die background-toegang nodig heeft.

---

## 4. App Transport Security (ATS)

iOS dwingt HTTPS af. Ondermijn dit alleen met goed argument:

```xml
<!-- Info.plist — vrijwel altijd FOUT -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>  <!-- ❌ NIET DOEN -->
</dict>
```

**Wel oké voor specifieke domains** (bv. legacy partner-API):

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSExceptionDomains</key>
    <dict>
        <key>legacy-api.partner.com</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
            <key>NSExceptionRequiresForwardSecrecy</key>
            <false/>
        </dict>
    </dict>
</dict>
```

**Bij submission:** Apple vraagt rationale voor ATS-exceptions. Hou een uitleg klaar in App Review Notes.

---

## 5. Local Authentication (Face ID / Touch ID)

### Wanneer gebruiken

- Re-authentication bij gevoelige acties (transfer, account-delete)
- Lock-screen voor privé-data
- **Niet** als enige auth — moet altijd combineren met password/passcode-fallback.

### Implementatie

```swift
import LocalAuthentication

public actor BiometricAuthenticator {
    public func authenticate(reason: String) async throws -> Bool {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            throw AuthError.biometricsUnavailable
        }

        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthentication,  // valt terug op passcode bij failure
                localizedReason: reason
            )
        } catch let error as LAError {
            throw mapLAError(error)
        }
    }
}
```

**Belangrijk:**
- `Info.plist`: `NSFaceIDUsageDescription` verplicht (zonder = crash op Face ID-prompt).
- `.deviceOwnerAuthentication` (passcode-fallback) i.p.v. `.deviceOwnerAuthenticationWithBiometrics` (alleen biometric).
- `localizedReason` is wat user ziet — wees specifiek: "Bevestig om je betaalgegevens te tonen", niet "Authenticate".

### Anti-pattern: alleen biometric voor toegang tot tokens

```swift
// ❌ FOUT — token in plain Keychain, biometric alleen UI-laagje
if biometric.success {
    let token = keychain.get("token")
    api.use(token)
}

// ✅ JUIST — token VEREIST biometric voor ophalen
let access = SecAccessControlCreateWithFlags(
    nil, kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
    .userPresence, nil
)
SecItemAdd([
    // ...
    kSecAttrAccessControl as String: access!
] as CFDictionary, nil)
```

---

## 6. Sign in with Apple

**Verplicht** als je third-party social login (Google, Facebook) aanbiedt. **Aanbevolen** als enige auth — beste UX, beste privacy.

```swift
import AuthenticationServices

func signIn() {
    let provider = ASAuthorizationAppleIDProvider()
    let request = provider.createRequest()
    request.requestedScopes = [.fullName, .email]

    let controller = ASAuthorizationController(authorizationRequests: [request])
    controller.delegate = self
    controller.performRequests()
}

func authorizationController(controller: ASAuthorizationController,
                            didCompleteWithAuthorization authorization: ASAuthorization) {
    guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }
    let userID = credential.user                    // stable, gebruik als primary key
    let identityToken = credential.identityToken    // verifieer server-side!
    let email = credential.email                    // alleen op eerste login
}
```

**Server-side verificatie verplicht:**
- Identity token is JWT, signed by Apple
- Verify signature met Apple's public keys (https://appleid.apple.com/auth/keys)
- Check `iss`, `aud`, `exp`
- **Vertrouw user-ID alleen na verification.** Anders kan iemand een gefabriceerd token sturen.

---

## 7. Account deletion — security implications

Verplicht sinds 2022 (zie `app_store_readiness.md` §4). Beveiligingsaspecten:

- **Verwijder ALLE PII** uit primary store én backups.
- **Revoke alle auth tokens** server-side.
- **Verwijder Keychain entries** lokaal (`KeychainStore.deleteAll()`).
- **Stop background tasks** die nog data verwerken.
- **Bewaar audit log** van deletion-request (legal requirement) — alleen timestamp + hashed user-ID, geen PII.
- **Anonymiseer** wat je niet kunt verwijderen (analytics events).

```swift
public actor AccountDeletion {
    public func deleteAccount() async throws {
        try await api.requestDeletion()
        try keychain.deleteAll()
        try await persistentStore.dropAllUserData()
        try analytics.optOut()
        try await pushNotifications.unregister()
        try await UserDefaults.standard.removePersistentDomain()
    }
}
```

---

## 8. Jailbreak detection — wanneer wel/niet

**Niet doen** voor algemene apps — false positives, cat-and-mouse, kost performance.

**Wel overwegen** voor:
- Banking, payment, healthcare
- Apps met DRM-content
- Identity verification

**Implementatie (basis):**
```swift
struct JailbreakDetector {
    static var isJailbroken: Bool {
        let suspiciousPaths = [
            "/Applications/Cydia.app",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt"
        ]
        return suspiciousPaths.contains { FileManager.default.fileExists(atPath: $0) }
    }
}
```

**Wat doen bij detectie:**
- Niet **blokkeren** (false positives bestaan).
- **Wel** waarschuwen + degraded mode (geen sensitive features).
- **Server-side ook checken** — client kan liegen.

---

## 9. Reverse engineering / IP-protection

Een app op een device kan worden gedecompileerd. Geen client-side bescherming is waterdicht.

**Wat helpt:**
- Server-side validation van premium features (geen client-side `isPremium = true`)
- Receipt validation server-side (StoreKit 2 met App Store Server API)
- Obfuscatie van string-constants (`SwiftShield`-achtig) — vertraagt reverse-engineering, stopt het niet
- Geen API-keys in binary (gebruik proxy-service)

**Wat niet helpt:**
- Encryptie van strings die wel worden gedecrypt op runtime — trivial bypass.
- "Detecteer debugger" — wordt gepatcht.

---

## 10. Anti-patterns

- ❌ `kSecAttrAccessibleAlways` — werkt niet meer in moderne iOS, en als het wel werkt: tokens leesbaar zonder unlock.
- ❌ Wachtwoorden in `UserDefaults`. → Plain text. Use Keychain.
- ❌ ATS uitzetten "voor development". → Vergeet je in productie.
- ❌ Biometric authentication zonder passcode-fallback. → User die net pleister op vinger heeft = gelocked uit.
- ❌ "User-ID" = email. → Hash het, of gebruik provider's stable user ID.
- ❌ Server-side check vergeten. → "Premium" flag client-side bewerkbaar.
- ❌ Tokens loggen "voor debug". → Eén leak en alle gebruikers gecompromitteerd.

---

## 11. Checklist

- [ ] `docs/threat-model.md` bestaat met assets, threats, mitigations
- [ ] Keychain accessibility = `*ThisDeviceOnly` tenzij sync gewenst
- [ ] Data Protection class gezet op persistent store
- [ ] ATS niet uitgezet, of exceptions gedocumenteerd met rationale
- [ ] Sign in with Apple beschikbaar (indien third-party social login)
- [ ] Local Authentication met passcode-fallback
- [ ] Account deletion verwijdert ALLE PII (lokaal + remote + Keychain)
- [ ] Premium-checks server-side, niet alleen client-side
- [ ] Geen tokens/wachtwoorden in `os.Logger`
- [ ] Jailbreak-respons (indien sensitive app) is "warn", niet "block"
