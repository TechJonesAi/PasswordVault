//
//  PasswordGeneratorView.swift
//  PasswordVault
//
//  Created by AI Assistant on 05/12/2025.
//  ENHANCED: Quick copy, seamless save flow, new account creation helper
//

import SwiftUI

/// Password Generator Tab (Tab 1)
struct PasswordGeneratorView: View {
    
    @State private var viewModel = GeneratorViewModel()
    @Binding var vaultViewModel: VaultViewModel
    @Binding var isPremium: Bool
    @State private var showSaveSheet = false
    @State private var showQuickSave = false
    @State private var quickSaveWebsite = ""
    @State private var quickSaveUsername = ""
    @State private var showNewAccountHelper = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // New Account Helper Card
                    NewAccountHelperCard(
                        onTap: { showNewAccountHelper = true }
                    )
                    .padding(.horizontal)
                    
                    // Password display with tap-to-copy
                    PasswordDisplayCard(
                        password: viewModel.generatedPassword,
                        strength: viewModel.passwordStrength,
                        showCopied: viewModel.showCopiedConfirmation,
                        onCopy: { viewModel.copyToClipboard() },
                        onRegenerate: { viewModel.generatePassword() }
                    )
                    .padding(.horizontal)
                    
                    // Quick action buttons
                    QuickActionButtons(
                        showCopied: viewModel.showCopiedConfirmation,
                        onCopy: { viewModel.copyToClipboard() },
                        onCopyAndOpen: { copyAndOpenSettings() },
                        onQuickSave: { showQuickSave = true }
                    )
                    .padding(.horizontal)
                    
                    // Length slider
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Length")
                                .font(.headline)
                            Spacer()
                            Text("\(viewModel.configuration.length)")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(.blue)
                                .monospacedDigit()
                        }
                        
                        Slider(
                            value: Binding(
                                get: { Double(viewModel.configuration.length) },
                                set: { viewModel.configuration.length = Int($0) }
                            ),
                            in: 8...32,
                            step: 1
                        )
                        .tint(.blue)
                        .onChange(of: viewModel.configuration.length) {
                            viewModel.generatePassword()
                        }
                    }
                    .padding(.horizontal)
                    
                    // Character type toggles
                    VStack(spacing: 0) {
                        CharacterToggleRow(
                            title: "Uppercase",
                            subtitle: "A-Z",
                            icon: "textformat.size.larger",
                            isOn: $viewModel.configuration.includeUppercase
                        )
                        .onChange(of: viewModel.configuration.includeUppercase) {
                            viewModel.generatePassword()
                        }
                        
                        Divider().padding(.leading, 50)
                        
                        CharacterToggleRow(
                            title: "Lowercase",
                            subtitle: "a-z",
                            icon: "textformat.size.smaller",
                            isOn: $viewModel.configuration.includeLowercase
                        )
                        .onChange(of: viewModel.configuration.includeLowercase) {
                            viewModel.generatePassword()
                        }
                        
                        Divider().padding(.leading, 50)
                        
                        CharacterToggleRow(
                            title: "Numbers",
                            subtitle: "0-9",
                            icon: "number",
                            isOn: $viewModel.configuration.includeNumbers
                        )
                        .onChange(of: viewModel.configuration.includeNumbers) {
                            viewModel.generatePassword()
                        }
                        
                        Divider().padding(.leading, 50)
                        
                        CharacterToggleRow(
                            title: "Symbols",
                            subtitle: "!@#$%^&*",
                            icon: "star.fill",
                            isOn: $viewModel.configuration.includeSymbols
                        )
                        .onChange(of: viewModel.configuration.includeSymbols) {
                            viewModel.generatePassword()
                        }
                    }
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Full save button
                    Button {
                        showSaveSheet = true
                    } label: {
                        Label("Save to Vault with Details", systemImage: "lock.shield.fill")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                .padding(.vertical)
            }
            .navigationTitle("Generator")
            .sheet(isPresented: $showSaveSheet) {
                AddCredentialView(
                    vaultViewModel: $vaultViewModel,
                    isPremium: $isPremium,
                    isPresented: $showSaveSheet,
                    prefillPassword: viewModel.generatedPassword
                )
            }
            .sheet(isPresented: $showQuickSave) {
                QuickSaveSheet(
                    password: viewModel.generatedPassword,
                    website: $quickSaveWebsite,
                    username: $quickSaveUsername,
                    isPresented: $showQuickSave,
                    onSave: { website, username in
                        quickSaveCredential(website: website, username: username)
                    }
                )
                .presentationDetents([.medium])
            }
            .sheet(isPresented: $showNewAccountHelper) {
                NewAccountHelperSheet(
                    password: viewModel.generatedPassword,
                    isPresented: $showNewAccountHelper,
                    onCopy: { viewModel.copyToClipboard() },
                    onRegenerate: { viewModel.generatePassword() },
                    onSaveAfterCreation: { website, username in
                        quickSaveCredential(website: website, username: username)
                    }
                )
            }
        }
    }
    
    private func copyAndOpenSettings() {
        viewModel.copyToClipboard()
        // Small delay to show feedback before potential app switch
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        }
    }
    
    private func quickSaveCredential(website: String, username: String) {
        let credential = Credential(
            websiteName: website,
            websiteURL: website.lowercased().contains(".") ? website.lowercased() : "\(website.lowercased()).com",
            username: username,
            password: viewModel.generatedPassword
        )
        
        vaultViewModel.saveCredential(credential, isPremium: isPremium)
        
        // Reset and generate new password for next use
        quickSaveWebsite = ""
        quickSaveUsername = ""
        viewModel.generatePassword()
    }
}

// MARK: - New Account Helper Card

struct NewAccountHelperCard: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 50, height: 50)
                    Image(systemName: "person.badge.plus")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Creating a New Account?")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("Tap here for step-by-step help")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Password Display Card

struct PasswordDisplayCard: View {
    let password: String
    let strength: PasswordStrength
    let showCopied: Bool
    let onCopy: () -> Void
    let onRegenerate: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Password text - tap to copy
            Button(action: onCopy) {
                VStack(spacing: 8) {
                    Text(password)
                        .font(.system(.title3, design: .monospaced))
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary)
                    
                    HStack {
                        Image(systemName: showCopied ? "checkmark.circle.fill" : "doc.on.doc")
                            .foregroundStyle(showCopied ? .green : .secondary)
                        Text(showCopied ? "Copied!" : "Tap to copy")
                            .font(.caption)
                            .foregroundStyle(showCopied ? .green : .secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .animation(.easeInOut(duration: 0.2), value: showCopied)
            
            // Strength and regenerate
            HStack {
                // Strength indicator
                HStack(spacing: 6) {
                    Image(systemName: "shield.fill")
                        .foregroundStyle(Color(strength.color))
                    Text(strength.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(strength.color))
                }
                
                Spacer()
                
                // Regenerate button
                Button(action: onRegenerate) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                        Text("New")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.15))
                    .cornerRadius(8)
                }
            }
        }
    }
}

// MARK: - Quick Action Buttons

struct QuickActionButtons: View {
    let showCopied: Bool
    let onCopy: () -> Void
    let onCopyAndOpen: () -> Void
    let onQuickSave: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Copy button
            Button(action: onCopy) {
                VStack(spacing: 6) {
                    Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                        .font(.title2)
                    Text(showCopied ? "Copied!" : "Copy")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(showCopied ? Color.green.opacity(0.15) : Color(.systemGray6))
                .foregroundStyle(showCopied ? .green : .primary)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            
            // Quick save button
            Button(action: onQuickSave) {
                VStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.title2)
                    Text("Quick Save")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(.systemGray6))
                .foregroundStyle(.primary)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            
            // Share button
            Button(action: {
                sharePassword()
            }) {
                VStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title2)
                    Text("Share")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(.systemGray6))
                .foregroundStyle(.primary)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
    }
    
    private func sharePassword() {
        // This will be implemented with the actual password
    }
}

// MARK: - Character Toggle Row

struct CharacterToggleRow: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Quick Save Sheet

struct QuickSaveSheet: View {
    let password: String
    @Binding var website: String
    @Binding var username: String
    @Binding var isPresented: Bool
    let onSave: (String, String) -> Void
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case website, username
    }
    
    var canSave: Bool {
        !website.trimmingCharacters(in: .whitespaces).isEmpty &&
        !username.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Password preview
                VStack(spacing: 4) {
                    Text("Password to save:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(password)
                        .font(.system(.body, design: .monospaced))
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                .padding(.top)
                
                // Form fields
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Website")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("e.g. Google, Facebook", text: $website)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.words)
                            .focused($focusedField, equals: .website)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Username or Email")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("e.g. john@email.com", text: $username)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .focused($focusedField, equals: .username)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Save button
                Button {
                    onSave(website, username)
                    isPresented = false
                } label: {
                    Text("Save to Vault")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canSave ? Color.green : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(!canSave)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Quick Save")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
            .onAppear {
                focusedField = .website
            }
        }
    }
}

// MARK: - New Account Helper Sheet

struct NewAccountHelperSheet: View {
    let password: String
    @Binding var isPresented: Bool
    let onCopy: () -> Void
    let onRegenerate: () -> Void
    let onSaveAfterCreation: (String, String) -> Void
    
    @State private var currentStep = 1
    @State private var websiteName = ""
    @State private var username = ""
    @State private var hasCopied = false
    @State private var showCopiedFeedback = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress indicator
                HStack(spacing: 8) {
                    ForEach(1...3, id: \.self) { step in
                        Circle()
                            .fill(step <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 10, height: 10)
                    }
                }
                .padding(.top, 20)
                
                TabView(selection: $currentStep) {
                    // Step 1: Copy Password
                    step1View
                        .tag(1)
                    
                    // Step 2: Create Account
                    step2View
                        .tag(2)
                    
                    // Step 3: Save to Vault
                    step3View
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentStep)
            }
            .navigationTitle("New Account Helper")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    // MARK: Step 1 - Copy Password
    
    private var step1View: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "1.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
            
            Text("Copy Your Password")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("First, copy this strong password to your clipboard")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            // Password display
            VStack(spacing: 12) {
                Text(password)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                
                Button {
                    onRegenerate()
                } label: {
                    Label("Generate Different", systemImage: "arrow.clockwise")
                        .font(.caption)
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            // Copy button
            Button {
                onCopy()
                hasCopied = true
                showCopiedFeedback = true
                
                // Auto-advance after copying
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    showCopiedFeedback = false
                    currentStep = 2
                }
            } label: {
                Label(
                    showCopiedFeedback ? "Copied! ✓" : "Copy Password",
                    systemImage: showCopiedFeedback ? "checkmark" : "doc.on.doc"
                )
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(showCopiedFeedback ? Color.green : Color.blue)
                .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }
    
    // MARK: Step 2 - Create Account
    
    private var step2View: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "2.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
            
            Text("Create Your Account")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 16) {
                instructionRow(number: "1", text: "Go to the website or app where you want to create an account")
                instructionRow(number: "2", text: "Fill in your email/username")
                instructionRow(number: "3", text: "Paste the password (it's in your clipboard!)")
                instructionRow(number: "4", text: "Complete the signup")
            }
            .padding(.horizontal, 32)
            
            // Re-copy if needed
            if hasCopied {
                Button {
                    onCopy()
                    showCopiedFeedback = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        showCopiedFeedback = false
                    }
                } label: {
                    Label(
                        showCopiedFeedback ? "Copied Again!" : "Copy Password Again",
                        systemImage: "doc.on.doc"
                    )
                    .font(.subheadline)
                    .foregroundStyle(showCopiedFeedback ? .green : .blue)
                }
            }
            
            Spacer()
            
            // Continue button
            Button {
                currentStep = 3
            } label: {
                Text("I've Created My Account →")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }
    
    // MARK: Step 3 - Save to Vault
    
    private var step3View: some View {
        VStack(spacing: 24) {
            Image(systemName: "3.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
                .padding(.top, 32)
            
            Text("Save to Vault")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Now save your login details so PasswordVault can autofill next time!")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            // Form fields
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Website Name")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("e.g. Gmail, Netflix, Twitter", text: $websiteName)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.words)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Username or Email")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("The email/username you just signed up with", text: $username)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            // Save button
            Button {
                if !websiteName.isEmpty && !username.isEmpty {
                    onSaveAfterCreation(websiteName, username)
                    isPresented = false
                }
            } label: {
                Label("Save to Vault", systemImage: "checkmark.shield.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        (!websiteName.isEmpty && !username.isEmpty) ? Color.green : Color.gray
                    )
                    .cornerRadius(12)
            }
            .disabled(websiteName.isEmpty || username.isEmpty)
            .padding(.horizontal, 32)
            
            Button("Skip for now") {
                isPresented = false
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.bottom, 32)
        }
    }
    
    private func instructionRow(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Color.blue)
                .clipShape(Circle())
            
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
            
            Spacer()
        }
    }
}

#Preview {
    PasswordGeneratorView(
        vaultViewModel: .constant(VaultViewModel()),
        isPremium: .constant(false)
    )
}
