//
//  GeneratorViewModel.swift
//  PasswordVault
//
//  Created by AI Assistant on 05/12/2025.
//  ENHANCED: Better copy feedback, share support
//

import Foundation
import UIKit

/// ViewModel for password generator
@Observable
final class GeneratorViewModel {
    
    // State
    var generatedPassword: String = ""
    var passwordStrength: PasswordStrength = .medium
    var configuration = PasswordConfiguration()
    var showCopiedConfirmation: Bool = false
    
    private let passwordGenerator = PasswordGenerator()
    
    init() {
        // Generate initial password
        generatePassword()
    }
    
    /// Generate a new password based on current configuration
    func generatePassword() {
        guard configuration.isValid else {
            generatedPassword = ""
            return
        }
        
        generatedPassword = passwordGenerator.generate(config: configuration)
        passwordStrength = passwordGenerator.calculateStrength(generatedPassword)
    }
    
    /// Copy password to clipboard with haptic feedback
    func copyToClipboard() {
        #if os(iOS)
        UIPasteboard.general.string = generatedPassword
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        #endif
        
        showCopiedConfirmation = true
        
        // Hide confirmation after 2 seconds
        Task {
            try? await Task.sleep(for: .seconds(2))
            await MainActor.run {
                showCopiedConfirmation = false
            }
        }
    }
    
    /// Share password via share sheet
    func sharePassword() -> String {
        return generatedPassword
    }
}
