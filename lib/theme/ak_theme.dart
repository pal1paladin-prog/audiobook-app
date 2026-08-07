import 'package:flutter/material.dart';

class AkTheme {
  static const bg1 = Color(0xFF0a0a0c);
  static const bg2 = Color(0xFF141418);
  static const bg3 = Color(0xFF1e1e24);
  static const card = Color(0xDD14141a);
  static const border = Color(0xFF2e2e36);
  static const text = Color(0xFFe8e2d8);
  static const dim = Color(0xFF9a948c);
  static const accent = Color(0xFFe8e0d0);
  static const accent2 = Color(0xFFc4b498);
  static const danger = Color(0xFFa05050);
  static const ok = Color(0xFF57b657);

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg1,
        colorScheme: const ColorScheme.dark(
          primary: accent2,
          secondary: accent2,
          surface: bg2,
          error: danger,
        ),
        cardColor: card,
        dividerColor: border,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: text, fontSize: 13, fontFamily: 'monospace'),
          bodySmall: TextStyle(color: dim, fontSize: 11, fontFamily: 'monospace'),
          titleMedium: TextStyle(color: accent, fontSize: 14, fontFamily: 'monospace'),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: ButtonStyle(
            foregroundColor: WidgetStatePropertyAll(dim),
            side: WidgetStatePropertyAll(BorderSide(color: border)),
            shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10)))),
          ),
        ),
        appBarTheme: const AppBarTheme(backgroundColor: bg2, foregroundColor: accent, elevation: 0),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: bg2,
          indicatorColor: accent2,
          labelTextStyle: WidgetStatePropertyAll(TextStyle(color: text, fontSize: 11)),
          iconTheme: WidgetStatePropertyAll(WidgetStatePropertyAll(IconThemeData(color: dim))),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: bg3,
          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: accent2)),
          hintStyle: TextStyle(color: dim),
          labelStyle: TextStyle(color: dim),
        ),
      );
}
