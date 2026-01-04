import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:groovybox/l10n/app_localizations.dart';
import 'package:groovybox/logic/audio_handler.dart';
import 'package:groovybox/logic/window_helpers.dart';
import 'package:groovybox/providers/audio_provider.dart';
import 'package:groovybox/providers/locale_provider.dart';
import 'package:groovybox/providers/theme_provider.dart';
import 'package:groovybox/router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:audio_service/audio_service.dart' as audio_service;

late AudioHandler _audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  // Initialize window manager for desktop platforms
  if (isDesktopPlatform()) {
    await initializeWindowManager();
  }

  // Initialize AudioService
  _audioHandler = await audio_service.AudioService.init(
    builder: () => AudioHandler(),
    config: const audio_service.AudioServiceConfig(
      androidNotificationChannelId: 'dev.solsynth.rhythmBox.channel.audio',
      androidNotificationChannelName: 'GroovyBox Audio',
      androidNotificationOngoing: true,
    ),
  );

  // Set the audio handler for the provider
  setAudioHandler(_audioHandler);

  runApp(
    ProviderScope(
      child: Builder(
        builder: (context) {
          // Get the provider container and set it on the audio handler
          final container = ProviderScope.containerOf(context);
          _audioHandler.setProviderContainer(container);
          return const GroovyApp();
        },
      ),
    ),
  );
}

class GroovyApp extends ConsumerWidget {
  const GroovyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'GroovyBox',
      debugShowCheckedModeBanner: false,
      theme: ref.watch(lightThemeProvider),
      darkTheme: ref.watch(darkThemeProvider),
      themeMode: themeMode,
      locale: locale,
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('zh'), // Chinese
      ],
    );
  }
}
