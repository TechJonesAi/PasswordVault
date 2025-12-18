//
//  MainTabView.swift
//  PasswordVault
//
//  Created by AI Assistant on 05/12/2025.
//  ENHANCED: Added Secure Notes, Credit Cards tabs, iCloud Sync, and feature managers
//

import SwiftUI

/// Main tab container view
struct MainTabView: View {
    
    @Bindable var premiumManager: PremiumManager
    var lockManager: AppLockManager
    var settingsManager: AppSettingsManager
    var aiAssistant: AIPasswordAssistant
    var iCloudManager: iCloudSyncManager
    
    @State private var vaultViewModel = VaultViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Generator
            PasswordGeneratorView(
                vaultViewModel: $vaultViewModel,
                isPremium: $premiumManager.isPremium
            )
            .tabItem {
                Label("Generator", systemImage: "key.fill")
            }
            .tag(0)
            
            // Tab 2: Vault (Passwords)
            VaultListView(
                viewModel: $vaultViewModel,
                isPremium: $premiumManager.isPremium,
                premiumManager: premiumManager,
                aiAssistant: aiAssistant,
                settingsManager: settingsManager
            )
            .tabItem {
                Label("Vault", systemImage: "lock.fill")
            }
            .tag(1)
            
            // Tab 3: Secure Notes (Feature 4)
            SecureNotesView(
                isPremium: $premiumManager.isPremium,
                premiumManager: premiumManager
            )
            .tabItem {
                Label("Notes", systemImage: "note.text")
            }
            .tag(2)
            
            // Tab 4: Credit Cards (Feature 7)
            CreditCardsView(
                isPremium: $premiumManager.isPremium,
                premiumManager: premiumManager
            )
            .tabItem {
                Label("Cards", systemImage: "creditcard.fill")
            }
            .tag(3)
            
            // Tab 5: Settings (includes Security, App Icons, iCloud Sync, etc.)
            SettingsView(
                premiumManager: premiumManager,
                vaultViewModel: $vaultViewModel,
                lockManager: lockManager,
                settingsManager: settingsManager,
                iCloudManager: iCloudManager
            )
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .tag(4)
        }
    }
}

// Backward compatible inits for previews
extension MainTabView {
    init(premiumManager: PremiumManager) {
        self.premiumManager = premiumManager
        self.lockManager = AppLockManager()
        self.settingsManager = AppSettingsManager()
        self.aiAssistant = AIPasswordAssistant()
        self.iCloudManager = iCloudSyncManager()
    }
    
    init(premiumManager: PremiumManager, lockManager: AppLockManager, settingsManager: AppSettingsManager, aiAssistant: AIPasswordAssistant) {
        self.premiumManager = premiumManager
        self.lockManager = lockManager
        self.settingsManager = settingsManager
        self.aiAssistant = aiAssistant
        self.iCloudManager = iCloudSyncManager()
    }
}

#Preview {
    MainTabView(premiumManager: PremiumManager())
}
