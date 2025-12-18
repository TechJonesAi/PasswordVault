//
//  KeychainService.swift
//  PasswordVault
//
//  Created by AI Assistant on 05/12/2025.
//  ENHANCED: Smart URL matching, Secure Notes, Credit Cards storage
//

import Foundation
import Security
import AuthenticationServices

/// Errors that can occur during keychain operations
enum KeychainError: Error, LocalizedError {
    case encodingFailed
    case decodingFailed
    case saveFailed(status: OSStatus)
    case loadFailed(status: OSStatus)
    case deleteFailed(status: OSStatus)
    case notFound
    
    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode data"
        case .decodingFailed:
            return "Failed to decode data"
        case .saveFailed(let status):
            return "Failed to save to keychain (status: \(status))"
        case .loadFailed(let status):
            return "Failed to load from keychain (status: \(status))"
        case .deleteFailed(let status):
            return "Failed to delete from keychain (status: \(status))"
        case .notFound:
            return "Item not found in keychain"
        }
    }
}

/// Service for securely storing and retrieving data from iOS Keychain
final class KeychainService {
    
    // MARK: - Shared Storage Keys
    
    /// App Group for UserDefaults sharing (works reliably between app and extension)
    private let appGroupID = "group.co.uk.techjonesai.PasswordVaultShared"
    
    /// Keys for storing different types of data
    private let credentialsKey = "vault_credentials_v2"
    private let premiumStatusKey = "premium_status_v2"
    private let secureNotesKey = "vault_secure_notes_v1"
    private let creditCardsKey = "vault_credit_cards_v1"
    
    /// Shared UserDefaults - PRIMARY storage for extension compatibility
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }
    
    // MARK: - Known App Bundle ID to Domain Mappings
    
    /// Maps app bundle IDs to their associated domains
    private let appBundleToDomain: [String: [String]] = [
        "com.google": ["google.com", "gmail.com", "youtube.com"],
        "com.facebook": ["facebook.com", "fb.com"],
        "com.twitter": ["twitter.com", "x.com"],
        "com.instagram": ["instagram.com"],
        "com.linkedin": ["linkedin.com"],
        "com.amazon": ["amazon.com", "amazon.co.uk"],
        "com.netflix": ["netflix.com"],
        "com.spotify": ["spotify.com"],
        "com.apple": ["apple.com", "icloud.com"],
        "com.microsoft": ["microsoft.com", "outlook.com", "live.com", "hotmail.com"],
        "com.dropbox": ["dropbox.com"],
        "com.slack": ["slack.com"],
        "com.zoom": ["zoom.us"],
        "com.tiktok": ["tiktok.com"],
        "com.snapchat": ["snapchat.com"],
        "com.pinterest": ["pinterest.com"],
        "com.reddit": ["reddit.com"],
        "com.github": ["github.com"],
        "com.paypal": ["paypal.com"],
        "com.ebay": ["ebay.com", "ebay.co.uk"],
    ]
    
    // MARK: - Domain Aliases
    
    private let domainAliases: [String: [String]] = [
        "google": ["google.com", "gmail.com", "accounts.google.com", "mail.google.com", "drive.google.com", "docs.google.com", "youtube.com"],
        "facebook": ["facebook.com", "fb.com", "messenger.com", "instagram.com"],
        "microsoft": ["microsoft.com", "outlook.com", "live.com", "hotmail.com", "office.com", "office365.com", "onedrive.com"],
        "apple": ["apple.com", "icloud.com", "me.com", "mac.com"],
        "amazon": ["amazon.com", "amazon.co.uk", "amazon.de", "amazon.fr", "aws.amazon.com", "prime.amazon.com"],
        "twitter": ["twitter.com", "x.com"],
        "yahoo": ["yahoo.com", "yahoo.co.uk", "ymail.com"],
    ]
    
    // MARK: - Credentials Storage
    
    func saveCredentials(_ credentials: [Credential]) throws {
        guard let defaults = sharedDefaults else {
            print("❌ Failed to access shared UserDefaults")
            throw KeychainError.saveFailed(status: -1)
        }
        
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(credentials) else {
            throw KeychainError.encodingFailed
        }
        
        defaults.set(data, forKey: credentialsKey)
        defaults.synchronize()
        
        print("✅ Saved \(credentials.count) credentials to App Group")
        
        registerCredentialsWithAutoFill(credentials)
    }
    
    func fetchAllCredentials() throws -> [Credential] {
        guard let defaults = sharedDefaults else {
            print("❌ Failed to access shared UserDefaults")
            return []
        }
        
        guard let data = defaults.data(forKey: credentialsKey) else {
            print("ℹ️ No credentials found in App Group")
            return []
        }
        
        let decoder = JSONDecoder()
        guard let credentials = try? decoder.decode([Credential].self, from: data) else {
            print("❌ Failed to decode credentials")
            throw KeychainError.decodingFailed
        }
        
        print("✅ Loaded \(credentials.count) credentials from App Group")
        return credentials
    }
    
    func fetchCredentials(matchingDomain domain: String, limit: Int = 50) throws -> [Credential] {
        let allCredentials = try fetchAllCredentials()
        
        if allCredentials.isEmpty {
            print("ℹ️ No credentials stored")
            return []
        }
        
        if domain.isEmpty {
            print("ℹ️ No domain specified, returning all \(allCredentials.count) credentials")
            return Array(allCredentials.prefix(limit))
        }
        
        let normalizedDomain = normalizeDomain(domain)
        let baseDomain = extractBaseDomain(from: normalizedDomain)
        let relatedDomains = getRelatedDomains(for: normalizedDomain)
        
        print("🔍 Searching for domain: \(normalizedDomain)")
        
        var scoredCredentials: [(credential: Credential, score: Int)] = []
        
        for credential in allCredentials {
            let score = calculateMatchScore(
                credential: credential,
                searchDomain: normalizedDomain,
                baseDomain: baseDomain,
                relatedDomains: relatedDomains
            )
            
            if score > 0 {
                scoredCredentials.append((credential, score))
            }
        }
        
        let matched = scoredCredentials
            .sorted { $0.score > $1.score }
            .map { $0.credential }
        
        if matched.isEmpty {
            print("⚠️ No domain matches, showing all \(allCredentials.count) credentials")
            return Array(allCredentials.prefix(limit))
        }
        
        print("✅ Found \(matched.count) matching credentials for \(normalizedDomain)")
        return Array(matched.prefix(limit))
    }
    
    // MARK: - Secure Notes Storage (Feature 4)
    
    func saveSecureNotes(_ notes: [SecureNote]) {
        guard let defaults = sharedDefaults else {
            print("❌ Failed to access shared UserDefaults for notes")
            return
        }
        
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(notes) else {
            print("❌ Failed to encode notes")
            return
        }
        
        defaults.set(data, forKey: secureNotesKey)
        defaults.synchronize()
        print("✅ Saved \(notes.count) secure notes")
    }
    
    func fetchSecureNotes() -> [SecureNote] {
        guard let defaults = sharedDefaults else {
            print("❌ Failed to access shared UserDefaults for notes")
            return []
        }
        
        guard let data = defaults.data(forKey: secureNotesKey) else {
            return []
        }
        
        let decoder = JSONDecoder()
        guard let notes = try? decoder.decode([SecureNote].self, from: data) else {
            print("❌ Failed to decode notes")
            return []
        }
        
        return notes
    }
    
    // MARK: - Credit Cards Storage (Feature 7)
    
    func saveCreditCards(_ cards: [CreditCard]) {
        guard let defaults = sharedDefaults else {
            print("❌ Failed to access shared UserDefaults for cards")
            return
        }
        
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(cards) else {
            print("❌ Failed to encode cards")
            return
        }
        
        defaults.set(data, forKey: creditCardsKey)
        defaults.synchronize()
        print("✅ Saved \(cards.count) credit cards")
    }
    
    func fetchCreditCards() -> [CreditCard] {
        guard let defaults = sharedDefaults else {
            print("❌ Failed to access shared UserDefaults for cards")
            return []
        }
        
        guard let data = defaults.data(forKey: creditCardsKey) else {
            return []
        }
        
        let decoder = JSONDecoder()
        guard let cards = try? decoder.decode([CreditCard].self, from: data) else {
            print("❌ Failed to decode cards")
            return []
        }
        
        return cards
    }
    
    // MARK: - Smart Matching Helpers
    
    private func normalizeDomain(_ domain: String) -> String {
        var normalized = domain
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        normalized = normalized
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
        
        normalized = normalized.replacingOccurrences(of: "www.", with: "")
        
        if let slashIndex = normalized.firstIndex(of: "/") {
            normalized = String(normalized[..<slashIndex])
        }
        if let questionIndex = normalized.firstIndex(of: "?") {
            normalized = String(normalized[..<questionIndex])
        }
        
        return normalized
    }
    
    private func extractBaseDomain(from domain: String) -> String {
        let parts = domain.components(separatedBy: ".")
        
        let commonSecondLevelTLDs = ["co.uk", "com.au", "co.jp"]
        
        if parts.count >= 3 {
            let lastTwo = "\(parts[parts.count - 2]).\(parts[parts.count - 1])"
            if commonSecondLevelTLDs.contains(lastTwo) {
                return parts.count >= 3 ? parts[parts.count - 3] : domain
            }
        }
        
        if parts.count >= 2 {
            return parts[parts.count - 2]
        }
        
        return domain
    }
    
    private func getRelatedDomains(for domain: String) -> Set<String> {
        var related = Set<String>()
        let baseDomain = extractBaseDomain(from: domain)
        
        for (key, aliases) in domainAliases {
            if key == baseDomain || aliases.contains(where: { $0.contains(baseDomain) || baseDomain.contains(extractBaseDomain(from: $0)) }) {
                related.formUnion(aliases)
            }
        }
        
        for (bundlePrefix, domains) in appBundleToDomain {
            if domain.contains(bundlePrefix) || domains.contains(where: { $0.contains(baseDomain) }) {
                related.formUnion(domains)
            }
        }
        
        return related
    }
    
    private func calculateMatchScore(
        credential: Credential,
        searchDomain: String,
        baseDomain: String,
        relatedDomains: Set<String>
    ) -> Int {
        var score = 0
        
        let credentialName = credential.websiteName.lowercased()
        let credentialURL = normalizeDomain(credential.websiteURL ?? "")
        let credentialBaseDomain = extractBaseDomain(from: credentialURL.isEmpty ? credentialName : credentialURL)
        
        if credentialURL == searchDomain {
            score += 100
        }
        
        if credentialBaseDomain == baseDomain {
            score += 80
        }
        
        if credentialName == baseDomain || credentialName.contains(baseDomain) || baseDomain.contains(credentialName) {
            score += 70
        }
        
        if relatedDomains.contains(credentialURL) || relatedDomains.contains(where: { $0.contains(credentialBaseDomain) }) {
            score += 60
        }
        
        if credentialURL.contains(baseDomain) || baseDomain.contains(credentialBaseDomain) {
            score += 40
        }
        
        if credentialName.contains(baseDomain) || baseDomain.contains(credentialName) {
            score += 30
        }
        
        return score
    }
    
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
    
    // MARK: - Premium Status Storage
    
    func savePremiumStatus(_ isPremium: Bool) throws {
        sharedDefaults?.set(isPremium, forKey: premiumStatusKey)
        sharedDefaults?.synchronize()
        print("✅ Saved premium status: \(isPremium)")
    }
    
    func fetchPremiumStatus() throws -> Bool {
        return sharedDefaults?.bool(forKey: premiumStatusKey) ?? false
    }
    
    func isPremium() -> Bool {
        return sharedDefaults?.bool(forKey: premiumStatusKey) ?? false
    }
    
    // MARK: - AutoFill Registration
    
    private func registerCredentialsWithAutoFill(_ credentials: [Credential]) {
        let store = ASCredentialIdentityStore.shared
        
        store.getState { [weak self] state in
            guard let self = self else { return }
            guard state.isEnabled else {
                print("⚠️ AutoFill not enabled in Settings")
                return
            }
            
            var identities: [ASPasswordCredentialIdentity] = []
            
            for credential in credentials {
                let primaryDomain = credential.websiteURL ?? credential.websiteName.lowercased()
                let normalizedPrimary = self.normalizeDomain(primaryDomain)
                let baseDomain = self.extractBaseDomain(from: normalizedPrimary)
                
                let primaryServiceID = ASCredentialServiceIdentifier(
                    identifier: normalizedPrimary.isEmpty ? credential.websiteName.lowercased() : normalizedPrimary,
                    type: .domain
                )
                identities.append(ASPasswordCredentialIdentity(
                    serviceIdentifier: primaryServiceID,
                    user: credential.username,
                    recordIdentifier: credential.id.uuidString
                ))
                
                if baseDomain != normalizedPrimary && !baseDomain.isEmpty {
                    let baseServiceID = ASCredentialServiceIdentifier(
                        identifier: baseDomain,
                        type: .domain
                    )
                    identities.append(ASPasswordCredentialIdentity(
                        serviceIdentifier: baseServiceID,
                        user: credential.username,
                        recordIdentifier: credential.id.uuidString
                    ))
                }
                
                let relatedDomains = self.getRelatedDomains(for: normalizedPrimary)
                for relatedDomain in relatedDomains.prefix(5) {
                    let relatedServiceID = ASCredentialServiceIdentifier(
                        identifier: relatedDomain,
                        type: .domain
                    )
                    identities.append(ASPasswordCredentialIdentity(
                        serviceIdentifier: relatedServiceID,
                        user: credential.username,
                        recordIdentifier: credential.id.uuidString
                    ))
                }
            }
            
            store.replaceCredentialIdentities(with: identities) { success, error in
                if let error = error {
                    print("❌ Failed to register AutoFill identities: \(error)")
                } else {
                    print("✅ Registered \(identities.count) identities for \(credentials.count) credentials with AutoFill")
                }
            }
        }
    }
    
    // MARK: - Delete All Data
    
    func deleteAllData() throws {
        sharedDefaults?.removeObject(forKey: credentialsKey)
        sharedDefaults?.removeObject(forKey: premiumStatusKey)
        sharedDefaults?.removeObject(forKey: secureNotesKey)
        sharedDefaults?.removeObject(forKey: creditCardsKey)
        sharedDefaults?.synchronize()
        
        ASCredentialIdentityStore.shared.removeAllCredentialIdentities { success, error in
            if let error = error {
                print("❌ Failed to clear AutoFill identities: \(error)")
            } else {
                print("✅ Cleared all AutoFill identities")
            }
        }
        
        print("✅ Deleted all data from App Group")
    }
    
    // MARK: - Debug Helpers
    
    func debugPrintCredentials() {
        do {
            let credentials = try fetchAllCredentials()
            print("📦 Stored credentials (\(credentials.count)):")
            for (index, cred) in credentials.enumerated() {
                print("  \(index + 1). \(cred.websiteName) - \(cred.username)")
            }
        } catch {
            print("❌ Debug print failed: \(error)")
        }
    }
}
