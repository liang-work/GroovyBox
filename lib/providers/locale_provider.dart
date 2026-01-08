import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'locale_provider.g.dart';

@Riverpod(keepAlive: true)
class LocaleNotifier extends _$LocaleNotifier {
  @override
  Future<Locale> build() async {
    final prefs = await SharedPreferences.getInstance();
    final localeString = prefs.getString('locale') ?? 'en';
    return Locale(localeString);
  }

  Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', locale.languageCode);
    ref.invalidateSelf();
  }

  Future<void> setEnglish() async {
    await setLocale(const Locale('en'));
  }

  Future<void> setChinese() async {
    await setLocale(const Locale('zh'));
  }
}



