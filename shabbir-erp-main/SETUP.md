# Shabbir ERP — Supabase Setup Guide

Firebase has been completely removed. Cloud sync is now powered by **Supabase** (free, no account needed from your users).

## Supabase Credentials (already configured)

| Setting | Value |
|---------|-------|
| **Project URL** | `https://ikadfsikkfslnystotxr.supabase.co` |
| **Anon Key** | Already in `supabase_service.dart` |

## Database Tables Setup

Run this SQL once in your Supabase dashboard:

**Dashboard → SQL Editor → New Query → Paste → Run**

```sql
-- See supabase_setup.sql in this repo
```

The file `supabase_setup.sql` in this repo has all the SQL you need.

## What was changed

- ✅ Firebase completely removed (pubspec.yaml, main.dart, firebase_options.dart, android/build.gradle)
- ✅ Supabase initialized at app startup (Google OAuth + Facebook OAuth login)
- ✅ GitHub Gist backup removed from Settings
- ✅ Supabase Cloud Sync added to Settings (push all data, restore from cloud)
- ✅ Login screen: Google login, Facebook login, Offline mode

## Login Options

1. **Google Login** — via Supabase OAuth (data syncs across devices)
2. **Facebook Login** — via Supabase OAuth
3. **Offline Mode** — no account needed (data stored on device only)
