import 'package:shared_preferences/shared_preferences.dart';

class SecurityService {
  static SecurityService? _instance;
  SecurityService._();
  static SecurityService get instance {
    _instance ??= SecurityService._();
    return _instance!;
  }

  static const String _patternKey = 'erp:pattern_lock';
  static const String _enabledKey = 'erp:pattern_enabled';

  Future<bool> isPatternEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  Future<String?> getPattern() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_patternKey);
  }

  Future<void> setPattern(String pattern) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_patternKey, pattern);
    await prefs.setBool(_enabledKey, true);
  }

  Future<void> disablePattern() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_patternKey);
    await prefs.setBool(_enabledKey, false);
  }

  Future<bool> verifyPattern(String input) async {
    final stored = await getPattern();
    return stored == input;
  }

  Future<bool> hasPatternSet() async {
    final stored = await getPattern();
    return stored != null && stored.isNotEmpty;
  }
}
