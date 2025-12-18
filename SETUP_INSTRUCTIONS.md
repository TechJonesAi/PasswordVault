# PasswordVault - Setup Instructions

## 🎉 Code Generation Complete!

All code files have been created successfully! Now you need to configure target membership and Xcode settings.

---

## 📋 TARGET MEMBERSHIP CONFIGURATION

**CRITICAL:** Some files must be added to BOTH targets (app + extension) for them to work.

### ✅ Files That Need BOTH Targets:

These files must have **PasswordVault** AND **PasswordVaultAutoFill** checked in their target membership:

1. **Credential.swift** ✨
2. **KeychainService.swift** ✨
3. **PasswordGenerator.swift** (optional, but recommended)

### How to Set Target Membership:

1. In Xcode, select the file in the Project Navigator (left sidebar)
2. Open the File Inspector (right sidebar - first tab)
3. Under "Target Membership", check BOTH:
   - ☑️ PasswordVault
   - ☑️ PasswordVaultAutoFill

---

## ⚙️ EXTENSION CONFIGURATION

### 1. Configure Extension Info.plist Keys

The AutoFill extension needs specific configuration. Add these to the **PasswordVaultAutoFill target**:

**Method 1: Using Build Settings (Recommended)**

1. Select **PasswordVaultAutoFill** target
2. Go to **Build Settings** tab
3. Search for "Info.plist"
4. Make sure **"Generate Info.plist File"** is set to **YES**
5. Add these keys:

```
NSExtension
  └─ NSExtensionAttributes
       └─ ASCredentialProviderExtensionCapabilities
            └─ ProvidesPasswords = YES
  └─ NSExtensionPointIdentifier = com.apple.authentication-services-credential-provider-ui
  └─ NSExtensionPrincipalClass = $(PRODUCT_MODULE_NAME).CredentialProviderViewController
```

**Method 2: If You Have a Physical Info.plist File**

If your extension has an Info.plist file, add this:

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

### 2. Verify Extension Bundle ID

Make sure the extension bundle ID is correct:
- Main app: `co.uk.techjonesai.PasswordVault`
- Extension: `co.uk.techjonesai.PasswordVault.PasswordVaultAutoFill`

---

## 🔐 KEYCHAIN ACCESS GROUP

Verify both targets use the same keychain group:

1. Select **PasswordVault** target → **Signing & Capabilities**
2. Under **Keychain Sharing**, confirm: `co.uk.techjonesai.PasswordVaultShared`
3. Select **PasswordVaultAutoFill** target → **Signing & Capabilities**
4. Under **Keychain Sharing**, confirm: `co.uk.techjonesai.PasswordVaultShared`

Both must match exactly!

---

## 🛒 STOREKIT CONFIGURATION

Verify StoreKit is set up correctly:

1. **Product → Scheme → Edit Scheme**
2. Select **Run** → **Options** tab
3. **StoreKit Configuration** should be set to: **Products.storekit**

---

## 🏗️ BUILD THE APP

1. Select **PasswordVault** scheme (not the extension)
2. Choose a simulator or device
3. Press **Cmd+B** to build
4. Fix any build errors (most likely target membership issues)

---

## ✅ TESTING CHECKLIST

### Phase 1: Basic App Testing

- [ ] App launches without crashes
- [ ] Onboarding shows on first launch
- [ ] Can dismiss onboarding with "Start Free"
- [ ] Generator tab creates passwords
- [ ] Can adjust password settings (length, character types)
- [ ] Strength indicator works
- [ ] Copy to clipboard works

### Phase 2: Vault Testing (Free Tier)

- [ ] Can save 1 password
- [ ] Password appears in vault list
- [ ] Can tap to view password details
- [ ] Can edit password
- [ ] Can delete password
- [ ] Trying to save 2nd password shows paywall
- [ ] "1/1 passwords used" badge shows

### Phase 3: Premium Testing

- [ ] Paywall appears when trying to save 2nd password
- [ ] Can see both subscription options (Monthly/Yearly)
- [ ] Can select a product
- [ ] Subscribe button works (StoreKit testing)
- [ ] After purchase, "Premium Active" shows in Settings
- [ ] Can now save unlimited passwords
- [ ] Health tab shows dashboard (not upsell)

### Phase 4: Health Dashboard (Premium)

- [ ] Security score displays
- [ ] Weak/Reused/Old password cards show
- [ ] Suggestions appear
- [ ] Pull to refresh works

### Phase 5: AutoFill Extension

**Enable the Extension:**
1. Go to iOS **Settings** app
2. **Passwords** → **Password Options**
3. Enable **PasswordVault**

**Test AutoFill:**
- [ ] Open Safari
- [ ] Go to a login page
- [ ] Tap password field
- [ ] PasswordVault appears in QuickType bar or AutoFill
- [ ] If FREE: Shows premium upsell
- [ ] If PREMIUM: Shows saved passwords
- [ ] Selecting a password fills it in

---

## 🐛 COMMON BUILD ISSUES

### Issue: "Cannot find 'Credential' in scope"

**Solution:** Add `Credential.swift` to the extension target:
1. Select `Credential.swift`
2. File Inspector → Target Membership
3. Check ☑️ PasswordVaultAutoFill

### Issue: "Cannot find 'KeychainService' in scope"

**Solution:** Add `KeychainService.swift` to the extension target:
1. Select `KeychainService.swift`
2. File Inspector → Target Membership
3. Check ☑️ PasswordVaultAutoFill

### Issue: "No such module 'AuthenticationServices'"

**Solution:** This is normal for the main app target. Only the extension needs this. Make sure the file is in the correct target.

### Issue: Extension doesn't appear in Settings

**Solution:** 
1. Check extension's Info.plist has correct keys
2. Verify extension bundle ID format: `com.company.app.extension`
3. Try deleting the app and reinstalling

### Issue: StoreKit products not loading

**Solution:**
1. Verify Products.storekit file exists
2. Check scheme has StoreKit Configuration set
3. Try cleaning build folder (Shift+Cmd+K)
4. Restart Xcode

---

## 📱 TESTING PREMIUM FEATURES

### Testing Purchases (StoreKit Testing)

1. No real money is charged during development
2. You can "purchase" unlimited times
3. Use Xcode's **StoreKit Transaction Manager** to:
   - View transactions
   - Clear purchases (Debug → StoreKit → Manage Transactions)
   - Test restore purchases

### Reset Premium Status

To test the free tier again:
1. Go to Xcode → **Debug** → **StoreKit** → **Manage Transactions**
2. Delete all transactions
3. Restart the app
4. Premium status will reset to free

---

## 🎯 NEXT STEPS

1. **Set target membership** for shared files ✨
2. **Configure extension Info.plist** ⚙️
3. **Build the app** 🏗️
4. **Test free tier** (1 password limit)
5. **Test premium purchase**
6. **Enable and test AutoFill extension**

---

## 💡 TIPS

- Use **iPhone 15 Pro** simulator (iOS 17+)
- Test on a real device for AutoFill (simulators have limitations)
- Check Xcode console for error messages
- Use breakpoints to debug issues
- StoreKit testing is fully local (no App Store Connect needed)

---

## 🆘 NEED HELP?

If you encounter issues:
1. Check the **Target Membership** of all files
2. Verify **Keychain Groups** match exactly
3. Check **Extension Info.plist** configuration
4. Clean build folder (Shift+Cmd+K) and rebuild
5. Review error messages in Xcode console

---

## ✅ SUCCESS CRITERIA

Your app is working correctly when:
- ✅ No build errors
- ✅ App launches and shows onboarding
- ✅ Can generate and save 1 password (free)
- ✅ Paywall blocks 2nd password
- ✅ Premium purchase works
- ✅ After premium: unlimited passwords
- ✅ Health dashboard shows (premium only)
- ✅ AutoFill extension appears in Settings
- ✅ Extension fills passwords in Safari (premium only)

---

## 🎉 YOU'RE READY TO GO!

All the code is complete. Now just configure the settings above and start testing!

Good luck! 🚀
