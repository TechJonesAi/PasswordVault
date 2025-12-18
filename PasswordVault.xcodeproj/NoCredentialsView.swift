//
//  NoCredentialsView.swift
//  PasswordVaultAutoFill
//
//  Created by AI Assistant on 06/12/2025.
//

import SwiftUI

struct NoCredentialsView: View {
    let serviceName: String
    let onOpenApp: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 80))
                    .foregroundStyle(.secondary)
                
                Text("No Passwords Found")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("You don't have any passwords saved for \(serviceName). Open PasswordVault to add one.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Spacer()
                
                VStack(spacing: 12) {
                    Button {
                        onOpenApp()
                    } label: {
                        Text("Open PasswordVault")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    
                    Button {
                        onCancel()
                    } label: {
                        Text("Cancel")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
            .navigationBarHidden(true)
        }
    }
}
