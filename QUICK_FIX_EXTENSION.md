# ⚡️ Quick Fix: Extension Not Appearing

## 🎯 The #1 Most Common Issue

Your extension's **Info.plist** is missing or has the wrong extension point identifier.

---

## ✅ QUICK FIX (5 minutes)

### Step 1: Add Info.plist Keys

1. Select **PasswordVaultAutoFill** target in Xcode
2. Click **Info** tab
3. Add these keys:

#### Required Keys:

| Key | Type | Value |
|-----|------|-------|
| NSExtension | Dictionary | (expand below) |
| ↳ NSExtensionPointIdentifier | String | `com.apple.authentication-services-credential-provider-ui` |
| ↳ NSExtensionPrincipalClass | String | `$(PRODUCT_MODULE_NAME).CredentialProviderViewController` |
| ↳ NSExtensionAttributes | Dictionary | (expand below) |
| &nbsp;&nbsp;&nbsp;↳ ASCredentialProviderExtensionCapabilities | Dictionary | (expand below) |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;↳ ProvidesPasswords | Boolean | YES |

### Step 2: Verify Bundle IDs

- **Main App:** `co.uk.techjonesai.PasswordVault`
- **Extension:** `co.uk.techjonesai.PasswordVault.PasswordVaultAutoFill`

Extension **must** start with the app's bundle ID!

### Step 3: Clean & Rebuild

1. Press **Shift + Cmd + K** (clean)
2. **Delete app** from device/simulator
3. Press **Cmd + R** (rebuild and run)
4. Check **Settings → Passwords → Password Options**

---

## 🚨 CRITICAL GOTCHA

**Wrong:**
```
com.apple.credential-provider-ui
```

**Correct:**
```
com.apple.authentication-services-credential-provider-ui
```

The word **"authentication-services"** is required!

---

## 📱 Test on Real Device

Simulators have limited AutoFill support. **Always test on a real iPhone/iPad** running iOS 17+.

---

## 📄 More Help

See `EXTENSION_TROUBLESHOOTING.md` for comprehensive debugging steps.

---

**Quick Tip:** If extension still doesn't appear, check Console logs in **Window → Devices and Simulators → Open Console** for error messages.
