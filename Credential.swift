//
//  Credential.swift
//  PasswordVault
//
//  Created by AI Assistant on 05/12/2025.
//  ENHANCED: Added folders, favourites, expiry reminders, and AI-powered features
//

import Foundation

/// Represents a stored password credential
struct Credential: Identifiable, Codable {
    let id: UUID
    var websiteName: String      // "Gmail", "Facebook"
    var websiteURL: String?      // "gmail.com"
    var username: String         // "user@example.com"
    var password: String         // "SecurePass123!"
    var notes: String?           // Optional notes
    var createdDate: Date
    var lastModifiedDate: Date
    
    // NEW: Feature 2 - Folders/Categories
    var folder: PasswordFolder?
    
    // NEW: Feature 3 - Favourites
    var isFavourite: Bool
    
    // NEW: Feature 9 - Password Expiry
    var passwordLastChanged: Date
    var expiryReminderDays: Int?  // nil = no reminder, otherwise days until reminder
    
    // NEW: Custom icon (for Feature 8 - future app customisation)
    var customIconName: String?
    
    // MARK: - Coding Keys
    
    enum CodingKeys: String, CodingKey {
        case id
        case websiteName
        case websiteURL
        case username
        case password
        case notes
        case createdDate
        case lastModifiedDate
        case folder
        case isFavourite
        case passwordLastChanged
        case expiryReminderDays
        case customIconName
    }
    
    // MARK: - Custom Decoder (handles old data without new fields)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Required fields
        id = try container.decode(UUID.self, forKey: .id)
        websiteName = try container.decode(String.self, forKey: .websiteName)
        username = try container.decode(String.self, forKey: .username)
        password = try container.decode(String.self, forKey: .password)
        createdDate = try container.decode(Date.self, forKey: .createdDate)
        lastModifiedDate = try container.decode(Date.self, forKey: .lastModifiedDate)
        
        // Optional fields (always optional)
        websiteURL = try container.decodeIfPresent(String.self, forKey: .websiteURL)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        
        // NEW fields with defaults for backward compatibility
        folder = try container.decodeIfPresent(PasswordFolder.self, forKey: .folder)
        isFavourite = try container.decodeIfPresent(Bool.self, forKey: .isFavourite) ?? false
        passwordLastChanged = try container.decodeIfPresent(Date.self, forKey: .passwordLastChanged) ?? createdDate
        expiryReminderDays = try container.decodeIfPresent(Int.self, forKey: .expiryReminderDays)
        customIconName = try container.decodeIfPresent(String.self, forKey: .customIconName)
    }
    
    init(
        id: UUID = UUID(),
        websiteName: String,
        websiteURL: String? = nil,
        username: String,
        password: String,
        notes: String? = nil,
        createdDate: Date = Date(),
        lastModifiedDate: Date = Date(),
        folder: PasswordFolder? = nil,
        isFavourite: Bool = false,
        passwordLastChanged: Date? = nil,
        expiryReminderDays: Int? = nil,
        customIconName: String? = nil
    ) {
        self.id = id
        self.websiteName = websiteName
        self.websiteURL = websiteURL
        self.username = username
        self.password = password
        self.notes = notes
        self.createdDate = createdDate
        self.lastModifiedDate = lastModifiedDate
        self.folder = folder
        self.isFavourite = isFavourite
        self.passwordLastChanged = passwordLastChanged ?? createdDate
        self.expiryReminderDays = expiryReminderDays
        self.customIconName = customIconName
    }
    
    // MARK: - Password Age
    
    /// Days since password was last changed
    var passwordAgeDays: Int {
        Calendar.current.dateComponents([.day], from: passwordLastChanged, to: Date()).day ?? 0
    }
    
    /// Check if password expiry reminder is due
    var isExpiryReminderDue: Bool {
        guard let reminderDays = expiryReminderDays else { return false }
        return passwordAgeDays >= reminderDays
    }
    
    /// Human readable password age
    var passwordAgeDescription: String {
        let days = passwordAgeDays
        if days == 0 {
            return "Changed today"
        } else if days == 1 {
            return "Changed yesterday"
        } else if days < 30 {
            return "Changed \(days) days ago"
        } else if days < 365 {
            let months = days / 30
            return "Changed \(months) month\(months == 1 ? "" : "s") ago"
        } else {
            let years = days / 365
            return "Changed \(years) year\(years == 1 ? "" : "s") ago"
        }
    }
}

// MARK: - Password Folder / Category

enum PasswordFolder: String, Codable, CaseIterable, Identifiable {
    case personal = "Personal"
    case work = "Work"
    case banking = "Banking"
    case social = "Social Media"
    case shopping = "Shopping"
    case entertainment = "Entertainment"
    case travel = "Travel"
    case health = "Health"
    case education = "Education"
    case other = "Other"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .personal: return "person.fill"
        case .work: return "briefcase.fill"
        case .banking: return "banknote.fill"
        case .social: return "bubble.left.and.bubble.right.fill"
        case .shopping: return "cart.fill"
        case .entertainment: return "tv.fill"
        case .travel: return "airplane"
        case .health: return "heart.fill"
        case .education: return "graduationcap.fill"
        case .other: return "folder.fill"
        }
    }
    
    var color: String {
        switch self {
        case .personal: return "blue"
        case .work: return "purple"
        case .banking: return "green"
        case .social: return "pink"
        case .shopping: return "orange"
        case .entertainment: return "red"
        case .travel: return "cyan"
        case .health: return "mint"
        case .education: return "indigo"
        case .other: return "gray"
        }
    }
}

// MARK: - Secure Note (Feature 4)

struct SecureNote: Identifiable, Codable {
    let id: UUID
    var title: String
    var content: String
    var folder: PasswordFolder?
    var isFavourite: Bool
    var createdDate: Date
    var lastModifiedDate: Date
    
    init(
        id: UUID = UUID(),
        title: String,
        content: String,
        folder: PasswordFolder? = nil,
        isFavourite: Bool = false,
        createdDate: Date = Date(),
        lastModifiedDate: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.folder = folder
        self.isFavourite = isFavourite
        self.createdDate = createdDate
        self.lastModifiedDate = lastModifiedDate
    }
}

// MARK: - Credit Card (Feature 7)

struct CreditCard: Identifiable, Codable {
    let id: UUID
    var cardName: String         // "Personal Visa", "Work Amex"
    var cardholderName: String   // Name on card
    var cardNumber: String       // Full card number (encrypted)
    var expiryMonth: Int         // 1-12
    var expiryYear: Int          // e.g., 2027
    var cvv: String              // Security code
    var cardType: CardType
    var billingAddress: String?
    var notes: String?
    var isFavourite: Bool
    var createdDate: Date
    var lastModifiedDate: Date
    
    init(
        id: UUID = UUID(),
        cardName: String,
        cardholderName: String,
        cardNumber: String,
        expiryMonth: Int,
        expiryYear: Int,
        cvv: String,
        cardType: CardType = .unknown,
        billingAddress: String? = nil,
        notes: String? = nil,
        isFavourite: Bool = false,
        createdDate: Date = Date(),
        lastModifiedDate: Date = Date()
    ) {
        self.id = id
        self.cardName = cardName
        self.cardholderName = cardholderName
        self.cardNumber = cardNumber
        self.expiryMonth = expiryMonth
        self.expiryYear = expiryYear
        self.cvv = cvv
        self.cardType = cardType
        self.billingAddress = billingAddress
        self.notes = notes
        self.isFavourite = isFavourite
        self.createdDate = createdDate
        self.lastModifiedDate = lastModifiedDate
    }
    
    /// Masked card number for display (e.g., •••• •••• •••• 1234)
    var maskedNumber: String {
        let lastFour = String(cardNumber.suffix(4))
        return "•••• •••• •••• \(lastFour)"
    }
    
    /// Formatted expiry date
    var expiryDateFormatted: String {
        String(format: "%02d/%02d", expiryMonth, expiryYear % 100)
    }
    
    /// Check if card is expired
    var isExpired: Bool {
        let now = Date()
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)
        
        if expiryYear < currentYear {
            return true
        } else if expiryYear == currentYear && expiryMonth < currentMonth {
            return true
        }
        return false
    }
    
    /// Check if card expires soon (within 3 months)
    var expiresSoon: Bool {
        guard !isExpired else { return false }
        
        let now = Date()
        let calendar = Calendar.current
        guard let expiryDate = calendar.date(from: DateComponents(year: expiryYear, month: expiryMonth, day: 1)) else {
            return false
        }
        
        let threeMonthsFromNow = calendar.date(byAdding: .month, value: 3, to: now) ?? now
        return expiryDate <= threeMonthsFromNow
    }
}

enum CardType: String, Codable, CaseIterable, Identifiable {
    case visa = "Visa"
    case mastercard = "Mastercard"
    case amex = "American Express"
    case discover = "Discover"
    case dinersClub = "Diners Club"
    case jcb = "JCB"
    case unionPay = "UnionPay"
    case unknown = "Unknown"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .visa: return "creditcard.fill"
        case .mastercard: return "creditcard.fill"
        case .amex: return "creditcard.fill"
        case .discover: return "creditcard.fill"
        case .dinersClub: return "creditcard.fill"
        case .jcb: return "creditcard.fill"
        case .unionPay: return "creditcard.fill"
        case .unknown: return "creditcard"
        }
    }
    
    /// Detect card type from card number
    static func detect(from cardNumber: String) -> CardType {
        let number = cardNumber.replacingOccurrences(of: " ", with: "")
        
        if number.hasPrefix("4") {
            return .visa
        } else if number.hasPrefix("5") || (number.hasPrefix("2") && number.count >= 2) {
            let prefix = Int(String(number.prefix(4))) ?? 0
            if (prefix >= 2221 && prefix <= 2720) || (prefix >= 5100 && prefix <= 5599) {
                return .mastercard
            }
        } else if number.hasPrefix("34") || number.hasPrefix("37") {
            return .amex
        } else if number.hasPrefix("6011") || number.hasPrefix("65") || number.hasPrefix("644") {
            return .discover
        } else if number.hasPrefix("36") || number.hasPrefix("38") || number.hasPrefix("30") {
            return .dinersClub
        } else if number.hasPrefix("35") {
            return .jcb
        } else if number.hasPrefix("62") {
            return .unionPay
        }
        
        return .unknown
    }
}

// MARK: - Sample Data for Previews
extension Credential {
    static let sample = Credential(
        websiteName: "Gmail",
        websiteURL: "gmail.com",
        username: "user@example.com",
        password: "SecurePass123!",
        notes: "Primary email account",
        folder: .personal,
        isFavourite: true
    )
    
    static let samples = [
        Credential(
            websiteName: "Gmail",
            websiteURL: "gmail.com",
            username: "user@example.com",
            password: "SecurePass123!",
            notes: "Primary email",
            folder: .personal,
            isFavourite: true
        ),
        Credential(
            websiteName: "Facebook",
            websiteURL: "facebook.com",
            username: "user@example.com",
            password: "WeakPassword",
            createdDate: Calendar.current.date(byAdding: .month, value: -14, to: Date()) ?? Date(),
            folder: .social
        ),
        Credential(
            websiteName: "Twitter",
            websiteURL: "twitter.com",
            username: "user@example.com",
            password: "SecurePass123!",
            notes: "Social media",
            folder: .social
        ),
        Credential(
            websiteName: "Chase Bank",
            websiteURL: "chase.com",
            username: "user@example.com",
            password: "V3ryS3cur3P@ss!",
            folder: .banking,
            isFavourite: true,
            expiryReminderDays: 90
        )
    ]
}

extension SecureNote {
    static let sample = SecureNote(
        title: "WiFi Password",
        content: "Home WiFi: MyNetwork\nPassword: SuperSecret123",
        folder: .personal
    )
    
    static let samples = [
        SecureNote(
            title: "WiFi Password",
            content: "Home WiFi: MyNetwork\nPassword: SuperSecret123",
            folder: .personal,
            isFavourite: true
        ),
        SecureNote(
            title: "Recovery Codes",
            content: "Google: ABC123, DEF456\nGitHub: XYZ789",
            folder: .work
        ),
        SecureNote(
            title: "Safe Combination",
            content: "34-22-18",
            folder: .personal
        )
    ]
}

extension CreditCard {
    static let sample = CreditCard(
        cardName: "Personal Visa",
        cardholderName: "John Doe",
        cardNumber: "4111111111111234",
        expiryMonth: 12,
        expiryYear: 2027,
        cvv: "123",
        cardType: .visa
    )
}
