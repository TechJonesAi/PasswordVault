//
//  ImportExportView.swift
//  PasswordVault
//
//  Created by AI Assistant on 10/12/2025.
//  Import passwords from Chrome, Brave, Firefox, Safari, Edge, 1Password, LastPass, etc.
//

import SwiftUI
import UniformTypeIdentifiers

struct ImportExportView: View {
    @Binding var vaultViewModel: VaultViewModel
    @Binding var isPremium: Bool
    @Environment(\.dismiss) private var dismiss
    
    @State private var showImportPicker = false
    @State private var showExportShare = false
    @State private var importResult: ImportResult?
    @State private var showResultAlert = false
    @State private var isProcessing = false
    @State private var exportURL: URL?
    
    var body: some View {
        NavigationStack {
            List {
                // Import Section
                Section {
                    Button {
                        showImportPicker = true
                    } label: {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.15))
                                    .frame(width: 44, height: 44)
                                Image(systemName: "square.and.arrow.down")
                                    .font(.title3)
                                    .foregroundStyle(.blue)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Import Passwords")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("From CSV file")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            if isProcessing {
                                ProgressView()
                            } else {
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .disabled(isProcessing)
                } header: {
                    Text("Import")
                } footer: {
                    Text("Supports Chrome, Brave, Firefox, Safari, Edge, 1Password, LastPass, Bitwarden, and Dashlane exports.")
                }
                
                // Export Section
                Section {
                    Button {
                        exportPasswords()
                    } label: {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.green.opacity(0.15))
                                    .frame(width: 44, height: 44)
                                Image(systemName: "square.and.arrow.up")
                                    .font(.title3)
                                    .foregroundStyle(.green)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Export Passwords")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("As CSV file")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Export")
                } footer: {
                    Text("Export your passwords to transfer to another device or password manager.")
                }
                
                // Instructions Section
                Section("How to Export from Browsers") {
                    BrowserInstructionRow(
                        browser: "Chrome",
                        icon: "globe",
                        color: .red,
                        instructions: "Settings → Passwords → ⋮ → Export passwords"
                    )
                    
                    BrowserInstructionRow(
                        browser: "Brave",
                        icon: "shield.fill",
                        color: .orange,
                        instructions: "Settings → Passwords → ⋮ → Export passwords"
                    )
                    
                    BrowserInstructionRow(
                        browser: "Firefox",
                        icon: "flame.fill",
                        color: .orange,
                        instructions: "Settings → Passwords → ⋯ → Export Logins"
                    )
                    
                    BrowserInstructionRow(
                        browser: "Safari",
                        icon: "safari.fill",
                        color: .blue,
                        instructions: "Settings → Passwords → Export All Passwords"
                    )
                    
                    BrowserInstructionRow(
                        browser: "Edge",
                        icon: "globe",
                        color: .cyan,
                        instructions: "Settings → Passwords → ⋮ → Export passwords"
                    )
                }
                
                // Other Password Managers
                Section("From Other Password Managers") {
                    BrowserInstructionRow(
                        browser: "1Password",
                        icon: "key.fill",
                        color: .blue,
                        instructions: "File → Export → CSV format"
                    )
                    
                    BrowserInstructionRow(
                        browser: "LastPass",
                        icon: "lock.fill",
                        color: .red,
                        instructions: "Account Options → Advanced → Export"
                    )
                    
                    BrowserInstructionRow(
                        browser: "Bitwarden",
                        icon: "shield.fill",
                        color: .blue,
                        instructions: "Tools → Export Vault → CSV"
                    )
                    
                    BrowserInstructionRow(
                        browser: "Dashlane",
                        icon: "d.circle.fill",
                        color: .green,
                        instructions: "File → Export → CSV format"
                    )
                }
            }
            .navigationTitle("Import / Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $showImportPicker,
                allowedContentTypes: [.commaSeparatedText, .plainText],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
            .sheet(isPresented: $showExportShare) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
            .alert("Import Result", isPresented: $showResultAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                if let result = importResult {
                    Text(result.message)
                }
            }
        }
    }
    
    // MARK: - Import Logic
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            isProcessing = true
            
            Task {
                do {
                    // Need to start accessing security-scoped resource
                    guard url.startAccessingSecurityScopedResource() else {
                        throw ImportError.accessDenied
                    }
                    defer { url.stopAccessingSecurityScopedResource() }
                    
                    let data = try Data(contentsOf: url)
                    guard let csvString = String(data: data, encoding: .utf8) else {
                        throw ImportError.invalidFormat
                    }
                    
                    let importedCredentials = try PasswordImporter.parseCSV(csvString)
                    
                    await MainActor.run {
                        // Save imported credentials
                        let keychainService = SecureKeychainService()
                        var existingCredentials = (try? keychainService.fetchAllCredentials()) ?? []
                        
                        // Check for duplicates and merge
                        var newCount = 0
                        var duplicateCount = 0
                        
                        for imported in importedCredentials {
                            let isDuplicate = existingCredentials.contains { existing in
                                existing.websiteName.lowercased() == imported.websiteName.lowercased() &&
                                existing.username.lowercased() == imported.username.lowercased()
                            }
                            
                            if isDuplicate {
                                duplicateCount += 1
                            } else {
                                existingCredentials.append(imported)
                                newCount += 1
                            }
                        }
                        
                        // Save all credentials
                        try? keychainService.saveCredentials(existingCredentials)
                        
                        // Reload vault
                        vaultViewModel.loadCredentials()
                        
                        // Show result
                        importResult = ImportResult(
                            success: true,
                            imported: newCount,
                            duplicates: duplicateCount,
                            total: importedCredentials.count
                        )
                        isProcessing = false
                        showResultAlert = true
                    }
                } catch {
                    await MainActor.run {
                        importResult = ImportResult(
                            success: false,
                            error: error.localizedDescription
                        )
                        isProcessing = false
                        showResultAlert = true
                    }
                }
            }
            
        case .failure(let error):
            importResult = ImportResult(success: false, error: error.localizedDescription)
            showResultAlert = true
        }
    }
    
    // MARK: - Export Logic
    
    private func exportPasswords() {
        let credentials = vaultViewModel.credentials
        
        guard !credentials.isEmpty else {
            importResult = ImportResult(success: false, error: "No passwords to export")
            showResultAlert = true
            return
        }
        
        let csvString = PasswordImporter.exportToCSV(credentials)
        
        // Save to temporary file
        let fileName = "PasswordVault_Export_\(dateString()).csv"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try csvString.write(to: tempURL, atomically: true, encoding: .utf8)
            exportURL = tempURL
            showExportShare = true
        } catch {
            importResult = ImportResult(success: false, error: "Failed to create export file")
            showResultAlert = true
        }
    }
    
    private func dateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

// MARK: - Import Result

struct ImportResult {
    let success: Bool
    var imported: Int = 0
    var duplicates: Int = 0
    var total: Int = 0
    var error: String?
    
    var message: String {
        if success {
            if duplicates > 0 {
                return "Successfully imported \(imported) passwords.\n\(duplicates) duplicates were skipped."
            } else {
                return "Successfully imported \(imported) passwords!"
            }
        } else {
            return "Import failed: \(error ?? "Unknown error")"
        }
    }
}

// MARK: - Import Error

enum ImportError: LocalizedError {
    case accessDenied
    case invalidFormat
    case noData
    
    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Could not access the file. Please try again."
        case .invalidFormat:
            return "The file format is not supported. Please use a CSV file."
        case .noData:
            return "The file appears to be empty."
        }
    }
}

// MARK: - Browser Instruction Row

struct BrowserInstructionRow: View {
    let browser: String
    let icon: String
    let color: Color
    let instructions: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(browser)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(instructions)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Password Importer

struct PasswordImporter {
    
    /// Parse CSV from various password managers
    static func parseCSV(_ csvString: String) throws -> [Credential] {
        var credentials: [Credential] = []
        
        // Split into lines
        let lines = csvString.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        guard lines.count > 1 else {
            throw ImportError.noData
        }
        
        // Parse header to determine format
        let header = parseCSVLine(lines[0]).map { $0.lowercased() }
        let format = detectFormat(header: header)
        
        print("📥 Detected CSV format: \(format)")
        print("📥 Header columns: \(header)")
        
        // Parse data rows
        for i in 1..<lines.count {
            let values = parseCSVLine(lines[i])
            
            if let credential = parseCredential(values: values, header: header, format: format) {
                credentials.append(credential)
            }
        }
        
        print("📥 Parsed \(credentials.count) credentials")
        return credentials
    }
    
    /// Detect which password manager format the CSV is from
    private static func detectFormat(header: [String]) -> CSVFormat {
        // Chrome/Brave: name,url,username,password
        if header.contains("name") && header.contains("url") && header.contains("username") && header.contains("password") {
            return .chrome
        }
        
        // Firefox: url,username,password,httpRealm,formActionOrigin,guid,timeCreated,timeLastUsed,timePasswordChanged
        if header.contains("url") && header.contains("username") && header.contains("password") && header.contains("guid") {
            return .firefox
        }
        
        // Safari: Title,URL,Username,Password,Notes,OTPAuth
        if header.contains("title") && header.contains("url") && header.contains("username") && header.contains("password") {
            return .safari
        }
        
        // 1Password: Title,Url,Username,Password,Notes,OTP
        if header.contains("title") && header.contains("url") && (header.contains("username") || header.contains("login")) {
            return .onePassword
        }
        
        // LastPass: url,username,password,totp,extra,name,grouping,fav
        if header.contains("url") && header.contains("username") && header.contains("password") && header.contains("extra") {
            return .lastPass
        }
        
        // Bitwarden: folder,favorite,type,name,notes,fields,reprompt,login_uri,login_username,login_password,login_totp
        if header.contains("login_uri") && header.contains("login_username") && header.contains("login_password") {
            return .bitwarden
        }
        
        // Dashlane: username,password,url,title,note
        if header.contains("username") && header.contains("password") && (header.contains("url") || header.contains("domain")) {
            return .dashlane
        }
        
        // Generic fallback - try to find common columns
        return .generic
    }
    
    /// Parse a single CSV line handling quoted values
    private static func parseCSVLine(_ line: String) -> [String] {
        var values: [String] = []
        var currentValue = ""
        var insideQuotes = false
        
        for char in line {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                values.append(currentValue.trimmingCharacters(in: .whitespaces))
                currentValue = ""
            } else {
                currentValue.append(char)
            }
        }
        values.append(currentValue.trimmingCharacters(in: .whitespaces))
        
        return values
    }
    
    /// Parse a credential from CSV values
    private static func parseCredential(values: [String], header: [String], format: CSVFormat) -> Credential? {
        // Create a dictionary mapping headers to values
        var dict: [String: String] = [:]
        for (index, key) in header.enumerated() {
            if index < values.count {
                dict[key] = values[index]
            }
        }
        
        // Extract fields based on format
        var name: String?
        var url: String?
        var username: String?
        var password: String?
        var notes: String?
        
        switch format {
        case .chrome:
            name = dict["name"]
            url = dict["url"]
            username = dict["username"]
            password = dict["password"]
            notes = dict["note"] ?? dict["notes"]
            
        case .firefox:
            url = dict["url"]
            username = dict["username"]
            password = dict["password"]
            // Firefox doesn't have a name field, extract from URL
            name = extractDomainName(from: url)
            
        case .safari:
            name = dict["title"]
            url = dict["url"]
            username = dict["username"]
            password = dict["password"]
            notes = dict["notes"]
            
        case .onePassword:
            name = dict["title"]
            url = dict["url"]
            username = dict["username"] ?? dict["login"]
            password = dict["password"]
            notes = dict["notes"]
            
        case .lastPass:
            name = dict["name"]
            url = dict["url"]
            username = dict["username"]
            password = dict["password"]
            notes = dict["extra"]
            
        case .bitwarden:
            name = dict["name"]
            url = dict["login_uri"]
            username = dict["login_username"]
            password = dict["login_password"]
            notes = dict["notes"]
            
        case .dashlane:
            name = dict["title"] ?? dict["name"]
            url = dict["url"] ?? dict["domain"]
            username = dict["username"] ?? dict["login"]
            password = dict["password"]
            notes = dict["note"] ?? dict["notes"]
            
        case .generic:
            // Try common field names
            name = dict["name"] ?? dict["title"] ?? dict["site"] ?? dict["website"]
            url = dict["url"] ?? dict["uri"] ?? dict["website"] ?? dict["domain"] ?? dict["login_uri"]
            username = dict["username"] ?? dict["login"] ?? dict["email"] ?? dict["user"] ?? dict["login_username"]
            password = dict["password"] ?? dict["pass"] ?? dict["pwd"] ?? dict["login_password"]
            notes = dict["notes"] ?? dict["note"] ?? dict["extra"] ?? dict["comment"]
        }
        
        // Validate required fields
        guard let finalUsername = username, !finalUsername.isEmpty,
              let finalPassword = password, !finalPassword.isEmpty else {
            return nil
        }
        
        // Generate name from URL if not provided
        let finalName = name?.isEmpty == false ? name! : extractDomainName(from: url) ?? "Unknown"
        
        // Clean up URL
        var finalURL = url
        if let urlString = url, !urlString.isEmpty {
            // Ensure it doesn't have android-app: prefix
            if urlString.hasPrefix("android-app://") {
                finalURL = urlString.replacingOccurrences(of: "android-app://", with: "")
            }
        }
        
        return Credential(
            websiteName: finalName,
            websiteURL: finalURL,
            username: finalUsername,
            password: finalPassword,
            notes: notes?.isEmpty == true ? nil : notes
        )
    }
    
    /// Extract domain name from URL for display
    private static func extractDomainName(from url: String?) -> String? {
        guard let url = url, !url.isEmpty else { return nil }
        
        var domain = url
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .replacingOccurrences(of: "www.", with: "")
        
        if let slashIndex = domain.firstIndex(of: "/") {
            domain = String(domain[..<slashIndex])
        }
        
        // Get the main part before .com/.org/etc
        let parts = domain.components(separatedBy: ".")
        if parts.count >= 2 {
            return parts[parts.count - 2].capitalized
        }
        
        return domain.capitalized
    }
    
    /// Export credentials to CSV format
    static func exportToCSV(_ credentials: [Credential]) -> String {
        var csv = "name,url,username,password,notes\n"
        
        for credential in credentials {
            let name = escapeCSV(credential.websiteName)
            let url = escapeCSV(credential.websiteURL ?? "")
            let username = escapeCSV(credential.username)
            let password = escapeCSV(credential.password)
            let notes = escapeCSV(credential.notes ?? "")
            
            csv += "\(name),\(url),\(username),\(password),\(notes)\n"
        }
        
        return csv
    }
    
    /// Escape a value for CSV
    private static func escapeCSV(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return value
    }
}

// MARK: - CSV Format

enum CSVFormat {
    case chrome
    case firefox
    case safari
    case onePassword
    case lastPass
    case bitwarden
    case dashlane
    case generic
}

#Preview {
    ImportExportView(
        vaultViewModel: .constant(VaultViewModel()),
        isPremium: .constant(true)
    )
}
