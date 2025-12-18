//
//  ConfigurationView.swift
//  PasswordVaultAutoFill
//
//  Created by AI Assistant on 06/12/2025.
//

import SwiftUI

struct ConfigurationView: View {
    let onDone: () -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Enable AutoFill")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    Text("Follow these steps to enable PasswordVault AutoFill:")
                        .font(.body)
                        .foregroundStyle(.secondary)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        InstructionStep(
                            number: 1,
                            title: "Open Settings",
                            description: "Go to your device Settings app"
                        )
                        
                        InstructionStep(
                            number: 2,
                            title: "Find Passwords",
                            description: "Tap on 'Passwords' or 'Password Options'"
                        )
                        
                        InstructionStep(
                            number: 3,
                            title: "Enable AutoFill",
                            description: "Turn on 'AutoFill Passwords and Passkeys'"
                        )
                        
                        InstructionStep(
                            number: 4,
                            title: "Select PasswordVault",
                            description: "Check 'PasswordVault' in the list of password apps"
                        )
                    }
                    .padding(.vertical)
                    
                    Button {
                        // Note: Can't open Settings directly from app extensions
                        // User will need to manually navigate to Settings
                        onDone()
                    } label: {
                        Text("Got It")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onDone()
                    }
                }
            }
        }
    }
}

struct InstructionStep: View {
    let number: Int
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 32, height: 32)
                
                Text("\(number)")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
