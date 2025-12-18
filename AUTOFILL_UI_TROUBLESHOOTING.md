# 🔧 AutoFill UI Troubleshooting Guide

## Problem: Extension Shows Only "Cancel" Button - No Credential List

If your AutoFill extension launches but doesn't show the credential list UI, follow these steps in order.

---

## ✅ Step 1: Enable Debug Logging

The updated `CredentialProviderViewController` now includes extensive debug logging. Check the Xcode console for these messages:

### Expected Console Output:

```
🚀 CredentialProviderViewController: viewDidLoad called
🚀 View frame: (0.0, 0.0, 393.0, 852.0)
🚀 View bounds: (0.0, 0.0, 393.0, 852.0)
🔍 AutoFill: prepareCredentialList called
🔍 Service identifiers: [twitter.com]
🔍 Domain: twitter.com
✅ Found 3 credentials
🔍 View added to hierarchy
🎨 Creating credential list view with 3 items
🎨 Adding hosting controller to view hierarchy
✅ Hosting controller added successfully
✅ View frame: (0.0, 0.0, 393.0, 852.0)
✅ View bounds: (0.0, 0.0, 393.0, 852.0)
🎨 SimpleCredentialListView appeared with 3 credentials
```

### How to View Console Logs:

1. **In Xcode:**
   - Run your app on a device/simulator
   - Open the **Console** (Cmd + Shift + C)
   - Filter by: `PasswordVault` or `🔍`

2. **On Device:**
   - Window → Devices and Simulators
   - Select your device
   - Click "Open Console"
   - Filter by your app name

---

## ✅ Step 2: Check If prepareCredentialList Is Called

### If you DON'T see "🔍 AutoFill: prepareCredentialList called":

**The extension isn't being invoked properly. Check:**

1. **Extension is enabled:**
   - Settings → Passwords → Password Options
   - Toggle on **PasswordVault**

2. **You're testing on the correct trigger:**
   - Open Safari (not Chrome/Firefox)
   - Navigate to a login page (twitter.com, facebook.com, etc.)
   - Tap on a username or password field
   - Look for the QuickType bar above keyboard
   - Tap the key icon or "Passwords" button

3. **Info.plist is correct:**
   - See `EXTENSION_TROUBLESHOOTING.md` for full setup
   - Verify extension point identifier

### If you DO see the message but no UI:

Continue to Step 3.

---

## ✅ Step 3: Check If Credentials Are Being Found

Look for this line in the console:
```
✅ Found X credentials
```

### If X = 0 (No credentials found):

**Your keychain is empty or domain matching is failing.**

#### Option A: Add Test Credentials (Recommended)

1. Open `PasswordVaultAutoFillCredentialProviderViewController_FINAL.swift`
2. Find the line in `viewDidLoad()`:
   ```swift
   // UNCOMMENT THIS LINE FOR TESTING - adds sample credentials if keychain is empty
   // ensureTestCredentials()
   ```
3. **Uncomment it:**
   ```swift
   ensureTestCredentials()
   ```
4. Rebuild and run
5. Check console for:
   ```
   ⚠️ No credentials found - adding test data
   ✅ Test credentials added
   ```

#### Option B: Add Credentials via Main App

1. Launch your main **PasswordVault** app
2. Add at least one credential (any website/username/password)
3. Go back to Safari and test AutoFill again

#### Option C: Verify Keychain Sharing

If credentials exist in the main app but extension can't see them:

1. Select **PasswordVault** target → Signing & Capabilities
2. Check **Keychain Sharing** has: `co.uk.techjonesai.PasswordVaultShared`
3. Select **PasswordVaultAutoFill** target → Signing & Capabilities
4. Check **Keychain Sharing** has: `co.uk.techjonesai.PasswordVaultShared`
5. **They must match exactly!**

### If credentials are found (X > 0):

Continue to Step 4.

---

## ✅ Step 4: Verify View Hierarchy Setup

Look for these console messages:

```
🎨 Creating credential list view with X items
🎨 Adding hosting controller to view hierarchy
✅ Hosting controller added successfully
```

### If you DON'T see these messages:

The code never reached `showCredentialList()`. Check for errors:

```
❌ Error fetching credentials: [error message]
```

This means the extension is canceling due to an error. Fix the underlying issue first.

### If you DO see these messages:

The view IS being added! Continue to Step 5.

---

## ✅ Step 5: Verify SwiftUI View Rendering

Look for:
```
🎨 SimpleCredentialListView appeared with X credentials
```

### If you DON'T see this message:

**The SwiftUI view isn't rendering.**

#### Possible Causes:

1. **UIHostingController issue** - Try this fix:
   
   Add to `showCredentialList()` right after creating `hosting`:
   ```swift
   hosting.view.backgroundColor = .systemBackground
   hosting.view.isOpaque = true
   ```

2. **View frame is zero** - Check console:
   ```
   ✅ View frame: (0.0, 0.0, 0.0, 0.0)  ← BAD!
   ```
   
   If width/height are 0, add this to `viewDidLoad()`:
   ```swift
   view.frame = UIScreen.main.bounds
   ```

3. **SwiftUI preview mode** - NavigationView can fail in extensions.
   
   Replace the entire `SimpleCredentialListView` with a simpler version:
   ```swift
   struct SimpleCredentialListView: View {
       let credentials: [Credential]
       let onSelect: (Credential) -> Void
       let onCancel: () -> Void
       
       var body: some View {
           VStack(spacing: 0) {
               // Simple header
               HStack {
                   Text("Select Password")
                       .font(.headline)
                       .padding()
                   Spacer()
                   Button("Cancel") {
                       onCancel()
                   }
                   .padding()
               }
               .background(Color.gray.opacity(0.1))
               
               Divider()
               
               // Simple list
               ScrollView {
                   VStack(spacing: 0) {
                       ForEach(credentials) { credential in
                           Button(action: {
                               onSelect(credential)
                           }) {
                               HStack {
                                   VStack(alignment: .leading) {
                                       Text(credential.websiteName)
                                           .font(.headline)
                                       Text(credential.username)
                                           .font(.subheadline)
                                           .foregroundColor(.gray)
                                   }
                                   Spacer()
                               }
                               .padding()
                               .background(Color.white)
                           }
                           .buttonStyle(.plain)
                           
                           Divider()
                       }
                   }
               }
               .background(Color.white)
           }
           .background(Color.white)
       }
   }
   ```

### If you DO see the message but still no UI:

Continue to Step 6.

---

## ✅ Step 6: Test on a Real Device

**Critical:** AutoFill extensions have limited functionality on simulators.

### Simulator Limitations:
- UI may not render correctly
- View controllers may not load properly
- Background colors may be transparent
- Navigation views may fail

### Testing on a Real Device:

1. Connect iPhone/iPad via USB
2. Select it as the run destination in Xcode
3. Build and run (Cmd + R)
4. On device: Settings → Passwords → Password Options → Enable PasswordVault
5. Open Safari and test on a real website

**This fixes 80% of UI rendering issues!**

---

## ✅ Step 7: Verify View Controller Presentation Mode

iOS may be presenting your extension in a different mode than expected.

### Add this diagnostic method:

```swift
override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    print("🎬 viewDidAppear called")
    print("🎬 View has subviews: \(view.subviews.count)")
    print("🎬 Children view controllers: \(children.count)")
    
    view.subviews.forEach { subview in
        print("   - Subview: \(type(of: subview)), frame: \(subview.frame)")
    }
    
    children.forEach { child in
        print("   - Child VC: \(type(of: child))")
    }
}
```

### Expected Output:
```
🎬 viewDidAppear called
🎬 View has subviews: 1
🎬 Children view controllers: 1
   - Subview: UIView, frame: (0.0, 0.0, 393.0, 852.0)
   - Child VC: UIHostingController<SimpleCredentialListView>
```

### If subviews = 0 or children = 0:

The view wasn't added! Check `showCredentialList()` is being called.

---

## ✅ Step 8: Force View Update

Sometimes the view needs an explicit layout pass.

### Add to end of `showCredentialList()`:

```swift
hosting.didMove(toParent: self)

// Force layout update
view.setNeedsLayout()
view.layoutIfNeeded()

// Force view to appear
DispatchQueue.main.async {
    hosting.view.setNeedsDisplay()
}

print("✅ Hosting controller added successfully")
```

---

## ✅ Step 9: Alternative Presentation Method

If nothing works, try presenting the view modally instead:

### Replace `showCredentialList()` with:

```swift
private func showCredentialList(_ credentials: [Credential]) {
    print("🎨 Creating credential list view with \(credentials.count) items")
    
    let listView = SimpleCredentialListView(
        credentials: credentials,
        onSelect: { [weak self] credential in
            self?.selectCredential(credential)
        },
        onCancel: { [weak self] in
            self?.cancelRequest()
        }
    )
    
    let hosting = UIHostingController(rootView: listView)
    hosting.view.backgroundColor = .systemBackground
    
    // Present modally instead of adding as child
    hosting.modalPresentationStyle = .fullScreen
    present(hosting, animated: false) {
        print("✅ View presented")
    }
}
```

---

## ✅ Step 10: Nuclear Option - Ultra-Simple UIKit View

If SwiftUI absolutely won't work, use pure UIKit:

```swift
private func showCredentialList(_ credentials: [Credential]) {
    // Create a simple table view
    let tableView = UITableView(frame: view.bounds, style: .insetGrouped)
    tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    tableView.backgroundColor = .systemBackground
    tableView.dataSource = self
    tableView.delegate = self
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    
    view.addSubview(tableView)
    
    // Store credentials for table view
    self.currentCredentials = credentials
    tableView.reloadData()
    
    print("✅ UIKit table view added")
}

// Store credentials
private var currentCredentials: [Credential] = []
```

Then conform to UITableViewDataSource/Delegate:

```swift
extension CredentialProviderViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentCredentials.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let credential = currentCredentials[indexPath.row]
        
        var config = cell.defaultContentConfiguration()
        config.text = credential.websiteName
        config.secondaryText = credential.username
        cell.contentConfiguration = config
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let credential = currentCredentials[indexPath.row]
        selectCredential(credential)
    }
}
```

---

## 📊 Quick Diagnostic Checklist

Run through this checklist and note where you get stuck:

- [ ] Extension appears in Settings → Passwords → Password Options
- [ ] Extension is enabled (toggle is ON)
- [ ] Testing on a real device (not simulator)
- [ ] Console shows: "🚀 CredentialProviderViewController: viewDidLoad called"
- [ ] Console shows: "🔍 AutoFill: prepareCredentialList called"
- [ ] Console shows: "✅ Found X credentials" (where X > 0)
- [ ] Console shows: "🎨 Creating credential list view"
- [ ] Console shows: "✅ Hosting controller added successfully"
- [ ] Console shows: "🎨 SimpleCredentialListView appeared"
- [ ] `viewDidAppear` shows 1 child view controller
- [ ] Keychain groups match in both targets
- [ ] Credentials exist in keychain (test with main app)

**Stop at the first unchecked item - that's your issue!**

---

## 🎯 Most Common Issues & Solutions

### 1. "Only see Cancel button, no list"
- **Cause:** SwiftUI view isn't rendering in extension context
- **Fix:** Use the simple UIKit table view (Step 10)

### 2. "Console says view added, but nothing visible"
- **Cause:** Testing on simulator
- **Fix:** Test on a real device

### 3. "Found 0 credentials"
- **Cause:** Keychain is empty or groups don't match
- **Fix:** Uncomment `ensureTestCredentials()` in `viewDidLoad()`

### 4. "Extension never launches"
- **Cause:** Info.plist misconfigured
- **Fix:** See `EXTENSION_TROUBLESHOOTING.md`

### 5. "View has wrong size/frame"
- **Cause:** Layout constraints not properly set
- **Fix:** Use Auto Layout constraints (already in updated code)

### 6. "prepareCredentialList never called"
- **Cause:** Extension point identifier wrong
- **Fix:** Must be `com.apple.authentication-services-credential-provider-ui`

---

## 🔍 Advanced Debugging

### View Hierarchy Debugging:

1. Run app on device/simulator
2. Trigger the extension
3. In Xcode: Debug → View Debugging → Capture View Hierarchy
4. Look for your views in the 3D hierarchy

### Memory Debugging:

If the view disappears immediately:

1. Make hosting controller a property:
   ```swift
   private var hostingController: UIHostingController<SimpleCredentialListView>?
   ```

2. Store it instead of using a local variable:
   ```swift
   self.hostingController = UIHostingController(rootView: listView)
   ```

---

## ✅ Success Criteria

Your extension UI is working when:

1. ✅ Extension launches when tapping password fields
2. ✅ You see a navigation bar with "Select Password" title
3. ✅ You see a Cancel button in the navigation bar
4. ✅ You see a list of credentials (or "No Passwords Found" if empty)
5. ✅ Tapping a credential fills it into the form
6. ✅ Tapping Cancel dismisses the extension
7. ✅ Console shows all expected debug messages

---

## 📞 Getting Help

If you're still stuck, share this information:

1. **Console output** - Copy all messages starting from "🚀"
2. **Diagnostic checklist** - Which items are checked?
3. **Testing environment** - Simulator or real device? iOS version?
4. **View hierarchy** - Run the diagnostic in Step 7
5. **Screenshot** - What do you see when extension launches?

---

**Last Updated:** December 9, 2025
**Compatible with:** iOS 17+, Xcode 15+
