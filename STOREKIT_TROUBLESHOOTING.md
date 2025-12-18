# StoreKit Sandbox Testing - Troubleshooting Guide

## 🔍 Issue: Subscription Not Detected After App Reinstall

### What Happened:
1. ✅ You deleted the app from your device
2. ✅ You did a clean build
3. ✅ App reinstalled successfully  
4. ✅ Keychain data persisted (5 passwords still there)
5. ❌ Premium status lost (UserDefaults was cleared)
6. ❌ "Restore Purchases" says no purchases found

### Why This Happens:

**Two Storage Systems:**
1. **UserDefaults** - Gets deleted when app is deleted
   - Stores: Premium status flag
   - Status: ❌ Cleared on deletion

2. **Keychain** - Persists even after app deletion  
   - Stores: Your passwords
   - Status: ✅ Still has 5 passwords

3. **StoreKit** - Apple's subscription system
   - Stores: Your actual subscriptions
   - Status: ⚠️ Should persist but needs to be queried

---

## 🛠️ Solutions

### Solution 1: Reset Sandbox Account (Most Common Fix)

**Steps:**
1. Go to **Settings → App Store**
2. Scroll to **Sandbox Account**
3. **Sign out** of your sandbox tester account
4. **Close** the Settings app completely
5. **Reopen** your PasswordVault app
6. When prompted, **sign in** to sandbox account again
7. Try **"Restore Purchases"** again

**Why this works:** Sometimes sandbox accounts get "stuck" and need a fresh sign-in.

---

### Solution 2: Check Subscription Status in App Store Connect

1. Go to **App Store Connect**
2. Navigate to your app
3. Go to **"Subscriptions"** section
4. Verify that both product IDs are:
   - ✅ `co.uk.techjonesai.PasswordVault.premium_monthly`
   - ✅ `co.uk.techjonesai.PasswordVault.premium_yearly`
5. Check they are **"Ready to Submit"** or **"Approved"**

---

### Solution 3: Use Enhanced Debug Logging

**I've added more detailed logging to PremiumManager.** Run the app again and check the console for:

```
🔍 Checking subscription status...
📋 Looking for product IDs:
   - Monthly: co.uk.techjonesai.PasswordVault.premium_monthly
   - Yearly: co.uk.techjonesai.PasswordVault.premium_yearly
📦 Entitlement #1:
   Product ID: [will show actual ID]
   Purchase Date: [will show date]
   Expiration: [will show expiration]
📊 Summary: Found X total entitlements
```

**What to look for:**
- If `Found 0 total entitlements` → Subscription not in StoreKit
- If entitlement shows different Product ID → Product ID mismatch
- If entitlement shows but wrong date → Subscription expired in sandbox

---

### Solution 4: Clear All Sandbox Purchases

If you've been testing a lot, sandbox might have multiple expired subscriptions.

**Steps:**
1. Settings → App Store → Sandbox Account
2. Tap your sandbox tester email
3. **"Manage"** → **"Clear Purchase History"**
4. Sign out and back in
5. Re-purchase the subscription in your app

---

### Solution 5: Create Fresh Sandbox Tester

Sometimes a sandbox account gets corrupted from too much testing.

1. **App Store Connect** → **Users and Access** → **Sandbox Testers**
2. Create a **new sandbox tester** with different email
3. Sign out of old tester on device
4. Sign in with new tester
5. Purchase subscription fresh

---

## 🧪 Testing Best Practices

### For Sandbox Testing:

1. **Use StoreKit Configuration File** (recommended)
   - Xcode → Product → Scheme → Edit Scheme
   - Run → Options → StoreKit Configuration
   - Select your `.storekit` file
   - This simulates purchases locally without Apple's servers

2. **Sandbox Account Guidelines:**
   - Create multiple testers for different scenarios
   - Don't use your real Apple ID
   - Clear purchase history between major test sessions

3. **After App Deletion:**
   - Always expect UserDefaults to be cleared
   - Keychain will persist (this is correct)
   - StoreKit subscriptions should restore via `AppStore.sync()`

---

## 📊 Expected Behavior After Fix

Once working, you should see:

```
✅ Premium status loaded: false (from UserDefaults - expected after deletion)
🔍 Checking subscription status...
📦 Entitlement #1:
   Product ID: co.uk.techjonesai.PasswordVault.premium_yearly
   Purchase Date: 2025-12-05
✅ Active Yearly subscription found
✅ Final status: Yearly subscription active
✅ Premium status saved: true (UserDefaults updated)
✅ Premium status updated: true
```

---

## 🎯 Quick Diagnosis

Run your app and check the debug output:

| Debug Message | What It Means | Action |
|--------------|---------------|--------|
| `Found 0 total entitlements` | No subscription in StoreKit | Reset sandbox account |
| `Found 1 total entitlements` but wrong ID | Product ID mismatch | Check App Store Connect |
| `Failed to verify transaction` | Verification error | Check internet connection |
| `No active subscription found` | Subscription expired | Re-purchase in sandbox |

---

## 🔄 Current Code Improvements

I've enhanced `PremiumManager` to:

1. ✅ Add detailed logging for debugging
2. ✅ Show product IDs being searched
3. ✅ Display entitlement count
4. ✅ Show purchase and expiration dates
5. ✅ Better error messages

---

## 💡 Pro Tip: Local StoreKit Testing

For faster testing without network issues:

1. Create a StoreKit configuration file in Xcode
2. Add your subscription products
3. Enable in scheme settings
4. Test purchases work offline
5. No sandbox account needed for basic testing

This is perfect for development and avoids sandbox issues!

---

## 📱 Next Steps

1. **Build and run** with the new logging
2. **Try "Restore Purchases"**
3. **Check the console** for detailed output
4. **Share the new debug log** if it still doesn't work

The enhanced logging will tell us exactly why StoreKit isn't finding your subscription! 🔍
