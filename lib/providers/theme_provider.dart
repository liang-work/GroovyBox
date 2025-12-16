import 'dart:io';

import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_provider.g.dart';

// Default seed color
const Color defaultSeedColor = Colors.deepPurple;

// State class for theme data
class ThemeState {
  final ThemeMode themeMode;
  final Color seedColor;

  const ThemeState({required this.themeMode, required this.seedColor});

  ThemeState copyWith({ThemeMode? themeMode, Color? seedColor}) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      seedColor: seedColor ?? this.seedColor,
    );
  }
}

// Light theme definition with dynamic seed color
ThemeData createLightTheme(Color seedColor) => ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: Brightness.light,
  ),
  useMaterial3: true,
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(12)),
    ),
  ),
);

// Dark theme definition with dynamic seed color
ThemeData createDarkTheme(Color seedColor) => ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: Brightness.dark,
  ),
  useMaterial3: true,
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(12)),
    ),
  ),
);

@Riverpod(keepAlive: true)
class ThemeNotifier extends _$ThemeNotifier {
  @override
  ThemeMode build() {
    return ThemeMode.system; // Default to system theme
  }

  void setThemeMode(ThemeMode themeMode) {
    state = themeMode;
  }

  void toggleTheme() {
    switch (state) {
      case ThemeMode.light:
        state = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        state = ThemeMode.light;
        break;
      case ThemeMode.system:
        // If system, default to light
        state = ThemeMode.light;
        break;
    }
  }

  void setLightTheme() => state = ThemeMode.light;
  void setDarkTheme() => state = ThemeMode.dark;
  void setSystemTheme() => state = ThemeMode.system;
}

@Riverpod(keepAlive: true)
class SeedColorNotifier extends _$SeedColorNotifier {
  @override
  Color build() {
    return defaultSeedColor;
  }

  void setSeedColor(Color color) {
    state = color;
  }

  void updateFromAlbumArt(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) {
      // Reset to default color if no album art
      state = defaultSeedColor;
      return;
    }

    try {
      // Validate that the file exists before attempting to load it
      final file = File(imagePath);
      if (!await file.exists()) {
        // File doesn't exist, reset to default color
        state = defaultSeedColor;
        return;
      }

      // Additional validation: check if file is readable and not empty
      final fileStat = await file.stat();
      if (fileStat.size == 0) {
        // Empty file, reset to default color
        state = defaultSeedColor;
        return;
      }

      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        FileImage(file),
        size: const Size(200, 200),
        maximumColorCount: 20, // Increase color count for better extraction
      );

      // Use dominant color with better fallback hierarchy
      Color? extractedColor;
      if (paletteGenerator.dominantColor != null) {
        extractedColor = paletteGenerator.dominantColor!.color;
      } else if (paletteGenerator.vibrantColor != null) {
        extractedColor = paletteGenerator.vibrantColor!.color;
      } else if (paletteGenerator.mutedColor != null) {
        extractedColor = paletteGenerator.mutedColor!.color;
      } else if (paletteGenerator.paletteColors.isNotEmpty) {
        // Fallback to the first available color
        extractedColor = paletteGenerator.paletteColors.first.color;
      }

      // Ensure we have a valid color, otherwise use default
      state = extractedColor ?? defaultSeedColor;
    } catch (e) {
      // Log the error for debugging (in a real app, you'd use proper logging)
      // debugPrint('Failed to extract color from album art: $e');
      // If color extraction fails, reset to default color
      state = defaultSeedColor;
    }
  }

  void resetToDefault() {
    state = defaultSeedColor;
  }
}

@Riverpod(keepAlive: true)
ThemeData currentTheme(Ref ref) {
  final themeMode = ref.watch(themeProvider);
  final seedColor = ref.watch(seedColorProvider);
  final brightness = themeMode == ThemeMode.system
      ? WidgetsBinding.instance.platformDispatcher.platformBrightness
      : (themeMode == ThemeMode.dark ? Brightness.dark : Brightness.light);

  return brightness == Brightness.dark
      ? createDarkTheme(seedColor)
      : createLightTheme(seedColor);
}

// Legacy providers for backward compatibility
@Riverpod(keepAlive: true)
ThemeData lightTheme(Ref ref) => createLightTheme(ref.watch(seedColorProvider));

@Riverpod(keepAlive: true)
ThemeData darkTheme(Ref ref) => createDarkTheme(ref.watch(seedColorProvider));
