# Adding Share Extension to PasswordVault

## Quick Setup (2 minutes)

### Step 1: Add New Target in Xcode
1. Open PasswordVault in Xcode
2. File → New → Target...
3. Search for "Share Extension"
4. Select it → Click Next
5. Product Name: `PasswordVaultShare`
6. Click Finish
7. When asked "Activate scheme?" → Click Cancel

### Step 2: Replace Generated Files
After Xcode creates the extension, replace these files:

1. Delete the auto-generated `ShareViewController.swift` in the PasswordVaultShare folder
2. In Finder, copy `ShareViewController.swift` from `PasswordVaultShareExtension` folder to `PasswordVaultShare` folder
3. Drag the copied file into Xcode under the PasswordVaultShare group

### Step 3: Add Entitlements
1. Select PasswordVaultShare target in Xcode
2. Go to Signing & Capabilities tab
3. Click + Capability
4. Add "App Groups" → check `group.co.uk.techjonesai.PasswordVaultShared`
5. Add "Keychain Sharing" → add `group.co.uk.techjonesai.PasswordVaultShared`

### Step 4: Add Shared Files to Target
Select these files and in the File Inspector (right panel), check the PasswordVaultShare target:
- Credential.swift
- KeychainService.swift
- SecureKeychainService.swift

### Step 5: Update Info.plist
Replace the contents of PasswordVaultShare/Info.plist with the Info.plist from PasswordVaultShareExtension folder.

### Step 6: Build & Run
Build the app (Cmd + B) and test!

---

## How to Test

1. Run the app on simulator or device
2. Open Safari
3. Go to any website (e.g., gmail.com)
4. Tap the Share button
5. Scroll and find "Save to Vault"
6. Fill in credentials and save!
