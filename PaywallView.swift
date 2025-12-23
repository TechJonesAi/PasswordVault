//
//  PaywallView.swift
//  PasswordVault
//
//  Created by AI Assistant on 05/12/2025.
//

import SwiftUI
import StoreKit

/// Paywall view for premium purchase
struct PaywallView: View {
    
    @Binding var isPresented: Bool
    var premiumManager: PremiumManager
    var onPurchaseComplete: () -> Void
    
    @State private var selectedProduct: Product?
    @State private var initialPremiumStatus: Bool?
    @State private var showRestoreAlert = false
    @State private var restoreMessage = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("Unlock Premium")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Get unlimited passwords and exclusive features")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    
                    // Subscription Info (Required by Apple)
                    VStack(spacing: 8) {
                        Text("Premium Subscription Options:")
                            .font(.headline)
                        Text("• Monthly: $1.99/month")
                            .font(.subheadline)
                        Text("• Yearly: $18.00/year")
                            .font(.subheadline)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    // Feature comparison
                    VStack(spacing: 16) {
                        FeatureRow(
                            icon: "lock.fill",
                            title: "Password Storage",
                            freeValue: "1 password",
                            premiumValue: "Unlimited",
                            isPremium: true
                        )
                        
                        FeatureRow(
                            icon: "key.fill",
                            title: "Password Generator",
                            freeValue: "Unlimited",
                            premiumValue: "Unlimited",
                            isPremium: false
                        )
                        
                        FeatureRow(
                            icon: "apps.iphone",
                            title: "AutoFill Extension",
                            freeValue: "Not included",
                            premiumValue: "Included",
                            isPremium: true
                        )
                        
                        FeatureRow(
                            icon: "heart.text.square",
                            title: "Health Dashboard",
                            freeValue: "Not included",
                            premiumValue: "Included",
                            isPremium: true
                        )
                    }
                    .padding(.horizontal)
                    
                    // Product selection
                    VStack(spacing: 12) {
                        if premiumManager.isLoading && premiumManager.availableProducts.isEmpty {
                            ProgressView("Loading products...")
                                .padding()
                        } else {
                            ForEach(premiumManager.availableProducts, id: \.id) { product in
                                ProductButton(
                                    product: product,
                                    isSelected: selectedProduct?.id == product.id
                                ) {
                                    selectedProduct = product
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Purchase button
                    if let product = selectedProduct {
                        Button {
                            purchaseProduct(product)
                        } label: {
                            if premiumManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            } else {
                                Text("Subscribe for \(product.displayPrice)")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            }
                        }
                        .background(Color.purple)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .disabled(premiumManager.isLoading)
                    }
                    
                    // Restore purchases link
                    Button {
                        restorePurchases()
                    } label: {
                        if premiumManager.isLoading {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Restoring...")
                            }
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                        } else {
                            Text("Restore Purchases")
                                .font(.subheadline)
                                .foregroundStyle(.blue)
                        }
                    }
                    .disabled(premiumManager.isLoading)
                    
                    // Fine print (Required by Apple)
                    VStack(spacing: 8) {
                        Text("Subscription automatically renews unless auto-renew is turned off at least 24 hours before the end of the current period. Your account will be charged for renewal within 24 hours prior to the end of the current period. You can manage and cancel your subscriptions by going to your App Store account settings after purchase.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        
                        HStack(spacing: 16) {
                            Link("Privacy Policy", destination: URL(string: "https://techjonesai.github.io/PasswordVault/privacy.html")!)
                            Text("•")
                            Link("Terms of Use (EULA)", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                        }
                        .font(.caption2)
                        .foregroundStyle(.blue)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Maybe Later") {
                        isPresented = false
                    }
                }
            }
            .alert("Restore Purchases", isPresented: $showRestoreAlert) {
                Button("OK", role: .cancel) {
                    // If premium was restored, dismiss paywall
                    if premiumManager.isPremium {
                        onPurchaseComplete()
                        isPresented = false
                    }
                }
            } message: {
                Text(restoreMessage)
            }
        }
        .onAppear {
            // Capture initial premium status
            initialPremiumStatus = premiumManager.isPremium
            
            // Select first product by default
            if selectedProduct == nil {
                selectedProduct = premiumManager.availableProducts.first
            }
        }
        .onChange(of: premiumManager.availableProducts) {
            // When products load, select first one if none selected
            if selectedProduct == nil, let first = premiumManager.availableProducts.first {
                selectedProduct = first
            }
        }
        .onChange(of: premiumManager.isPremium) { oldValue, newValue in
            // Only dismiss if premium status changed from false to true
            // AND we had captured the initial status
            if let initial = initialPremiumStatus, !initial && newValue {
                print("✅ Premium purchase completed!")
                onPurchaseComplete()
                isPresented = false
            }
        }
    }
    
    private func purchaseProduct(_ product: Product) {
        Task {
            print("🛒 Starting purchase for: \(product.displayName)")
            let success = await premiumManager.purchase(product)
            
            if success {
                // Give PremiumManager a moment to update
                try? await Task.sleep(for: .milliseconds(500))
                
                // Check if premium status was updated
                if premiumManager.isPremium {
                    print("✅ Purchase completed successfully, dismissing paywall")
                    await MainActor.run {
                        onPurchaseComplete()
                        isPresented = false
                    }
                } else {
                    print("⚠️ Purchase completed but premium status not updated")
                }
            } else {
                print("⚠️ Purchase was not completed")
            }
        }
    }
    
    private func restorePurchases() {
        Task {
            print("🔄 Starting restore purchases...")
            await premiumManager.restorePurchases()
            
            // Show result to user
            await MainActor.run {
                if premiumManager.isPremium {
                    restoreMessage = "Premium successfully restored!"
                } else {
                    restoreMessage = "No active subscriptions found. If you believe this is an error, please contact support."
                }
                showRestoreAlert = true
            }
        }
    }
}

/// Feature comparison row
struct FeatureRow: View {
    let icon: String
    let title: String
    let freeValue: String
    let premiumValue: String
    let isPremium: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(isPremium ? .purple : .blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(spacing: 8) {
                    Label(freeValue, systemImage: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    
                    Label(premiumValue, systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

/// Product selection button
struct ProductButton: View {
    let product: Product
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.displayName)
                        .font(.headline)
                    Text(product.displayPrice)
                        .font(.title3)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .blue : .secondary)
                    .font(.title2)
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PaywallView(
        isPresented: .constant(true),
        premiumManager: PremiumManager(),
        onPurchaseComplete: {}
    )
}
