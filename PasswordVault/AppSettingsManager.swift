//
//  AppSettingsManager.swift
//  PasswordVault
//
//  Created by AI Assistant on 10/12/2025.
//  Centralized app settings management
//

import Foundation
import SwiftUI

/// Manages app-wide settings
@Observable
final class AppSettingsManager {
    
    // MARK: - Storage Keys
    private let appGroupID = "group.co.uk.techjonesai.PasswordVaultShared"
    
    // Settings keys
    private let selectedAppIconKey = "selected_app_icon"
    private let defaultPasswordLengthKey = "default_password_length"
    private let defaultPasswordOptionsKey = "default_password_options"
    private let passwordExpiryDefaultDaysKey = "password_expiry_default_days"
    private let sortOrderKey = "vault_sort_order"
    
    // MARK: - Settings Properties
    
    // Feature 8: Custom App Icons
    var selectedAppIcon: AppIconOption = .default {
        didSet { saveSettings() }
    }
    
    // Password Generator Defaults
    var defaultPasswordLength: Int = 16 {
        didSet { saveSettings() }
    }
    
    var defaultIncludeUppercase: Bool = true {
        didSet { saveSettings() }
    }
    
    var defaultIncludeLowercase: Bool = true {
        didSet { saveSettings() }
    }
    
    var defaultIncludeNumbers: Bool = true {
        didSet { saveSettings() }
    }
    
    var defaultIncludeSymbols: Bool = true {
        didSet { saveSettings() }
    }
    
    // Feature 9: Password Expiry Default
    var defaultExpiryReminderDays: Int? = 90 {
        didSet { saveSettings() }
    }
    
    // Vault Sort Order
    var vaultSortOrder: VaultSortOrder = .nameAsc {
        didSet { saveSettings() }
    }
    
    // MARK: - App Icon Options (Feature 8)
    
    enum AppIconOption: String, CaseIterable, Identifiable {
        case `default` = "AppIcon"
        case dark = "AppIconDark"
        case blue = "AppIconBlue"
        case green = "AppIconGreen"
        case purple = "AppIconPurple"
        case minimal = "AppIconMinimal"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .default: return "Default"
            case .dark: return "Dark"
            case .blue: return "Blue"
            case .green: return "Green"
            case .purple: return "Purple"
            case .minimal: return "Minimal"
            }
        }
        
        var previewColor: Color {
            switch self {
            case .default: return .blue
            case .dark: return .black
            case .blue: return .cyan
            case .green: return .green
            case .purple: return .purple
            case .minimal: return .gray
            }
        }
    }
    
    // MARK: - Sort Order Options
    
    enum VaultSortOrder: String, CaseIterable, Identifiable {
        case nameAsc = "name_asc"
        case nameDesc = "name_desc"
        case dateAddedNewest = "date_newest"
        case dateAddedOldest = "date_oldest"
        case lastModified = "last_modified"
        case folder = "folder"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .nameAsc: return "Name (A-Z)"
            case .nameDesc: return "Name (Z-A)"
            case .dateAddedNewest: return "Newest First"
            case .dateAddedOldest: return "Oldest First"
            case .lastModified: return "Last Modified"
            case .folder: return "By Folder"
            }
        }
    }
    
    // MARK: - Password Expiry Options
    
    enum ExpiryReminderOption: Int, CaseIterable, Identifiable {
        case none = 0
        case thirtyDays = 30
        case sixtyDays = 60
        case ninetyDays = 90
        case oneEightyDays = 180
        case oneYear = 365
        
        var id: Int { rawValue }
        
        var displayName: String {
            switch self {
            case .none: return "No Reminder"
            case .thirtyDays: return "30 days"
            case .sixtyDays: return "60 days"
            case .ninetyDays: return "90 days"
            case .oneEightyDays: return "180 days"
            case .oneYear: return "1 year"
            }
        }
    }
    
    // MARK: - UserDefaults
    
    private var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }
    
    // MARK: - Init
    
    init() {
        loadSettings()
    }
    
    // MARK: - Load/Save
    
    private func loadSettings() {
        // App Icon
        if let iconRaw = defaults.string(forKey: selectedAppIconKey),
           let icon = AppIconOption(rawValue: iconRaw) {
            selectedAppIcon = icon
        }
        
        // Password defaults
        let length = defaults.integer(forKey: defaultPasswordLengthKey)
        defaultPasswordLength = length > 0 ? length : 16
        
        // Sort order
        if let sortRaw = defaults.string(forKey: sortOrderKey),
           let sort = VaultSortOrder(rawValue: sortRaw) {
            vaultSortOrder = sort
        }
        
        // Expiry reminder
        let expiry = defaults.integer(forKey: passwordExpiryDefaultDaysKey)
        defaultExpiryReminderDays = expiry > 0 ? expiry : 90
    }
    
    private func saveSettings() {
        defaults.set(selectedAppIcon.rawValue, forKey: selectedAppIconKey)
        defaults.set(defaultPasswordLength, forKey: defaultPasswordLengthKey)
        defaults.set(vaultSortOrder.rawValue, forKey: sortOrderKey)
        defaults.set(defaultExpiryReminderDays ?? 0, forKey: passwordExpiryDefaultDaysKey)
        defaults.synchronize()
    }
    
    // MARK: - App Icon Changing
    
    func changeAppIcon(to icon: AppIconOption) {
        let iconName: String? = icon == .default ? nil : icon.rawValue
        
        UIApplication.shared.setAlternateIconName(iconName) { error in
            if let error = error {
                print("❌ Failed to change app icon: \(error)")
            } else {
                print("✅ Changed app icon to: \(icon.displayName)")
                self.selectedAppIcon = icon
            }
        }
    }
}
