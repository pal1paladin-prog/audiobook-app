import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  String _baseUrl;
  String _user;
  String _theme; // dark / light / system

  SettingsProvider({String baseUrl = '', String user = 'default', String theme = 'dark'})
      : _baseUrl = baseUrl,
        _user = user,
        _theme = theme;

  String get baseUrl => _baseUrl;
  String get user => _user;
  String get theme => _theme;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _baseUrl = p.getString('baseUrl') ?? '';
    _user = p.getString('user') ?? 'default';
    _theme = p.getString('theme') ?? 'dark';
    notifyListeners();
  }

  Future<void> setBaseUrl(String v) async {
    _baseUrl = v;
    final p = await SharedPreferences.getInstance();
    await p.setString('baseUrl', v);
    notifyListeners();
  }

  Future<void> setUser(String v) async {
    _user = v;
    final p = await SharedPreferences.getInstance();
    await p.setString('user', v);
    notifyListeners();
  }

  Future<void> setTheme(String v) async {
    _theme = v;
    final p = await SharedPreferences.getInstance();
    await p.setString('theme', v);
    notifyListeners();
  }
}
