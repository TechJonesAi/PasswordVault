//
//  VaultViewModel.swift
//  PasswordVault
//
//  Created by AI Assistant on 05/12/2025.
//  SECURITY UPDATE: Now uses SecureKeychainService with proper encryption
//

import Foundation

/// ViewModel for password vault
@Observable
final class VaultViewModel {
    
    // State
    var credentials: [Credential] = []
    var searchText: String = ""
    var sortOption: SortOption = .nameAscending
    var isLoading: Bool = false
    var errorMessage: String?
    var showPaywall: Bool = false
    
    // SECURITY: Use SecureKeychainService instead of KeychainService
    private let keychainService = SecureKeychainService()
    
    enum SortOption: String, CaseIterable {
        case nameAscending = "Name (A-Z)"
        case nameDescending = "Name (Z-A)"
        case dateNewest = "Newest First"
        case dateOldest = "Oldest First"
    }
    
    init() {
        keychainService.migrateFromInsecureStorage()
        loadCredentials()
    }
    
    // MARK: - Computed Properties
    
    /// Filtered and sorted credentials based on search and sort option
    var filteredCredentials: [Credential] {
        var filtered = credentials
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { credential in
                credential.websiteName.localizedCaseInsensitiveContains(searchText) ||
                credential.username.localizedCaseInsensitiveContains(searchText) ||
                (credential.websiteURL?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Apply sort
        switch sortOption {
        case .nameAscending:
            filtered.sort { $0.websiteName.localizedCaseInsensitiveCompare($1.websiteName) == .orderedAscending }
        case .nameDescending:
            filtered.sort { $0.websiteName.localizedCaseInsensitiveCompare($1.websiteName) == .orderedDescending }
        case .dateNewest:
            filtered.sort { $0.createdDate > $1.createdDate }
        case .dateOldest:
            filtered.sort { $0.createdDate < $1.createdDate }
        }
        
        return filtered
    }
    
    /// Check if user can save more passwords
    func canSaveMorePasswords(isPremium: Bool) -> Bool {
        if isPremium {
            return true
        }
        return credentials.count < 1
    }
    
    // MARK: - CRUD Operations
    
    /// Load all credentials from secure keychain
    func loadCredentials() {
        isLoading = true
        errorMessage = nil
        
        do {
            credentials = try keychainService.fetchAllCredentials()
        } catch {
            errorMessage = "Failed to load passwords"
            credentials = []
        }
        
        isLoading = false
    }
    
    /// Save or update a credential
    func saveCredential(_ credential: Credential, isPremium: Bool) {
        // Check if this is an update to existing credential
        let isUpdate = credentials.contains(where: { $0.id == credential.id })
        
        // Check premium limit only for NEW credentials
        if !isUpdate && !canSaveMorePasswords(isPremium: isPremium) {
            showPaywall = true
            return
        }
        
        do {
            try keychainService.saveCredential(credential)
            loadCredentials()
        } catch {
            errorMessage = "Failed to save password"
        }
    }
    
    /// Save all credentials (for batch operations like toggling favourites)
    func saveCredentials() {
        do {
            try keychainService.saveCredentials(credentials)
        } catch {
            errorMessage = "Failed to save passwords"
        }
    }
    
    /// Delete a credential
    func deleteCredential(_ credential: Credential) {
        do {
            try keychainService.deleteCredential(id: credential.id)
            loadCredentials()
        } catch {
            errorMessage = "Failed to delete password"
        }
    }
    
    /// Delete credential at index set (for swipe to delete)
    func deleteCredentials(at offsets: IndexSet) {
        let credentialsToDelete = offsets.map { filteredCredentials[$0] }
        
        for credential in credentialsToDelete {
            deleteCredential(credential)
        }
    }
}
