//
//  iCloudSyncManager.swift
//  PasswordVault
//
//  Created by AI Assistant on 15/12/2025.
//  Feature 6: iCloud Sync across iPhone, iPad, Mac
//

import Foundation
import CloudKit
import SwiftUI

/// Manages iCloud synchronization for PasswordVault data
@Observable
final class iCloudSyncManager {
    
    // MARK: - Configuration
    
    private let containerIdentifier = "iCloud.co.uk.techjonesai.PasswordVault"
    private let recordZoneName = "PasswordVaultZone"
    
    // Keys
    private let iCloudEnabledKey = "icloud_sync_enabled"
    private let lastSyncDateKey = "last_icloud_sync_date"
    private let syncTokenKey = "icloud_sync_token"
    
    // Record Types
    private let credentialRecordType = "Credential"
    private let secureNoteRecordType = "SecureNote"
    private let creditCardRecordType = "CreditCard"
    
    // MARK: - State
    
    var isSyncEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(isSyncEnabled, forKey: iCloudEnabledKey)
            if isSyncEnabled {
                setupCloudKit()
            }
        }
    }
    
    var isSyncing: Bool = false
    var lastSyncDate: Date?
    var syncError: String?
    var cloudStatus: CloudStatus = .unknown
    
    // CloudKit objects
    private var container: CKContainer?
    private var privateDatabase: CKDatabase?
    private var recordZone: CKRecordZone?
    private var zoneID: CKRecordZone.ID?
    
    // MARK: - Cloud Status
    
    enum CloudStatus: String {
        case available = "Available"
        case noAccount = "No iCloud Account"
        case restricted = "Restricted"
        case couldNotDetermine = "Could Not Determine"
        case unknown = "Checking..."
        
        var icon: String {
            switch self {
            case .available: return "checkmark.icloud.fill"
            case .noAccount: return "xmark.icloud"
            case .restricted: return "exclamationmark.icloud"
            case .couldNotDetermine: return "questionmark.circle"
            case .unknown: return "icloud"
            }
        }
        
        var color: Color {
            switch self {
            case .available: return .green
            case .noAccount, .restricted: return .red
            case .couldNotDetermine, .unknown: return .orange
            }
        }
    }
    
    // MARK: - App Group UserDefaults
    
    private var appGroupDefaults: UserDefaults {
        UserDefaults(suiteName: "group.co.uk.techjonesai.PasswordVaultShared") ?? .standard
    }
    
    // MARK: - Init
    
    init() {
        loadSettings()
        checkiCloudStatus()
        
        if isSyncEnabled {
            setupCloudKit()
        }
    }
    
    // MARK: - Settings
    
    private func loadSettings() {
        isSyncEnabled = UserDefaults.standard.bool(forKey: iCloudEnabledKey)
        
        if let lastSync = UserDefaults.standard.object(forKey: lastSyncDateKey) as? Date {
            lastSyncDate = lastSync
        }
    }
    
    // MARK: - iCloud Status Check
    
    func checkiCloudStatus() {
        cloudStatus = .unknown
        
        CKContainer.default().accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ iCloud status error: \(error)")
                    self?.cloudStatus = .couldNotDetermine
                    return
                }
                
                switch status {
                case .available:
                    self?.cloudStatus = .available
                case .noAccount:
                    self?.cloudStatus = .noAccount
                case .restricted:
                    self?.cloudStatus = .restricted
                case .couldNotDetermine:
                    self?.cloudStatus = .couldNotDetermine
                case .temporarilyUnavailable:
                    self?.cloudStatus = .couldNotDetermine
                @unknown default:
                    self?.cloudStatus = .unknown
                }
            }
        }
    }
    
    // MARK: - CloudKit Setup
    
    private func setupCloudKit() {
        container = CKContainer(identifier: containerIdentifier)
        privateDatabase = container?.privateCloudDatabase
        zoneID = CKRecordZone.ID(zoneName: recordZoneName, ownerName: CKCurrentUserDefaultName)
        recordZone = CKRecordZone(zoneID: zoneID!)
        
        // Create custom zone if needed
        createCustomZoneIfNeeded()
        
        // Subscribe to changes
        subscribeToChanges()
    }
    
    private func createCustomZoneIfNeeded() {
        guard let zone = recordZone, let database = privateDatabase else { return }
        
        let operation = CKModifyRecordZonesOperation(recordZonesToSave: [zone], recordZoneIDsToDelete: nil)
        
        operation.modifyRecordZonesResultBlock = { result in
            switch result {
            case .success:
                print("✅ iCloud zone created/verified")
            case .failure(let error):
                print("⚠️ iCloud zone creation: \(error.localizedDescription)")
                // Zone might already exist, which is fine
            }
        }
        
        database.add(operation)
    }
    
    // MARK: - Subscriptions
    
    private func subscribeToChanges() {
        guard let database = privateDatabase, let zoneID = zoneID else { return }
        
        let subscriptionID = "vault-changes-subscription"
        
        // Create subscription for database changes
        let subscription = CKDatabaseSubscription(subscriptionID: subscriptionID)
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo
        
        database.save(subscription) { _, error in
            if let error = error {
                let ckError = error as? CKError
                // Subscription might already exist
                if ckError?.code != .serverRecordChanged {
                    print("⚠️ Subscription error: \(error.localizedDescription)")
                }
            } else {
                print("✅ Subscribed to iCloud changes")
            }
        }
    }
    
    // MARK: - Sync Operations
    
    /// Perform a full sync (upload local changes, download remote changes)
    func performSync(credentials: [Credential], notes: [SecureNote], cards: [CreditCard]) async throws -> SyncResult {
        guard isSyncEnabled else {
            throw SyncError.syncDisabled
        }
        
        guard cloudStatus == .available else {
            throw SyncError.iCloudUnavailable
        }
        
        guard let database = privateDatabase, let zoneID = zoneID else {
            throw SyncError.notConfigured
        }
        
        await MainActor.run {
            isSyncing = true
            syncError = nil
        }
        
        defer {
            Task { @MainActor in
                isSyncing = false
            }
        }
        
        do {
            // Upload local data
            try await uploadCredentials(credentials, to: database)
            try await uploadSecureNotes(notes, to: database)
            try await uploadCreditCards(cards, to: database)
            
            // Download remote data
            let remoteCredentials = try await fetchCredentials(from: database)
            let remoteNotes = try await fetchSecureNotes(from: database)
            let remoteCards = try await fetchCreditCards(from: database)
            
            // Update last sync date
            await MainActor.run {
                lastSyncDate = Date()
                UserDefaults.standard.set(lastSyncDate, forKey: lastSyncDateKey)
            }
            
            return SyncResult(
                credentials: mergeCredentials(local: credentials, remote: remoteCredentials),
                notes: mergeNotes(local: notes, remote: remoteNotes),
                cards: mergeCards(local: cards, remote: remoteCards)
            )
            
        } catch {
            await MainActor.run {
                syncError = error.localizedDescription
            }
            throw error
        }
    }
    
    // MARK: - Upload Operations
    
    private func uploadCredentials(_ credentials: [Credential], to database: CKDatabase) async throws {
        guard let zoneID = zoneID else { return }
        
        var recordsToSave: [CKRecord] = []
        
        for credential in credentials {
            let recordID = CKRecord.ID(recordName: credential.id.uuidString, zoneID: zoneID)
            let record = CKRecord(recordType: credentialRecordType, recordID: recordID)
            
            record["websiteName"] = credential.websiteName
            record["websiteURL"] = credential.websiteURL
            record["username"] = credential.username
            record["password"] = credential.password // Note: In production, encrypt this!
            record["notes"] = credential.notes
            record["createdDate"] = credential.createdDate
            record["lastModifiedDate"] = credential.lastModifiedDate
            record["folder"] = credential.folder?.rawValue
            record["isFavourite"] = credential.isFavourite ? 1 : 0
            record["passwordLastChanged"] = credential.passwordLastChanged
            record["expiryReminderDays"] = credential.expiryReminderDays
            
            recordsToSave.append(record)
        }
        
        try await saveRecords(recordsToSave, to: database)
    }
    
    private func uploadSecureNotes(_ notes: [SecureNote], to database: CKDatabase) async throws {
        guard let zoneID = zoneID else { return }
        
        var recordsToSave: [CKRecord] = []
        
        for note in notes {
            let recordID = CKRecord.ID(recordName: note.id.uuidString, zoneID: zoneID)
            let record = CKRecord(recordType: secureNoteRecordType, recordID: recordID)
            
            record["title"] = note.title
            record["content"] = note.content
            record["folder"] = note.folder?.rawValue
            record["isFavourite"] = note.isFavourite ? 1 : 0
            record["createdDate"] = note.createdDate
            record["lastModifiedDate"] = note.lastModifiedDate
            
            recordsToSave.append(record)
        }
        
        try await saveRecords(recordsToSave, to: database)
    }
    
    private func uploadCreditCards(_ cards: [CreditCard], to database: CKDatabase) async throws {
        guard let zoneID = zoneID else { return }
        
        var recordsToSave: [CKRecord] = []
        
        for card in cards {
            let recordID = CKRecord.ID(recordName: card.id.uuidString, zoneID: zoneID)
            let record = CKRecord(recordType: creditCardRecordType, recordID: recordID)
            
            record["cardName"] = card.cardName
            record["cardholderName"] = card.cardholderName
            record["cardNumber"] = card.cardNumber // Note: In production, encrypt this!
            record["expiryMonth"] = card.expiryMonth
            record["expiryYear"] = card.expiryYear
            record["cvv"] = card.cvv // Note: In production, encrypt this!
            record["cardType"] = card.cardType.rawValue
            record["billingAddress"] = card.billingAddress
            record["notes"] = card.notes
            record["isFavourite"] = card.isFavourite ? 1 : 0
            record["createdDate"] = card.createdDate
            record["lastModifiedDate"] = card.lastModifiedDate
            
            recordsToSave.append(record)
        }
        
        try await saveRecords(recordsToSave, to: database)
    }
    
    private func saveRecords(_ records: [CKRecord], to database: CKDatabase) async throws {
        guard !records.isEmpty else { return }
        
        return try await withCheckedThrowingContinuation { continuation in
            let operation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
            operation.savePolicy = .changedKeys
            
            operation.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            database.add(operation)
        }
    }
    
    // MARK: - Fetch Operations
    
    private func fetchCredentials(from database: CKDatabase) async throws -> [Credential] {
        guard let zoneID = zoneID else { return [] }
        
        let query = CKQuery(recordType: credentialRecordType, predicate: NSPredicate(value: true))
        
        return try await withCheckedThrowingContinuation { continuation in
            database.perform(query, inZoneWith: zoneID) { records, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let credentials = (records ?? []).compactMap { record -> Credential? in
                    guard let id = UUID(uuidString: record.recordID.recordName) else { return nil }
                    
                    let folderRaw = record["folder"] as? String
                    let folder = folderRaw.flatMap { PasswordFolder(rawValue: $0) }
                    
                    return Credential(
                        id: id,
                        websiteName: record["websiteName"] as? String ?? "",
                        websiteURL: record["websiteURL"] as? String,
                        username: record["username"] as? String ?? "",
                        password: record["password"] as? String ?? "",
                        notes: record["notes"] as? String,
                        createdDate: record["createdDate"] as? Date ?? Date(),
                        lastModifiedDate: record["lastModifiedDate"] as? Date ?? Date(),
                        folder: folder,
                        isFavourite: (record["isFavourite"] as? Int ?? 0) == 1,
                        passwordLastChanged: record["passwordLastChanged"] as? Date,
                        expiryReminderDays: record["expiryReminderDays"] as? Int
                    )
                }
                
                continuation.resume(returning: credentials)
            }
        }
    }
    
    private func fetchSecureNotes(from database: CKDatabase) async throws -> [SecureNote] {
        guard let zoneID = zoneID else { return [] }
        
        let query = CKQuery(recordType: secureNoteRecordType, predicate: NSPredicate(value: true))
        
        return try await withCheckedThrowingContinuation { continuation in
            database.perform(query, inZoneWith: zoneID) { records, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let notes = (records ?? []).compactMap { record -> SecureNote? in
                    guard let id = UUID(uuidString: record.recordID.recordName) else { return nil }
                    
                    let folderRaw = record["folder"] as? String
                    let folder = folderRaw.flatMap { PasswordFolder(rawValue: $0) }
                    
                    return SecureNote(
                        id: id,
                        title: record["title"] as? String ?? "",
                        content: record["content"] as? String ?? "",
                        folder: folder,
                        isFavourite: (record["isFavourite"] as? Int ?? 0) == 1,
                        createdDate: record["createdDate"] as? Date ?? Date(),
                        lastModifiedDate: record["lastModifiedDate"] as? Date ?? Date()
                    )
                }
                
                continuation.resume(returning: notes)
            }
        }
    }
    
    private func fetchCreditCards(from database: CKDatabase) async throws -> [CreditCard] {
        guard let zoneID = zoneID else { return [] }
        
        let query = CKQuery(recordType: creditCardRecordType, predicate: NSPredicate(value: true))
        
        return try await withCheckedThrowingContinuation { continuation in
            database.perform(query, inZoneWith: zoneID) { records, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let cards = (records ?? []).compactMap { record -> CreditCard? in
                    guard let id = UUID(uuidString: record.recordID.recordName) else { return nil }
                    
                    let cardTypeRaw = record["cardType"] as? String ?? ""
                    let cardType = CardType(rawValue: cardTypeRaw) ?? .unknown
                    
                    return CreditCard(
                        id: id,
                        cardName: record["cardName"] as? String ?? "",
                        cardholderName: record["cardholderName"] as? String ?? "",
                        cardNumber: record["cardNumber"] as? String ?? "",
                        expiryMonth: record["expiryMonth"] as? Int ?? 1,
                        expiryYear: record["expiryYear"] as? Int ?? 2025,
                        cvv: record["cvv"] as? String ?? "",
                        cardType: cardType,
                        billingAddress: record["billingAddress"] as? String,
                        notes: record["notes"] as? String,
                        isFavourite: (record["isFavourite"] as? Int ?? 0) == 1,
                        createdDate: record["createdDate"] as? Date ?? Date(),
                        lastModifiedDate: record["lastModifiedDate"] as? Date ?? Date()
                    )
                }
                
                continuation.resume(returning: cards)
            }
        }
    }
    
    // MARK: - Merge Operations (Last-Write-Wins)
    
    private func mergeCredentials(local: [Credential], remote: [Credential]) -> [Credential] {
        var merged: [UUID: Credential] = [:]
        
        // Add all local
        for cred in local {
            merged[cred.id] = cred
        }
        
        // Merge remote (newer wins)
        for remoteCred in remote {
            if let existing = merged[remoteCred.id] {
                if remoteCred.lastModifiedDate > existing.lastModifiedDate {
                    merged[remoteCred.id] = remoteCred
                }
            } else {
                merged[remoteCred.id] = remoteCred
            }
        }
        
        return Array(merged.values).sorted { $0.websiteName < $1.websiteName }
    }
    
    private func mergeNotes(local: [SecureNote], remote: [SecureNote]) -> [SecureNote] {
        var merged: [UUID: SecureNote] = [:]
        
        for note in local {
            merged[note.id] = note
        }
        
        for remoteNote in remote {
            if let existing = merged[remoteNote.id] {
                if remoteNote.lastModifiedDate > existing.lastModifiedDate {
                    merged[remoteNote.id] = remoteNote
                }
            } else {
                merged[remoteNote.id] = remoteNote
            }
        }
        
        return Array(merged.values).sorted { $0.title < $1.title }
    }
    
    private func mergeCards(local: [CreditCard], remote: [CreditCard]) -> [CreditCard] {
        var merged: [UUID: CreditCard] = [:]
        
        for card in local {
            merged[card.id] = card
        }
        
        for remoteCard in remote {
            if let existing = merged[remoteCard.id] {
                if remoteCard.lastModifiedDate > existing.lastModifiedDate {
                    merged[remoteCard.id] = remoteCard
                }
            } else {
                merged[remoteCard.id] = remoteCard
            }
        }
        
        return Array(merged.values).sorted { $0.cardName < $1.cardName }
    }
    
    // MARK: - Delete from iCloud
    
    func deleteCredential(_ credential: Credential) async throws {
        guard isSyncEnabled, let database = privateDatabase, let zoneID = zoneID else { return }
        
        let recordID = CKRecord.ID(recordName: credential.id.uuidString, zoneID: zoneID)
        try await database.deleteRecord(withID: recordID)
    }
    
    func deleteSecureNote(_ note: SecureNote) async throws {
        guard isSyncEnabled, let database = privateDatabase, let zoneID = zoneID else { return }
        
        let recordID = CKRecord.ID(recordName: note.id.uuidString, zoneID: zoneID)
        try await database.deleteRecord(withID: recordID)
    }
    
    func deleteCreditCard(_ card: CreditCard) async throws {
        guard isSyncEnabled, let database = privateDatabase, let zoneID = zoneID else { return }
        
        let recordID = CKRecord.ID(recordName: card.id.uuidString, zoneID: zoneID)
        try await database.deleteRecord(withID: recordID)
    }
    
    // MARK: - Sync Result
    
    struct SyncResult {
        let credentials: [Credential]
        let notes: [SecureNote]
        let cards: [CreditCard]
    }
    
    // MARK: - Errors
    
    enum SyncError: LocalizedError {
        case syncDisabled
        case iCloudUnavailable
        case notConfigured
        case uploadFailed
        case fetchFailed
        
        var errorDescription: String? {
            switch self {
            case .syncDisabled:
                return "iCloud Sync is disabled"
            case .iCloudUnavailable:
                return "iCloud is not available. Please sign in to iCloud in Settings."
            case .notConfigured:
                return "iCloud is not properly configured"
            case .uploadFailed:
                return "Failed to upload data to iCloud"
            case .fetchFailed:
                return "Failed to fetch data from iCloud"
            }
        }
    }
}
