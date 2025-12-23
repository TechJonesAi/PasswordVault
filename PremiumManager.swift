//
//  PremiumManager.swift
//  PasswordVault
//
//  Created by AI Assistant on 05/12/2025.
//

import Foundation
import StoreKit

/// Manages premium subscription status and in-app purchases
@Observable
final class PremiumManager {
    
    // MARK: - Product IDs
    static nonisolated let monthlyProductID = "co.uk.techjonesai.PasswordVault.premium_monthly"
    static nonisolated let yearlyProductID = "co.uk.techjonesai.PasswordVault.premium_yearly"
    
    // MARK: - Published Properties
    @MainActor var isPremium: Bool = false
    @MainActor var availableProducts: [Product] = []
    @MainActor var isLoading: Bool = true
    @MainActor var errorMessage: String?
    @MainActor var subscriptionType: String?
    
    // MARK: - Private Properties
    private var transactionListener: Task<Void, Never>?
    private let premiumKey = "isPremiumUser"
    
    // MARK: - Initialization
    @MainActor
    init() {
        transactionListener = listenForTransactions()
        
        Task {
            await checkSubscriptionStatus()
            await loadProducts()
            self.isLoading = false
        }
    }
    
    deinit {
        transactionListener?.cancel()
    }
    
    // MARK: - Load Products
    
    @MainActor
    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let productIDs = [Self.monthlyProductID, Self.yearlyProductID]
            let products = try await Product.products(for: productIDs)
            
            self.availableProducts = products.sorted { $0.price < $1.price }
            self.isLoading = false
        } catch {
            self.errorMessage = "Failed to load products"
            self.isLoading = false
        }
    }
    
    // MARK: - Purchase
    
    @MainActor
    func purchase(_ product: Product) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                
                updatePremiumStatus(true)
                
                if transaction.productID == Self.monthlyProductID {
                    subscriptionType = "Monthly"
                } else if transaction.productID == Self.yearlyProductID {
                    subscriptionType = "Yearly"
                }
                
                await transaction.finish()
                
                self.isLoading = false
                
                return true
                
            case .userCancelled:
                self.isLoading = false
                return false
                
            case .pending:
                self.errorMessage = "Purchase pending approval"
                self.isLoading = false
                return false
                
            @unknown default:
                self.isLoading = false
                return false
            }
        } catch {
            self.errorMessage = "Purchase failed"
            self.isLoading = false
            return false
        }
    }
    
    // MARK: - Restore Purchases
    
    @MainActor
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await AppStore.sync()
            await checkSubscriptionStatus()
            
            self.isLoading = false
            if !self.isPremium {
                self.errorMessage = "No active subscriptions found"
            }
        } catch {
            self.errorMessage = "Restore failed"
            self.isLoading = false
        }
    }
    
    // MARK: - Check Subscription Status
    
    @MainActor
    func checkSubscriptionStatus() async {
        var hasActiveSubscription = false
        var foundType: String? = nil
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                if transaction.productID == Self.monthlyProductID {
                    hasActiveSubscription = true
                    foundType = "Monthly"
                } else if transaction.productID == Self.yearlyProductID {
                    hasActiveSubscription = true
                    foundType = "Yearly"
                }
            } catch {
                // Transaction verification failed
            }
        }
        
        self.subscriptionType = foundType
        updatePremiumStatus(hasActiveSubscription)
    }
    
    // MARK: - Transaction Listener
    
    @MainActor
    private func listenForTransactions() -> Task<Void, Never> {
        return Task.detached { [weak self] in
            for await result in Transaction.updates {
                do {
                    let transaction = try self?.checkVerified(result)
                    
                    if let transaction = transaction {
                        let monthlyID = PremiumManager.monthlyProductID
                        let yearlyID = PremiumManager.yearlyProductID
                        
                        if transaction.productID == monthlyID ||
                           transaction.productID == yearlyID {
                            await MainActor.run {
                                self?.updatePremiumStatus(true)
                                
                                if transaction.productID == monthlyID {
                                    self?.subscriptionType = "Monthly"
                                } else {
                                    self?.subscriptionType = "Yearly"
                                }
                            }
                        }
                        
                        await transaction.finish()
                    }
                } catch {
                    // Transaction verification failed
                }
            }
        }
    }
    
    // MARK: - Verification
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Premium Status Persistence
    
    @MainActor
    private func updatePremiumStatus(_ isPremium: Bool) {
        self.isPremium = isPremium
        savePremiumStatus(isPremium)
    }
    
    private func savePremiumStatus(_ isPremium: Bool) {
        UserDefaults.standard.set(isPremium, forKey: premiumKey)
        
        let sharedDefaults = UserDefaults(suiteName: "group.co.uk.techjonesai.PasswordVaultShared")
        sharedDefaults?.set(isPremium, forKey: premiumKey)
    }
    
    @MainActor
    private func loadPremiumStatus() {
        isPremium = UserDefaults.standard.bool(forKey: premiumKey)
    }
}
