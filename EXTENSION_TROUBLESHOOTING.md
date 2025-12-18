# 🔧 AutoFill Extension Troubleshooting Guide

## ❌ Problem: Extension Not Appearing in Settings

If your PasswordVault extension doesn't appear in **Settings → Passwords → Password Options**, follow these steps:

---

## ✅ Step 1: Verify Info.plist Configuration

The **most common issue** is incorrect or missing Info.plist keys.

### Option A: Using Xcode Info Tab (Recommended)

1. In Xcode, select the **PasswordVaultAutoFill** target
2. Click the **Info** tab
3. Add these keys exactly:

#### Visual Guide:
```
Custom iOS Target Properties
├─ NSExtension (Dictionary)
   ├─ NSExtensionAttributes (Dictionary)
   │  └─ ASCredentialProviderExtensionCapabilities (Dictionary)
   │     └─ ProvidesPasswords (Boolean) = YES
   ├─ NSExtensionPointIdentifier (String) = com.apple.authentication-services-credential-provider-ui
   └─ NSExtensionPrincipalClass (String) = $(PRODUCT_MODULE_NAME).CredentialProviderViewController
```

#### Step-by-Step:
1. Click **+** to add a new key
2. Type: `NSExtension`
3. Change type to **Dictionary**
4. Expand it and add child keys:
   - `NSExtensionAttributes` (Dictionary)
     - Inside this, add: `ASCredentialProviderExtensionCapabilities` (Dictionary)
       - Inside this, add: `ProvidesPasswords` (Boolean) = YES
   - `NSExtensionPointIdentifier` (String) = `com.apple.authentication-services-credential-provider-ui`
   - `NSExtensionPrincipalClass` (String) = `$(PRODUCT_MODULE_NAME).CredentialProviderViewController`

### Option B: Using Physical Info.plist File

If your extension has an `Info.plist` file in the project:

1. Locate `PasswordVaultAutoFill/Info.plist`
2. Right-click → Open As → Source Code
3. Add this XML inside the `<dict>` tag:

```xml
<key>NSExtension</key>
<dict>
    <key>NSExtensionAttributes</key>
    <dict>
        <key>ASCredentialProviderExtensionCapabilities</key>
        <dict>
            <key>ProvidesPasswords</key>
            <true/>
        </dict>
    </dict>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.authentication-services-credential-provider-ui</string>
    <key>NSExtensionPrincipalClass</key>
    <string>$(PRODUCT_MODULE_NAME).CredentialProviderViewController</string>
</dict>
```

**⚠️ CRITICAL:** The extension point identifier MUST be:
- ✅ `com.apple.authentication-services-credential-provider-ui`
- ❌ NOT `com.apple.credential-provider-ui` (missing "authentication-services")

---

## ✅ Step 2: Verify Bundle Identifiers

1. Select **PasswordVault** (main app) target
2. Go to **General** tab
3. Check **Bundle Identifier**: Should be `co.uk.techjonesai.PasswordVault`

4. Select **PasswordVaultAutoFill** (extension) target
5. Go to **General** tab
6. Check **Bundle Identifier**: Should be `co.uk.techjonesai.PasswordVault.PasswordVaultAutoFill`

**⚠️ IMPORTANT:** The extension bundle ID **must** be a child of the app bundle ID!

---

## ✅ Step 3: Verify Capabilities

### Extension Target Capabilities:

1. Select **PasswordVaultAutoFill** target
2. Go to **Signing & Capabilities** tab
3. Ensure these capabilities are present:
   - **Keychain Sharing**
     - Group: `co.uk.techjonesai.PasswordVaultShared`

### Main App Target Capabilities:

1. Select **PasswordVault** target
2. Go to **Signing & Capabilities** tab
3. Ensure these capabilities are present:
   - **Keychain Sharing**
     - Group: `co.uk.techjonesai.PasswordVaultShared`
   - (Optional) **In-App Purchase** (for StoreKit)

**⚠️ CRITICAL:** Both targets must use the **exact same** keychain group!

---

## ✅ Step 4: Verify Extension is Embedded

1. Select **PasswordVault** (main app) target
2. Go to **General** tab
3. Scroll down to **Frameworks, Libraries, and Embedded Content**
4. Look for `PasswordVaultAutoFill.appex`
5. If missing, click **+** and add it

---

## ✅ Step 5: Verify Target Membership

These files **must** be in both targets:

1. **Credential.swift**
   - Select the file in Project Navigator
   - Open File Inspector (right sidebar)
   - Under "Target Membership", check both:
     - ☑️ PasswordVault
     - ☑️ PasswordVaultAutoFill

2. **KeychainService.swift**
   - Select the file
   - Check both targets:
     - ☑️ PasswordVault
     - ☑️ PasswordVaultAutoFill

---

## ✅ Step 6: Clean and Rebuild

1. **Clean Build Folder**: Press **Shift + Cmd + K**
2. **Delete Derived Data**:
   - Go to Xcode → Settings → Locations
   - Click the arrow next to Derived Data path
   - Delete the folder for your project
3. **Delete the app** from your device/simulator
4. **Rebuild**: Press **Cmd + B**
5. **Run**: Press **Cmd + R**

---

## ✅ Step 7: Test on Real Device

**Important:** AutoFill extensions have **limited functionality on simulators**.

### Testing on a Real Device:

1. Connect your iPhone/iPad
2. Select it as the run destination
3. Build and run the app
4. On the device, go to **Settings → Passwords → Password Options**
5. Look for **PasswordVault** in the list

### Common Simulator Limitations:
- Extension may not appear in Settings
- AutoFill may not work in Safari
- Biometric authentication behaves differently

**Recommendation:** Always test AutoFill on a **real device running iOS 17+**

---

## ✅ Step 8: Check Console Logs

1. Open Xcode → **Window → Devices and Simulators**
2. Select your device/simulator
3. Click **Open Console**
4. Filter by: `PasswordVault`
5. Look for errors like:
   - "Extension point not found"
   - "Missing Info.plist keys"
   - "Invalid bundle identifier"

---

## 🐛 Common Error Messages

### Error: "Extension point identifier not found"

**Cause:** Wrong `NSExtensionPointIdentifier` value

**Fix:** Change it to: `com.apple.authentication-services-credential-provider-ui`

### Error: "Principal class not found"

**Cause:** Wrong `NSExtensionPrincipalClass` value or class doesn't exist

**Fix:** 
- Verify the class is named `CredentialProviderViewController`
- Use: `$(PRODUCT_MODULE_NAME).CredentialProviderViewController`

### Error: "Extension not embedded in host app"

**Cause:** Extension isn't included in the main app

**Fix:** 
1. Select main app target
2. General tab → Embed App Extensions
3. Add the extension

### Error: "Keychain access denied"

**Cause:** Keychain groups don't match between app and extension

**Fix:** 
- Both must use: `co.uk.techjonesai.PasswordVaultShared`
- Check Signing & Capabilities tab

---

## 📱 Testing Checklist

After making changes, verify these:

### Extension Appears:
- [ ] Settings → Passwords → Password Options shows PasswordVault
- [ ] Can toggle the switch on/off
- [ ] App icon appears next to the name

### Extension Launches:
- [ ] Open Safari
- [ ] Go to any login page (e.g., twitter.com)
- [ ] Tap on username/password field
- [ ] QuickType bar shows "Passwords" or a key icon
- [ ] Tapping it opens your extension

### Extension Works:
- [ ] Free users see premium upsell
- [ ] Premium users see credential list
- [ ] Can select a credential
- [ ] Credential fills into the form

---

## 🔍 Debugging Tips

### Print Extension Launch
Add this to `CredentialProviderViewController.swift`:

```swift
override func viewDidLoad() {
    super.viewDidLoad()
    print("🚀 Extension loaded successfully!")
}
```

### Check Premium Status
Add this to verify keychain access:

```swift
private func isPremiumUser() -> Bool {
    let isPremium = keychainService.isPremium()
    print("💎 Premium status: \(isPremium)")
    return isPremium
}
```

### Monitor AutoFill Requests
Enable detailed logging:

```swift
override func prepareCredentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
    print("🔍 AutoFill requested for:")
    serviceIdentifiers.forEach { identifier in
        print("  - \(identifier.identifier) (type: \(identifier.type))")
    }
    // ... rest of code
}
```

---

## 🆘 Still Not Working?

### Final Checklist:

1. ✅ Info.plist has correct extension point identifier
2. ✅ Bundle IDs follow parent-child pattern
3. ✅ Keychain groups match exactly
4. ✅ Extension is embedded in main app
5. ✅ Shared files have correct target membership
6. ✅ App is code-signed properly
7. ✅ Testing on a real device (not simulator)
8. ✅ iOS 17+ is installed
9. ✅ Cleaned build folder and deleted app
10. ✅ Checked console logs for errors

### Get Xcode Project Info:

Run these commands in Terminal:

```bash
# Check bundle IDs
xcodebuild -project PasswordVault.xcodeproj -target PasswordVaultAutoFill -showBuildSettings | grep PRODUCT_BUNDLE_IDENTIFIER

# Check if Info.plist exists
find . -name "Info.plist" -path "*/PasswordVaultAutoFill/*"

# Check extension point
plutil -p ./PasswordVaultAutoFill/Info.plist | grep -A 5 NSExtension
```

---

## ✅ Success Criteria

Your extension is properly configured when:

1. ✅ Extension appears in Settings → Passwords → Password Options
2. ✅ Can enable the extension (toggle switch works)
3. ✅ Extension launches when tapping password fields in Safari
4. ✅ Free users see the premium upsell screen
5. ✅ Premium users see the credential list
6. ✅ Selecting a credential fills it into the form
7. ✅ No errors in Xcode console

---

## 💡 Pro Tips

- **Always test on a real device** for AutoFill features
- **Use print statements** to debug extension lifecycle
- **Check keychain groups** first if data isn't shared
- **Clean build often** when changing extension settings
- **Restart your device** if extension doesn't update after rebuilding

---

## 📚 Additional Resources

- [Apple Docs: AutoFill Credential Provider](https://developer.apple.com/documentation/authenticationservices/aspasswordcredentialprovider)
- [WWDC: Implementing AutoFill Credential Provider Extensions](https://developer.apple.com/videos/play/wwdc2018/721/)
- [Extension Programming Guide](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/)

---

**Last Updated:** December 6, 2025

Good luck! 🚀
