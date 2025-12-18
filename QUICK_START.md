# PasswordVault - Quick Start Checklist

## ⚡ IMMEDIATE NEXT STEPS

Follow these steps **in order** to get your app running:

---

## ✅ STEP 1: Set Target Membership (CRITICAL!)

### Files That Need BOTH Targets:

Open each file below and set target membership:

#### 1. Credential.swift
- [ ] Select file in Project Navigator
- [ ] File Inspector (right sidebar)
- [ ] Target Membership:
  - [ ] ✅ PasswordVault
  - [ ] ✅ PasswordVaultAutoFill

#### 2. KeychainService.swift
- [ ] Select file in Project Navigator
- [ ] File Inspector (right sidebar)
- [ ] Target Membership:
  - [ ] ✅ PasswordVault
  - [ ] ✅ PasswordVaultAutoFill

#### 3. PasswordGenerator.swift (Optional but recommended)
- [ ] Select file in Project Navigator
- [ ] File Inspector (right sidebar)
- [ ] Target Membership:
  - [ ] ✅ PasswordVault
  - [ ] ✅ PasswordVaultAutoFill

---

## ✅ STEP 2: Configure Extension Target

### Check Extension Bundle ID:
- [ ] Select **PasswordVaultAutoFill** target
- [ ] General tab
- [ ] Bundle Identifier should be: `co.uk.techjonesai.PasswordVault.PasswordVaultAutoFill`

### Verify Extension Capabilities:
- [ ] Select **PasswordVaultAutoFill** target
- [ ] Signing & Capabilities tab
- [ ] Should have **Keychain Sharing** with: `co.uk.techjonesai.PasswordVaultShared`

---

## ✅ STEP 3: First Build

- [ ] Select **PasswordVault** scheme (top toolbar)
- [ ] Select iPhone 15 Pro simulator (or any iOS 17+ device)
- [ ] Press **⌘ + B** (Build)

### If Build Fails:

**Check for these common errors:**

1. **"Cannot find 'Credential' in scope"**
   → Add Credential.swift to extension target (Step 1)

2. **"Cannot find 'KeychainService' in scope"**
   → Add KeychainService.swift to extension target (Step 1)

3. **"No such module 'SwiftUI'"**
   → Make sure file is in correct target

4. **StoreKit errors**
   → Verify Products.storekit is in project
   → Check scheme has StoreKit Configuration set

---

## ✅ STEP 4: Run the App

- [ ] Press **⌘ + R** (Run)
- [ ] App should launch in simulator
- [ ] You should see the onboarding flow

---

## ✅ STEP 5: Test Free Tier

### Test Password Generator:
- [ ] Go to Generator tab
- [ ] Adjust length slider
- [ ] Toggle character options
- [ ] Press "Generate New"
- [ ] Press "Copy to Clipboard"
- [ ] Check strength indicator changes

### Test Saving First Password:
- [ ] Tap "Save to Vault"
- [ ] Fill in:
  - Website Name: "Gmail"
  - Username: "test@example.com"
  - Password: (use generated password)
- [ ] Tap "Save"
- [ ] Go to Vault tab
- [ ] Should see 1 password listed
- [ ] Should see "1/1 passwords used" badge

### Test Premium Paywall:
- [ ] Try to add a 2nd password
- [ ] Paywall should appear
- [ ] Should show feature comparison
- [ ] Should show Monthly and Yearly options

---

## ✅ STEP 6: Test Premium Purchase

### Purchase Premium:
- [ ] Open paywall (try to save 2nd password)
- [ ] Select Monthly or Yearly option
- [ ] Tap "Subscribe for £X.XX"
- [ ] StoreKit will show confirmation
- [ ] Confirm purchase (no real money - it's testing!)
- [ ] Paywall should close

### Verify Premium Active:
- [ ] Go to Settings tab
- [ ] Should show "Premium Active" ✅
- [ ] Badge should be green with checkmark

### Test Unlimited Passwords:
- [ ] Go to Generator tab
- [ ] Save multiple passwords (should work!)
- [ ] Go to Vault tab
- [ ] Should see all passwords
- [ ] No "1/1" limit badge

---

## ✅ STEP 7: Test Health Dashboard

### Open Health Tab:
- [ ] Tap Health tab (heart icon)
- [ ] If FREE: Shows premium upsell
- [ ] If PREMIUM: Shows dashboard

### Test Dashboard (Premium Required):
- [ ] Should see security score (0-100)
- [ ] Should see 3 cards:
  - Weak Passwords
  - Reused Passwords
  - Old Passwords
- [ ] Should see recommendations
- [ ] Pull down to refresh

---

## ✅ STEP 8: Test AutoFill Extension

### Enable Extension on Device/Simulator:
- [ ] Open **Settings** app
- [ ] Go to **Passwords**
- [ ] Tap **Password Options**
- [ ] Enable **PasswordVault**

### Test in Safari:
- [ ] Open Safari
- [ ] Go to a website with login (e.g., twitter.com)
- [ ] Tap username or password field
- [ ] QuickType bar should show PasswordVault
- [ ] Tap PasswordVault icon

### Expected Behavior:
- [ ] If FREE: Shows "Premium Required" message
- [ ] If PREMIUM: Shows list of saved passwords
- [ ] Selecting a password fills it in

---

## ✅ STEP 9: Test Premium Features

### Test Password Health:
- [ ] Add 3+ passwords with:
  - One weak password (e.g., "password123")
  - Two with same password (reused)
  - One old password (manually change date in code/debug)
- [ ] Go to Health tab
- [ ] Should show issues detected
- [ ] Security score should be low (< 80)

### Test Restore Purchases:
- [ ] Go to Settings
- [ ] Tap "Restore Purchases"
- [ ] Should show success message
- [ ] Premium should remain active

---

## ✅ STEP 10: Reset and Re-test

### Clear Premium Status:
- [ ] In Xcode: **Debug → StoreKit → Manage Transactions**
- [ ] Delete all transactions
- [ ] Restart app
- [ ] Should be back to FREE tier

### Clear All Data:
- [ ] Delete app from simulator
- [ ] Reinstall (⌘ + R)
- [ ] Onboarding should show again
- [ ] Vault should be empty

---

## 🐛 TROUBLESHOOTING

### App Won't Build

**Error: Cannot find type 'Credential'**
- Solution: Add Credential.swift to extension target

**Error: No such module 'StoreKit'**
- Solution: Check target membership of PremiumManager.swift

**Error: Command CompileSwift failed**
- Solution: Clean build folder (⌘ + Shift + K), then rebuild

### Extension Won't Appear

**Extension not in Settings → Passwords**
- Solution: Delete app, clean build, reinstall
- Check extension bundle ID is correct
- Verify extension has Keychain Sharing capability

### Premium Purchase Not Working

**Products not loading**
- Solution: Check Products.storekit exists
- Verify scheme has StoreKit Configuration set
- Restart Xcode

**Purchase completes but still shows Free**
- Solution: Check PremiumManager is saving to keychain
- Check KeychainService is in both targets

### AutoFill Not Working

**Extension shows but crashes**
- Solution: Check Credential.swift and KeychainService.swift are in extension target
- Check for any missing dependencies

**Extension shows blank screen**
- Solution: Verify CredentialProviderViewController is set as principal class
- Check extension Info.plist configuration

---

## 📱 TESTING TIPS

1. **Use iPhone 15 Pro simulator** (iOS 17+)
2. **Test on real device** for AutoFill (simulators have limitations)
3. **Check Xcode console** for error messages
4. **Use breakpoints** to debug crashes
5. **Clear app data** between tests (delete app)
6. **StoreKit testing** is fully local (no real purchases)

---

## 🎯 SUCCESS CRITERIA

### ✅ Your App is Working When:

- ✅ App builds without errors
- ✅ Onboarding shows on first launch
- ✅ Password generator creates passwords
- ✅ Can save 1 password (free)
- ✅ Paywall blocks 2nd password
- ✅ Premium purchase works
- ✅ After premium: unlimited passwords
- ✅ Health dashboard shows data (premium)
- ✅ Extension appears in Settings
- ✅ Extension shows upsell (free)
- ✅ Extension fills passwords (premium)
- ✅ No crashes or errors

---

## 🚀 YOU'RE DONE!

If all steps pass, your PasswordVault app is **fully functional** and ready for:
- Further customization
- Real StoreKit product setup
- App Store submission preparation
- Additional features

---

## 📚 DOCUMENTATION

- `SETUP_INSTRUCTIONS.md` - Detailed setup guide
- `FILE_STRUCTURE.md` - Complete file structure
- `README.md` - Project overview (you can create this)

---

## 🆘 STILL STUCK?

1. Re-read SETUP_INSTRUCTIONS.md
2. Check target membership of ALL files
3. Verify keychain groups match
4. Clean build folder and restart Xcode
5. Check Xcode console for specific errors
6. Try on a real device (not simulator)

---

**Good luck! 🎉**
