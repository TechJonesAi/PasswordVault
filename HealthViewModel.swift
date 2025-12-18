//
//  HealthViewModel.swift
//  PasswordVault
//
//  Created by AI Assistant on 05/12/2025.
//

import Foundation
import SwiftUI  // ✅ Added for Color type

/// ViewModel for password health dashboard
@Observable
final class HealthViewModel {
    
    // State
    var healthReport: PasswordHealthReport?
    var suggestions: [PasswordSuggestion] = []
    var isLoading: Bool = false
    
    private let healthEngine = PasswordHealthEngine()
    private let keychainService = SecureKeychainService()
    
    /// Analyze all passwords and generate health report
    func analyzePasswords() {
        isLoading = true
        
        do {
            let credentials = try keychainService.fetchAllCredentials()
            let report = healthEngine.analyzePasswords(credentials)
            let newSuggestions = healthEngine.generateSuggestions(for: report)
            
            healthReport = report
            suggestions = newSuggestions
        } catch {
            // Handle error
            healthReport = nil
            suggestions = []
        }
        
        isLoading = false
    }
    
    /// Get color for security score
    func scoreColor(for score: Int) -> Color {
        if score >= 80 {
            return .green
        } else if score >= 50 {
            return .orange
        } else {
            return .red
        }
    }
    
    /// Get descriptive text for security score
    func scoreDescription(for score: Int) -> String {
        if score >= 80 {
            return "Excellent"
        } else if score >= 50 {
            return "Fair"
        } else {
            return "Poor"
        }
    }
}
