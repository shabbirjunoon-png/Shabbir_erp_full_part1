# Firebase & Google Services — Exact Step-by-Step Action Plan

Follow these steps exactly. It takes about 15 minutes total.

---

## PART 1 — Create Firebase Project (5 min)

### Step 1: Open Firebase Console
→ Go to: https://console.firebase.google.com/
→ Sign in with your Google account

### Step 2: Create New Project
→ Click the big **"+ Add project"** card
→ Type project name: `ShabbirERP` → Click **Continue**
→ Toggle off "Enable Google Analytics" (optional) → Click **Create project**
→ Wait ~30 seconds → Click **Continue**

---

## PART 2 — Enable Authentication (3 min)

### Step 3: Enable Google Sign-In
→ In left sidebar, click **Authentication**
→ Click **Get started** (first time only)
→ Click **Sign-in method** tab
→ Click **Google** row
→ Toggle **Enable** to ON
→ Enter your Support email (your Gmail)
→ Click **Save**

### Step 4: Enable Phone Authentication
→ Still on Sign-in method tab
→ Click **Phone** row
→ Toggle **Enable** to ON
→ Click **Save**

---

## PART 3 — Add Android App (5 min)

### Step 5: Register Android App
→ On Firebase home, click the **Android icon** (looks like a robot head)
→ Fill:
  - **Android package name**: `com.shabbir.erp`
  - **App nickname**: `Shabbir ERP Android`
  - **Debug signing certificate SHA-1**: (skip for now, add later for production)
→ Click **Register app**

### Step 6: Download google-services.json
→ Click **Download google-services.json** (blue button)
→ A file named `google-services.json` will download to your computer
→ Click **Next** → **Next** → **Continue to console**

### Step 7: Upload to Replit
→ In Replit file explorer, navigate to: `shabbir_erp_flutter/android/app/`
→ Right-click that folder → **Upload file**
→ Select the `google-services.json` you just downloaded
→ The file will appear at: `shabbir_erp_flutter/android/app/google-services.json`
→ **Delete** the placeholder file: `shabbir_erp_flutter/android/app/google-services-placeholder.json`

---

## PART 4 — Add iOS App (3 min)

### Step 8: Register iOS App
→ In Firebase console, click **+ Add app** → **iOS icon**
→ Fill:
  - **Apple Bundle ID**: `com.shabbir.erp`
  - **App nickname**: `Shabbir ERP iOS`
→ Click **Register app**

### Step 9: Download GoogleService-Info.plist
→ Click **Download GoogleService-Info.plist** (blue button)
→ Click **Next** → **Next** → **Continue to console**

### Step 10: Upload GoogleService-Info.plist to Replit
→ In Replit, navigate to: `shabbir_erp_flutter/ios/Runner/`
→ Right-click → **Upload file**
→ Select the `GoogleService-Info.plist` you downloaded

---

## PART 5 — Generate firebase_options.dart (2 min)

### Step 11: Get Your Firebase Config Values
→ In Firebase Console → Click ⚙️ (gear icon) top-left → **Project settings**
→ Scroll down to **Your apps** section
→ Click on your **Android app**
→ Copy these values (you'll need them):
  - `mobileSdkAppId` → this is your **App ID**
  - `projectId`
  - `storageBucket`
  - `messagingSenderId`
  - `apiKey`

### Step 12: Update firebase_options.dart
→ In Replit, open: `shabbir_erp_flutter/lib/firebase_options.dart`
→ Replace each `YOUR_ANDROID_API_KEY`, `YOUR_ANDROID_APP_ID`, etc.
  with the actual values from Step 11
→ Do the same for iOS values from **GoogleService-Info.plist**:
  - `API_KEY` → iOS api key
  - `GOOGLE_APP_ID` → iOS App ID
  - `GCM_SENDER_ID` → sender ID
  - `PROJECT_ID` → project ID

---

## PART 6 — Google Drive API (for Cloud Backup)

### Step 13: Enable Drive API
→ Go to: https://console.cloud.google.com/
→ Make sure your Firebase project is selected (top dropdown)
→ Click **APIs & Services** → **Library**
→ Search: `Google Drive API`
→ Click it → Click **Enable**

### Step 14: Configure OAuth Consent Screen
→ Click **OAuth consent screen** in left sidebar
→ Choose **External** → Click **Create**
→ Fill:
  - App name: `Shabbir ERP`
  - User support email: your Gmail
  - Developer contact: your Gmail
→ Click **Save and Continue** through all steps

---

## PART 7 — Google Sign-In SHA-1 for Android

### Step 15: Add SHA-1 to Firebase (for Google Sign-In to work on Android)

If you're building the app on your computer:
```bash
# Run this in your terminal (Mac/Linux):
keytool -list -v \
  -keystore ~/.android/debug.keystore \
  -alias androiddebugkey \
  -storepass android -keypass android

# Windows:
keytool -list -v ^
  -keystore %USERPROFILE%\.android\debug.keystore ^
  -alias androiddebugkey ^
  -storepass android -keypass android
```
→ Copy the `SHA-1` value
→ In Firebase Console → Project Settings → Your Android App → **Add fingerprint**
→ Paste the SHA-1 → Save

---

## PART 8 — Build & Run

### Step 16: Build the APK
After uploading google-services.json and updating firebase_options.dart:

**Option A — Build on your local machine:**
```bash
cd shabbir_erp_flutter
flutter pub get
flutter run -d android     # Run on connected phone
flutter build apk --release  # Build APK file
```
The APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

**Option B — Use a cloud build service:**
→ Upload the project to GitHub
→ Use https://appdistribution.firebase.google.com/ to build & distribute

---

## Why Replit Can't Run Flutter Directly

Replit runs in a Linux container in your browser. Flutter apps compile to native Android/iOS binaries. There is no Android emulator inside Replit. You need to:

1. **Connect a real Android phone** via USB to your computer and run `flutter run`
2. **Use Android Studio** with an emulator on your own machine
3. **Build an APK** (`flutter build apk`) and install it on your phone

The code is 100% complete in this Replit project. You just need to build it on a machine with Flutter installed.

---

## Quick Reference: Files That Need Your Config

| File | What to put there |
|------|------------------|
| `android/app/google-services.json` | Downloaded from Firebase Console (Step 6) |
| `ios/Runner/GoogleService-Info.plist` | Downloaded from Firebase Console (Step 9) |
| `lib/firebase_options.dart` | Fill in the placeholder values (Step 12) |
| `ios/Runner/Info.plist` | Replace `YOUR_IOS_CLIENT_ID` with REVERSED_CLIENT_ID from GoogleService-Info.plist |
