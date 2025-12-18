//
//  CredentialListView.swift
//  PasswordVaultAutoFill
//
//  Created by AI Assistant on 06/12/2025.
//

import SwiftUI
import AuthenticationServices

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
            // Clean up the domain
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
