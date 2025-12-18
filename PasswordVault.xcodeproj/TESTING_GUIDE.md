# 🧪 Extension Memory Fix - Testing Guide

## 🎯 Quick Test (5 minutes)

After rebuilding the app, test these scenarios:

---

## ✅ Test 1: Basic AutoFill Works

1. Open Safari on your device
2. Go to any login page (e.g., gmail.com, twitter.com)
3. Tap the username or password field
4. Tap "Passwords" in the QuickType bar (or the key icon)
5. **Expected:** Extension opens without crashing ✅
6. **Expected:** Shows matching credentials for that site ✅

**What to check:**
- No crash on launch
- Extension UI appears
- Credentials load within 1 second

---

## ✅ Test 2: Premium User Flow

**If you're a premium user:**

1. Tap a password field in Safari
2. **Expected:** Extension shows credential list ✅
3. Select a credential
4. **Expected:** Face ID/Touch ID prompt appears ✅
5. Authenticate
6. **Expected:** Password fills into the form ✅

**Memory check:**
- Open Xcode Debug Navigator (Cmd + 7)
- Click Memory graph
- Should stay under 10MB during entire flow ✅

---

## ✅ Test 3: Free User Flow

**If you're a free user:**

1. Tap a password field in Safari
2. **Expected:** Extension shows premium upgrade prompt ✅
3. Tap "Upgrade to Premium"
4. **Expected:** Opens main app to subscription page ✅

**Memory check:**
- Premium prompt should use ~4-5MB
- No crash ✅

---

## ✅ Test 4: No Matching Credentials

1. Go to a website you DON'T have credentials for
2. Tap password field
3. **Expected:** Shows "No Passwords Found" message ✅
4. **Expected:** Option to "Open PasswordVault" ✅

**Memory check:**
- Should use minimal memory (~3-4MB)
- No crash ✅

---

## ✅ Test 5: Large Vault (100+ Credentials)

**If you have many saved passwords:**

1. Tap password field on a popular site (e.g., Gmail)
2. **Expected:** Only shows Gmail-related credentials (not all 100+) ✅
3. **Expected:** Maximum 50 credentials shown ✅
4. **Expected:** Loads quickly (<1 second) ✅

**Memory check:**
- Should still stay under 10MB
- Domain filtering is working ✅

---

## 📊 Monitoring Memory in Xcode

### Method 1: Debug Navigator

1. Run your app with Xcode attached
2. Press **Cmd + 7** to open Debug Navigator
3. Click **Memory**
4. Trigger AutoFill in Safari
5. Watch the memory graph:
   - **Good:** Stays under 15MB ✅
   - **Warning:** Goes above 15MB ⚠️
   - **Bad:** Spikes to 20MB+ or crashes ❌

### Method 2: Console Logs

Look for these logs:

**Good signs:**
```
✅ Keychain load succeeded for key: credentials
🔍 AutoFill: Preparing credential list for: [gmail.com]
📊 Fetching credentials for domain: gmail.com
📊 Found 3 matches
✅ AutoFill: Successfully authenticated and providing credential
```

**Warning signs:**
```
⚠️ Memory pressure: critical
⚠️ Loading all credentials (500+)
❌ Extension terminated: memory limit exceeded
```

---

## 🐛 Troubleshooting

### Issue: Extension still crashes

**Check:**
1. Did you clean build? (Shift + Cmd + K)
2. Did you delete the app from device?
3. Did you rebuild completely?
4. Are you testing on a real device (not simulator)?

**Fix:**
- Lower the credential limit in `CredentialProviderViewController.swift`:
  ```swift
  private let maxCredentials = 25  // Instead of 50
  ```

---

### Issue: No credentials showing up

**Check:**
1. Are credentials saved in the main app?
2. Is keychain sharing enabled for both targets?
3. Are you using the same app group?

**Verify:**
- Main app target: Keychain group = `group.co.uk.techjonesai.PasswordVaultShared`
- Extension target: Keychain group = `group.co.uk.techjonesai.PasswordVaultShared`

---

### Issue: Wrong credentials showing

**Check:**
- Domain filtering is working correctly
- Log the domain being searched:
  ```swift
  print("🔍 Searching for domain: \(domain)")
  ```

**Verify:**
- Website names in credentials match the domain
- Example: Credential with "Gmail" should match "gmail.com"

---

## 📝 Performance Benchmarks

After optimization, you should see:

| Test Scenario | Memory Usage | Load Time | Status |
|---------------|--------------|-----------|--------|
| Launch extension | ~3-5MB | <0.5s | ✅ |
| Load 5 credentials | ~5-6MB | <0.5s | ✅ |
| Load 50 credentials | ~7-8MB | ~1s | ✅ |
| Show premium prompt | ~4-5MB | <0.3s | ✅ |
| Authenticate + fill | ~6-7MB | ~1s | ✅ |

---

## ✅ Success Criteria

Your extension is working correctly when:

- [x] Extension launches without crashing
- [x] Memory stays under 15MB at all times
- [x] Credentials load in less than 1 second
- [x] Domain filtering works (only shows relevant credentials)
- [x] Can successfully fill passwords in Safari
- [x] Premium/free user flows work correctly
- [x] No memory warnings in Xcode console

---

## 🎉 Final Verification

Run all 5 tests above. If all pass, your extension is optimized and production-ready!

**Still seeing issues?** Check:
- `EXTENSION_MEMORY_OPTIMIZATION.md` for detailed debugging
- `MEMORY_FIX_SUMMARY.md` for quick reference
- Console logs for specific errors

---

**Last Updated:** December 7, 2025

Good luck testing! 🚀

