//
//  PremiumUpgradeView.swift
//  PasswordVaultAutoFill
//
//  Created by AI Assistant on 06/12/2025.
//

import SwiftUI

struct PremiumUpgradeView: View {
    let onUpgrade: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Premium Feature")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("AutoFill is a premium feature. Upgrade to access your passwords in any app instantly.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                VStack(alignment: .leading, spacing: 16) {
                    FeatureBullet(icon: "apps.iphone", text: "Fill passwords in all apps")
                    FeatureBullet(icon: "key.fill", text: "Strong password suggestions")
                    FeatureBullet(icon: "faceid", text: "Secure with Face ID")
                    FeatureBullet(icon: "infinity", text: "Unlimited passwords")
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                VStack(spacing: 12) {
                    Button {
                        onUpgrade()
                    } label: {
                        Text("Upgrade to Premium")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .cornerRadius(12)
                    }
                    
                    Button {
                        onCancel()
                    } label: {
                        Text("Maybe Later")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
            .navigationBarHidden(true)
        }
    }
}

struct FeatureBullet: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 30)
            
            Text(text)
                .font(.body)
        }
    }
}
