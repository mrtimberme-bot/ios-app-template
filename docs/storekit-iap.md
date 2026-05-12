# storekit-iap.md — In-App Purchase, Subscriptions, Review Prompts

> **Doel:** monetization-patterns die App Review halen — StoreKit 2, server-side validation, subscription lifecycle, restore purchases.
> **Wanneer raadplegen:** zodra je app betaalde features krijgt. Ook bij review-prompts (geen IAP, wel StoreKit).
> **Hoort bij:** `app_store_readiness.md` §10 (Guideline 3.1.1).

---

## 1. Verplichte regels (Apple Guidelines 3.1)

- **Digitale content of services in je app** = **MOET** via In-App Purchase.
- **Externe payment-links** voor digitale content = **rejection-grond** (3.1.1, 3.1.3).
- **Restore Purchases**-functie = **verplicht** (3.1.1).
- **Subscription pricing** moet vóór purchase zichtbaar zijn (3.1.2).
- **Auto-renewable subscriptions** vereisen Privacy Policy + Terms of Use links (3.1.2).

**Reader-apps** (Spotify, Netflix-style): externe accounts/login + content viewen mag, *afsluiten* van abonnement moet via App Store of via "Reader" entitlement (apart aanvragen bij Apple).

---

## 2. StoreKit 2 (iOS 15+) — moderne API

### Producten ophalen

```swift
import StoreKit

public actor StoreManager {
    private let productIDs: Set<String> = ["pro_monthly", "pro_yearly", "lifetime"]
    public private(set) var products: [Product] = []
    public private(set) var purchasedProductIDs: Set<String> = []

    public func loadProducts() async throws {
        products = try await Product.products(for: productIDs)
    }

    public func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updatePurchasedProducts()
            await transaction.finish()
            return transaction
        case .userCancelled, .pending:
            return nil
        @unknown default:
            return nil
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    public func updatePurchasedProducts() async {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.revocationDate == nil {
                purchasedProductIDs.insert(transaction.productID)
            } else {
                purchasedProductIDs.remove(transaction.productID)
            }
        }
    }

    public func listenForTransactions() -> Task<Void, Never> {
        Task.detached {
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else { continue }
                await self.updatePurchasedProducts()
                await transaction.finish()
            }
        }
    }
}
```

**Belangrijk:**
- Start `listenForTransactions()` in `App.init()`.
- `Transaction.updates` ontvangt updates die **buiten** de app gebeuren (refunds, family sharing, App Store-cancellatie).

---

## 3. Restore Purchases — verplicht

```swift
public func restorePurchases() async throws {
    try await AppStore.sync()
    await updatePurchasedProducts()
}
```

UI-knop: "Restore Purchases" — **moet** in Settings of Paywall te vinden zijn. Anders: rejection.

---

## 4. Server-side receipt validation

**Voor productie-apps:** validate receipts server-side, niet alleen client-side.

**Waarom:**
- Client-side `Transaction.verify` checkt signature, maar:
  - Receipt-data kan worden geintercept en hergebruikt.
  - Premium-status moet bron-of-truth server-side zijn voor cross-device.
  - Family Sharing, refunds, billing-issues: server-side bron is betrouwbaarder.

**Hoe:**
1. App stuurt JWS-representation van transaction naar je backend.
2. Backend valideert via App Store Server API.
3. Backend updatet user's premium-status in DB.
4. App vraagt status van backend, niet van device.

```swift
// In app
let jws = transaction.jwsRepresentation
let response: PremiumStatus = try await api.verifyPurchase(jws: jws)
if response.isPremium {
    UserDefaults.standard.set(true, forKey: "premium")
}
```

**App Store Server API documentatie:** https://developer.apple.com/documentation/appstoreserverapi

---

## 5. Subscription lifecycle

### Status types

```swift
let statuses = try await Product.SubscriptionInfo.status(for: groupID)
for status in statuses {
    switch status.state {
    case .subscribed: // active
    case .expired: // expired, may resubscribe
    case .inBillingRetryPeriod: // payment failed, Apple retrying
    case .inGracePeriod: // payment failed but still access
    case .revoked: // refunded, no access
    @unknown default: break
    }
}
```

### Grace period

Default: tot 16 dagen na payment-failure waarin user nog access heeft.
Reden: voorkomt dat tijdelijke billing-issues users meteen lockt.

**UI:** "Je betaling kon niet worden verwerkt. Update je betaalmethode." — banner, niet hard block.

### Expiration & re-subscribe

```swift
let expirationDate = transaction.expirationDate
let willAutoRenew = await transaction.subscriptionStatus?.renewalInfo

// Niet: eigen lokale expiration logic — vraag het aan StoreKit/server.
```

---

## 6. Promotional offers & introductory pricing

### Introductory offer (eerste keer)
```swift
if let intro = product.subscription?.introductoryOffer {
    Text("\(intro.displayPrice) voor de eerste \(intro.period.value) \(intro.period.unit.localizedDescription)")
}
```

### Promotional offer (existing/lapsed users)
- Vereist signed offer-token van je backend.
- Setup in App Store Connect: per product → "Subscription Offers".

---

## 7. Family Sharing

Optie per product: "Family Sharing" aan/uit in App Store Connect.

```swift
if transaction.ownershipType == .familyShared {
    // De gebruiker heeft toegang via family sharing
}
```

UI moet het verschil tonen — sommige apps geven shared users iets minder (geen account-koppeling bv).

---

## 8. Paywall design tips

App Review let op:

- **Pricing zichtbaar** — prijs + duur duidelijk vóór "subscribe" tap.
- **Auto-renewal disclosure**: "Subscription auto-renews unless cancelled 24h before period end."
- **Restore Purchases** knop op paywall.
- **Privacy Policy + Terms** links zichtbaar.
- **"Niet nu" / "Skip"-optie** zichtbaar (geen forced paywall op eerste run zonder mogelijkheid weg te klikken).
- **Geen misleidende design** — geen "X" die eigenlijk subscribe-actie is.

```swift
struct PaywallView: View {
    var body: some View {
        VStack {
            // Features uitleg
            // Pricing per product
            ForEach(products) { product in
                Button(product.displayName) { purchase(product) }
                Text("\(product.displayPrice) per \(product.subscription?.subscriptionPeriod.unit.localizedDescription ?? "")")
            }

            // Verplichte disclosures
            Text("Auto-renewable. Cancel anytime in Settings.")
                .font(.caption)
            HStack {
                Link("Privacy Policy", destination: URL(string: "https://app.com/privacy")!)
                Link("Terms of Use", destination: URL(string: "https://app.com/terms")!)
            }

            // Verplichte knoppen
            Button("Restore Purchases") { Task { try? await store.restorePurchases() } }
            Button("Niet nu") { dismiss() }
        }
    }
}
```

---

## 9. Testen

### StoreKit Test framework

`StoreKitTest.storekit` configuration file in repo. Definieert mock-products, transactions, errors.

In test:
```swift
let session = try SKTestSession(configurationFileNamed: "Configuration")
session.disableDialogs = true
session.clearTransactions()
// ...test purchase flows
```

### Sandbox account

App Store Connect → Users and Access → Sandbox Testers. Sandbox-accounts:
- Korte renewal-periodes (1 jaar = 1 uur in sandbox)
- Geen echte betaling

### TestFlight

TestFlight gebruikt sandbox StoreKit. Productie-data wordt pas in productie geactiveerd.

---

## 10. SKStoreReviewController — review prompts

**Niet IAP, maar wel StoreKit.** Vraag user om review.

```swift
import StoreKit

if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
    SKStoreReviewController.requestReview(in: scene)
}
```

**Regels:**
- Apple toont prompt **maximaal 3x per 365 dagen** per user.
- Apple kan 'm helemaal niet tonen — je hebt geen garantie.
- Vraag op **positieve momenten**: na succesvolle actie, niet na error.
- Niet blokkerend; user moet je app kunnen blijven gebruiken.

**Strategie:**
- Track "happy moments" (key feature gebruikt N keer, succesvolle workflow voltooid).
- Pas dan prompt.
- Onthouden of je het al gevraagd hebt deze versie.

```swift
@AppStorage("lastReviewPromptVersion") var lastPromptVersion = ""

if happyMoments >= 5 && lastPromptVersion != currentAppVersion {
    requestReview()
    lastPromptVersion = currentAppVersion
}
```

---

## 11. Anti-patterns

- ❌ Externe payment URL voor digitale content. → Rejection 3.1.1.
- ❌ Geen Restore Purchases. → Rejection 3.1.1.
- ❌ Premium check alleen client-side. → Bypass via JB-device of patches.
- ❌ Lokale expiration-tracking. → Klok-manipulatie omzeilt het.
- ❌ Review-prompt na error. → User klaagt vóór ze realiseren ze 1-ster geven.
- ❌ Review-prompt op elke launch. → Apple negeert je en je gebruikers haten je.
- ❌ Auto-renew zonder duidelijke disclosure. → Rejection 3.1.2.
- ❌ Eerste paywall zonder "X" om weg te klikken. → Rejection 4.0.

---

## 12. Checklist voor een paywall-feature

- [ ] StoreKit 2 (Product/Transaction APIs)
- [ ] Restore Purchases knop in UI
- [ ] Server-side receipt validation
- [ ] Transaction.updates listener actief
- [ ] Status-handling: subscribed/expired/grace/billing-retry/revoked
- [ ] Auto-renewal disclosure zichtbaar
- [ ] Privacy Policy + Terms links zichtbaar
- [ ] "Niet nu" / dismiss knop
- [ ] Pricing per product zichtbaar vóór purchase
- [ ] Localized pricing (StoreKit doet dit auto)
- [ ] StoreKitTest configuration file voor unit tests
- [ ] Sandbox-tester accounts aangemaakt
- [ ] App Store Connect: subscription group + products + screenshots per product

## 13. Checklist voor review prompts

- [ ] `SKStoreReviewController.requestReview` gebruikt (niet eigen alert)
- [ ] Triggered op positief moment, niet bij errors
- [ ] Eén keer per app-versie max
- [ ] Niet blokkerend
- [ ] Niet op eerste launch
