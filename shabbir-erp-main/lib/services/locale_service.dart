import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLang { english, romanUrdu, urdu }

class LocaleService extends ChangeNotifier {
  static final LocaleService _instance = LocaleService._();
  static LocaleService get instance => _instance;
  LocaleService._();

  AppLang _lang = AppLang.romanUrdu;
  AppLang get lang => _lang;

  bool get isUrdu => _lang == AppLang.urdu;
  bool get isEnglish => _lang == AppLang.english;
  bool get isRomanUrdu => _lang == AppLang.romanUrdu;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('app_lang') ?? 'romanUrdu';
    _lang = _fromString(saved);
    notifyListeners();
  }

  Future<void> setLang(AppLang lang) async {
    _lang = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_lang', _toString(lang));
    notifyListeners();
  }

  Future<void> toggle() async {
    final next = _lang == AppLang.urdu ? AppLang.english : (_lang == AppLang.english ? AppLang.romanUrdu : AppLang.urdu);
    await setLang(next);
  }

  String t(String en, String ur) => _lang == AppLang.urdu ? ur : en;

  String t3(String en, String roman, String ur) {
    switch (_lang) {
      case AppLang.english: return en;
      case AppLang.romanUrdu: return roman;
      case AppLang.urdu: return ur;
    }
  }

  AppLang _fromString(String s) {
    switch (s) {
      case 'english': return AppLang.english;
      case 'urdu': return AppLang.urdu;
      default: return AppLang.romanUrdu;
    }
  }

  String _toString(AppLang l) {
    switch (l) {
      case AppLang.english: return 'english';
      case AppLang.urdu: return 'urdu';
      case AppLang.romanUrdu: return 'romanUrdu';
    }
  }
}
