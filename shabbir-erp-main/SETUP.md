# Shabbir ERP — Flutter Setup Guide

## Prerequisites

Install the following on your machine:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.x or later)
- Android Studio (for Android builds)
- Xcode (for iOS builds, macOS only)
- [Firebase CLI](https://firebase.google.com/docs/cli)

---

## Step 1: Get Dependencies

```bash
cd shabbir_erp_flutter
flutter pub get
```

---

## Step 2: Add Inter Font Files

Download the Inter font from Google Fonts and place these files in `assets/fonts/`:
- `Inter-Regular.ttf`
- `Inter-Medium.ttf`
- `Inter-SemiBold.ttf`
- `Inter-Bold.ttf`

```bash
mkdir -p assets/fonts
# Download from https://fonts.google.com/specimen/Inter
```

---

## Step 3: Set Up Firebase

### 3.1 Create Firebase Project
1. Go to https://console.firebase.google.com/
2. Click **Add project** → name it "Shabbir ERP"
3. Enable Google Analytics (optional)

### 3.2 Enable Authentication Methods
In Firebase Console → Authentication → Sign-in method:
- Enable **Google**
- Enable **Phone** (add Pakistan country code +92)

### 3.3 Add Android App
1. Click **Add app** → Android
2. Package name: `com.shabbir.erp`
3. Download `google-services.json`
4. Place it at: `android/app/google-services.json`
5. Delete `android/app/google-services-placeholder.json`

### 3.4 Add iOS App
1. Click **Add app** → iOS
2. Bundle ID: `com.shabbir.erp`
3. Download `GoogleService-Info.plist`
4. Place it at: `ios/Runner/GoogleService-Info.plist`

### 3.5 Generate Firebase Options
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```
This auto-generates `lib/firebase_options.dart` with your real credentials. Replace the placeholder file.

---

## Step 4: Configure Google Sign-In (iOS)

In `ios/Runner/Info.plist`, replace:
```
com.googleusercontent.apps.YOUR_IOS_CLIENT_ID
```
With your actual reversed client ID from `GoogleService-Info.plist` (the `REVERSED_CLIENT_ID` field).

---

## Step 5: Enable Phone Auth (Pakistan)

In Firebase Console:
1. Authentication → Sign-in method → Phone
2. Add test phone numbers for development if needed
3. For production, verify your app with reCAPTCHA

---

## Step 6: Google Drive API (for cloud backup)

1. Go to https://console.cloud.google.com/
2. Enable **Google Drive API** for your Firebase project
3. Add OAuth scopes: `https://www.googleapis.com/auth/drive.file`
4. In Firebase Console → Authentication → Settings → Authorized domains — add your domain

---

## Step 7: Run the App

```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# Release build (Android APK)
flutter build apk --release

# Release build (iOS)
flutter build ipa --release
```

---

## App Architecture

```
lib/
├── main.dart                    # Entry point, Firebase init, auth routing
├── firebase_options.dart        # ⚠️ Replace with flutterfire configure output
├── constants/
│   └── app_colors.dart          # Color palette (matching original app)
├── models/
│   ├── party.dart               # Party & PartyWithBalance models
│   ├── stock_item.dart          # Inventory item model
│   └── transaction.dart        # Voucher/transaction model
├── providers/
│   └── erp_provider.dart        # State management (ChangeNotifier)
├── services/
│   ├── database_service.dart    # SQLite via sqflite
│   ├── auth_service.dart        # Firebase Auth (Google + Phone OTP)
│   ├── backup_service.dart      # Local & Google Drive backup/restore
│   ├── security_service.dart    # Pattern lock storage & verification
│   └── pdf_service.dart         # PDF generation & printing
├── screens/
│   ├── login_screen.dart        # Google + Phone OTP login
│   ├── pattern_lock_screen.dart # Set/Verify/Change pattern lock
│   ├── main_screen.dart         # Bottom tab navigation
│   ├── parties_screen.dart      # Parties list with search & filters
│   ├── inventory_screen.dart    # Stock management
│   ├── reports_screen.dart      # Business reports & analytics
│   ├── settings_screen.dart     # Security, backup, account settings
│   ├── party_detail_screen.dart # Ledger detail with PDF export
│   ├── trial_balance_screen.dart# Trial balance with grand total & PDF
│   ├── add_party_sheet.dart     # Add/edit party bottom sheet
│   ├── add_item_sheet.dart      # Add/edit stock item bottom sheet
│   └── new_transaction_sheet.dart # New/edit voucher bottom sheet
└── widgets/
    ├── app_header.dart          # Custom app header
    ├── party_card.dart          # Party list card
    ├── item_card.dart           # Stock item card
    ├── transaction_row.dart     # Voucher row
    ├── erp_bottom_sheet.dart    # Reusable sheet + form widgets
    └── pattern_input.dart       # 3×3 pattern lock input widget
```

---

## Features Implemented

| Feature | Status |
|---------|--------|
| Parties list with real-time search | ✅ |
| Customer/Supplier filter pills | ✅ |
| Add/Edit/Delete parties | ✅ |
| Inventory management | ✅ |
| New Voucher (Sale/Purchase/Receipt/Payment) | ✅ |
| Party ledger with date range filter | ✅ |
| PDF ledger export & print | ✅ |
| Reports screen with monthly metrics | ✅ |
| **Trial Balance with grand total & PDF** | ✅ |
| **Firebase Google Sign-In** | ✅ |
| **Firebase Phone OTP (Pakistani numbers)** | ✅ |
| **Pattern Lock (set/verify/change/disable)** | ✅ |
| **SQLite local database (sqflite)** | ✅ |
| **Local device backup (share/save .json)** | ✅ |
| **Google Drive backup & restore** | ✅ |
| **Settings hub** | ✅ |
| Multi-device support via Firebase Auth | ✅ |

---

## Data Flow

```
Firebase Auth → User authenticated
     ↓
Pattern Lock (if enabled) → Verified
     ↓
ERPProvider loads from SQLite
     ↓
UI renders from in-memory state
     ↓
All writes go to SQLite first, then update state
     ↓
Backup: SQLite → JSON → Local/Google Drive
Restore: Google Drive/Local → JSON → SQLite → reload state
```

---

## Troubleshooting

**"Cannot find package 'firebase_core'"**
→ Run `flutter pub get`

**Google Sign-In fails on Android**
→ Add SHA-1 fingerprint in Firebase Console → Project Settings → Your Android App
→ Run: `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android`

**Phone OTP not sending**
→ Ensure phone authentication is enabled in Firebase Console
→ For testing, add test numbers in Firebase Console → Authentication → Phone → Test phone numbers

**Google Drive backup fails**
→ Ensure Drive API is enabled in Google Cloud Console
→ Check OAuth scopes include `drive.file`

**Pattern lock not working**
→ Minimum 4 dots required to complete a pattern
→ Pattern is stored securely in SharedPreferences
