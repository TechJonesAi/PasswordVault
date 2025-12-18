//
//  CredentialDetailView.swift
//  PasswordVault
//
//  Created by AI Assistant on 05/12/2025.
//

import SwiftUI

/// Detail view for viewing/editing a credential
struct CredentialDetailView: View {
    
    let credential: Credential
    @Binding var vaultViewModel: VaultViewModel
    @Binding var isPremium: Bool
    
    @Environment(\.dismiss) private var dismiss
    @State private var showPassword = false
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false
    @State private var showCopiedConfirmation = false
    
    var body: some View {
        NavigationStack {
            List {
                // Website section
                Section("Website") {
                    LabeledContent("Name", value: credential.websiteName)
                    
                    if let url = credential.websiteURL {
                        LabeledContent("URL", value: url)
                    }
                }
                
                // Credentials section
                Section("Credentials") {
                    LabeledContent("Username", value: credential.username)
                    
                    HStack {
                        Text("Password")
                        Spacer()
                        if showPassword {
                            Text(credential.password)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("••••••••")
                                .foregroundStyle(.secondary)
                        }
                        
                        Button {
                            showPassword.toggle()
                        } label: {
                            Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                    
                    Button {
                        copyPassword()
                    } label: {
                        Label(
                            showCopiedConfirmation ? "Copied!" : "Copy Password",
                            systemImage: showCopiedConfirmation ? "checkmark" : "doc.on.doc"
                        )
                    }
                }
                
                // Notes section
                if let notes = credential.notes, !notes.isEmpty {
                    Section("Notes") {
                        Text(notes)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Metadata section
                Section("Information") {
                    LabeledContent("Created", value: credential.createdDate.formatted(date: .abbreviated, time: .shortened))
                    LabeledContent("Modified", value: credential.lastModifiedDate.formatted(date: .abbreviated, time: .shortened))
                }
                
                // Actions section
                Section {
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("Delete Password", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Password Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") {
                        showEditSheet = true
                    }
                }
            }
            .sheet(isPresented: $showEditSheet) {
                AddCredentialView(
                    vaultViewModel: $vaultViewModel,
                    isPremium: $isPremium,
                    isPresented: $showEditSheet,
                    editingCredential: credential
                )
            }
            .alert("Delete Password?", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    vaultViewModel.deleteCredential(credential)
                    dismiss()
                }
            } message: {
                Text("This password will be permanently deleted.")
            }
        }
    }
    
    private func copyPassword() {
        #if os(iOS)
        UIPasteboard.general.string = credential.password
        #endif
        
        showCopiedConfirmation = true
        
        Task {
            try? await Task.sleep(for: .seconds(2))
            await MainActor.run {
                showCopiedConfirmation = false
            }
        }
    }
}

#Preview {
    CredentialDetailView(
        credential: .sample,
        vaultViewModel: .constant(VaultViewModel()),
        isPremium: .constant(false)
    )
}
