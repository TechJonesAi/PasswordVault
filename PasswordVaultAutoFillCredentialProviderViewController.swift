//
//  CredentialProviderViewController.swift
//  PasswordVaultAutoFill
//
//  Created by AI Assistant on 10/12/2025.
//  SECURITY UPDATE: Uses SecureKeychainService with proper encryption
//

import AuthenticationServices
import SwiftUI

class CredentialProviderViewController: ASCredentialProviderViewController {
    
    // SECURITY: Use SecureKeychainService instead of KeychainService
    private lazy var keychainService = SecureKeychainService()
    private let maxCredentials = 50
    private var hasSetupUI = false
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        #if DEBUG
        debugAppGroupAccess()
        #endif
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // If prepareCredentialList wasn't called (direct launch), show all credentials
        if !hasSetupUI {
            showAllCredentials()
        }
    }
    
    // MARK: - Debug Helpers
    
    #if DEBUG
    private func debugAppGroupAccess() {
        let appGroupID = "group.co.uk.techjonesai.PasswordVaultShared"
        
        if UserDefaults(suiteName: appGroupID) != nil {
            print("✅ App Group accessible")
        } else {
            print("❌ Cannot access App Group")
        }
    }
    #endif
    
    // MARK: - Storyboard Actions
    
    @IBAction func cancel(_ sender: Any?) {
        cancelRequest()
    }
    
    @IBAction func passwordSelected(_ sender: Any?) {
        showAllCredentials()
    }
    
    // MARK: - Prepare Credential List (Main Entry Point)
    
    override func prepareCredentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        let domain = serviceIdentifiers.first?.identifier ?? ""
        loadAndShowCredentials(for: domain)
    }
    
    // MARK: - Provide Credential Without User Interaction
    
    override func provideCredentialWithoutUserInteraction(for credentialIdentity: ASPasswordCredentialIdentity) {
        // For security, always require user interaction
        let error = NSError(
            domain: ASExtensionErrorDomain,
            code: ASExtensionError.userInteractionRequired.rawValue
        )
        extensionContext.cancelRequest(withError: error)
    }
    
    // MARK: - Prepare Interface to Provide Credential
    
    override func prepareInterfaceToProvideCredential(for credentialIdentity: ASPasswordCredentialIdentity) {
        // If we have a record identifier, try to find that specific credential
        if let recordId = credentialIdentity.recordIdentifier,
           let uuid = UUID(uuidString: recordId) {
            do {
                if let credential = try keychainService.fetchCredential(byId: uuid) {
                    selectCredential(credential)
                    return
                }
            } catch {
                #if DEBUG
                print("⚠️ Error fetching credential: \(error)")
                #endif
            }
        }
        
        // Fall back to showing filtered list
        let domain = credentialIdentity.serviceIdentifier.identifier
        loadAndShowCredentials(for: domain)
    }
    
    // MARK: - Password Generation
    
    override func prepareInterfaceForExtensionConfiguration() {
        // Configuration UI if needed
    }
    
    override func prepareCredentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier], requestParameters: ASPasskeyCredentialRequestParameters) {
        let domain = serviceIdentifiers.first?.identifier ?? ""
        loadAndShowCredentials(for: domain)
    }
    
    override func prepareOneTimeCodeCredentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        cancelRequest()
    }
    
    // MARK: - Core Logic
    
    private func showAllCredentials() {
        loadAndShowCredentials(for: "")
    }
    
    private func loadAndShowCredentials(for domain: String) {
        hasSetupUI = true
        let cleanDomain = cleanDomainForDisplay(domain)
        
        do {
            let credentials = try keychainService.fetchCredentials(matchingDomain: domain, limit: maxCredentials)
            
            if credentials.isEmpty {
                showEmptyState(for: cleanDomain)
            } else {
                showCredentialList(credentials, searchDomain: cleanDomain)
            }
            
        } catch {
            showErrorState(error: error)
        }
    }
    
    private func cleanDomainForDisplay(_ domain: String) -> String {
        var clean = domain
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
        
        if let questionMark = clean.firstIndex(of: "?") {
            clean = String(clean[..<questionMark])
        }
        
        if clean.count > 40 {
            let parts = clean.components(separatedBy: "/")
            if let first = parts.first {
                clean = first
            }
        }
        
        return clean
    }
    
    // MARK: - Password Generation
    
    private func generateStrongPassword() -> String {
        let length = 20
        let uppercase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let lowercase = "abcdefghijklmnopqrstuvwxyz"
        let numbers = "0123456789"
        let special = "!@#$%^&*"
        
        var password = ""
        password.append(uppercase.randomElement()!)
        password.append(lowercase.randomElement()!)
        password.append(numbers.randomElement()!)
        password.append(special.randomElement()!)
        
        let allChars = uppercase + lowercase + numbers + special
        for _ in 4..<length {
            password.append(allChars.randomElement()!)
        }
        
        return String(password.shuffled())
    }
    
    // MARK: - UI Display
    
    private func showCredentialList(_ credentials: [Credential], searchDomain: String) {
        let listView = AutoFillCredentialListView(
            credentials: credentials,
            searchDomain: searchDomain,
            onSelect: { [weak self] credential in
                self?.selectCredential(credential)
            },
            onCancel: { [weak self] in
                self?.cancelRequest()
            }
        )
        
        presentSwiftUIView(listView)
    }
    
    private func showEmptyState(for domain: String) {
        let emptyView = AutoFillEmptyStateView(
            domain: domain,
            onOpenApp: { [weak self] in
                self?.openMainApp()
            },
            onCancel: { [weak self] in
                self?.cancelRequest()
            }
        )
        
        presentSwiftUIView(emptyView)
    }
    
    private func showErrorState(error: Error) {
        let errorView = AutoFillErrorView(
            errorMessage: "Unable to load passwords",
            onRetry: { [weak self] in
                self?.showAllCredentials()
            },
            onCancel: { [weak self] in
                self?.cancelRequest()
            }
        )
        
        presentSwiftUIView(errorView)
    }
    
    private func presentSwiftUIView<Content: View>(_ swiftUIView: Content) {
        for subview in view.subviews {
            subview.removeFromSuperview()
        }
        
        for child in children {
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }
        
        let hosting = UIHostingController(rootView: swiftUIView)
        addChild(hosting)
        
        hosting.view.frame = view.bounds
        hosting.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hosting.view.backgroundColor = .systemBackground
        
        view.addSubview(hosting.view)
        hosting.didMove(toParent: self)
    }
    
    // MARK: - Actions
    
    private func selectCredential(_ credential: Credential) {
        let passwordCredential = ASPasswordCredential(
            user: credential.username,
            password: credential.password
        )
        
        extensionContext.completeRequest(
            withSelectedCredential: passwordCredential,
            completionHandler: nil
        )
    }
    
    private func cancelRequest() {
        let error = NSError(
            domain: ASExtensionErrorDomain,
            code: ASExtensionError.userCanceled.rawValue
        )
        extensionContext.cancelRequest(withError: error)
    }
    
    private func openMainApp() {
        if let url = URL(string: "passwordvault://add") {
            extensionContext.open(url) { _ in }
        }
        cancelRequest()
    }
}

// MARK: - AutoFill Credential List View

struct AutoFillCredentialListView: View {
    let credentials: [Credential]
    let searchDomain: String
    let onSelect: (Credential) -> Void
    let onCancel: () -> Void
    
    @State private var searchText = ""
    
    var filteredCredentials: [Credential] {
        if searchText.isEmpty {
            return credentials
        }
        return credentials.filter { cred in
            cred.websiteName.localizedCaseInsensitiveContains(searchText) ||
            cred.username.localizedCaseInsensitiveContains(searchText) ||
            (cred.websiteURL ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search passwords", text: $searchText)
                        .textFieldStyle(.plain)
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 8)
                
                if !searchDomain.isEmpty {
                    Text("Passwords for \(searchDomain)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
                
                if filteredCredentials.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "key.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No matching passwords")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(filteredCredentials) { credential in
                            Button(action: { onSelect(credential) }) {
                                CredentialRowView(credential: credential)
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Select Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                }
            }
        }
    }
}

// MARK: - Credential Row View

struct CredentialRowView: View {
    let credential: Credential
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Text(credential.websiteName.prefix(1).uppercased())
                    .font(.headline)
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(credential.websiteName)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(credential.username)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

// MARK: - Empty State View

struct AutoFillEmptyStateView: View {
    let domain: String
    let onOpenApp: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: "key.slash")
                    .font(.system(size: 64))
                    .foregroundColor(.secondary)
                
                Text("No Passwords Saved")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if !domain.isEmpty {
                    Text("No passwords found for \(domain)")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                Button(action: onOpenApp) {
                    Label("Open PasswordVault", systemImage: "arrow.up.forward.app")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 32)
                
                Spacer()
            }
            .navigationTitle("Select Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                }
            }
        }
    }
}

// MARK: - Error View

struct AutoFillErrorView: View {
    let errorMessage: String
    let onRetry: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 64))
                    .foregroundColor(.orange)
                
                Text("Something Went Wrong")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(errorMessage)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Button(action: onRetry) {
                    Label("Try Again", systemImage: "arrow.clockwise")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 32)
                
                Spacer()
            }
            .navigationTitle("Error")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                }
            }
        }
    }
}
