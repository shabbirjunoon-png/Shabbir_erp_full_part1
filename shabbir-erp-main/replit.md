# Shabbir ERP

A Flutter web business management application for tracking ledgers (Khata Book) and inventory.

## Overview

The app provides tools for small to medium businesses to manage:
- **Parties**: Customer and supplier directories with real-time search and balance tracking
- **Inventory**: Stock item management
- **Transactions**: Sales, purchases, receipts, and payments (vouchers)
- **Reports**: Party ledgers, trial balances, monthly metrics, and PDF exports
- **Security**: Pattern lock for app access
- **Firebase**: Google/Phone OTP authentication (optional — app works offline if not configured)

## Tech Stack

- **Framework**: Flutter 3.32 (web)
- **Language**: Dart
- **State Management**: Provider (ChangeNotifier)
- **Local Storage**: SharedPreferences (web-compatible)
- **Auth**: Firebase Auth (Google Sign-In + Phone OTP)
- **PDF**: pdf package
- **Fonts**: Google Fonts (Inter)

## Project Structure

```
lib/
├── main.dart                  # Entry point
├── app_config.dart            # Firebase readiness flag
├── firebase_options.dart      # Firebase config (Android, iOS, Web)
├── constants/app_colors.dart  # Color palette
├── models/                    # Data models (Party, StockItem, Transaction)
├── providers/erp_provider.dart # State management
├── services/
│   ├── database_service.dart  # SharedPreferences-based storage (web-compatible)
│   ├── auth_service.dart      # Firebase auth wrapper
│   ├── backup_service.dart    # JSON export/import
│   ├── security_service.dart  # Pattern lock
│   └── pdf_service.dart       # PDF generation
├── screens/                   # UI screens
└── widgets/                   # Reusable widgets
```

## Running the App

The workflow `Start application` builds Flutter web and serves on port 5000:

```bash
bash start.sh
```

The server patches `flutter_bootstrap.js` at runtime to:
- Use the local CanvasKit (no CDN required)
- Disable the PWA service worker (Replit iframe compatibility)
- Only use `dart2js` renderer (no WASM)

## Deployment

Configured for autoscale deployment:
- **Build**: `bash start_build.sh` (flutter build web)
- **Run**: `python3 serve.py`

## Firebase Setup

See `FIREBASE_SETUP.md` for full Firebase configuration. The app runs in offline mode without Firebase — data is stored locally in the browser via SharedPreferences.

## User Preferences

- Keep dart:io usage behind kIsWeb guards
- Use SharedPreferences for all storage (web-compatible, no sqflite)
- Patch flutter_bootstrap.js at serve time to fix Replit iframe compatibility
