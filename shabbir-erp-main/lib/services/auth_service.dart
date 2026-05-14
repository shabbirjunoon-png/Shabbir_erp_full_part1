// Firebase removed — auth via SupabaseService (Google/Facebook OAuth)
// and offline guest mode via SharedPreferences.
class AuthService {
  static final AuthService _i = AuthService._();
  static AuthService get instance => _i;
  AuthService._();
}
