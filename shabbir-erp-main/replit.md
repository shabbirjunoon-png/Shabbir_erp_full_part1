# Shabbir ERP

A Flutter Android business management application for tracking ledgers (Khata Book) and inventory.

## Overview

The app provides tools for small to medium businesses to manage:
- **Parties**: Customer and supplier directories with real-time search and balance tracking
- **Inventory**: Stock item management
- **Transactions**: Sales, purchases, receipts, and payments (vouchers)
- **Reports**: Party ledgers, trial balances, monthly metrics, and PDF exports
- **Security**: Pattern lock for app access
- **Auth**: Google Sign-In via Firebase Authentication + Offline guest mode

## Tech Stack

- **Framework**: Flutter 3.32 (Android)
- **Language**: Dart
- **State Management**: Provider (ChangeNotifier)
- **Local Storage**: SharedPreferences (web-compatible)
- **Auth**: Firebase Auth (Google Sign-In)
- **PDF**: pdf package
- **Fonts**: Google Fonts (Inter)

## Firebase Project

- **Project ID**: shabbirer-eca8d
- **Package name**: com.shabbir.erp
- **google-services.json**: Already placed at android/app/google-services.json

## Project Structure

```
lib/
├── main.dart                        # Entry point — Firebase init
├── firebase_options.dart            # Firebase config
├── constants/app_colors.dart        # Color palette
├── models/                          # Data models (Party, StockItem, Transaction)
├── providers/erp_provider.dart      # State management
├── services/
│   ├── firebase_auth_service.dart   # Firebase Auth + Google Sign-In
│   ├── database_service.dart        # SharedPreferences-based storage
│   ├── backup_service.dart          # JSON export/import
│   ├── security_service.dart        # Pattern lock
│   └── pdf_service.dart             # PDF generation
├── screens/                         # UI screens
└── widgets/                         # Reusable widgets
```

## Building the Android APK

```bash
cd shabbir-erp-main
flutter build apk --release
```

The signed APK uses:
- Keystore: android/app/shabbir_release.jks
- Key alias: shabbirkey

## Running the Web Preview (Replit)

The workflow `Start application` builds Flutter web and serves on port 5000:

```bash
bash start.sh
```

## User Preferences

- Android-only app (web build kept for Replit preview only)
- Firebase Auth with Google Sign-In (no Supabase, no Facebook login)
- SharedPreferences for all local storage (web-compatible)
- Patch flutter_bootstrap.js at serve time to fix Replit iframe compatibility
