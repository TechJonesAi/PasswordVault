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
    static let monthlyProductID = "co.uk.techjonesai.PasswordVault.premium_monthly"
    static let yearlyProductID = "co.uk.techjonesai.PasswordVault.premium_yearly"
    
    // MARK: - Published Properties
    var isPremium: Bool = false
    var availableProducts: [Product] = []
    var isLoading: Bool = true
    var errorMessage: String?
    var subscriptionType: String?
    
    // MARK: - Private Properties
    private var transactionListener: Task<Void, Never>?
    private let premiumKey = "isPremiumUser"
    
    // MARK: - Initialization
    init() {
        transactionListener = listenForTransactions()
        
        Task {
            await checkSubscriptionStatus()
            await loadProducts()
            
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    deinit {
        transactionListener?.cancel()
    }
    
    // MARK: - Load Products
    
    func loadProducts() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let productIDs = [Self.monthlyProductID, Self.yearlyProductID]
            let products = try await Product.products(for: productIDs)
            
            await MainActor.run {
                self.availableProducts = products.sorted { $0.price < $1.price }
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load products"
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Purchase
    
    func purchase(_ product: Product) async -> Bool {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                
                await updatePremiumStatus(true)
                
                if transaction.productID == Self.monthlyProductID {
                    await MainActor.run { subscriptionType = "Monthly" }
                } else if transaction.productID == Self.yearlyProductID {
                    await MainActor.run { subscriptionType = "Yearly" }
                }
                
                await transaction.finish()
                
                await MainActor.run {
                    self.isLoading = false
                }
                
                return true
                
            case .userCancelled:
                await MainActor.run {
                    self.isLoading = false
                }
                return false
                
            case .pending:
                await MainActor.run {
                    self.errorMessage = "Purchase pending approval"
                    self.isLoading = false
                }
                return false
                
            @unknown default:
                await MainActor.run {
                    self.isLoading = false
                }
                return false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Purchase failed"
                self.isLoading = false
            }
            return false
        }
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            try await AppStore.sync()
            await checkSubscriptionStatus()
            
            await MainActor.run {
                self.isLoading = false
                if !self.isPremium {
                    self.errorMessage = "No active subscriptions found"
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Restore failed"
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Check Subscription Status
    
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
        
        await MainActor.run {
            self.subscriptionType = foundType
        }
        
        await updatePremiumStatus(hasActiveSubscription)
    }
    
    // MARK: - Transaction Listener
    
    private func listenForTransactions() -> Task<Void, Never> {
        return Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self = self else { return }
                
                do {
                    let transaction = try self.checkVerified(result)
                    
                    if transaction.productID == Self.monthlyProductID ||
                       transaction.productID == Self.yearlyProductID {
                        await self.updatePremiumStatus(true)
                        
                        await MainActor.run {
                            if transaction.productID == Self.monthlyProductID {
                                self.subscriptionType = "Monthly"
                            } else {
                                self.subscriptionType = "Yearly"
                            }
                        }
                    }
                    
                    await transaction.finish()
                    
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
    
    private func updatePremiumStatus(_ isPremium: Bool) async {
        await MainActor.run {
            self.isPremium = isPremium
        }
        savePremiumStatus(isPremium)
    }
    
    private func savePremiumStatus(_ isPremium: Bool) {
        UserDefaults.standard.set(isPremium, forKey: premiumKey)
        
        let sharedDefaults = UserDefaults(suiteName: "group.co.uk.techjonesai.PasswordVaultShared")
        sharedDefaults?.set(isPremium, forKey: premiumKey)
    }
    
    private func loadPremiumStatus() {
        isPremium = UserDefaults.standard.bool(forKey: premiumKey)
    }
}
