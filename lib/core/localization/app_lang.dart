import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _langKey = 'app_lang';
final ValueNotifier<String> appLang = ValueNotifier<String>('kk');

Future<void> loadAppLang() async {
  final prefs = await SharedPreferences.getInstance();
  appLang.value = prefs.getString(_langKey) ?? 'kk';
}

Future<void> setAppLang(String lang) async {
  appLang.value = lang;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_langKey, lang);
}

String tr(String kk, String ru) {
  return appLang.value == 'ru' ? ru : kk;
}
