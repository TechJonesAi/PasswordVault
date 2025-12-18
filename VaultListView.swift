//
//  VaultListView.swift
//  PasswordVault
//
//  Created by AI Assistant on 05/12/2025.
//  ENHANCED: Added folders, favourites, expiry warnings, and AI search
//

import SwiftUI

/// Password Vault Tab (Tab 2)
struct VaultListView: View {
    
    @Binding var viewModel: VaultViewModel
    @Binding var isPremium: Bool
    var premiumManager: PremiumManager
    var aiAssistant: AIPasswordAssistant
    var settingsManager: AppSettingsManager
    
    @State private var showAddSheet = false
    @State private var selectedCredential: Credential?
    @State private var selectedFolder: PasswordFolder?
    @State private var showFolderFilter = false
    @State private var showExpiryWarnings = false
    
    // Computed: credentials with expiry warnings
    private var expiringCredentials: [Credential] {
        viewModel.credentials.filter { $0.isExpiryReminderDue }
    }
    
    // Filtered credentials by folder
    private var filteredByFolder: [Credential] {
        if let folder = selectedFolder {
            return viewModel.filteredCredentials.filter { $0.folder == folder }
        }
        return viewModel.filteredCredentials
    }
    
    // Separated into favourites and others
    private var favouriteCredentials: [Credential] {
        filteredByFolder.filter { $0.isFavourite }
    }
    
    private var otherCredentials: [Credential] {
        filteredByFolder.filter { !$0.isFavourite }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.credentials.isEmpty {
                    emptyStateView
                } else {
                    credentialsList
                }
            }
            .navigationTitle("Vault")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    // Folder filter
                    Menu {
                        Button {
                            selectedFolder = nil
                        } label: {
                            Label("All Passwords", systemImage: selectedFolder == nil ? "checkmark" : "")
                        }
                        
                        Divider()
                        
                        ForEach(PasswordFolder.allCases) { folder in
                            Button {
                                selectedFolder = folder
                            } label: {
                                Label(folder.rawValue, systemImage: selectedFolder == folder ? "checkmark" : folder.iconName)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: selectedFolder?.iconName ?? "folder.fill")
                            if let folder = selectedFolder {
                                Text(folder.rawValue)
                                    .font(.caption)
                            }
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Sort By", selection: $viewModel.sortOption) {
                            ForEach(VaultViewModel.SortOption.allCases, id: \.self) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down")
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                bottomInfoBar
            }
            .sheet(isPresented: $showAddSheet) {
                AddCredentialView(
                    vaultViewModel: $viewModel,
                    isPremium: $isPremium,
                    isPresented: $showAddSheet,
                    aiAssistant: aiAssistant
                )
            }
            .sheet(item: $selectedCredential) { credential in
                CredentialDetailView(
                    credential: credential,
                    vaultViewModel: $viewModel,
                    isPremium: $isPremium
                )
            }
            .sheet(isPresented: $viewModel.showPaywall) {
                PaywallView(
                    isPresented: $viewModel.showPaywall,
                    premiumManager: premiumManager,
                    onPurchaseComplete: {}
                )
            }
            .sheet(isPresented: $showExpiryWarnings) {
                ExpiryWarningsView(
                    credentials: expiringCredentials,
                    onSelectCredential: { credential in
                        showExpiryWarnings = false
                        selectedCredential = credential
                    }
                )
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        ContentUnavailableView(
            "No Passwords Saved",
            systemImage: "lock.slash",
            description: Text("Tap + to add your first password")
        )
    }
    
    // MARK: - Credentials List
    
    private var credentialsList: some View {
        List {
            // Expiry warnings banner
            if !expiringCredentials.isEmpty {
                Section {
                    Button {
                        showExpiryWarnings = true
                    } label: {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            VStack(alignment: .leading) {
                                Text("\(expiringCredentials.count) password\(expiringCredentials.count == 1 ? "" : "s") need attention")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("Tap to review")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
            
            // Favourites section
            if !favouriteCredentials.isEmpty {
                Section("Favourites") {
                    ForEach(favouriteCredentials) { credential in
                        credentialRow(credential)
                    }
                    .onDelete { indexSet in
                        deleteFavourites(at: indexSet)
                    }
                }
            }
            
            // Other credentials
            Section(favouriteCredentials.isEmpty ? "All Passwords" : "Other Passwords") {
                ForEach(otherCredentials) { credential in
                    credentialRow(credential)
                }
                .onDelete { indexSet in
                    deleteOthers(at: indexSet)
                }
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Search passwords")
    }
    
    // MARK: - Credential Row
    
    private func credentialRow(_ credential: Credential) -> some View {
        Button {
            selectedCredential = credential
        } label: {
            HStack(spacing: 12) {
                // Folder-colored icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(folderColor(credential.folder).opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: credential.folder?.iconName ?? "globe")
                        .font(.title3)
                        .foregroundStyle(folderColor(credential.folder))
                }
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(credential.websiteName)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        if credential.isFavourite {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }
                        
                        if credential.isExpiryReminderDue {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }
                    }
                    
                    Text(credential.username)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 8) {
                        if let folder = credential.folder {
                            Text(folder.rawValue)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        
                        Text("••••••••")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 4)
        }
        .swipeActions(edge: .leading) {
            Button {
                toggleFavourite(credential)
            } label: {
                Label(
                    credential.isFavourite ? "Unfavourite" : "Favourite",
                    systemImage: credential.isFavourite ? "star.slash" : "star.fill"
                )
            }
            .tint(.orange)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                viewModel.deleteCredential(credential)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    // MARK: - Bottom Info Bar
    
    private var bottomInfoBar: some View {
        VStack {
            if !isPremium {
                HStack {
                    Image(systemName: "lock.fill")
                    Text("\(viewModel.credentials.count)/1 passwords used")
                        .font(.caption)
                    Spacer()
                    Text("Upgrade for unlimited")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding()
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func folderColor(_ folder: PasswordFolder?) -> Color {
        guard let folder = folder else { return .blue }
        switch folder.color {
        case "blue": return .blue
        case "purple": return .purple
        case "green": return .green
        case "pink": return .pink
        case "orange": return .orange
        case "red": return .red
        case "cyan": return .cyan
        case "mint": return .mint
        case "indigo": return .indigo
        default: return .gray
        }
    }
    
    private func toggleFavourite(_ credential: Credential) {
        if let index = viewModel.credentials.firstIndex(where: { $0.id == credential.id }) {
            viewModel.credentials[index].isFavourite.toggle()
            viewModel.saveCredentials()
        }
    }
    
    private func deleteFavourites(at offsets: IndexSet) {
        let toDelete = offsets.map { favouriteCredentials[$0] }
        for credential in toDelete {
            viewModel.deleteCredential(credential)
        }
    }
    
    private func deleteOthers(at offsets: IndexSet) {
        let toDelete = offsets.map { otherCredentials[$0] }
        for credential in toDelete {
            viewModel.deleteCredential(credential)
        }
    }
}

// MARK: - Expiry Warnings View

struct ExpiryWarningsView: View {
    let credentials: [Credential]
    var onSelectCredential: (Credential) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("These passwords haven't been changed in a while. Consider updating them for better security.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Section("Passwords to Review") {
                    ForEach(credentials) { credential in
                        Button {
                            onSelectCredential(credential)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(credential.websiteName)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text(credential.username)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(credential.passwordAgeDescription)
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Password Reminders")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Backward compatible init
extension VaultListView {
    init(viewModel: Binding<VaultViewModel>, isPremium: Binding<Bool>, premiumManager: PremiumManager) {
        self._viewModel = viewModel
        self._isPremium = isPremium
        self.premiumManager = premiumManager
        self.aiAssistant = AIPasswordAssistant()
        self.settingsManager = AppSettingsManager()
    }
}

#Preview {
    VaultListView(
        viewModel: .constant(VaultViewModel()),
        isPremium: .constant(false),
        premiumManager: PremiumManager()
    )
}
