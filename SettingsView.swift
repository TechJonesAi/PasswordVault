//
//  SettingsView.swift
//  PasswordVault
//
//  Created by AI Assistant on 05/12/2025.
//  ENHANCED: Added Biometric Lock, Auto-Lock, App Icons, Expiry Settings, iCloud Sync
//

import SwiftUI
import AuthenticationServices

/// Settings Tab
struct SettingsView: View {
    
    var premiumManager: PremiumManager
    @Binding var vaultViewModel: VaultViewModel
    @Bindable var lockManager: AppLockManager
    @Bindable var settingsManager: AppSettingsManager
    var iCloudManager: iCloudSyncManager?
    
    @State private var showPaywall = false
    @State private var showRestoreAlert = false
    @State private var restoreMessage = ""
    @State private var showImportExport = false
    @State private var showAppIconPicker = false
    @State private var showSyncAlert = false
    @State private var syncAlertMessage = ""
    
    private var isPremium: Bool {
        premiumManager.isPremium
    }
    
    var body: some View {
        NavigationStack {
            List {
                // MARK: - Security Section (Features 1 & 5)
                securitySection
                
                // MARK: - iCloud Sync (Feature 6)
                if let cloudManager = iCloudManager {
                    iCloudSection(cloudManager)
                }
                
                // MARK: - Import/Export
                dataSection
                
                // MARK: - Appearance (Feature 8)
                appearanceSection
                
                // MARK: - Password Defaults (Feature 9)
                passwordDefaultsSection
                
                // MARK: - Premium Section
                premiumSection
                
                // MARK: - AutoFill
                autoFillSection
                
                // MARK: - About
                aboutSection
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) {
                PaywallView(
                    isPresented: $showPaywall,
                    premiumManager: premiumManager,
                    onPurchaseComplete: {}
                )
            }
            .sheet(isPresented: $showImportExport) {
                ImportExportView(
                    vaultViewModel: $vaultViewModel,
                    isPremium: .constant(isPremium)
                )
            }
            .sheet(isPresented: $showAppIconPicker) {
                AppIconPickerView(settingsManager: settingsManager, isPremium: isPremium)
            }
            .alert("Restore Purchases", isPresented: $showRestoreAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(restoreMessage)
            }
            .alert("iCloud Sync", isPresented: $showSyncAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(syncAlertMessage)
            }
        }
    }
    
    // MARK: - Security Section
    
    private var securitySection: some View {
        Section {
            // Biometric Lock Toggle (Feature 1)
            if lockManager.canUseBiometrics {
                HStack {
                    Image(systemName: lockManager.biometricType.iconName)
                        .foregroundStyle(.blue)
                        .frame(width: 24)
                    
                    Toggle("Lock with \(lockManager.biometricType.displayName)", isOn: Binding(
                        get: { lockManager.biometricEnabled },
                        set: { newValue in
                            Task {
                                if newValue {
                                    let success = await lockManager.authenticate()
                                    if success {
                                        lockManager.biometricEnabled = true
                                        lockManager.saveSettings()
                                    }
                                } else {
                                    lockManager.biometricEnabled = false
                                    lockManager.isLocked = false
                                    lockManager.saveSettings()
                                }
                            }
                        }
                    ))
                }
                
                // Auto-Lock Timer (Feature 5)
                if lockManager.biometricEnabled {
                    Toggle(isOn: $lockManager.autoLockEnabled) {
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundStyle(.orange)
                                .frame(width: 24)
                            Text("Auto-Lock")
                        }
                    }
                    .onChange(of: lockManager.autoLockEnabled) {
                        lockManager.saveSettings()
                    }
                    
                    if lockManager.autoLockEnabled {
                        Picker("Lock After", selection: $lockManager.autoLockDuration) {
                            ForEach(AppLockManager.AutoLockDuration.allCases) { duration in
                                Text(duration.displayName).tag(duration)
                            }
                        }
                        .onChange(of: lockManager.autoLockDuration) {
                            lockManager.saveSettings()
                        }
                    }
                }
            } else {
                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.secondary)
                        .frame(width: 24)
                    Text("Biometric authentication not available")
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Security")
        } footer: {
            if lockManager.canUseBiometrics {
                Text("Require \(lockManager.biometricType.displayName) to access your passwords")
            }
        }
    }
    
    // MARK: - iCloud Section (Feature 6)
    
    private func iCloudSection(_ cloudManager: iCloudSyncManager) -> some View {
        Section {
            HStack {
                Image(systemName: cloudManager.cloudStatus.icon)
                    .foregroundStyle(cloudManager.cloudStatus.color)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("iCloud Status")
                    Text(cloudManager.cloudStatus.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button {
                    cloudManager.checkiCloudStatus()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                }
            }
            
            if isPremium {
                Toggle(isOn: Binding(
                    get: { cloudManager.isSyncEnabled },
                    set: { newValue in
                        if newValue && cloudManager.cloudStatus != .available {
                            syncAlertMessage = "Please sign in to iCloud in Settings to enable sync."
                            showSyncAlert = true
                        } else {
                            cloudManager.isSyncEnabled = newValue
                        }
                    }
                )) {
                    HStack {
                        Image(systemName: "icloud.fill")
                            .foregroundStyle(.blue)
                            .frame(width: 24)
                        Text("iCloud Sync")
                    }
                }
                .disabled(cloudManager.cloudStatus != .available)
                
                if cloudManager.isSyncEnabled {
                    Button {
                        performSync(cloudManager)
                    } label: {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundStyle(.blue)
                                .frame(width: 24)
                            Text("Sync Now")
                            Spacer()
                            if cloudManager.isSyncing {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(cloudManager.isSyncing)
                    
                    if let lastSync = cloudManager.lastSyncDate {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundStyle(.secondary)
                                .frame(width: 24)
                            Text("Last Sync")
                            Spacer()
                            Text(lastSync, style: .relative)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Image(systemName: "icloud.fill")
                            .foregroundStyle(.blue)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("iCloud Sync")
                            Text("Sync across all your devices")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "crown.fill")
                            .foregroundStyle(.orange)
                    }
                }
            }
            
            if let error = cloudManager.syncError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .frame(width: 24)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        } header: {
            Text("iCloud")
        } footer: {
            if isPremium && cloudManager.isSyncEnabled {
                Text("Your passwords sync securely across all your Apple devices")
            } else if !isPremium {
                Text("Upgrade to Premium to sync passwords across iPhone, iPad, and Mac")
            }
        }
    }
    
    private func performSync(_ cloudManager: iCloudSyncManager) {
        Task {
            do {
                let credentials = vaultViewModel.credentials
                let notes: [SecureNote] = []
                let cards: [CreditCard] = []
                
                let result = try await cloudManager.performSync(
                    credentials: credentials,
                    notes: notes,
                    cards: cards
                )
                
                vaultViewModel.credentials = result.credentials
                vaultViewModel.saveCredentials()
                
                syncAlertMessage = "Sync completed successfully!"
                showSyncAlert = true
            } catch {
                syncAlertMessage = "Sync failed: \(error.localizedDescription)"
                showSyncAlert = true
            }
        }
    }
    
    // MARK: - Data Section
    
    private var dataSection: some View {
        Section {
            Button {
                showImportExport = true
            } label: {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.purple.opacity(0.15))
                            .frame(width: 44, height: 44)
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.title3)
                            .foregroundStyle(.purple)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Import / Export Passwords")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("From Chrome, Firefox, Safari & more")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Data")
        }
    }
    
    // MARK: - Appearance Section
    
    private var appearanceSection: some View {
        Section {
            Button {
                if isPremium {
                    showAppIconPicker = true
                } else {
                    showPaywall = true
                }
            } label: {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(settingsManager.selectedAppIcon.previewColor)
                            .frame(width: 44, height: 44)
                        Image(systemName: "lock.shield.fill")
                            .foregroundStyle(.white)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("App Icon")
                            .foregroundStyle(.primary)
                        Text(settingsManager.selectedAppIcon.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if !isPremium {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(.orange)
                    }
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
            }
            
            Picker("Default Sort", selection: $settingsManager.vaultSortOrder) {
                ForEach(AppSettingsManager.VaultSortOrder.allCases) { option in
                    Text(option.displayName).tag(option)
                }
            }
        } header: {
            Text("Appearance")
        }
    }
    
    // MARK: - Password Defaults Section
    
    private var passwordDefaultsSection: some View {
        Section {
            Stepper("Default Length: \(settingsManager.defaultPasswordLength)", 
                    value: $settingsManager.defaultPasswordLength, 
                    in: 8...32)
            
            Picker("Password Expiry Reminder", selection: Binding(
                get: { 
                    AppSettingsManager.ExpiryReminderOption(rawValue: settingsManager.defaultExpiryReminderDays ?? 0) ?? .ninetyDays
                },
                set: { newValue in
                    settingsManager.defaultExpiryReminderDays = newValue == .none ? nil : newValue.rawValue
                }
            )) {
                ForEach(AppSettingsManager.ExpiryReminderOption.allCases) { option in
                    Text(option.displayName).tag(option)
                }
            }
        } header: {
            Text("Password Defaults")
        } footer: {
            Text("Get reminded to change passwords after the set number of days")
        }
    }
    
    // MARK: - Premium Section
    
    private var premiumSection: some View {
        Section {
            if isPremium {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(.yellow)
                        Text("Premium Active")
                            .fontWeight(.semibold)
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                    if let subscription = premiumManager.subscriptionType {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundStyle(.blue)
                            Text("Current Plan: \(subscription)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Change Plan")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                
                if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                    Link(destination: url) {
                        HStack {
                            Image(systemName: "gearshape")
                            Text("Manage Subscription")
                            Spacer()
                            Image(systemName: "arrow.up.forward")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(.yellow)
                        Text("Upgrade to Premium")
                            .fontWeight(.semibold)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            
            Button {
                restorePurchases()
            } label: {
                HStack {
                    Text("Restore Purchases")
                    if premiumManager.isLoading {
                        Spacer()
                        ProgressView()
                    }
                }
            }
            .disabled(premiumManager.isLoading)
        } header: {
            Text("Premium")
        } footer: {
            if let error = premiumManager.errorMessage {
                Text(error)
                    .foregroundStyle(.red)
            }
        }
    }
    
    // MARK: - AutoFill Section
    
    private var autoFillSection: some View {
        Section {
            Button {
                openAutoFillSettings()
            } label: {
                HStack {
                    Image(systemName: "key.fill")
                        .foregroundStyle(.blue)
                    Text("Enable AutoFill")
                    Spacer()
                    Image(systemName: "arrow.up.forward")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("AutoFill")
        } footer: {
            Text("Settings → search 'Passwords' → AutoFill Passwords and Passkeys → Turn on PasswordVault")
        }
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0.0")
                    .foregroundStyle(.secondary)
            }
            
            Link(destination: URL(string: "https://techjonesai.co.uk/passwordvault/privacy")!) {
                HStack {
                    Text("Privacy Policy")
                    Spacer()
                    Image(systemName: "arrow.up.forward")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Link(destination: URL(string: "mailto:support@techjonesai.co.uk")!) {
                HStack {
                    Text("Contact Support")
                    Spacer()
                    Image(systemName: "arrow.up.forward")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            HStack {
                Image(systemName: "lock.shield.fill")
                    .foregroundStyle(.green)
                VStack(alignment: .leading, spacing: 4) {
                    Text("All data stored on-device")
                        .font(.subheadline)
                    Text("Your passwords never leave your device (unless iCloud Sync is enabled)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Actions
    
    private func restorePurchases() {
        Task {
            await premiumManager.restorePurchases()
            restoreMessage = isPremium ? "Premium successfully restored!" : "No previous purchases found."
            showRestoreAlert = true
        }
    }
    
    private func openAutoFillSettings() {
        if let url = URL(string: "App-Prefs:PASSWORDS") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
        }
    }
}

// MARK: - App Icon Picker View

struct AppIconPickerView: View {
    var settingsManager: AppSettingsManager
    var isPremium: Bool
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(AppSettingsManager.AppIconOption.allCases) { icon in
                    Button {
                        settingsManager.changeAppIcon(to: icon)
                    } label: {
                        HStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(icon.previewColor)
                                    .frame(width: 60, height: 60)
                                Image(systemName: "lock.shield.fill")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                            }
                            Text(icon.displayName)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Spacer()
                            if settingsManager.selectedAppIcon == icon {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("App Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Backward compatible inits
extension SettingsView {
    init(premiumManager: PremiumManager, vaultViewModel: Binding<VaultViewModel>) {
        self.premiumManager = premiumManager
        self._vaultViewModel = vaultViewModel
        self.lockManager = AppLockManager()
        self.settingsManager = AppSettingsManager()
        self.iCloudManager = nil
    }
    
    init(premiumManager: PremiumManager, vaultViewModel: Binding<VaultViewModel>, lockManager: AppLockManager, settingsManager: AppSettingsManager) {
        self.premiumManager = premiumManager
        self._vaultViewModel = vaultViewModel
        self.lockManager = lockManager
        self.settingsManager = settingsManager
        self.iCloudManager = nil
    }
}

#Preview {
    SettingsView(
        premiumManager: PremiumManager(),
        vaultViewModel: .constant(VaultViewModel())
    )
}
