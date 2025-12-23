//
//  SecureKeychainService.swift
//  PasswordVault
//
//  Created by AI Assistant on 15/12/2025.
//  SECURITY: Apple-compliant storage using ONLY iOS Keychain
//  NO UserDefaults for any sensitive data
//

import Foundation
import Security
import CryptoKit
import AuthenticationServices

/// Apple-compliant secure service using ONLY iOS Keychain for all sensitive data
/// This meets App Store requirements for password manager apps
final class SecureKeychainService {
    
    // MARK: - Configuration
    
    /// Keychain access group for sharing between app and extension
    private let accessGroup = "group.co.uk.techjonesai.PasswordVaultShared"
    
    /// Service identifier for keychain items
    private let serviceIdentifier = "co.uk.techjonesai.PasswordVault"
    
    /// Keychain account names for different data types
    private let credentialsAccount = "vault_credentials_v3"
    private let secureNotesAccount = "vault_notes_v3"
    private let creditCardsAccount = "vault_cards_v3"
    private let encryptionKeyAccount = "vault_key_v3"
    
    /// Track if we've already logged (to reduce log spam)
    private static var hasLoggedLoad = false
    
    // MARK: - Initialization
    
    init() {
        // Clean up any old problematic keychain items (only once)
        cleanupOldKeychainItems()
    }
    
    /// Remove old keychain items that may have had issues
    private func cleanupOldKeychainItems() {
        let oldAccounts = [
            "vault_encryption_key",
            "vault_encryption_key_v2",
            "vault_credentials_encrypted",
            "vault_credentials_encrypted_v2",
            "vault_notes_encrypted",
            "vault_notes_encrypted_v2",
            "vault_cards_encrypted",
            "vault_cards_encrypted_v2"
        ]
        
        for account in oldAccounts {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: serviceIdentifier,
                kSecAttrAccount as String: account,
                kSecAttrAccessGroup as String: accessGroup
            ]
            SecItemDelete(query as CFDictionary)
        }
    }
    
    // MARK: - Encryption Key Management
    
    private func getOrCreateEncryptionKey() throws -> SymmetricKey {
        // Try to load existing key
        if let existingKeyData = try? loadFromKeychain(account: encryptionKeyAccount) {
            return SymmetricKey(data: existingKeyData)
        }
        
        // Create new key
        let newKey = SymmetricKey(size: .bits256)
        let keyData = newKey.withUnsafeBytes { Data($0) }
        
        try saveToKeychain(data: keyData, account: encryptionKeyAccount)
        
        #if DEBUG
        print("🔑 Created new encryption key in Keychain")
        #endif
        
        return newKey
    }
    
    // MARK: - Encryption/Decryption
    
    private func encrypt(_ data: Data) throws -> Data {
        let key = try getOrCreateEncryptionKey()
        let sealedBox = try AES.GCM.seal(data, using: key)
        
        guard let combined = sealedBox.combined else {
            throw KeychainError.encodingFailed
        }
        
        return combined
    }
    
    private func decrypt(_ data: Data) throws -> Data {
        let key = try getOrCreateEncryptionKey()
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: key)
    }
    
    // MARK: - Keychain Operations (Apple-Compliant)
    
    private func saveToKeychain(data: Data, account: String) throws {
        // Delete existing item first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: account,
            kSecAttrAccessGroup as String: accessGroup
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        // Add new item with Apple-recommended accessibility
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: account,
            kSecAttrAccessGroup as String: accessGroup,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status: status)
        }
    }
    
    private func loadFromKeychain(account: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: account,
            kSecAttrAccessGroup as String: accessGroup,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess, let data = result as? Data else {
            throw KeychainError.loadFailed(status: status)
        }
        
        return data
    }
    
    private func deleteFromKeychain(account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: account,
            kSecAttrAccessGroup as String: accessGroup
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status: status)
        }
    }
    
    // MARK: - Credentials Storage
    
    func saveCredentials(_ credentials: [Credential]) throws {
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(credentials)
        let encryptedData = try encrypt(jsonData)
        
        try saveToKeychain(data: encryptedData, account: credentialsAccount)
        
        // Register with AutoFill
        registerCredentialsWithAutoFill(credentials)
        
        #if DEBUG
        print("✅ Saved \(credentials.count) credentials to Keychain")
        #endif
    }
    
    func fetchAllCredentials() throws -> [Credential] {
        do {
            let encryptedData = try loadFromKeychain(account: credentialsAccount)
            let jsonData = try decrypt(encryptedData)
            
            let decoder = JSONDecoder()
            let credentials = try decoder.decode([Credential].self, from: jsonData)
            
            return credentials
        } catch let error as KeychainError {
            if case .loadFailed(let status) = error, status == errSecItemNotFound {
                return []
            }
            throw error
        }
    }
    
    // MARK: - Secure Notes Storage
    
    func saveSecureNotes(_ notes: [SecureNote]) throws {
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(notes)
        let encryptedData = try encrypt(jsonData)
        
        try saveToKeychain(data: encryptedData, account: secureNotesAccount)
    }
    
    func fetchSecureNotes() throws -> [SecureNote] {
        do {
            let encryptedData = try loadFromKeychain(account: secureNotesAccount)
            let jsonData = try decrypt(encryptedData)
            
            let decoder = JSONDecoder()
            return try decoder.decode([SecureNote].self, from: jsonData)
        } catch let error as KeychainError {
            if case .loadFailed(let status) = error, status == errSecItemNotFound {
                return []
            }
            throw error
        }
    }
    
    // MARK: - Credit Cards Storage
    
    func saveCreditCards(_ cards: [CreditCard]) throws {
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(cards)
        let encryptedData = try encrypt(jsonData)
        
        try saveToKeychain(data: encryptedData, account: creditCardsAccount)
    }
    
    func fetchCreditCards() throws -> [CreditCard] {
        do {
            let encryptedData = try loadFromKeychain(account: creditCardsAccount)
            let jsonData = try decrypt(encryptedData)
            
            let decoder = JSONDecoder()
            return try decoder.decode([CreditCard].self, from: jsonData)
        } catch let error as KeychainError {
            if case .loadFailed(let status) = error, status == errSecItemNotFound {
                return []
            }
            throw error
        }
    }
    
    // MARK: - AutoFill Registration
    
    private func registerCredentialsWithAutoFill(_ credentials: [Credential]) {
        let store = ASCredentialIdentityStore.shared
        
        store.getState { state in
            guard state.isEnabled else { return }
            
            var identities: [ASPasswordCredentialIdentity] = []
            
            for credential in credentials {
                let domain = credential.websiteURL ?? credential.websiteName.lowercased()
                let normalizedDomain = self.normalizeDomain(domain)
                
                let serviceID = ASCredentialServiceIdentifier(
                    identifier: normalizedDomain,
                    type: .domain
                )
                
                identities.append(ASPasswordCredentialIdentity(
                    serviceIdentifier: serviceID,
                    user: credential.username,
                    recordIdentifier: credential.id.uuidString
                ))
            }
            
            // Use new async API
            Task {
                do {
                    try await store.replaceCredentialIdentities(identities)
                } catch {
                    print("❌ Failed to register AutoFill identities: \(error)")
                }
            }
        }
    }
    
    private func normalizeDomain(_ domain: String) -> String {
        var normalized = domain
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .replacingOccurrences(of: "www.", with: "")
        
        if let slashIndex = normalized.firstIndex(of: "/") {
            normalized = String(normalized[..<slashIndex])
        }
        
        return normalized
    }
    
    // MARK: - Single Credential Operations
    
    func fetchCredential(byId id: UUID) throws -> Credential? {
        let allCredentials = try fetchAllCredentials()
        return allCredentials.first { $0.id == id }
    }
    
    func saveCredential(_ credential: Credential) throws {
        var credentials = try fetchAllCredentials()
        
        if let index = credentials.firstIndex(where: { $0.id == credential.id }) {
            credentials[index] = credential
        } else {
            credentials.append(credential)
        }
        
        try saveCredentials(credentials)
    }
    
    func deleteCredential(id: UUID) throws {
        var credentials = try fetchAllCredentials()
        credentials.removeAll { $0.id == id }
        try saveCredentials(credentials)
    }
    
    // MARK: - Domain Matching (for AutoFill Extension)
    
    func fetchCredentials(matchingDomain domain: String, limit: Int = 50) throws -> [Credential] {
        let allCredentials = try fetchAllCredentials()
        
        if domain.isEmpty {
            return Array(allCredentials.prefix(limit))
        }
        
        let normalizedDomain = normalizeDomain(domain)
        
        let matched = allCredentials.filter { credential in
            let credDomain = normalizeDomain(credential.websiteURL ?? credential.websiteName)
            return credDomain.contains(normalizedDomain) || normalizedDomain.contains(credDomain)
        }
        
        if matched.isEmpty {
            return Array(allCredentials.prefix(limit))
        }
        
        return Array(matched.prefix(limit))
    }
    
    // MARK: - Migration (for API compatibility)
    
    func migrateFromInsecureStorage() {
        // No-op: All data is now in Keychain only
    }
    
    // MARK: - Delete All Data
    
    func deleteAllData() throws {
        try deleteFromKeychain(account: credentialsAccount)
        try deleteFromKeychain(account: secureNotesAccount)
        try deleteFromKeychain(account: creditCardsAccount)
        try deleteFromKeychain(account: encryptionKeyAccount)
        
        Task {
            do {
                try await ASCredentialIdentityStore.shared.removeAllCredentialIdentities()
            } catch {
                print("❌ Failed to clear AutoFill identities: \(error)")
            }
        }
    }
}

// NOTE: KeychainError is defined in KeychainService.swift
