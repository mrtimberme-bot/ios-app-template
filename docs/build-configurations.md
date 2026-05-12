# build-configurations.md — Build Flavors & Configurations

> **Doel:** dev/staging/prod scheidingen die voorkomen dat je TestFlight-tester met productie-data praat of dat staging-keys in App Store komen.
> **Wanneer raadplegen:** Fase 2 (project setup), elke nieuwe environment.
> **Hoort bij:** `architecture.md` §11 (secrets), `observability.md`.

---

## 1. Drie environments minimum

| Environment | Doel | Bundle ID | App naam | Endpoint |
|------------|------|-----------|----------|----------|
| **Debug** | Lokale development | `com.company.app.debug` | `App (Debug)` | `dev.api.com` |
| **TestFlight/Staging** | Beta-testers | `com.company.app.beta` | `App (Beta)` | `staging.api.com` |
| **Release** | App Store | `com.company.app` | `App` | `api.com` |

**Waarom verschillende Bundle IDs:** je kunt alle drie naast elkaar op je device installeren. Anders moet je telkens app verwijderen + her-installeren.

---

## 2. xcconfig-files (aanbevolen approach)

```
Configurations/
  Shared.xcconfig        # gedeeld
  Debug.xcconfig         # dev-specifiek
  Staging.xcconfig       # TestFlight-specifiek
  Release.xcconfig       # productie
```

### Shared.xcconfig

```
// Shared.xcconfig
SWIFT_VERSION = 6.0
IPHONEOS_DEPLOYMENT_TARGET = 17.0
SWIFT_STRICT_CONCURRENCY = complete
DEVELOPMENT_TEAM = ABCDE12345
APP_DISPLAY_NAME = MyApp
```

### Debug.xcconfig

```
#include "Shared.xcconfig"

PRODUCT_BUNDLE_IDENTIFIER = com.company.app.debug
APP_DISPLAY_NAME = MyApp (Debug)
APP_ICON_NAME = AppIcon-Debug
API_BASE_URL = https://dev.api.com
LOG_LEVEL = debug
ENABLE_EXPERIMENTAL_FEATURES = YES
```

### Release.xcconfig

```
#include "Shared.xcconfig"

PRODUCT_BUNDLE_IDENTIFIER = com.company.app
APP_DISPLAY_NAME = MyApp
APP_ICON_NAME = AppIcon
API_BASE_URL = https://api.com
LOG_LEVEL = warn
ENABLE_EXPERIMENTAL_FEATURES = NO
```

### Info.plist hookup

```xml
<key>API_BASE_URL</key>
<string>$(API_BASE_URL)</string>
<key>LOG_LEVEL</key>
<string>$(LOG_LEVEL)</string>
<key>ENABLE_EXPERIMENTAL_FEATURES</key>
<string>$(ENABLE_EXPERIMENTAL_FEATURES)</string>
```

### Reading in Swift

```swift
public enum BuildConfiguration {
    public static var apiBaseURL: URL {
        guard let str = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
              let url = URL(string: str) else {
            fatalError("API_BASE_URL ontbreekt in Info.plist")
        }
        return url
    }

    public static var enableExperimentalFeatures: Bool {
        let str = Bundle.main.object(forInfoDictionaryKey: "ENABLE_EXPERIMENTAL_FEATURES") as? String ?? "NO"
        return str == "YES"
    }
}
```

---

## 3. Schemes setup

In Xcode:

1. Product → Scheme → Manage Schemes
2. Voor elke environment één scheme:
   - `App-Debug` (build config: Debug)
   - `App-Beta` (build config: Staging)
   - `App-Release` (build config: Release)
3. Markeer alle als "Shared" (committen in repo)

Per scheme:
- **Run** action: build config matching environment
- **Test** action: meestal Debug
- **Archive** action: Beta of Release naargelang

---

## 4. Secrets per environment

**xcconfig committen JA**, **secrets in xcconfig committen NEE**.

```
// ❌ FOUT
API_KEY = sk-abc123...

// ✅ Goed — uit env-var of CI
API_KEY = ${API_KEY}
```

### Lokale dev secrets

`.env` in `.gitignore`, plus een `Scripts/load-env.sh`:

```bash
#!/usr/bin/env bash
if [ -f .env ]; then
  while IFS= read -r line; do
    [[ "$line" =~ ^#.*$ ]] && continue
    [[ -z "$line" ]] && continue
    export "$line"
  done < .env
fi
```

Run-script in build phase:
```bash
source Scripts/load-env.sh
echo "API_KEY = $API_KEY" > Configurations/Generated.xcconfig
```

`Generated.xcconfig` in `.gitignore`. `#include "Generated.xcconfig"` in Debug.xcconfig.

### CI secrets

GitHub Actions secrets (`Settings → Secrets and variables → Actions`):
```yaml
- name: Build
  env:
    API_KEY: ${{ secrets.API_KEY }}
  run: |
    echo "API_KEY = $API_KEY" >> Configurations/Generated.xcconfig
    xcodebuild ...
```

### TestFlight/Production secrets

Twee opties:
1. **CI bouwt + uploadt** met juiste secrets per environment.
2. **Server-side**, zodat client geen API-keys heeft. Aanbevolen voor third-party API's met kostenrisico.

---

## 5. App icoon per environment

Visuele markering: dev = rode icon, staging = oranje, prod = normaal.

In Assets.xcassets:
- `AppIcon` (productie)
- `AppIcon-Debug` (rood overlay)
- `AppIcon-Beta` (oranje overlay)

In xcconfig: `ASSETCATALOG_COMPILER_APPICON_NAME = $(APP_ICON_NAME)`

**Voorbij visuele check:** TestFlight-tester ziet "(Beta)" naast app naam, dev kan op productie-bundle-ID controleren via Settings → General → Storage.

---

## 6. Feature flags per environment

Combineer met `FeatureFlags.swift` uit Fase 2:

```swift
public extension FeatureFlags {
    static let active: FeatureFlags = {
        #if DEBUG
        return .debug
        #else
        if Bundle.main.bundleIdentifier?.hasSuffix(".beta") == true {
            return .testFlight
        }
        return .production
        #endif
    }()
}
```

---

## 7. URL schemes per environment

Als je deep links hebt:
- Debug: `myapp-debug://`
- Beta: `myapp-beta://`
- Prod: `myapp://`

Universal links: gebruik subdomains (`dev.app.com`, `staging.app.com`, `app.com`).

---

## 8. Push notifications per environment

- **APNs sandbox** voor Debug en TestFlight builds (apns-development.entitlements).
- **APNs production** voor App Store builds (apns-production.entitlements).
- Aparte server-side certificates / .p8 keys per environment.

Mismatch = pushes komen niet aan en geven geen error → lastig debuggen.

---

## 9. Analytics per environment

- Debug: NoOp-implementatie of dev-project in analytics-tool.
- Staging: aparte analytics-project (kan hetzelfde tool zijn, ander dashboard).
- Production: hoofd-analytics-project.

```swift
let analytics: AnalyticsClient = {
    #if DEBUG
    return FakeAnalyticsClient()  // print naar console
    #else
    return TelemetryDeckClient(appID: BuildConfiguration.analyticsAppID)
    #endif
}()
```

---

## 10. Crash reporting per environment

Debug builds → vaak geen crash reporting (zou je dashboard pollueren met dev-crashes).
TestFlight builds → wel reporten (echte device-data).
Production → hoofdstroom.

Sentry: zet `environment` op build config:
```swift
SentrySDK.start { options in
    options.environment = BuildConfiguration.environmentName  // "debug" / "staging" / "production"
}
```

---

## 11. Test-data zaaien

Voor Debug + Beta:
- Optie om sample data te laden (`--seed-data` launch arg)
- Reset-knop in dev-only Settings sectie
- Mock-mode voor demo's

```swift
#if DEBUG
struct DevMenu: View {
    var body: some View {
        Section("Developer") {
            Button("Seed sample data") { /* ... */ }
            Button("Clear all data") { /* ... */ }
            Button("Toggle feature flags") { /* ... */ }
        }
    }
}
#endif
```

---

## 12. Anti-patterns

- ❌ Eén Bundle ID voor alle environments. → Kunt niet naast elkaar installeren.
- ❌ API-keys hardcoded in Swift. → Lekken via reverse-engineering.
- ❌ Productie-data sturen tijdens dev. → Kan productie corrupten.
- ❌ Feature flags in Production op `true` zetten "voor testing". → Half-werkend feature in App Store.
- ❌ Dev-build naar TestFlight uploaden. → Beta-testers zien debug-rode icon, oei.
- ❌ Eén crash-reporting project voor alles. → Productie-incidents verdwijnen tussen dev-noise.

---

## 13. Checklist

- [ ] Drie schemes: Debug, Beta/Staging, Release
- [ ] Drie xcconfig-bestanden + Shared
- [ ] Verschillende Bundle IDs per environment
- [ ] Verschillende app icons per environment
- [ ] Secrets via env-vars / CI secrets, niet in xcconfig committen
- [ ] APNs sandbox voor Debug+Beta, production voor Release
- [ ] Analytics environment-aware
- [ ] FeatureFlags.active linkt naar build config
- [ ] DevMenu beschikbaar in Debug builds
- [ ] CI weet welk scheme/env te bouwen voor welke trigger
