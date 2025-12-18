//
//  OnboardingFlowView.swift
//  PasswordVault
//
//  Created by AI Assistant on 05/12/2025.
//

import SwiftUI

/// Onboarding flow shown on first launch
struct OnboardingFlowView: View {
    
    @Binding var isPresented: Bool
    @Bindable var premiumManager: PremiumManager  // ✅ Changed from @Binding to @Bindable
    @State private var currentPage = 0
    @State private var showPaywall = false
    
    var body: some View {
        ZStack {
            // Page content
            TabView(selection: $currentPage) {
                // Page 1: Welcome
                OnboardingPageView(
                    systemImage: "lock.shield.fill",
                    title: "Welcome to PasswordVault",
                    description: "Your secure password manager for iOS",
                    accentColor: .blue
                )
                .tag(0)
                
                // Page 2: Generate
                OnboardingPageView(
                    systemImage: "key.fill",
                    title: "Generate Strong Passwords",
                    description: "Create secure passwords with customizable options",
                    accentColor: .green
                )
                .tag(1)
                
                // Page 3: Store
                OnboardingPageView(
                    systemImage: "lock.fill",
                    title: "Store Securely",
                    description: "Your passwords are encrypted in iOS Keychain",
                    accentColor: .orange
                )
                .tag(2)
                
                // Page 4: AutoFill
                OnboardingPageView(
                    systemImage: "sparkles",
                    title: "AutoFill Everywhere",
                    description: "Premium feature: Fill passwords in any app or website",
                    accentColor: .purple
                )
                .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            
            // Bottom buttons
            VStack {
                Spacer()
                
                if currentPage == 3 {
                    // Final page buttons
                    VStack(spacing: 16) {
                        Button {
                            showPaywall = true
                        } label: {
                            Text("Unlock Premium")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.purple)
                                .cornerRadius(12)
                        }
                        
                        Button {
                            isPresented = false
                        } label: {
                            Text("Start Free")
                                .font(.headline)
                                .foregroundStyle(.blue)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 50)
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(
                isPresented: $showPaywall,
                premiumManager: premiumManager,
                onPurchaseComplete: {
                    isPresented = false
                }
            )
        }
    }
}

/// Individual onboarding page
struct OnboardingPageView: View {
    let systemImage: String
    let title: String
    let description: String
    let accentColor: Color
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: systemImage)
                .font(.system(size: 80))
                .foregroundStyle(accentColor)
            
            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text(description)
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Spacer()
            Spacer()
        }
    }
}

#Preview {
    OnboardingFlowView(
        isPresented: .constant(true),
        premiumManager: PremiumManager()  // ✅ Fixed: Pass instance directly
    )
}
