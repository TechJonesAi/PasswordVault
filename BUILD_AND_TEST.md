# PasswordVault - Final Build & Test Guide

## 🏗 BUILD STEPS

### Step 1: Open Project in Xcode
```bash
cd "SWIFT APPS/PasswordVault"
open PasswordVault.xcodeproj
```

### Step 2: Configure Signing (Both Targets)

#### Main App (PasswordVault):
1. Select **PasswordVault** target
2. **Signing & Capabilities** tab
3. Team: Select your Apple Developer team
4. Bundle ID: `co.uk.techjonesai.PasswordVault`

#### Extension (PasswordVaultAutoFill):
1. Select **PasswordVaultAutoFill** target
2. **Signing & Capabilities** tab
3. Team: **SAME team** as main app
4. Bundle ID: `co.uk.techjonesai.PasswordVault.PasswordVaultAutoFill`

### Step 3: Add iCloud Capability (Main App Only)
1. Select **PasswordVault** target
2. **+ Capability** → **iCloud**
3. Check **CloudKit**
4. Add container: `iCloud.co.uk.techjonesai.PasswordVault`

### Step 4: Verify Shared Files Target Membership

Select each file and check **File Inspector** (right panel):

| File | PasswordVault | PasswordVaultAutoFill |
|------|:-------------:|:---------------------:|
| `Credential.swift` | ☑️ | ☑️ |
| `KeychainService.swift` | ☑️ | ☑️ |
| `PasswordGenerator.swift` | ☑️ | ☑️ (optional) |

### Step 5: Configure StoreKit Testing
1. **Product** → **Scheme** → **Edit Scheme**
2. Select **Run** → **Options** tab
3. **StoreKit Configuration**: `Products.storekit`

### Step 6: Build
```
Cmd + B
```

### Step 7: Run
```
Cmd + R
```

---

## 🧪 TEST CHECKLIST

### ✅ App Launch
- [ ] App launches without crash
- [ ] Onboarding shows (first launch)
- [ ] Main tab view shows after onboarding

### ✅ Password Generator (Tab 1)
- [ ] Generate password button works
- [ ] Length slider changes password length
- [ ] Character toggles work
- [ ] Copy to clipboard works
- [ ] Strength indicator updates

### ✅ Vault (Tab 2) - Free Tier
- [ ] Empty state shows if no passwords
- [ ] Can add 1 password
- [ ] Password appears in list
- [ ] Can view password details
- [ ] Paywall appears when adding 2nd password

### ✅ Vault - Premium
- [ ] Purchase premium subscription
- [ ] Can add unlimited passwords
- [ ] Folders filter works
- [ ] Favourites show at top
- [ ] Expiry warnings show (if applicable)
- [ ] Delete works

### ✅ Secure Notes (Tab 3)
- [ ] Premium upsell shows (if free)
- [ ] Can add notes (if premium)
- [ ] Notes save and persist

### ✅ Credit Cards (Tab 4)
- [ ] Premium upsell shows (if free)
- [ ] Can add cards (if premium)
- [ ] Card type auto-detects
- [ ] Cards save and persist

### ✅ Settings (Tab 5)
- [ ] Biometric toggle works (if device supports)
- [ ] Auto-lock toggle works
- [ ] iCloud status shows
- [ ] iCloud sync toggle works (premium)
- [ ] App icon picker works (premium)
- [ ] Import/Export button works
- [ ] Restore purchases works

### ✅ AutoFill Extension
1. Open **Settings** app on iPhone
2. Search for **"Passwords"** (or scroll to find it)
3. Tap **AutoFill Passwords and Passkeys**
4. Turn ON **PasswordVault**
5. Open Safari
6. Go to any login page (e.g., github.com)
7. Tap password field
- [ ] PasswordVault appears in QuickType bar
- [ ] Tapping shows credential list
- [ ] Selecting fills password

### ✅ iCloud Sync (Premium)
- [ ] Enable iCloud sync in Settings
- [ ] Tap "Sync Now"
- [ ] Success message appears
- [ ] Last sync date updates

### ✅ Biometric Lock (Premium)
- [ ] Enable biometric lock in Settings
- [ ] Press home/lock device
- [ ] Reopen app
- [ ] Lock screen appears
- [ ] Biometric unlocks app

---

## 🐛 TROUBLESHOOTING

### Build Error: "Cannot find 'X' in scope"
**Solution:** Check target membership of the missing file.

### Extension Not Appearing in Settings
**Solution:** 
1. Delete app from device
2. Clean build (Cmd+Shift+K)
3. Rebuild and run
4. Go to Settings → search "Passwords" → AutoFill Passwords and Passkeys → Enable PasswordVault

### iCloud Sync Fails
**Solution:**
1. Check you're signed into iCloud
2. Check iCloud capability is added in Xcode
3. Check container ID matches code

### Premium Purchase Not Working
**Solution:**
1. Check Products.storekit exists
2. Check StoreKit configuration in scheme
3. Restart Xcode

### Keychain Errors
**Solution:**
1. Check App Groups match in both targets
2. Check entitlements files are correct
3. Delete app and reinstall

---

## 📊 FEATURE SUMMARY

| Feature | Free | Premium |
|---------|:----:|:-------:|
| Password Generator | ✅ | ✅ |
| 1 Saved Password | ✅ | ✅ |
| Unlimited Passwords | ❌ | ✅ |
| Biometric Lock | ❌ | ✅ |
| Auto-Lock Timer | ❌ | ✅ |
| Folders/Categories | ❌ | ✅ |
| Favourites | ❌ | ✅ |
| Secure Notes | ❌ | ✅ |
| Credit Cards | ❌ | ✅ |
| iCloud Sync | ❌ | ✅ |
| Custom App Icons | ❌ | ✅ |
| Password Expiry | ❌ | ✅ |
| AutoFill Extension | ❌ | ✅ |
| Health Dashboard | ❌ | ✅ |

---

## 🎉 SUCCESS!

If all tests pass, your PasswordVault app is complete and ready for:
- App Store submission
- TestFlight beta testing
- Further customization

---

## 📚 DOCUMENTATION

- `FEATURE_STATUS.md` - All features and their status
- `CONFIGURATION_FIXES.md` - Configuration changes made
- `QUICK_START.md` - Quick setup guide
- `DO_THIS_NOW.md` - Extension troubleshooting
- `SETUP_INSTRUCTIONS.md` - Detailed setup

---

**Good luck! 🚀**
