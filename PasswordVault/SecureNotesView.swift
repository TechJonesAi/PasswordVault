//
//  SecureNotesView.swift
//  PasswordVault
//
//  Created by AI Assistant on 10/12/2025.
//  Feature 4: Secure Notes - Store PINs, recovery codes, secrets
//

import SwiftUI

struct SecureNotesView: View {
    
    @Binding var isPremium: Bool
    @State private var notes: [SecureNote] = []
    @State private var searchText = ""
    @State private var showAddNote = false
    @State private var selectedNote: SecureNote?
    @State private var showPaywall = false
    var premiumManager: PremiumManager
    
    private let keychainService = SecureKeychainService()
    
    var filteredNotes: [SecureNote] {
        if searchText.isEmpty {
            return notes.sorted { $0.isFavourite && !$1.isFavourite }
        }
        return notes.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.content.localizedCaseInsensitiveContains(searchText)
        }.sorted { $0.isFavourite && !$1.isFavourite }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if notes.isEmpty {
                    emptyStateView
                } else {
                    notesList
                }
            }
            .navigationTitle("Secure Notes")
            .searchable(text: $searchText, prompt: "Search notes")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        if isPremium {
                            showAddNote = true
                        } else {
                            showPaywall = true
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddNote) {
                AddEditNoteView(
                    isPresented: $showAddNote,
                    onSave: { note in
                        saveNote(note)
                    }
                )
            }
            .sheet(item: $selectedNote) { note in
                AddEditNoteView(
                    isPresented: .constant(true),
                    existingNote: note,
                    onSave: { updatedNote in
                        updateNote(updatedNote)
                        selectedNote = nil
                    },
                    onDismiss: {
                        selectedNote = nil
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
                loadNotes()
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "note.text")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("No Secure Notes")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Store PINs, recovery codes, WiFi passwords, and other sensitive information securely.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                if isPremium {
                    showAddNote = true
                } else {
                    showPaywall = true
                }
            } label: {
                Label("Add Note", systemImage: "plus")
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
    
    // MARK: - Notes List
    
    private var notesList: some View {
        List {
            // Favourites section
            let favourites = filteredNotes.filter { $0.isFavourite }
            if !favourites.isEmpty {
                Section("Favourites") {
                    ForEach(favourites) { note in
                        NoteRow(note: note)
                            .onTapGesture {
                                selectedNote = note
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteNote(note)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    toggleFavourite(note)
                                } label: {
                                    Label("Unfavourite", systemImage: "star.slash")
                                }
                                .tint(.orange)
                            }
                    }
                }
            }
            
            // All notes section
            let otherNotes = filteredNotes.filter { !$0.isFavourite }
            if !otherNotes.isEmpty {
                Section(favourites.isEmpty ? "All Notes" : "Other Notes") {
                    ForEach(otherNotes) { note in
                        NoteRow(note: note)
                            .onTapGesture {
                                selectedNote = note
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteNote(note)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    toggleFavourite(note)
                                } label: {
                                    Label("Favourite", systemImage: "star.fill")
                                }
                                .tint(.orange)
                            }
                    }
                }
            }
        }
    }
    
    // MARK: - Data Operations
    
    private func loadNotes() {
        notes = (try? keychainService.fetchSecureNotes()) ?? []
    }
    
    private func saveNote(_ note: SecureNote) {
        notes.append(note)
        try? keychainService.saveSecureNotes(notes)
    }
    
    private func updateNote(_ note: SecureNote) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index] = note
            try? keychainService.saveSecureNotes(notes)
        }
    }
    
    private func deleteNote(_ note: SecureNote) {
        notes.removeAll { $0.id == note.id }
        try? keychainService.saveSecureNotes(notes)
    }
    
    private func toggleFavourite(_ note: SecureNote) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index].isFavourite.toggle()
            try? keychainService.saveSecureNotes(notes)
        }
    }
}

// MARK: - Note Row

struct NoteRow: View {
    let note: SecureNote
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: "note.text")
                    .font(.title3)
                    .foregroundStyle(.blue)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(note.title)
                        .font(.headline)
                    
                    if note.isFavourite {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
                
                Text(note.content.prefix(50) + (note.content.count > 50 ? "..." : ""))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                if let folder = note.folder {
                    HStack(spacing: 4) {
                        Image(systemName: folder.iconName)
                            .font(.caption2)
                        Text(folder.rawValue)
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add/Edit Note View

struct AddEditNoteView: View {
    
    @Binding var isPresented: Bool
    var existingNote: SecureNote?
    var onSave: (SecureNote) -> Void
    var onDismiss: (() -> Void)?
    
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var folder: PasswordFolder?
    @State private var isFavourite: Bool = false
    
    private var isEditing: Bool { existingNote != nil }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("Note title", text: $title)
                }
                
                Section("Content") {
                    TextEditor(text: $content)
                        .frame(minHeight: 150)
                }
                
                Section("Organisation") {
                    Picker("Folder", selection: $folder) {
                        Text("None").tag(nil as PasswordFolder?)
                        ForEach(PasswordFolder.allCases) { folder in
                            Label(folder.rawValue, systemImage: folder.iconName)
                                .tag(folder as PasswordFolder?)
                        }
                    }
                    
                    Toggle(isOn: $isFavourite) {
                        Label("Favourite", systemImage: "star.fill")
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Note" : "New Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onDismiss?()
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        let note = SecureNote(
                            id: existingNote?.id ?? UUID(),
                            title: title,
                            content: content,
                            folder: folder,
                            isFavourite: isFavourite,
                            createdDate: existingNote?.createdDate ?? Date(),
                            lastModifiedDate: Date()
                        )
                        onSave(note)
                        isPresented = false
                    }
                    .disabled(title.isEmpty || content.isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                if let note = existingNote {
                    title = note.title
                    content = note.content
                    folder = note.folder
                    isFavourite = note.isFavourite
                }
            }
        }
    }
}

#Preview {
    SecureNotesView(
        isPremium: .constant(true),
        premiumManager: PremiumManager()
    )
}
