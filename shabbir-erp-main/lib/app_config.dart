/// True once Firebase.initializeApp() succeeds.
/// Stays false when firebase_options.dart still has placeholder values.
/// Used by screens to gracefully degrade when Firebase is not configured.
bool firebaseReady = false;
