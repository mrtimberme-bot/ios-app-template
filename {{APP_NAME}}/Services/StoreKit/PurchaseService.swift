// StoreKit 2 IAP module — OFF by default
// Activeren: verwijder deze comment en voeg StoreKit toe aan project capabilities
// Zie: /setup-storekit voor gedetailleerde instructies

/*
import StoreKit
import Observation
import OSLog

private let logger = Logger(subsystem: "{{BUNDLE_ID}}", category: "StoreKit")

@Observable
final class PurchaseService {
    static let shared = PurchaseService()

    private(set) var purchasedProductIDs: Set<String> = []
    private var transactionTask: Task<Void, Never>?

    private init() {
        transactionTask = observeTransactions()
        Task { await loadPurchasedProducts() }
    }

    func purchase(_ product: Product) async throws -> StoreKit.Transaction? {
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
        case .unverified: throw StoreKitError.failedVerification
        case .verified(let value): return value
        }
    }

    private func observeTransactions() -> Task<Void, Never> {
        Task(priority: .background) {
            for await verification in Transaction.updates {
                if let transaction = try? checkVerified(verification) {
                    await updatePurchasedProducts()
                    await transaction.finish()
                }
            }
        }
    }

    @MainActor
    private func updatePurchasedProducts() async {
        var purchased: Set<String> = []
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                purchased.insert(transaction.productID)
            }
        }
        purchasedProductIDs = purchased
    }

    private func loadPurchasedProducts() async {
        await updatePurchasedProducts()
    }
}

enum StoreKitError: LocalizedError {
    case failedVerification
    var errorDescription: String? { "Aankoop verificatie mislukt." }
}
*/
