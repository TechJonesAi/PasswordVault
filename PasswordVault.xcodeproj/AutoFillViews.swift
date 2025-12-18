//
//  AutoFillViews.swift
//  PasswordVaultAutoFill
//
//  Created by AI Assistant on 06/12/2025.
//

import SwiftUI
import AuthenticationServices
import LocalAuthentication

// MARK: - Biometric Authentication Service

enum BiometricAuthService {
    
    static func authenticate(completion: @escaping (Bool, Error?) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            authenticateWithPasscode(completion: completion)
            return
        }
        
        let reason = "Authenticate to fill your password"
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }
    
    private static func authenticateWithPasscode(completion: @escaping (Bool, Error?) -> Void) {
        let context = LAContext()
        let reason = "Authenticate to fill your password"
        
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }
}

// MARK: - Credential List View

struct CredentialListView: View {
    let credentials: [Credential]
    let serviceIdentifiers: [ASCredentialServiceIdentifier]
    let onSelect: (Credential) -> Void
    let onCancel: () -> Void
    
    @State private var searchText = ""
    
    private var filteredCredentials: [Credential] {
        if searchText.isEmpty {
            return credentials
        }
        return credentials.filter {
            $0.websiteName.localizedCaseInsensitiveContains(searchText) ||
            $0.username.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var serviceName: String {
        if let identifier = serviceIdentifiers.first?.identifier {
            return identifier
                .replacingOccurrences(of: "www.", with: "")
                .replacingOccurrences(of: "https://", with: "")
                .replacingOccurrences(of: "http://", with: "")
        }
        return "this service"
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(filteredCredentials) { credential in
                        Button {
                            onSelect(credential)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "globe")
                                    .font(.title2)
                                    .foregroundStyle(.blue)
                                    .frame(width: 40, height: 40)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(credential.websiteName)
                                        .font(.headline)
                                    Text(credential.username)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    if credentials.count == 1 {
                        Text("Password for \(serviceName)")
                    } else {
                        Text("\(credentials.count) passwords for \(serviceName)")
                    }
                } footer: {
                    Text("Tap a password to fill it. You'll be asked to authenticate with Face ID.")
                }
            }
            .searchable(text: $searchText, prompt: "Search passwords")
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

// MARK: - Premium Upgrade View

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
                    AutoFillFeature(icon: "apps.iphone", text: "Fill passwords in all apps")
                    AutoFillFeature(icon: "key.fill", text: "Strong password suggestions")
                    AutoFillFeature(icon: "faceid", text: "Secure with Face ID")
                    AutoFillFeature(icon: "infinity", text: "Unlimited passwords")
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

struct AutoFillFeature: View {
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

// MARK: - No Credentials View

struct NoCredentialsView: View {
    let serviceName: String
    let onOpenApp: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 80))
                    .foregroundStyle(.secondary)
                
                Text("No Passwords Found")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("You don't have any passwords saved for \(serviceName). Open PasswordVault to add one.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Spacer()
                
                VStack(spacing: 12) {
                    Button {
                        onOpenApp()
                    } label: {
                        Text("Open PasswordVault")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    
                    Button {
                        onCancel()
                    } label: {
                        Text("Cancel")
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

// MARK: - Configuration View

struct ConfigurationView: View {
    let onDone: () -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Enable AutoFill")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    Text("Follow these steps to enable PasswordVault AutoFill:")
                        .font(.body)
                        .foregroundStyle(.secondary)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        SetupStep(number: 1, title: "Open Settings", description: "Go to your device Settings app")
                        SetupStep(number: 2, title: "Find Passwords", description: "Tap on 'Passwords' or 'Password Options'")
                        SetupStep(number: 3, title: "Enable AutoFill", description: "Turn on 'AutoFill Passwords and Passkeys'")
                        SetupStep(number: 4, title: "Select PasswordVault", description: "Check 'PasswordVault' in the list of password apps")
                    }
                    .padding(.vertical)
                    
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                        onDone()
                    } label: {
                        Text("Open Settings")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onDone()
                    }
                }
            }
        }
    }
}

struct SetupStep: View {
    let number: Int
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 32, height: 32)
                
                Text("\(number)")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
