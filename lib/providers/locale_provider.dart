import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'locale_provider.g.dart';

@Riverpod(keepAlive: true)
class LocaleNotifier extends _$LocaleNotifier {
  @override
  Locale build() {
    return const Locale('en'); // Default to English
  }

  Future<void> setLocale(BuildContext context, Locale locale) async {
    await context.setLocale(locale);
    state = locale;
  }

  Future<void> setEnglish(BuildContext context) async {
    await setLocale(context, const Locale('en'));
  }

  Future<void> setChinese(BuildContext context) async {
    await setLocale(context, const Locale('zh'));
  }
}



