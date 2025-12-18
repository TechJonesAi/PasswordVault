//
//  ExtensionCredentialListView.swift
//  PasswordVaultAutoFill
//
//  Created by AI Assistant on 05/12/2025.
//

import SwiftUI
import AuthenticationServices

/// SwiftUI view for displaying credentials in extension
struct ExtensionCredentialListView: View {
    
    let credentials: [Credential]
    let serviceIdentifiers: [ASCredentialServiceIdentifier]
    let onCredentialSelected: (Credential) -> Void
    let onCancel: () -> Void
    
    @State private var searchText = ""
    
    var filteredCredentials: [Credential] {
        if searchText.isEmpty {
            return matchingCredentials
        }
        
        return matchingCredentials.filter { credential in
            credential.websiteName.localizedCaseInsensitiveContains(searchText) ||
            credential.username.localizedCaseInsensitiveContains(searchText) ||
            (credential.websiteURL?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    var matchingCredentials: [Credential] {
        // Try to match credentials based on service identifiers
        let domains = serviceIdentifiers.compactMap { $0.identifier }
        
        if domains.isEmpty {
            return credentials
        }
        
        // First, find exact matches
        let exactMatches = credentials.filter { credential in
            guard let url = credential.websiteURL else { return false }
            return domains.contains { domain in
                url.localizedCaseInsensitiveContains(domain) ||
                domain.localizedCaseInsensitiveContains(url)
            }
        }
        
        if !exactMatches.isEmpty {
            return exactMatches
        }
        
        // If no exact matches, return all credentials
        return credentials
    }
    
    var body: some View {
        NavigationStack {
            List {
                if filteredCredentials.isEmpty {
                    ContentUnavailableView(
                        "No Passwords Found",
                        systemImage: "lock.slash",
                        description: Text(searchText.isEmpty ? "No saved passwords match this website" : "No results for '\(searchText)'")
                    )
                } else {
                    ForEach(filteredCredentials) { credential in
                        Button {
                            onCredentialSelected(credential)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "globe")
                                    .font(.title3)
                                    .foregroundStyle(.blue)
                                    .frame(width: 36, height: 36)
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

#Preview {
    ExtensionCredentialListView(
        credentials: Credential.samples,
        serviceIdentifiers: [],
        onCredentialSelected: { _ in },
        onCancel: { }
    )
}
