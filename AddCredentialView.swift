//
//  AddCredentialView.swift
//  PasswordVault
//
//  Created by AI Assistant on 05/12/2025.
//  ENHANCED: Added AI auto-categorization, folder selection, expiry reminders
//

import SwiftUI

/// Sheet for adding or editing a credential
struct AddCredentialView: View {
    
    @Binding var vaultViewModel: VaultViewModel
    @Binding var isPremium: Bool
    @Binding var isPresented: Bool
    
    var editingCredential: Credential?
    var prefillPassword: String?
    var aiAssistant: AIPasswordAssistant?
    
    @State private var websiteName: String = ""
    @State private var websiteURL: String = ""
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var notes: String = ""
    @State private var showPassword: Bool = false
    
    // New feature states
    @State private var selectedFolder: PasswordFolder?
    @State private var isFavourite: Bool = false
    @State private var expiryReminderDays: Int? = 90
    @State private var showExpiryPicker = false
    
    // AI suggestion state
    @State private var aiSuggestedFolder: PasswordFolder?
    @State private var showAISuggestion = false
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case websiteName, websiteURL, username, password, notes
    }
    
    private var isEditing: Bool {
        editingCredential != nil
    }
    
    private var isValid: Bool {
        !websiteName.isEmpty && !username.isEmpty && !password.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Website") {
                    TextField("Name (e.g., Gmail)", text: $websiteName)
                        .focused($focusedField, equals: .websiteName)
                        .textContentType(.organizationName)
                        .onChange(of: websiteName) {
                            suggestFolderWithAI()
                        }
                    
                    TextField("URL (optional)", text: $websiteURL)
                        .focused($focusedField, equals: .websiteURL)
                        .textContentType(.URL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .onChange(of: websiteURL) {
                            suggestFolderWithAI()
                        }
                }
                
                Section("Credentials") {
                    TextField("Username or Email", text: $username)
                        .focused($focusedField, equals: .username)
                        .textContentType(.username)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    
                    HStack {
                        if showPassword {
                            TextField("Password", text: $password)
                                .focused($focusedField, equals: .password)
                                .textContentType(.password)
                                .textInputAutocapitalization(.never)
                        } else {
                            SecureField("Password", text: $password)
                                .focused($focusedField, equals: .password)
                                .textContentType(.password)
                                .textInputAutocapitalization(.never)
                        }
                        
                        Button {
                            showPassword.toggle()
                        } label: {
                            Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                // Organisation Section (Feature 2 & 3)
                Section("Organisation") {
                    // Folder picker
                    Picker("Folder", selection: $selectedFolder) {
                        Text("None").tag(nil as PasswordFolder?)
                        ForEach(PasswordFolder.allCases) { folder in
                            Label(folder.rawValue, systemImage: folder.iconName)
                                .tag(folder as PasswordFolder?)
                        }
                    }
                    
                    // AI Suggestion
                    if showAISuggestion, let suggested = aiSuggestedFolder, selectedFolder != suggested {
                        Button {
                            withAnimation {
                                selectedFolder = suggested
                                showAISuggestion = false
                            }
                        } label: {
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundStyle(.purple)
                                Text("AI suggests: \(suggested.rawValue)")
                                    .font(.caption)
                                Spacer()
                                Text("Apply")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                            }
                        }
                        .listRowBackground(Color.purple.opacity(0.1))
                    }
                    
                    // Favourite toggle
                    Toggle(isOn: $isFavourite) {
                        Label("Favourite", systemImage: "star.fill")
                            .foregroundStyle(isFavourite ? .orange : .primary)
                    }
                }
                
                // Password Expiry Section (Feature 9)
                Section("Password Reminder") {
                    Picker("Remind to change after", selection: Binding(
                        get: { ExpiryOption(rawValue: expiryReminderDays ?? 0) ?? .ninetyDays },
                        set: { expiryReminderDays = $0 == .none ? nil : $0.rawValue }
                    )) {
                        ForEach(ExpiryOption.allCases) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                }
                
                Section("Notes (Optional)") {
                    TextField("Add notes", text: $notes, axis: .vertical)
                        .focused($focusedField, equals: .notes)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(isEditing ? "Edit Password" : "Add Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(isEditing ? "Update" : "Save") {
                        saveCredential()
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                loadCredential()
                focusedField = .websiteName
            }
        }
    }
    
    // MARK: - Expiry Options
    
    enum ExpiryOption: Int, CaseIterable, Identifiable {
        case none = 0
        case thirtyDays = 30
        case sixtyDays = 60
        case ninetyDays = 90
        case oneEightyDays = 180
        case oneYear = 365
        
        var id: Int { rawValue }
        
        var displayName: String {
            switch self {
            case .none: return "No reminder"
            case .thirtyDays: return "30 days"
            case .sixtyDays: return "60 days"
            case .ninetyDays: return "90 days"
            case .oneEightyDays: return "180 days"
            case .oneYear: return "1 year"
            }
        }
    }
    
    // MARK: - AI Folder Suggestion
    
    private func suggestFolderWithAI() {
        guard let ai = aiAssistant else { return }
        guard !websiteName.isEmpty || !websiteURL.isEmpty else {
            showAISuggestion = false
            return
        }
        
        let suggested = ai.suggestFolder(for: websiteName, url: websiteURL)
        
        // Only show if different from current and not "other"
        if suggested != .other && suggested != selectedFolder {
            aiSuggestedFolder = suggested
            showAISuggestion = true
        } else {
            showAISuggestion = false
        }
    }
    
    private func loadCredential() {
        if let credential = editingCredential {
            // Editing existing credential
            websiteName = credential.websiteName
            websiteURL = credential.websiteURL ?? ""
            username = credential.username
            password = credential.password
            notes = credential.notes ?? ""
            selectedFolder = credential.folder
            isFavourite = credential.isFavourite
            expiryReminderDays = credential.expiryReminderDays
        } else if let prefill = prefillPassword {
            // Pre-fill password from generator
            password = prefill
        }
    }
    
    private func saveCredential() {
        let credential = Credential(
            id: editingCredential?.id ?? UUID(),
            websiteName: websiteName,
            websiteURL: websiteURL.isEmpty ? nil : websiteURL,
            username: username,
            password: password,
            notes: notes.isEmpty ? nil : notes,
            createdDate: editingCredential?.createdDate ?? Date(),
            lastModifiedDate: Date(),
            folder: selectedFolder,
            isFavourite: isFavourite,
            passwordLastChanged: editingCredential?.password == password ? editingCredential?.passwordLastChanged : Date(),
            expiryReminderDays: expiryReminderDays
        )
        
        vaultViewModel.saveCredential(credential, isPremium: isPremium)
        
        // Only close if not showing paywall
        if !vaultViewModel.showPaywall {
            isPresented = false
        }
    }
}

// Backward compatible init
extension AddCredentialView {
    init(vaultViewModel: Binding<VaultViewModel>, isPremium: Binding<Bool>, isPresented: Binding<Bool>, prefillPassword: String? = nil) {
        self._vaultViewModel = vaultViewModel
        self._isPremium = isPremium
        self._isPresented = isPresented
        self.prefillPassword = prefillPassword
        self.aiAssistant = nil
    }
}

#Preview {
    AddCredentialView(
        vaultViewModel: .constant(VaultViewModel()),
        isPremium: .constant(false),
        isPresented: .constant(true)
    )
}
