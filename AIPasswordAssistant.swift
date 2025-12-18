//
//  AIPasswordAssistant.swift
//  PasswordVault
//
//  Created by AI Assistant on 10/12/2025.
//  Apple Intelligence powered features for password management
//

import Foundation
import NaturalLanguage

/// AI-powered assistant for password-related tasks
/// Uses on-device Apple frameworks (no data leaves device - GDPR safe)
@Observable
final class AIPasswordAssistant {
    
    // MARK: - Smart Categorization (Auto-assign folders)
    
    /// Automatically suggests a folder/category based on website name and URL
    func suggestFolder(for websiteName: String, url: String?) -> PasswordFolder {
        let searchText = "\(websiteName) \(url ?? "")".lowercased()
        
        // Banking keywords
        let bankingKeywords = ["bank", "chase", "wells fargo", "barclays", "hsbc", "lloyds", "natwest", 
                               "santander", "halifax", "monzo", "revolut", "paypal", "venmo", "wise",
                               "credit", "debit", "finance", "invest", "trading", "crypto", "coinbase"]
        if bankingKeywords.contains(where: { searchText.contains($0) }) {
            return .banking
        }
        
        // Social media keywords
        let socialKeywords = ["facebook", "twitter", "instagram", "linkedin", "tiktok", "snapchat",
                              "pinterest", "reddit", "tumblr", "discord", "whatsapp", "telegram",
                              "messenger", "social", "x.com"]
        if socialKeywords.contains(where: { searchText.contains($0) }) {
            return .social
        }
        
        // Work keywords
        let workKeywords = ["slack", "teams", "zoom", "jira", "confluence", "asana", "trello",
                            "notion", "github", "gitlab", "bitbucket", "office", "salesforce",
                            "hubspot", "work", "corporate", "enterprise", "business"]
        if workKeywords.contains(where: { searchText.contains($0) }) {
            return .work
        }
        
        // Shopping keywords
        let shoppingKeywords = ["amazon", "ebay", "etsy", "shopify", "aliexpress", "walmart",
                                "target", "bestbuy", "shop", "store", "buy", "cart", "checkout",
                                "asos", "zara", "nike", "adidas"]
        if shoppingKeywords.contains(where: { searchText.contains($0) }) {
            return .shopping
        }
        
        // Entertainment keywords
        let entertainmentKeywords = ["netflix", "disney", "hulu", "hbo", "prime video", "youtube",
                                     "spotify", "apple music", "soundcloud", "twitch", "steam",
                                     "playstation", "xbox", "nintendo", "gaming", "movie", "music",
                                     "podcast", "streaming"]
        if entertainmentKeywords.contains(where: { searchText.contains($0) }) {
            return .entertainment
        }
        
        // Travel keywords
        let travelKeywords = ["airline", "flight", "hotel", "booking", "airbnb", "expedia",
                              "tripadvisor", "uber", "lyft", "rental", "travel", "vacation",
                              "british airways", "ryanair", "easyjet"]
        if travelKeywords.contains(where: { searchText.contains($0) }) {
            return .travel
        }
        
        // Health keywords
        let healthKeywords = ["health", "medical", "doctor", "hospital", "pharmacy", "nhs",
                              "fitness", "gym", "wellness", "insurance", "patient"]
        if healthKeywords.contains(where: { searchText.contains($0) }) {
            return .health
        }
        
        // Education keywords
        let educationKeywords = ["university", "college", "school", "edu", "coursera", "udemy",
                                 "khan academy", "duolingo", "student", "learn", "academic"]
        if educationKeywords.contains(where: { searchText.contains($0) }) {
            return .education
        }
        
        // Email keywords -> Personal
        let emailKeywords = ["gmail", "outlook", "yahoo", "mail", "email", "icloud", "proton"]
        if emailKeywords.contains(where: { searchText.contains($0) }) {
            return .personal
        }
        
        return .other
    }
    
    // MARK: - Smart Password Strength Analysis
    
    struct PasswordAnalysis {
        let score: Int // 0-100
        let strength: PasswordStrength
        let suggestions: [String]
        let timeTocrack: String
        let issues: [PasswordIssue]
    }
    
    enum PasswordIssue: String {
        case tooShort = "Password is too short"
        case noUppercase = "Add uppercase letters"
        case noLowercase = "Add lowercase letters"
        case noNumbers = "Add numbers"
        case noSymbols = "Add special characters"
        case commonPattern = "Avoid common patterns"
        case repeatingChars = "Avoid repeating characters"
        case sequentialChars = "Avoid sequential characters"
        case dictionaryWord = "Avoid dictionary words"
    }
    
    /// Analyze password and provide detailed feedback
    func analyzePassword(_ password: String) -> PasswordAnalysis {
        var score = 0
        var issues: [PasswordIssue] = []
        var suggestions: [String] = []
        
        // Length scoring
        let length = password.count
        if length < 8 {
            issues.append(.tooShort)
            suggestions.append("Use at least 12 characters")
        } else if length >= 8 && length < 12 {
            score += 20
        } else if length >= 12 && length < 16 {
            score += 30
        } else {
            score += 40
        }
        
        // Character variety
        let hasUppercase = password.contains(where: { $0.isUppercase })
        let hasLowercase = password.contains(where: { $0.isLowercase })
        let hasNumbers = password.contains(where: { $0.isNumber })
        let hasSymbols = password.contains(where: { "!@#$%^&*()_+-=[]{}|;':\",./<>?".contains($0) })
        
        if hasUppercase { score += 10 } else { issues.append(.noUppercase) }
        if hasLowercase { score += 10 } else { issues.append(.noLowercase) }
        if hasNumbers { score += 10 } else { issues.append(.noNumbers) }
        if hasSymbols { score += 15 } else { issues.append(.noSymbols) }
        
        // Check for common patterns
        let lowercased = password.lowercased()
        let commonPatterns = ["123", "abc", "qwerty", "password", "letmein", "admin", "welcome"]
        if commonPatterns.contains(where: { lowercased.contains($0) }) {
            score -= 20
            issues.append(.commonPattern)
            suggestions.append("Avoid common patterns like '123' or 'abc'")
        }
        
        // Check for repeating characters
        if hasRepeatingCharacters(password) {
            score -= 10
            issues.append(.repeatingChars)
        }
        
        // Check for sequential characters
        if hasSequentialCharacters(password) {
            score -= 10
            issues.append(.sequentialChars)
        }
        
        // Estimate time to crack
        let timeTocrack = estimateTimeToCrack(password)
        
        // Calculate strength - use existing PasswordStrength enum values
        let strength: PasswordStrength
        if score >= 60 {
            strength = .strong
        } else if score >= 40 {
            strength = .medium
        } else {
            strength = .weak
        }
        
        // Generate suggestions if not strong
        if strength != .strong {
            if !hasUppercase { suggestions.append("Add uppercase letters (A-Z)") }
            if !hasSymbols { suggestions.append("Add special characters (!@#$%)") }
            if length < 16 { suggestions.append("Make it longer (16+ characters is ideal)") }
        }
        
        return PasswordAnalysis(
            score: max(0, min(100, score)),
            strength: strength,
            suggestions: suggestions,
            timeTocrack: timeTocrack,
            issues: issues
        )
    }
    
    private func hasRepeatingCharacters(_ password: String) -> Bool {
        guard password.count >= 3 else { return false }
        for i in 0..<(password.count - 2) {
            let index = password.index(password.startIndex, offsetBy: i)
            let char = password[index]
            let next1 = password[password.index(after: index)]
            let next2 = password[password.index(index, offsetBy: 2)]
            
            if char == next1 && next1 == next2 {
                return true
            }
        }
        return false
    }
    
    private func hasSequentialCharacters(_ password: String) -> Bool {
        let sequences = ["abcdefghijklmnopqrstuvwxyz", "0123456789", "qwertyuiop", "asdfghjkl", "zxcvbnm"]
        let lowercased = password.lowercased()
        
        for sequence in sequences {
            for i in 0..<(sequence.count - 2) {
                let startIndex = sequence.index(sequence.startIndex, offsetBy: i)
                let endIndex = sequence.index(startIndex, offsetBy: 3)
                let substring = String(sequence[startIndex..<endIndex])
                
                if lowercased.contains(substring) {
                    return true
                }
            }
        }
        return false
    }
    
    private func estimateTimeToCrack(_ password: String) -> String {
        // Simplified estimation based on entropy
        var charsetSize = 0
        if password.contains(where: { $0.isLowercase }) { charsetSize += 26 }
        if password.contains(where: { $0.isUppercase }) { charsetSize += 26 }
        if password.contains(where: { $0.isNumber }) { charsetSize += 10 }
        if password.contains(where: { "!@#$%^&*()_+-=[]{}|;':\",./<>?".contains($0) }) { charsetSize += 32 }
        
        let entropy = Double(password.count) * log2(Double(max(charsetSize, 1)))
        
        // Assuming 10 billion guesses per second
        let guessesPerSecond: Double = 10_000_000_000
        let combinations = pow(2, entropy)
        let seconds = combinations / guessesPerSecond / 2 // Average case
        
        if seconds < 1 {
            return "Instantly"
        } else if seconds < 60 {
            return "\(Int(seconds)) seconds"
        } else if seconds < 3600 {
            return "\(Int(seconds / 60)) minutes"
        } else if seconds < 86400 {
            return "\(Int(seconds / 3600)) hours"
        } else if seconds < 31536000 {
            return "\(Int(seconds / 86400)) days"
        } else if seconds < 31536000 * 100 {
            return "\(Int(seconds / 31536000)) years"
        } else if seconds < 31536000 * 1000000 {
            return "\(Int(seconds / 31536000 / 1000))k years"
        } else {
            return "Centuries+"
        }
    }
    
    // MARK: - Smart Search (Using NaturalLanguage)
    
    /// Search credentials using natural language processing
    func smartSearch(query: String, in credentials: [Credential]) -> [Credential] {
        let lowercasedQuery = query.lowercased()
        
        // Use NLP for tokenization
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = lowercasedQuery
        
        var queryTokens: [String] = []
        tokenizer.enumerateTokens(in: lowercasedQuery.startIndex..<lowercasedQuery.endIndex) { range, _ in
            queryTokens.append(String(lowercasedQuery[range]))
            return true
        }
        
        // Score each credential
        let scored = credentials.map { credential -> (Credential, Int) in
            var score = 0
            
            let searchableText = "\(credential.websiteName) \(credential.websiteURL ?? "") \(credential.username) \(credential.notes ?? "") \(credential.folder?.rawValue ?? "")".lowercased()
            
            // Exact match bonus
            if searchableText.contains(lowercasedQuery) {
                score += 100
            }
            
            // Token matches
            for token in queryTokens {
                if searchableText.contains(token) {
                    score += 20
                }
            }
            
            // Favourite bonus
            if credential.isFavourite {
                score += 5
            }
            
            return (credential, score)
        }
        
        return scored
            .filter { $0.1 > 0 }
            .sorted { $0.1 > $1.1 }
            .map { $0.0 }
    }
    
    // MARK: - Generate Memorable Password
    
    /// Generate a memorable but secure password using word combinations
    func generateMemorablePassword(wordCount: Int = 4, separator: String = "-", includeNumber: Bool = true) -> String {
        let words = [
            "apple", "banana", "cherry", "dragon", "eagle", "forest", "guitar", "harmony",
            "island", "jungle", "knight", "lemon", "mountain", "ocean", "phoenix", "quartz",
            "river", "sunset", "thunder", "umbrella", "violet", "whisper", "xylophone", "yellow",
            "zebra", "anchor", "bridge", "castle", "diamond", "ember", "falcon", "glacier",
            "harbor", "ivory", "jasmine", "kite", "lantern", "meadow", "nebula", "oracle",
            "pebble", "quantum", "rainbow", "silver", "tiger", "unity", "velvet", "willow"
        ]
        
        var selectedWords: [String] = []
        for _ in 0..<wordCount {
            if let word = words.randomElement() {
                // Randomly capitalize first letter
                let formatted = Bool.random() ? word.capitalized : word
                selectedWords.append(formatted)
            }
        }
        
        var password = selectedWords.joined(separator: separator)
        
        if includeNumber {
            password += separator + String(Int.random(in: 10...99))
        }
        
        return password
    }
    
    // MARK: - Duplicate Detection
    
    /// Find credentials with duplicate passwords
    func findDuplicatePasswords(in credentials: [Credential]) -> [[Credential]] {
        var passwordGroups: [String: [Credential]] = [:]
        
        for credential in credentials {
            let password = credential.password
            if passwordGroups[password] != nil {
                passwordGroups[password]?.append(credential)
            } else {
                passwordGroups[password] = [credential]
            }
        }
        
        return passwordGroups.values.filter { $0.count > 1 }
    }
    
    // MARK: - Expiry Checker
    
    /// Get credentials with expired or expiring passwords
    func getExpiringPasswords(from credentials: [Credential]) -> (expired: [Credential], expiringSoon: [Credential]) {
        var expired: [Credential] = []
        var expiringSoon: [Credential] = []
        
        for credential in credentials {
            if credential.isExpiryReminderDue {
                // Check if way overdue (2x the reminder period)
                if let reminderDays = credential.expiryReminderDays,
                   credential.passwordAgeDays >= reminderDays * 2 {
                    expired.append(credential)
                } else {
                    expiringSoon.append(credential)
                }
            }
        }
        
        return (expired, expiringSoon)
    }
}
