//
//  PasswordVaultApp.swift
//  PasswordVault
//
//  Created by Darren Jones on 03/12/2025.
//  ENHANCED: Added biometric lock, auto-lock timer, AI assistant, and iCloud Sync
//

import SwiftUI

@main
struct PasswordVaultApp: App {
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showOnboarding = false
    @State private var premiumManager = PremiumManager()
    @State private var lockManager = AppLockManager()
    @State private var settingsManager = AppSettingsManager()
    @State private var aiAssistant = AIPasswordAssistant()
    @State private var iCloudManager = iCloudSyncManager()
    
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Main content
                MainTabView(
                    premiumManager: premiumManager,
                    lockManager: lockManager,
                    settingsManager: settingsManager,
                    aiAssistant: aiAssistant,
                    iCloudManager: iCloudManager
                )
                
                // Lock screen overlay (Feature 1 & 5)
                if lockManager.isLocked && lockManager.biometricEnabled {
                    LockScreenView(lockManager: lockManager)
                        .transition(.opacity)
                        .zIndex(100)
                }
                
                // Show subtle loading overlay while checking subscription
                if premiumManager.isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(.white)
                        Text("Checking subscription...")
                            .foregroundStyle(.white)
                            .font(.subheadline)
                    }
                    .padding(24)
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: lockManager.isLocked)
            .onAppear {
                if !hasCompletedOnboarding {
                    showOnboarding = true
                }
            }
            .sheet(isPresented: $showOnboarding) {
                OnboardingFlowView(
                    isPresented: $showOnboarding,
                    premiumManager: premiumManager
                )
                .interactiveDismissDisabled()
                .onDisappear {
                    hasCompletedOnboarding = true
                }
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                handleScenePhaseChange(from: oldPhase, to: newPhase)
            }
        }
    }
    
    // MARK: - Scene Phase Handling for Auto-Lock
    
    private func handleScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            // App became active - check if we need to lock
            lockManager.checkAutoLock()
            
            // Refresh iCloud status
            iCloudManager.checkiCloudStatus()
            
        case .inactive:
            // App going inactive - update last active time
            lockManager.updateLastActiveTime()
            
        case .background:
            // App went to background
            lockManager.updateLastActiveTime()
            
            // If auto-lock is "immediately", lock now
            if lockManager.biometricEnabled && 
               lockManager.autoLockEnabled && 
               lockManager.autoLockDuration == .immediately {
                lockManager.lock()
            }
            
        @unknown default:
            break
        }
    }
}
