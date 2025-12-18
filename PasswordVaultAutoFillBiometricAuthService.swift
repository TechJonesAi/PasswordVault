//
//  BiometricAuthService.swift
//  PasswordVaultAutoFill
//
//  Created by AI Assistant on 06/12/2025.
//

import Foundation
import LocalAuthentication

enum BiometricAuthService {
    
    static func authenticate(completion: @escaping (Bool, Error?) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        // Check if biometric authentication is available
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            // Biometrics not available, fall back to passcode
            authenticateWithPasscode(completion: completion)
            return
        }
        
        let reason = "Authenticate to fill your password"
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }
    
    private static func authenticateWithPasscode(completion: @escaping (Bool, Error?) -> Void) {
        let context = LAContext()
        let reason = "Authenticate to fill your password"
        
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }
}
