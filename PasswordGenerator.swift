//
//  PasswordGenerator.swift
//  PasswordVault
//
//  Created by AI Assistant on 05/12/2025.
//

import Foundation
import SwiftUI  // ✅ Added for Color type

/// Configuration for password generation
struct PasswordConfiguration {
    var length: Int = 16
    var includeUppercase: Bool = true
    var includeLowercase: Bool = true
    var includeNumbers: Bool = true
    var includeSymbols: Bool = true
    
    var isValid: Bool {
        // At least one character type must be selected
        includeUppercase || includeLowercase || includeNumbers || includeSymbols
    }
}

/// Password strength levels
enum PasswordStrength: String {
    case weak = "Weak"
    case medium = "Medium"
    case strong = "Strong"
    
    var color: Color {
        switch self {
        case .weak: return .red
        case .medium: return .orange
        case .strong: return .green
        }
    }
}

/// Service for generating random passwords
final class PasswordGenerator {
    
    // Character sets
    private let uppercaseLetters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    private let lowercaseLetters = "abcdefghijklmnopqrstuvwxyz"
    private let numbers = "0123456789"
    private let symbols = "!@#$%^&*"
    
    /// Generate a random password based on configuration
    func generate(config: PasswordConfiguration) -> String {
        guard config.isValid else { return "" }
        
        var characterSet = ""
        
        if config.includeUppercase {
            characterSet += uppercaseLetters
        }
        if config.includeLowercase {
            characterSet += lowercaseLetters
        }
        if config.includeNumbers {
            characterSet += numbers
        }
        if config.includeSymbols {
            characterSet += symbols
        }
        
        // Ensure at least one character from each enabled category
        var password = ""
        
        if config.includeUppercase {
            password += String(uppercaseLetters.randomElement()!)
        }
        if config.includeLowercase {
            password += String(lowercaseLetters.randomElement()!)
        }
        if config.includeNumbers {
            password += String(numbers.randomElement()!)
        }
        if config.includeSymbols {
            password += String(symbols.randomElement()!)
        }
        
        // Fill remaining length with random characters
        let remainingLength = config.length - password.count
        for _ in 0..<remainingLength {
            if let randomChar = characterSet.randomElement() {
                password += String(randomChar)
            }
        }
        
        // Shuffle the password to randomize position of guaranteed characters
        return String(password.shuffled())
    }
    
    /// Calculate password strength
    func calculateStrength(_ password: String) -> PasswordStrength {
        var score = 0
        
        // Length scoring
        if password.count >= 8 { score += 1 }
        if password.count >= 12 { score += 1 }
        if password.count >= 16 { score += 1 }
        
        // Character variety scoring
        if password.contains(where: { $0.isUppercase }) { score += 1 }
        if password.contains(where: { $0.isLowercase }) { score += 1 }
        if password.contains(where: { $0.isNumber }) { score += 1 }
        if password.contains(where: { "!@#$%^&*".contains($0) }) { score += 1 }
        
        // Determine strength based on score
        if score <= 3 {
            return .weak
        } else if score <= 5 {
            return .medium
        } else {
            return .strong
        }
    }
}
