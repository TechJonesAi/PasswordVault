//
//  CredentialProviderViewController.swift
//  PasswordVaultAutoFill
//
//  Created by AI Assistant on 07/12/2025.
//  CLEAN SIMPLIFIED VERSION
//

import AuthenticationServices
import SwiftUI

class CredentialProviderViewController: ASCredentialProviderViewController {
    
    private lazy var keychainService = KeychainService()
    private let maxCredentials = 50
    
    // MARK: - Initialization (CRITICAL FOR DEBUGGING)
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        print("🚀🚀🚀 EXTENSION INIT CALLED 🚀🚀🚀")
        print("🚀 Extension process has started!")
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        print("🚀🚀🚀 EXTENSION INIT (CODER) CALLED 🚀🚀🚀")
        print("🚀 Extension process has started!")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("🚀🚀🚀 EXTENSION viewDidLoad CALLED 🚀🚀🚀")
        print("🚀 CredentialProviderViewController: viewDidLoad called")
        print("🚀 Extension is launching!")
        print("🚀 View frame: \(view.frame)")
        print("🚀 View bounds: \(view.bounds)")
        
        // Set a visible background color for debugging
        view.backgroundColor = .systemBackground
        
        // Add test credentials if keychain is empty
        ensureTestCredentials()
    }
    
    // MARK: - Prepare Credential List
    
    override func prepareCredentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        print("🔍🔍🔍 AutoFill: prepareCredentialList called 🔍🔍🔍")
        print("🔍 Service identifiers: \(serviceIdentifiers.map { $0.identifier })")
        
        let domain = serviceIdentifiers.first?.identifier ?? ""
        print("🔍 Domain: \(domain)")
        
        do {
            let credentials = try keychainService.fetchCredentials(matchingDomain: domain, limit: maxCredentials)
            print("✅ Found \(credentials.count) credentials for domain: \(domain)")
            
            if credentials.isEmpty {
                print("⚠️ No credentials found for domain: \(domain)")
            }
            
            showCredentialList(credentials)
            print("🔍 View added to hierarchy")
            
        } catch {
            print("❌ Error fetching credentials: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            cancelRequest()
        }
    }
    
    // MARK: - Provide Credential Without User Interaction
    
    override func provideCredentialWithoutUserInteraction(for credentialIdentity: ASPasswordCredentialIdentity) {
        print("🔍 AutoFill: provideCredentialWithoutUserInteraction")
        
        let domain = credentialIdentity.serviceIdentifier.identifier
        
        do {
            let credentials = try keychainService.fetchCredentials(matchingDomain: domain, limit: 1)
            if let credential = credentials.first {
                selectCredential(credential)
                return
            }
        } catch {
            print("❌ Error: \(error)")
        }
        
        let error = NSError(domain: ASExtensionErrorDomain, code: ASExtensionError.userInteractionRequired.rawValue)
        extensionContext.cancelRequest(withError: error)
    }
    
    // MARK: - Prepare Interface to Provide Credential
    
    override func prepareInterfaceToProvideCredential(for credentialIdentity: ASPasswordCredentialIdentity) {
        print("🔍 AutoFill: prepareInterfaceToProvideCredential")
        
        let domain = credentialIdentity.serviceIdentifier.identifier
        
        do {
            let credentials = try keychainService.fetchCredentials(matchingDomain: domain, limit: maxCredentials)
            
            if credentials.count == 1 {
                selectCredential(credentials[0])
            } else if !credentials.isEmpty {
                showCredentialList(credentials)
            } else {
                cancelRequest()
            }
        } catch {
            print("❌ Error: \(error)")
            cancelRequest()
        }
    }
    
    // MARK: - Helper Methods
    
    /// Test method to add sample credentials if none exist
    /// Automatically called from viewDidLoad during development
    private func ensureTestCredentials() {
        do {
            let existingCredentials = try keychainService.fetchAllCredentials()
            print("📊 Total credentials in keychain: \(existingCredentials.count)")
            
            if existingCredentials.isEmpty {
                print("⚠️ No credentials found - adding test data")
                let testCredentials = [
                    Credential(
                        websiteName: "Twitter",
                        websiteURL: "twitter.com",
                        username: "test@twitter.com",
                        password: "TestPassword123!",
                        notes: "Test credential"
                    ),
                    Credential(
                        websiteName: "Gmail",
                        websiteURL: "gmail.com",
                        username: "test@gmail.com",
                        password: "TestPassword456!",
                        notes: "Test credential"
                    ),
                    Credential(
                        websiteName: "Google",
                        websiteURL: "google.com",
                        username: "test@google.com",
                        password: "TestPassword789!",
                        notes: "Test credential"
                    ),
                    Credential(
                        websiteName: "Facebook",
                        websiteURL: "facebook.com",
                        username: "test@facebook.com",
                        password: "TestPassword321!",
                        notes: "Test credential"
                    )
                ]
                try keychainService.saveCredentials(testCredentials)
                print("✅ Test credentials added: \(testCredentials.count) credentials")
            } else {
                print("✅ Found \(existingCredentials.count) existing credentials:")
                existingCredentials.prefix(5).forEach { credential in
                    print("   - \(credential.websiteName) (\(credential.username))")
                }
            }
        } catch {
            print("❌ Error managing test credentials: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
        }
    }
    
    private func showCredentialList(_ credentials: [Credential]) {
        print("🎨 Creating credential list view with \(credentials.count) items")
        
        let listView = SimpleCredentialListView(
            credentials: credentials,
            onSelect: { [weak self] credential in
                self?.selectCredential(credential)
            },
            onCancel: { [weak self] in
                self?.cancelRequest()
            }
        )
        
        let hosting = UIHostingController(rootView: listView)
        
        // Critical: Set background color to ensure visibility
        hosting.view.backgroundColor = .systemBackground
        
        print("🎨 Adding hosting controller to view hierarchy")
        addChild(hosting)
        
        hosting.view.frame = view.bounds
        hosting.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(hosting.view)
        
        // Use constraints for more reliable layout
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        hosting.didMove(toParent: self)
        
        print("✅ Hosting controller added successfully")
        print("✅ View frame: \(hosting.view.frame)")
        print("✅ View bounds: \(view.bounds)")
    }
    
    private func selectCredential(_ credential: Credential) {
        print("✅ Selected: \(credential.websiteName)")
        
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
        print("❌ Cancelling request")
        let error = NSError(domain: ASExtensionErrorDomain, code: ASExtensionError.userCanceled.rawValue)
        extensionContext.cancelRequest(withError: error)
    }
}

// MARK: - Simple Credential List View

struct SimpleCredentialListView: View {
    let credentials: [Credential]
    let onSelect: (Credential) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background color - critical for visibility
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                if credentials.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "lock.shield")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("No Passwords Found")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("No saved passwords match this website")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Credential List
                    List {
                        ForEach(credentials.prefix(50)) { credential in
                            Button(action: {
                                print("🔘 User tapped credential: \(credential.websiteName)")
                                onSelect(credential)
                            }) {
                                HStack(spacing: 12) {
                                    // Icon
                                    Image(systemName: "key.fill")
                                        .foregroundColor(.blue)
                                        .frame(width: 30)
                                    
                                    // Credential info
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(credential.websiteName)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text(credential.username)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    // Chevron
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                .padding(.vertical, 8)
                                .contentShape(Rectangle()) // Make entire row tappable
                            }
                            .buttonStyle(.plain) // Remove default button styling
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Select Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        print("🔘 User tapped Cancel")
                        onCancel()
                    }
                }
            }
        }
        .onAppear {
            print("🎨 SimpleCredentialListView appeared with \(credentials.count) credentials")
        }
    }
}
