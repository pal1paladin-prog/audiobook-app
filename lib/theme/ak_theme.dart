import 'package:flutter/material.dart';

/// Тема приложения. Цвета-константы адаптивны: они возвращают значение
/// в зависимости от [brightness], который выставляется в MaterialApp.builder.
class AkTheme {
  static Brightness brightness = Brightness.dark;

  static Color _pick(Color dark, Color light) => brightness == Brightness.light ? light : dark;

  static Color get bg1 => _pick(const Color(0xFF0a0a0c), const Color(0xFFfaf7f2));
  static Color get bg2 => _pick(const Color(0xFF141418), const Color(0xFFffffff));
  static Color get bg3 => _pick(const Color(0xFF1e1e24), const Color(0xFFefe9df));
  static Color get card => _pick(const Color(0xDD14141a), const Color(0xEEffffff));
  static Color get border => _pick(const Color(0xFF2e2e36), const Color(0xFFddd8cf));
  static Color get text => _pick(const Color(0xFFe8e2d8), const Color(0xFF1c1a18));
  static Color get dim => _pick(const Color(0xFF9a948c), const Color(0xFF5c5854));
  static Color get accent => _pick(const Color(0xFFe8e0d0), const Color(0xFF2a2826));
  static Color get accent2 => _pick(const Color(0xFFc4b498), const Color(0xFF6b5e48));
  static Color get danger => _pick(const Color(0xFFa05050), const Color(0xFF8c2f2f));
  static Color get ok => _pick(const Color(0xFF57b657), const Color(0xFF2e7d32));

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0a0a0c),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFc4b498),
          secondary: Color(0xFFc4b498),
          surface: Color(0xFF141418),
          error: Color(0xFFa05050),
        ),
        cardColor: const Color(0xDD14141a),
        dividerColor: const Color(0xFF2e2e36),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFFe8e2d8), fontSize: 13, fontFamily: 'monospace'),
          bodySmall: TextStyle(color: Color(0xFF9a948c), fontSize: 11, fontFamily: 'monospace'),
          titleMedium: TextStyle(color: Color(0xFFe8e0d0), fontSize: 14, fontFamily: 'monospace'),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: ButtonStyle(
            foregroundColor: WidgetStatePropertyAll(const Color(0xFF9a948c)),
            side: WidgetStatePropertyAll(const BorderSide(color: Color(0xFF2e2e36))),
            shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10)))),
          ),
        ),
        appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF141418), foregroundColor: Color(0xFFe8e0d0), elevation: 0),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF141418),
          indicatorColor: const Color(0xFFc4b498),
          labelTextStyle: WidgetStatePropertyAll(TextStyle(color: const Color(0xFFe8e2d8), fontSize: 11)),
          iconTheme: WidgetStatePropertyAll(IconThemeData(color: const Color(0xFF9a948c))),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1e1e24),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              borderSide: const BorderSide(color: Color(0xFF2e2e36))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              borderSide: const BorderSide(color: Color(0xFFc4b498))),
          hintStyle: const TextStyle(color: Color(0xFF9a948c)),
          labelStyle: const TextStyle(color: Color(0xFF9a948c)),
        ),
      );

  static ThemeData get light => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFfaf7f2),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF6b5e48),
          secondary: Color(0xFF6b5e48),
          surface: Color(0xFFffffff),
          error: Color(0xFF8c2f2f),
          onSurface: Color(0xFF1c1a18),
        ),
        cardColor: const Color(0xEEffffff),
        dividerColor: const Color(0xFFddd8cf),
        appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFfaf7f2), foregroundColor: Color(0xFF2a2826), elevation: 0),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF1c1a18)),
          bodyMedium: TextStyle(color: Color(0xFF1c1a18)),
          bodySmall: TextStyle(color: Color(0xFF5c5854)),
          titleMedium: TextStyle(color: Color(0xFF2a2826)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF5c5854)),
        iconButtonTheme: IconButtonThemeData(
          style: ButtonStyle(
            foregroundColor: WidgetStatePropertyAll(const Color(0xFF5c5854)),
            side: WidgetStatePropertyAll(const BorderSide(color: Color(0xFFddd8cf))),
            shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10)))),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFFfaf7f2),
          indicatorColor: const Color(0xFF6b5e48),
          labelTextStyle: WidgetStatePropertyAll(TextStyle(color: const Color(0xFF1c1a18), fontSize: 11)),
          iconTheme: WidgetStatePropertyAll(IconThemeData(color: const Color(0xFF5c5854))),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFffffff),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              borderSide: const BorderSide(color: Color(0xFFddd8cf))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              borderSide: const BorderSide(color: Color(0xFF6b5e48))),
          hintStyle: const TextStyle(color: Color(0xFF5c5854)),
          labelStyle: const TextStyle(color: Color(0xFF5c5854)),
        ),
      );
}
