//
//  ExtensionPremiumUpsellView.swift
//  PasswordVaultAutoFill
//
//  Created by AI Assistant on 05/12/2025.
//

import SwiftUI

/// Premium upsell view shown in extension when user is on free tier
struct ExtensionPremiumUpsellView: View {
    
    let onCancel: () -> Void
    let onOpenApp: () -> Void
    
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
                
                Text("AutoFill requires Premium")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                VStack(alignment: .leading, spacing: 12) {
                    FeatureBullet(
                        icon: "infinity",
                        title: "Unlimited Passwords"
                    )
                    
                    FeatureBullet(
                        icon: "apps.iphone",
                        title: "AutoFill in All Apps"
                    )
                    
                    FeatureBullet(
                        icon: "heart.text.square",
                        title: "Password Health Dashboard"
                    )
                }
                .padding()
                
                Button {
                    onOpenApp()
                } label: {
                    Text("Upgrade to Premium")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("PasswordVault")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }
        }
    }
}

/// Feature bullet point
struct FeatureBullet: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .font(.title3)
                .frame(width: 30)
            
            Text(title)
                .font(.headline)
            
            Spacer()
        }
    }
}

#Preview {
    ExtensionPremiumUpsellView(
        onCancel: {},
        onOpenApp: {}
    )
}
