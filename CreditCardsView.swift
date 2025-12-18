//
//  CreditCardsView.swift
//  PasswordVault
//
//  Created by AI Assistant on 10/12/2025.
//  Feature 7: Credit Card Storage
//

import SwiftUI

struct CreditCardsView: View {
    
    @Binding var isPremium: Bool
    @State private var cards: [CreditCard] = []
    @State private var showAddCard = false
    @State private var selectedCard: CreditCard?
    @State private var showPaywall = false
    var premiumManager: PremiumManager
    
    private let keychainService = SecureKeychainService()
    
    var body: some View {
        NavigationStack {
            Group {
                if cards.isEmpty {
                    emptyStateView
                } else {
                    cardsList
                }
            }
            .navigationTitle("Credit Cards")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        if isPremium {
                            showAddCard = true
                        } else {
                            showPaywall = true
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddCard) {
                AddEditCardView(
                    isPresented: $showAddCard,
                    onSave: { card in
                        saveCard(card)
                    }
                )
            }
            .sheet(item: $selectedCard) { card in
                CardDetailView(
                    card: card,
                    onUpdate: { updatedCard in
                        updateCard(updatedCard)
                        selectedCard = nil
                    },
                    onDelete: {
                        deleteCard(card)
                        selectedCard = nil
                    },
                    onDismiss: {
                        selectedCard = nil
                    }
                )
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(
                    isPresented: $showPaywall,
                    premiumManager: premiumManager,
                    onPurchaseComplete: {}
                )
            }
            .onAppear {
                loadCards()
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "creditcard")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("No Credit Cards")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Securely store your credit and debit card details for quick reference.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                if isPremium {
                    showAddCard = true
                } else {
                    showPaywall = true
                }
            } label: {
                Label("Add Card", systemImage: "plus")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.top, 10)
            
            if !isPremium {
                Label("Premium Feature", systemImage: "crown.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }
    
    // MARK: - Cards List
    
    private var cardsList: some View {
        List {
            ForEach(cards) { card in
                CardRow(card: card)
                    .onTapGesture {
                        selectedCard = card
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            deleteCard(card)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
    }
    
    // MARK: - Data Operations
    
    private func loadCards() {
        cards = (try? keychainService.fetchCreditCards()) ?? []
    }
    
    private func saveCard(_ card: CreditCard) {
        cards.append(card)
        try? keychainService.saveCreditCards(cards)
    }
    
    private func updateCard(_ card: CreditCard) {
        if let index = cards.firstIndex(where: { $0.id == card.id }) {
            cards[index] = card
            try? keychainService.saveCreditCards(cards)
        }
    }
    
    private func deleteCard(_ card: CreditCard) {
        cards.removeAll { $0.id == card.id }
        try? keychainService.saveCreditCards(cards)
    }
}

// MARK: - Card Row

struct CardRow: View {
    let card: CreditCard
    
    var body: some View {
        HStack(spacing: 16) {
            // Card visual
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(cardGradient)
                    .frame(width: 60, height: 40)
                
                Image(systemName: "creditcard.fill")
                    .foregroundStyle(.white)
            }
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(card.cardName)
                        .font(.headline)
                    
                    if card.isExpired {
                        Text("EXPIRED")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .cornerRadius(4)
                    } else if card.expiresSoon {
                        Text("EXPIRES SOON")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .cornerRadius(4)
                    }
                }
                
                Text(card.maskedNumber)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                HStack {
                    Text(card.cardType.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("•")
                        .foregroundStyle(.secondary)
                    
                    Text("Expires \(card.expiryDateFormatted)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8)
    }
    
    private var cardGradient: LinearGradient {
        switch card.cardType {
        case .visa:
            return LinearGradient(colors: [.blue, .blue.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .mastercard:
            return LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .amex:
            return LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            return LinearGradient(colors: [.gray, .gray.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

// MARK: - Add/Edit Card View

struct AddEditCardView: View {
    
    @Binding var isPresented: Bool
    var existingCard: CreditCard?
    var onSave: (CreditCard) -> Void
    
    @State private var cardName: String = ""
    @State private var cardholderName: String = ""
    @State private var cardNumber: String = ""
    @State private var expiryMonth: Int = 1
    @State private var expiryYear: Int = Calendar.current.component(.year, from: Date())
    @State private var cvv: String = ""
    @State private var billingAddress: String = ""
    @State private var notes: String = ""
    @State private var detectedCardType: CardType = .unknown
    
    private var isEditing: Bool { existingCard != nil }
    
    private var isValid: Bool {
        !cardName.isEmpty &&
        !cardholderName.isEmpty &&
        cardNumber.count >= 13 &&
        cvv.count >= 3
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Card Preview
                Section {
                    CardPreview(
                        cardNumber: cardNumber,
                        cardholderName: cardholderName,
                        expiryMonth: expiryMonth,
                        expiryYear: expiryYear,
                        cardType: detectedCardType
                    )
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                
                Section("Card Details") {
                    TextField("Card Name (e.g., Personal Visa)", text: $cardName)
                    
                    TextField("Cardholder Name", text: $cardholderName)
                        .textContentType(.name)
                    
                    TextField("Card Number", text: $cardNumber)
                        .keyboardType(.numberPad)
                        .textContentType(.creditCardNumber)
                        .onChange(of: cardNumber) {
                            // Remove non-digits
                            cardNumber = cardNumber.filter { $0.isNumber }
                            // Limit to 19 digits
                            if cardNumber.count > 19 {
                                cardNumber = String(cardNumber.prefix(19))
                            }
                            // Detect card type
                            detectedCardType = CardType.detect(from: cardNumber)
                        }
                    
                    HStack {
                        Text("Detected Type:")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(detectedCardType.rawValue)
                            .foregroundStyle(.blue)
                    }
                }
                
                Section("Expiry & Security") {
                    HStack {
                        Picker("Month", selection: $expiryMonth) {
                            ForEach(1...12, id: \.self) { month in
                                Text(String(format: "%02d", month)).tag(month)
                            }
                        }
                        .pickerStyle(.menu)
                        
                        Text("/")
                        
                        Picker("Year", selection: $expiryYear) {
                            ForEach(currentYear...(currentYear + 15), id: \.self) { year in
                                Text(String(year)).tag(year)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    SecureField("CVV", text: $cvv)
                        .keyboardType(.numberPad)
                        .onChange(of: cvv) {
                            cvv = cvv.filter { $0.isNumber }
                            if cvv.count > 4 {
                                cvv = String(cvv.prefix(4))
                            }
                        }
                }
                
                Section("Additional Info (Optional)") {
                    TextField("Billing Address", text: $billingAddress, axis: .vertical)
                        .lineLimit(2...4)
                    
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle(isEditing ? "Edit Card" : "Add Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        let card = CreditCard(
                            id: existingCard?.id ?? UUID(),
                            cardName: cardName,
                            cardholderName: cardholderName,
                            cardNumber: cardNumber,
                            expiryMonth: expiryMonth,
                            expiryYear: expiryYear,
                            cvv: cvv,
                            cardType: detectedCardType,
                            billingAddress: billingAddress.isEmpty ? nil : billingAddress,
                            notes: notes.isEmpty ? nil : notes,
                            createdDate: existingCard?.createdDate ?? Date(),
                            lastModifiedDate: Date()
                        )
                        onSave(card)
                        isPresented = false
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                if let card = existingCard {
                    cardName = card.cardName
                    cardholderName = card.cardholderName
                    cardNumber = card.cardNumber
                    expiryMonth = card.expiryMonth
                    expiryYear = card.expiryYear
                    cvv = card.cvv
                    billingAddress = card.billingAddress ?? ""
                    notes = card.notes ?? ""
                    detectedCardType = card.cardType
                }
            }
        }
    }
    
    private var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }
}

// MARK: - Card Preview

struct CardPreview: View {
    let cardNumber: String
    let cardholderName: String
    let expiryMonth: Int
    let expiryYear: Int
    let cardType: CardType
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(cardGradient)
                .frame(height: 200)
                .shadow(radius: 10)
            
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text(cardType.rawValue)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                    Image(systemName: "wave.3.right")
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                Spacer()
                
                Text(formattedCardNumber)
                    .font(.system(size: 22, design: .monospaced))
                    .foregroundStyle(.white)
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("CARDHOLDER")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.7))
                        Text(cardholderName.isEmpty ? "YOUR NAME" : cardholderName.uppercased())
                            .font(.caption)
                            .foregroundStyle(.white)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("EXPIRES")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.7))
                        Text(String(format: "%02d/%02d", expiryMonth, expiryYear % 100))
                            .font(.caption)
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding(24)
        }
        .padding()
    }
    
    private var formattedCardNumber: String {
        let cleaned = cardNumber.isEmpty ? "0000000000000000" : cardNumber.padding(toLength: 16, withPad: "•", startingAt: 0)
        var formatted = ""
        for (index, char) in cleaned.enumerated() {
            if index > 0 && index % 4 == 0 {
                formatted += " "
            }
            formatted += String(char)
        }
        return String(formatted.prefix(19))
    }
    
    private var cardGradient: LinearGradient {
        switch cardType {
        case .visa:
            return LinearGradient(colors: [Color(red: 0.1, green: 0.2, blue: 0.5), Color(red: 0.2, green: 0.3, blue: 0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .mastercard:
            return LinearGradient(colors: [Color.orange, Color.red], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .amex:
            return LinearGradient(colors: [Color(red: 0.0, green: 0.5, blue: 0.5), Color(red: 0.0, green: 0.3, blue: 0.5)], startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            return LinearGradient(colors: [Color.gray, Color.gray.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

// MARK: - Card Detail View

struct CardDetailView: View {
    let card: CreditCard
    var onUpdate: (CreditCard) -> Void
    var onDelete: () -> Void
    var onDismiss: () -> Void
    
    @State private var showFullNumber = false
    @State private var showCVV = false
    @State private var showEditSheet = false
    @State private var showDeleteConfirm = false
    @State private var copiedField: String?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Card Preview
                    CardPreview(
                        cardNumber: showFullNumber ? card.cardNumber : String(repeating: "•", count: 12) + card.cardNumber.suffix(4),
                        cardholderName: card.cardholderName,
                        expiryMonth: card.expiryMonth,
                        expiryYear: card.expiryYear,
                        cardType: card.cardType
                    )
                    
                    // Details
                    VStack(spacing: 16) {
                        DetailRow(
                            label: "Card Number",
                            value: showFullNumber ? formatCardNumber(card.cardNumber) : card.maskedNumber,
                            isSecure: true,
                            isRevealed: showFullNumber,
                            onToggle: { showFullNumber.toggle() },
                            onCopy: {
                                copyToClipboard(card.cardNumber, field: "Card Number")
                            },
                            copiedField: copiedField,
                            fieldName: "Card Number"
                        )
                        
                        DetailRow(
                            label: "CVV",
                            value: showCVV ? card.cvv : "•••",
                            isSecure: true,
                            isRevealed: showCVV,
                            onToggle: { showCVV.toggle() },
                            onCopy: {
                                copyToClipboard(card.cvv, field: "CVV")
                            },
                            copiedField: copiedField,
                            fieldName: "CVV"
                        )
                        
                        DetailRow(
                            label: "Expiry",
                            value: card.expiryDateFormatted,
                            isSecure: false,
                            onCopy: {
                                copyToClipboard(card.expiryDateFormatted, field: "Expiry")
                            },
                            copiedField: copiedField,
                            fieldName: "Expiry"
                        )
                        
                        DetailRow(
                            label: "Cardholder",
                            value: card.cardholderName,
                            isSecure: false,
                            onCopy: {
                                copyToClipboard(card.cardholderName, field: "Cardholder")
                            },
                            copiedField: copiedField,
                            fieldName: "Cardholder"
                        )
                        
                        if let address = card.billingAddress, !address.isEmpty {
                            DetailRow(
                                label: "Billing Address",
                                value: address,
                                isSecure: false,
                                onCopy: {
                                    copyToClipboard(address, field: "Billing Address")
                                },
                                copiedField: copiedField,
                                fieldName: "Billing Address"
                            )
                        }
                        
                        if let notes = card.notes, !notes.isEmpty {
                            DetailRow(
                                label: "Notes",
                                value: notes,
                                isSecure: false,
                                onCopy: {
                                    copyToClipboard(notes, field: "Notes")
                                },
                                copiedField: copiedField,
                                fieldName: "Notes"
                            )
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // Delete button
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete Card", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 30)
            }
            .navigationTitle(card.cardName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        onDismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") {
                        showEditSheet = true
                    }
                }
            }
            .sheet(isPresented: $showEditSheet) {
                AddEditCardView(
                    isPresented: $showEditSheet,
                    existingCard: card,
                    onSave: onUpdate
                )
            }
            .alert("Delete Card?", isPresented: $showDeleteConfirm) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    onDelete()
                }
            } message: {
                Text("This cannot be undone.")
            }
        }
    }
    
    private func formatCardNumber(_ number: String) -> String {
        var formatted = ""
        for (index, char) in number.enumerated() {
            if index > 0 && index % 4 == 0 {
                formatted += " "
            }
            formatted += String(char)
        }
        return formatted
    }
    
    private func copyToClipboard(_ value: String, field: String) {
        UIPasteboard.general.string = value
        copiedField = field
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if copiedField == field {
                copiedField = nil
            }
        }
    }
}

// MARK: - Detail Row

struct DetailRow: View {
    let label: String
    let value: String
    var isSecure: Bool = false
    var isRevealed: Bool = false
    var onToggle: (() -> Void)? = nil
    var onCopy: () -> Void
    var copiedField: String?
    var fieldName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            HStack {
                Text(value)
                    .font(.body)
                    .fontDesign(isSecure ? .monospaced : .default)
                
                Spacer()
                
                if isSecure {
                    Button {
                        onToggle?()
                    } label: {
                        Image(systemName: isRevealed ? "eye.slash" : "eye")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Button {
                    onCopy()
                } label: {
                    Image(systemName: copiedField == fieldName ? "checkmark" : "doc.on.doc")
                        .foregroundStyle(copiedField == fieldName ? .green : .secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
}

#Preview {
    CreditCardsView(
        isPremium: .constant(true),
        premiumManager: PremiumManager()
    )
}
