import 'package:flutter/material.dart';

const seedColor = Color(0xFF0EA97B);
const kGreen = Color(0xFF0EA97B);
const kRed = Color(0xFFE5484D);

ThemeData buildTheme(bool dark) {
  final scheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: dark ? Brightness.dark : Brightness.light,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: dark ? const Color(0xFF0F1216) : const Color(0xFFF4F6F8),
    appBarTheme: AppBarTheme(
      centerTitle: false, elevation: 0, backgroundColor: Colors.transparent,
      foregroundColor: dark ? Colors.white : const Color(0xFF17222B),
    ),
  );
}

/// Semantic surface/text colours that adapt to light/dark.
class AppC {
  final Color card, field, text, muted, bg;
  const AppC({required this.card, required this.field, required this.text, required this.muted, required this.bg});

  static AppC of(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return dark
        ? const AppC(card: Color(0xFF1B2026), field: Color(0xFF232A31),
            text: Colors.white, muted: Colors.white60, bg: Color(0xFF0F1216))
        : const AppC(card: Colors.white, field: Color(0xFFF0F2F5),
            text: Color(0xFF17222B), muted: Colors.black54, bg: Color(0xFFF4F6F8));
  }
}
