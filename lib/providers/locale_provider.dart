import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'locale_provider.g.dart';

@Riverpod(keepAlive: true)
class LocaleNotifier extends _$LocaleNotifier {
  @override
  Locale build() {
    return const Locale('en'); // Default to English
  }

  void setLocale(Locale locale) {
    state = locale;
  }

  void setEnglish() => state = const Locale('en');
  void setChinese() => state = const Locale('zh');
}
