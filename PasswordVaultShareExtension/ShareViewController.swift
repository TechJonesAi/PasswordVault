//
//  ShareViewController.swift
//  PasswordVaultShareExtension
//
//  Created by AI Assistant on 18/12/2025.
//  Share Extension for saving credentials from Safari and other browsers
//

import UIKit
import SwiftUI
import UniformTypeIdentifiers

class ShareViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Extract URL from share context
        extractSharedURL { [weak self] url in
            DispatchQueue.main.async {
                self?.presentSaveCredentialView(with: url)
            }
        }
    }
    
    private func extractSharedURL(completion: @escaping (String?) -> Void) {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            completion(nil)
            return
        }
        
        for item in extensionItems {
            guard let attachments = item.attachments else { continue }
            
            for attachment in attachments {
                // Try to get URL
                if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    attachment.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { data, error in
                        if let url = data as? URL {
                            completion(self.extractDomain(from: url.absoluteString))
                        } else {
                            completion(nil)
                        }
                    }
                    return
                }
                
                // Try to get plain text (might be a URL)
                if attachment.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    attachment.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { data, error in
                        if let text = data as? String, text.contains("http") {
                            completion(self.extractDomain(from: text))
                        } else {
                            completion(nil)
                        }
                    }
                    return
                }
            }
        }
        
        completion(nil)
    }
    
    private func extractDomain(from urlString: String) -> String {
        var domain = urlString
            .lowercased()
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .replacingOccurrences(of: "www.", with: "")
        
        if let slashIndex = domain.firstIndex(of: "/") {
            domain = String(domain[..<slashIndex])
        }
        
        return domain
    }
    
    private func presentSaveCredentialView(with url: String?) {
        let saveView = SaveCredentialView(
            websiteURL: url ?? "",
            onSave: { [weak self] credential in
                self?.saveCredential(credential)
            },
            onCancel: { [weak self] in
                self?.cancel()
            }
        )
        
        let hostingController = UIHostingController(rootView: saveView)
        hostingController.modalPresentationStyle = .fullScreen
        hostingController.view.backgroundColor = .systemBackground
        
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.frame = view.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hostingController.didMove(toParent: self)
    }
    
    private func saveCredential(_ credential: ShareCredential) {
        let keychainService = SecureKeychainService()
        
        // Create a new Credential object
        let newCredential = Credential(
            websiteName: credential.websiteName.isEmpty ? credential.websiteURL : credential.websiteName,
            websiteURL: credential.websiteURL,
            username: credential.username,
            password: credential.password,
            notes: credential.notes
        )
        
        do {
            try keychainService.saveCredential(newCredential)
            completeWithSuccess()
        } catch {
            completeWithError(error)
        }
    }
    
    private func completeWithSuccess() {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
    
    private func completeWithError(_ error: Error) {
        extensionContext?.cancelRequest(withError: error)
    }
    
    private func cancel() {
        extensionContext?.cancelRequest(withError: NSError(domain: "PasswordVault", code: 0, userInfo: nil))
    }
}

// MARK: - Share Credential Model

struct ShareCredential {
    var websiteName: String
    var websiteURL: String
    var username: String
    var password: String
    var notes: String
}

// MARK: - Save Credential SwiftUI View

struct SaveCredentialView: View {
    @State var websiteName: String = ""
    @State var websiteURL: String
    @State var username: String = ""
    @State var password: String = ""
    @State var notes: String = ""
    @State private var showPassword: Bool = false
    @State private var showingGenerator: Bool = false
    
    let onSave: (ShareCredential) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Website")) {
                    TextField("Website Name (e.g., Gmail)", text: $websiteName)
                        .textContentType(.organizationName)
                        .autocapitalization(.words)
                    
                    TextField("Website URL", text: $websiteURL)
                        .textContentType(.URL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                }
                
                Section(header: Text("Credentials")) {
                    TextField("Username or Email", text: $username)
                        .textContentType(.username)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    
                    HStack {
                        if showPassword {
                            TextField("Password", text: $password)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                        } else {
                            SecureField("Password", text: $password)
                        }
                        
                        Button(action: { showPassword.toggle() }) {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundColor(.gray)
                        }
                        
                        Button(action: { showingGenerator = true }) {
                            Image(systemName: "wand.and.stars")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Section(header: Text("Notes (Optional)")) {
                    TextEditor(text: $notes)
                        .frame(height: 80)
                }
            }
            .navigationTitle("Save to Vault")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let credential = ShareCredential(
                            websiteName: websiteName,
                            websiteURL: websiteURL,
                            username: username,
                            password: password,
                            notes: notes
                        )
                        onSave(credential)
                    }
                    .disabled(username.isEmpty || password.isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingGenerator) {
                PasswordGeneratorSheet(password: $password)
            }
        }
    }
}

// MARK: - Password Generator Sheet

struct PasswordGeneratorSheet: View {
    @Binding var password: String
    @Environment(\.dismiss) var dismiss
    
    @State private var length: Double = 16
    @State private var includeUppercase = true
    @State private var includeLowercase = true
    @State private var includeNumbers = true
    @State private var includeSymbols = true
    @State private var generatedPassword = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Generated Password")) {
                    HStack {
                        Text(generatedPassword)
                            .font(.system(.body, design: .monospaced))
                            .lineLimit(2)
                        
                        Spacer()
                        
                        Button(action: generatePassword) {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
                
                Section(header: Text("Length: \(Int(length))")) {
                    Slider(value: $length, in: 8...32, step: 1)
                        .onChange(of: length) { _, _ in generatePassword() }
                }
                
                Section(header: Text("Character Types")) {
                    Toggle("Uppercase (A-Z)", isOn: $includeUppercase)
                        .onChange(of: includeUppercase) { _, _ in generatePassword() }
                    Toggle("Lowercase (a-z)", isOn: $includeLowercase)
                        .onChange(of: includeLowercase) { _, _ in generatePassword() }
                    Toggle("Numbers (0-9)", isOn: $includeNumbers)
                        .onChange(of: includeNumbers) { _, _ in generatePassword() }
                    Toggle("Symbols (!@#$)", isOn: $includeSymbols)
                        .onChange(of: includeSymbols) { _, _ in generatePassword() }
                }
            }
            .navigationTitle("Generate Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Use This") {
                        password = generatedPassword
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                generatePassword()
            }
        }
    }
    
    private func generatePassword() {
        var characters = ""
        
        if includeUppercase { characters += "ABCDEFGHIJKLMNOPQRSTUVWXYZ" }
        if includeLowercase { characters += "abcdefghijklmnopqrstuvwxyz" }
        if includeNumbers { characters += "0123456789" }
        if includeSymbols { characters += "!@#$%^&*()_+-=[]{}|;:,.<>?" }
        
        if characters.isEmpty {
            characters = "abcdefghijklmnopqrstuvwxyz"
        }
        
        generatedPassword = String((0..<Int(length)).map { _ in
            characters.randomElement()!
        })
    }
}
