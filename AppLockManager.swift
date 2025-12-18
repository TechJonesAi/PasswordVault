//
//  AppLockManager.swift
//  PasswordVault
//
//  Created by AI Assistant on 10/12/2025.
//  Feature 1: Biometric Lock (Face ID / Touch ID)
//  Feature 5: Auto-Lock Timer
//

import Foundation
import LocalAuthentication
import SwiftUI

/// Manages app lock state, biometric authentication, and auto-lock timer
@Observable
final class AppLockManager {
    
    // MARK: - Settings Keys
    private let biometricEnabledKey = "biometric_lock_enabled"
    private let autoLockEnabledKey = "auto_lock_enabled"
    private let autoLockDurationKey = "auto_lock_duration"
    private let lastActiveTimeKey = "last_active_time"
    
    // MARK: - State
    var isLocked: Bool = true
    var biometricEnabled: Bool = false
    var autoLockEnabled: Bool = false
    var autoLockDuration: AutoLockDuration = .oneMinute
    var biometricType: BiometricType = .none
    var authenticationError: String?
    
    // MARK: - Auto Lock Duration Options
    enum AutoLockDuration: Int, CaseIterable, Identifiable {
        case immediately = 0
        case thirtySeconds = 30
        case oneMinute = 60
        case twoMinutes = 120
        case fiveMinutes = 300
        case tenMinutes = 600
        case fifteenMinutes = 900
        
        var id: Int { rawValue }
        
        var displayName: String {
            switch self {
            case .immediately: return "Immediately"
            case .thirtySeconds: return "30 seconds"
            case .oneMinute: return "1 minute"
            case .twoMinutes: return "2 minutes"
            case .fiveMinutes: return "5 minutes"
            case .tenMinutes: return "10 minutes"
            case .fifteenMinutes: return "15 minutes"
            }
        }
    }
    
    // MARK: - Biometric Type
    enum BiometricType {
        case none
        case touchID
        case faceID
        case opticID
        
        var displayName: String {
            switch self {
            case .none: return "None"
            case .touchID: return "Touch ID"
            case .faceID: return "Face ID"
            case .opticID: return "Optic ID"
            }
        }
        
        var iconName: String {
            switch self {
            case .none: return "lock.fill"
            case .touchID: return "touchid"
            case .faceID: return "faceid"
            case .opticID: return "opticid"
            }
        }
    }
    
    // MARK: - Shared UserDefaults
    private var defaults: UserDefaults {
        UserDefaults(suiteName: "group.co.uk.techjonesai.PasswordVaultShared") ?? .standard
    }
    
    // MARK: - Init
    init() {
        loadSettings()
        checkBiometricType()
        
        // If biometric is not enabled, don't lock
        if !biometricEnabled {
            isLocked = false
        }
    }
    
    // MARK: - Load/Save Settings
    
    private func loadSettings() {
        biometricEnabled = defaults.bool(forKey: biometricEnabledKey)
        autoLockEnabled = defaults.bool(forKey: autoLockEnabledKey)
        
        let durationRaw = defaults.integer(forKey: autoLockDurationKey)
        autoLockDuration = AutoLockDuration(rawValue: durationRaw) ?? .oneMinute
    }
    
    func saveSettings() {
        defaults.set(biometricEnabled, forKey: biometricEnabledKey)
        defaults.set(autoLockEnabled, forKey: autoLockEnabledKey)
        defaults.set(autoLockDuration.rawValue, forKey: autoLockDurationKey)
        defaults.synchronize()
    }
    
    // MARK: - Biometric Detection
    
    func checkBiometricType() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            switch context.biometryType {
            case .touchID:
                biometricType = .touchID
            case .faceID:
                biometricType = .faceID
            case .opticID:
                biometricType = .opticID
            default:
                biometricType = .none
            }
        } else {
            biometricType = .none
        }
    }
    
    var canUseBiometrics: Bool {
        biometricType != .none
    }
    
    // MARK: - Authentication
    
    func authenticate() async -> Bool {
        let context = LAContext()
        var error: NSError?
        
        // Check if biometric auth is available
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            // Fall back to passcode
            return await authenticateWithPasscode()
        }
        
        do {
            let reason = "Unlock PasswordVault to access your passwords"
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            
            await MainActor.run {
                if success {
                    isLocked = false
                    authenticationError = nil
                    updateLastActiveTime()
                }
            }
            
            return success
        } catch let authError as LAError {
            await MainActor.run {
                switch authError.code {
                case .userCancel:
                    authenticationError = "Authentication cancelled"
                case .userFallback:
                    // User wants to use passcode
                    Task {
                        await authenticateWithPasscode()
                    }
                case .biometryLockout:
                    authenticationError = "Biometric locked. Please use device passcode."
                case .biometryNotAvailable:
                    authenticationError = "Biometric authentication not available"
                case .biometryNotEnrolled:
                    authenticationError = "No biometric data enrolled"
                default:
                    authenticationError = "Authentication failed"
                }
            }
            return false
        } catch {
            await MainActor.run {
                authenticationError = "Authentication failed"
            }
            return false
        }
    }
    
    @discardableResult
    func authenticateWithPasscode() async -> Bool {
        let context = LAContext()
        
        do {
            let reason = "Unlock PasswordVault to access your passwords"
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
            
            await MainActor.run {
                if success {
                    isLocked = false
                    authenticationError = nil
                    updateLastActiveTime()
                }
            }
            
            return success
        } catch {
            await MainActor.run {
                authenticationError = "Authentication failed"
            }
            return false
        }
    }
    
    // MARK: - Lock Management
    
    func lock() {
        if biometricEnabled {
            isLocked = true
        }
    }
    
    func unlock() {
        isLocked = false
        updateLastActiveTime()
    }
    
    // MARK: - Auto-Lock Timer
    
    func updateLastActiveTime() {
        defaults.set(Date().timeIntervalSince1970, forKey: lastActiveTimeKey)
    }
    
    func checkAutoLock() {
        guard biometricEnabled && autoLockEnabled else { return }
        guard autoLockDuration != .immediately else {
            lock()
            return
        }
        
        let lastActive = defaults.double(forKey: lastActiveTimeKey)
        guard lastActive > 0 else { return }
        
        let elapsed = Date().timeIntervalSince1970 - lastActive
        
        if elapsed >= Double(autoLockDuration.rawValue) {
            lock()
        }
    }
    
    // MARK: - Toggle Biometric
    
    func toggleBiometric() async -> Bool {
        if biometricEnabled {
            // Turning off - no auth needed
            biometricEnabled = false
            isLocked = false
            saveSettings()
            return true
        } else {
            // Turning on - authenticate first
            let success = await authenticate()
            if success {
                biometricEnabled = true
                isLocked = false
                saveSettings()
            }
            return success
        }
    }
}
