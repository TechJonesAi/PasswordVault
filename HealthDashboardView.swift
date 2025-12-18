//
//  HealthDashboardView.swift
//  PasswordVault
//
//  Created by AI Assistant on 05/12/2025.
//

import SwiftUI

/// Password Health Dashboard Tab (Tab 3 - Premium)
struct HealthDashboardView: View {
    
    @Binding var isPremium: Bool
    var premiumManager: PremiumManager
    @State private var viewModel = HealthViewModel()
    @State private var showPaywall = false
    @State private var showWeakPasswords = false
    @State private var showReusedPasswords = false
    @State private var showOldPasswords = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                if isPremium {
                    // Premium content
                    ScrollView {
                        VStack(spacing: 24) {
                            if let report = viewModel.healthReport {
                                // Total passwords overview
                                VStack(spacing: 16) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Total Passwords")
                                                .font(.headline)
                                                .foregroundStyle(.secondary)
                                            Text("\(report.totalCredentials)")
                                                .font(.system(size: 48, weight: .bold))
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "lock.shield.fill")
                                            .font(.system(size: 50))
                                            .foregroundStyle(
                                                LinearGradient(
                                                    colors: [.blue, .purple],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(16)
                                }
                                .padding(.horizontal)
                                
                                // Security score
                                VStack(spacing: 12) {
                                    Text("Security Score")
                                        .font(.headline)
                                    
                                    ZStack {
                                        Circle()
                                            .stroke(Color(.systemGray5), lineWidth: 20)
                                        
                                        Circle()
                                            .trim(from: 0, to: CGFloat(report.securityScore) / 100)
                                            .stroke(
                                                viewModel.scoreColor(for: report.securityScore),
                                                style: StrokeStyle(lineWidth: 20, lineCap: .round)
                                            )
                                            .rotationEffect(.degrees(-90))
                                        
                                        VStack {
                                            Text("\(report.securityScore)")
                                                .font(.system(size: 60, weight: .bold))
                                            Text(viewModel.scoreDescription(for: report.securityScore))
                                                .font(.headline)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .frame(width: 200, height: 200)
                                    .animation(.spring(), value: report.securityScore)
                                }
                                .padding()
                                
                                // Issue cards
                                VStack(spacing: 16) {
                                    HealthIssueCard(
                                        title: "Weak Passwords",
                                        count: report.weakPasswords.count,
                                        icon: "exclamationmark.shield",
                                        color: .red,
                                        onFixTapped: {
                                            showWeakPasswords = true
                                        }
                                    )
                                    
                                    HealthIssueCard(
                                        title: "Reused Passwords",
                                        count: report.reusedPasswords.count,
                                        icon: "arrow.triangle.2.circlepath",
                                        color: .orange,
                                        onFixTapped: {
                                            showReusedPasswords = true
                                        }
                                    )
                                    
                                    HealthIssueCard(
                                        title: "Old Passwords",
                                        count: report.oldPasswords.count,
                                        icon: "clock",
                                        color: .yellow,
                                        onFixTapped: {
                                            showOldPasswords = true
                                        }
                                    )
                                }
                                .padding(.horizontal)
                                
                                // Suggestions
                                if !viewModel.suggestions.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Recommendations")
                                            .font(.headline)
                                            .padding(.horizontal)
                                        
                                        ForEach(viewModel.suggestions) { suggestion in
                                            SuggestionCard(suggestion: suggestion)
                                                .padding(.horizontal)
                                        }
                                    }
                                    .padding(.top)
                                }
                            } else {
                                ProgressView("Analyzing passwords...")
                                    .padding()
                            }
                        }
                        .padding(.vertical)
                    }
                    .refreshable {
                        viewModel.analyzePasswords()
                    }
                } else {
                    // Premium upsell overlay
                    ContentUnavailableView {
                        Label("Premium Feature", systemImage: "crown.fill")
                    } description: {
                        Text("Upgrade to Premium to see your password health analysis")
                    } actions: {
                        Button {
                            showPaywall = true
                        } label: {
                            Text("Unlock Premium")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 12)
                                .background(Color.purple)
                                .cornerRadius(10)
                        }
                    }
                }
            }
            .navigationTitle("Health")
            .onAppear {
                if isPremium {
                    viewModel.analyzePasswords()
                }
            }
            .onChange(of: isPremium) {
                if isPremium {
                    viewModel.analyzePasswords()
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(
                    isPresented: $showPaywall,
                    premiumManager: premiumManager,
                    onPurchaseComplete: {}
                )
            }
            .sheet(isPresented: $showWeakPasswords) {
                if let report = viewModel.healthReport {
                    PasswordIssueListView(
                        title: "Weak Passwords",
                        credentials: report.weakPasswords,
                        issueType: .weak,
                        isPresented: $showWeakPasswords
                    )
                }
            }
            .sheet(isPresented: $showReusedPasswords) {
                if let report = viewModel.healthReport {
                    PasswordIssueListView(
                        title: "Reused Passwords",
                        credentials: report.reusedPasswords,
                        issueType: .reused,
                        isPresented: $showReusedPasswords
                    )
                }
            }
            .sheet(isPresented: $showOldPasswords) {
                if let report = viewModel.healthReport {
                    PasswordIssueListView(
                        title: "Old Passwords",
                        credentials: report.oldPasswords,
                        issueType: .old,
                        isPresented: $showOldPasswords
                    )
                }
            }
        }
    }
}

/// Card showing health issue
struct HealthIssueCard: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    let onFixTapped: () -> Void  // ✅ Added action callback
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 50, height: 50)
                .background(color.opacity(0.1))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text("\(count) found")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if count > 0 {
                Button {
                    onFixTapped()  // ✅ Call the action
                } label: {
                    Text("Fix")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.blue)
                }
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title3)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

/// Card showing suggestion
struct SuggestionCard: View {
    let suggestion: PasswordSuggestion
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(.yellow)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(suggestion.title)
                    .font(.headline)
                Text(suggestion.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

/// Sheet view showing list of password issues
struct PasswordIssueListView: View {
    let title: String
    let credentials: [Credential]
    let issueType: PasswordIssueType
    @Binding var isPresented: Bool
    @State private var selectedCredential: Credential?
    @State private var copiedPasswordID: UUID?
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(credentials) { credential in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "globe")
                                    .foregroundStyle(.blue)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(credential.websiteName)
                                        .font(.headline)
                                    Text(credential.username)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                issueIcon(for: issueType)
                            }
                            
                            // Password display
                            HStack {
                                Text(credential.password)
                                    .font(.system(.subheadline, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Button {
                                    copyToClipboard(credential.password, id: credential.id)
                                } label: {
                                    Image(systemName: copiedPasswordID == credential.id ? "checkmark" : "doc.on.doc")
                                        .foregroundStyle(copiedPasswordID == credential.id ? .green : .blue)
                                }
                                .buttonStyle(.plain)
                            }
                            
                            // Action buttons
                            HStack(spacing: 12) {
                                Button {
                                    selectedCredential = credential
                                } label: {
                                    HStack {
                                        Image(systemName: "pencil")
                                        Text("Edit")
                                    }
                                    .font(.subheadline)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(Color.blue)
                                    .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                                
                                Button {
                                    generateNewPassword(for: credential)
                                } label: {
                                    HStack {
                                        Image(systemName: "key.fill")
                                        Text("Generate")
                                    }
                                    .font(.subheadline)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(Color.green)
                                    .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                } header: {
                    Text("\(credentials.count) \(credentials.count == 1 ? "password" : "passwords") found")
                } footer: {
                    Text(footerText(for: issueType))
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
            .sheet(item: $selectedCredential) { credential in
                CredentialEditSheet(credential: credential, isPresented: $selectedCredential)
            }
        }
    }
    
    @ViewBuilder
    private func issueIcon(for type: PasswordIssueType) -> some View {
        switch type {
        case .weak:
            Image(systemName: "exclamationmark.shield.fill")
                .foregroundStyle(.red)
        case .reused:
            Image(systemName: "arrow.triangle.2.circlepath")
                .foregroundStyle(.orange)
        case .old:
            Image(systemName: "clock.fill")
                .foregroundStyle(.yellow)
        }
    }
    
    private func footerText(for type: PasswordIssueType) -> String {
        switch type {
        case .weak:
            return "These passwords are too simple and could be easily guessed. Tap 'Generate' to create a strong password, or 'Edit' to update manually."
        case .reused:
            return "These passwords are used for multiple accounts. If one account is compromised, all accounts using the same password are at risk. Generate unique passwords for each account."
        case .old:
            return "These passwords haven't been changed in a while. Regular password updates help maintain security. Consider generating new passwords for these accounts."
        }
    }
    
    private func copyToClipboard(_ text: String, id: UUID) {
        UIPasteboard.general.string = text
        copiedPasswordID = id
        
        // Reset checkmark after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if copiedPasswordID == id {
                copiedPasswordID = nil
            }
        }
    }
    
    private func generateNewPassword(for credential: Credential) {
        // Generate a strong password using PasswordGenerator
        let generator = PasswordGenerator()
        let config = PasswordConfiguration(
            length: 16,
            includeUppercase: true,
            includeLowercase: true,
            includeNumbers: true,
            includeSymbols: true
        )
        let newPassword = generator.generate(config: config)
        
        // Update the credential with new password
        do {
            let keychainService = SecureKeychainService()
            var updatedCredential = credential
            updatedCredential.password = newPassword
            try keychainService.saveCredential(updatedCredential)
            
            // Copy new password to clipboard
            copyToClipboard(newPassword, id: credential.id)
            
            // Show success feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        } catch {
            print("❌ Failed to update password: \(error)")
        }
    }
}

/// Edit credential sheet
struct CredentialEditSheet: View {
    let credential: Credential
    @Binding var isPresented: Credential?
    
    @State private var websiteName: String
    @State private var username: String
    @State private var password: String
    @State private var showPassword = false
    @State private var saveError: String?
    
    init(credential: Credential, isPresented: Binding<Credential?>) {
        self.credential = credential
        self._isPresented = isPresented
        self._websiteName = State(initialValue: credential.websiteName)
        self._username = State(initialValue: credential.username)
        self._password = State(initialValue: credential.password)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Website", text: $websiteName)
                        .textContentType(.URL)
                    
                    TextField("Username", text: $username)
                        .textContentType(.username)
                        .autocapitalization(.none)
                }
                
                Section("Password") {
                    HStack {
                        if showPassword {
                            TextField("Password", text: $password)
                                .textContentType(.password)
                                .autocapitalization(.none)
                        } else {
                            SecureField("Password", text: $password)
                                .textContentType(.password)
                        }
                        
                        Button {
                            showPassword.toggle()
                        } label: {
                            Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Button {
                        generatePassword()
                    } label: {
                        HStack {
                            Image(systemName: "key.fill")
                            Text("Generate Strong Password")
                        }
                    }
                }
                
                if let error = saveError {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Edit Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = nil
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(websiteName.isEmpty || username.isEmpty || password.isEmpty)
                }
            }
        }
    }
    
    private func generatePassword() {
        let generator = PasswordGenerator()
        let config = PasswordConfiguration(
            length: 16,
            includeUppercase: true,
            includeLowercase: true,
            includeNumbers: true,
            includeSymbols: true
        )
        password = generator.generate(config: config)
        showPassword = true
    }
    
    private func saveChanges() {
        do {
            let keychainService = SecureKeychainService()
            var updatedCredential = credential
            updatedCredential.websiteName = websiteName
            updatedCredential.username = username
            updatedCredential.password = password
            
            try keychainService.saveCredential(updatedCredential)
            
            // Success feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            isPresented = nil
        } catch {
            saveError = "Failed to save: \(error.localizedDescription)"
        }
    }
}

enum PasswordIssueType {
    case weak
    case reused
    case old
}

#Preview {
    HealthDashboardView(
        isPremium: .constant(true),
        premiumManager: PremiumManager()
    )
}
