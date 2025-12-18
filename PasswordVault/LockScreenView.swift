//
//  LockScreenView.swift
//  PasswordVault
//
//  Created by AI Assistant on 10/12/2025.
//  Displays when app is locked, handles biometric/passcode unlock
//

import SwiftUI

struct LockScreenView: View {
    
    @Bindable var lockManager: AppLockManager
    @State private var isAuthenticating = false
    @State private var showError = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // App icon and name
                VStack(spacing: 16) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.white)
                        .shadow(radius: 10)
                    
                    Text("PasswordVault")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    
                    Text("Locked")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.8))
                }
                
                Spacer()
                
                // Unlock button
                VStack(spacing: 20) {
                    Button {
                        performAuthentication()
                    } label: {
                        HStack(spacing: 12) {
                            if isAuthenticating {
                                ProgressView()
                                    .tint(.blue)
                            } else {
                                Image(systemName: lockManager.biometricType.iconName)
                                    .font(.title2)
                            }
                            
                            Text(unlockButtonText)
                                .font(.headline)
                        }
                        .foregroundStyle(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.white)
                        .cornerRadius(14)
                        .shadow(radius: 5)
                    }
                    .disabled(isAuthenticating)
                    .padding(.horizontal, 40)
                    
                    // Error message
                    if let error = lockManager.authenticationError, showError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(8)
                            .transition(.opacity)
                    }
                }
                
                Spacer()
                
                // Footer
                Text("Your passwords are protected")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.bottom, 30)
            }
        }
        .onAppear {
            // Auto-prompt for authentication on appear
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                performAuthentication()
            }
        }
    }
    
    private var unlockButtonText: String {
        switch lockManager.biometricType {
        case .faceID:
            return "Unlock with Face ID"
        case .touchID:
            return "Unlock with Touch ID"
        case .opticID:
            return "Unlock with Optic ID"
        case .none:
            return "Unlock with Passcode"
        }
    }
    
    private func performAuthentication() {
        isAuthenticating = true
        showError = false
        
        Task {
            let success = await lockManager.authenticate()
            
            await MainActor.run {
                isAuthenticating = false
                if !success {
                    showError = true
                    
                    // Hide error after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation {
                            showError = false
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    LockScreenView(lockManager: AppLockManager())
}
