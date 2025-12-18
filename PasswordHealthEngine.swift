//
//  PasswordHealthEngine.swift
//  PasswordVault
//
//  Created by AI Assistant on 05/12/2025.
//

import Foundation

/// Health report for password analysis
struct PasswordHealthReport {
    var securityScore: Int              // 0-100
    var weakPasswords: [Credential]
    var reusedPasswords: [Credential]
    var oldPasswords: [Credential]
    var totalCredentials: Int
    
    var hasIssues: Bool {
        !weakPasswords.isEmpty || !reusedPasswords.isEmpty || !oldPasswords.isEmpty
    }
}

/// Suggestion for improving password health
struct PasswordSuggestion: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let priority: Priority
    
    enum Priority {
        case high
        case medium
        case low
    }
}

/// Service for analyzing password health (Premium feature)
final class PasswordHealthEngine {
    
    private let passwordGenerator = PasswordGenerator()
    
    /// Analyze all passwords and generate health report
    func analyzePasswords(_ credentials: [Credential]) -> PasswordHealthReport {
        let weakPasswords = findWeakPasswords(credentials)
        let reusedPasswords = findReusedPasswords(credentials)
        let oldPasswords = findOldPasswords(credentials)
        
        let score = calculateSecurityScore(
            totalCount: credentials.count,
            weakCount: weakPasswords.count,
            reusedCount: reusedPasswords.count,
            oldCount: oldPasswords.count
        )
        
        return PasswordHealthReport(
            securityScore: score,
            weakPasswords: weakPasswords,
            reusedPasswords: reusedPasswords,
            oldPasswords: oldPasswords,
            totalCredentials: credentials.count
        )
    }
    
    /// Generate actionable suggestions based on health report
    func generateSuggestions(for report: PasswordHealthReport) -> [PasswordSuggestion] {
        var suggestions: [PasswordSuggestion] = []
        
        if !report.weakPasswords.isEmpty {
            suggestions.append(
                PasswordSuggestion(
                    title: "Update Weak Passwords",
                    description: "You have \(report.weakPasswords.count) weak password(s) that should be strengthened",
                    priority: .high
                )
            )
        }
        
        if !report.reusedPasswords.isEmpty {
            suggestions.append(
                PasswordSuggestion(
                    title: "Fix Reused Passwords",
                    description: "You're reusing \(report.reusedPasswords.count) password(s) across multiple accounts",
                    priority: .high
                )
            )
        }
        
        if !report.oldPasswords.isEmpty {
            suggestions.append(
                PasswordSuggestion(
                    title: "Refresh Old Passwords",
                    description: "\(report.oldPasswords.count) password(s) haven't been changed in over 12 months",
                    priority: .medium
                )
            )
        }
        
        if report.securityScore == 100 {
            suggestions.append(
                PasswordSuggestion(
                    title: "Excellent Security!",
                    description: "All your passwords are strong, unique, and up to date",
                    priority: .low
                )
            )
        }
        
        return suggestions
    }
    
    // MARK: - Private Analysis Methods
    
    /// Find weak passwords (strength = weak)
    private func findWeakPasswords(_ credentials: [Credential]) -> [Credential] {
        credentials.filter { credential in
            let strength = passwordGenerator.calculateStrength(credential.password)
            return strength == .weak
        }
    }
    
    /// Find reused passwords (same password used multiple times)
    private func findReusedPasswords(_ credentials: [Credential]) -> [Credential] {
        var passwordCounts: [String: Int] = [:]
        
        // Count password occurrences
        for credential in credentials {
            passwordCounts[credential.password, default: 0] += 1
        }
        
        // Find credentials with reused passwords
        return credentials.filter { credential in
            (passwordCounts[credential.password] ?? 0) > 1
        }
    }
    
    /// Find old passwords (not modified in 12+ months)
    private func findOldPasswords(_ credentials: [Credential]) -> [Credential] {
        let twelveMonthsAgo = Calendar.current.date(
            byAdding: .month,
            value: -12,
            to: Date()
        ) ?? Date()
        
        return credentials.filter { credential in
            credential.lastModifiedDate < twelveMonthsAgo
        }
    }
    
    /// Calculate overall security score (0-100)
    private func calculateSecurityScore(
        totalCount: Int,
        weakCount: Int,
        reusedCount: Int,
        oldCount: Int
    ) -> Int {
        guard totalCount > 0 else { return 100 }
        
        // Start with 100 and deduct points for issues
        var score = 100
        
        // Deduct for weak passwords (up to 40 points)
        let weakPercentage = Double(weakCount) / Double(totalCount)
        score -= Int(weakPercentage * 40)
        
        // Deduct for reused passwords (up to 40 points)
        let reusedPercentage = Double(reusedCount) / Double(totalCount)
        score -= Int(reusedPercentage * 40)
        
        // Deduct for old passwords (up to 20 points)
        let oldPercentage = Double(oldCount) / Double(totalCount)
        score -= Int(oldPercentage * 20)
        
        // Ensure score doesn't go below 0
        return max(0, score)
    }
}
