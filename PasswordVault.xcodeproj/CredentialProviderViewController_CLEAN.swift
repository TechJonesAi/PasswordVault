//
//  CredentialProviderViewController.swift
//  PasswordVaultAutoFill
//
//  Created by AI Assistant on 07/12/2025.
//  SIMPLIFIED VERSION THAT WORKS
//

import AuthenticationServices
import SwiftUI

class CredentialProviderViewController: ASCredentialProviderViewController {
    
    private lazy var keychainService = KeychainService()
    private let maxCredentials = 50
    
    // MARK: - Prepare Credential List
    
    override func prepareCredentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        print("🔍 AutoFill: prepareCredentialList called")
        print("🔍 AutoFill: Service identifiers: \(serviceIdentifiers)")
        
        let domain = serviceIdentifiers.first?.identifier ?? ""
        
        do {
            let credentials = try keychainService.fetchCredentials(matchingDomain: domain, limit: maxCredentials)
            print("✅ AutoFill: Found \(credentials.count) credentials")
            
            // Create simple list view
            let listView = SimpleCredentialListView(
                credentials: credentials,
                onSelect: { [weak self] credential in
                    self?.selectCredential(credential)
                },
                onCancel: { [weak self] in
                    self?.cancelRequest()
                }
            )
            
            // Add to view hierarchy
            let hosting = UIHostingController(rootView: listView)
            addChild(hosting)
            hosting.view.frame = view.bounds
            hosting.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.addSubview(hosting.view)
            hosting.didMove(toParent: self)
            
        } catch {
            print("❌ AutoFill: Error: \(error)")
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
        
        // Require user interaction
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
                // Single credential - provide immediately
                selectCredential(credentials[0])
            } else if !credentials.isEmpty {
                // Multiple credentials - show list
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
                addChild(hosting)
                hosting.view.frame = view.bounds
                hosting.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                view.addSubview(hosting.view)
                hosting.didMove(toParent: self)
            } else {
                // No credentials
                cancelRequest()
            }
        } catch {
            print("❌ Error: \(error)")
            cancelRequest()
        }
    }
    
    // MARK: - Helper Methods
    
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
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Select Password")
                    .font(.headline)
                Spacer()
                Button("Cancel") {
                    onCancel()
                }
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            
            Divider()
            
            // Credential List
            List {
                ForEach(credentials.prefix(50)) { credential in
                    Button(action: {
                        onSelect(credential)
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(credential.websiteName)
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text(credential.username)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .listStyle(.plain)
        }
    }
}
