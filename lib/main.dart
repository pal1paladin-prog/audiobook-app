import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'api/ak_api.dart';
import 'services/download_service.dart';
import 'services/player_service.dart';
import 'state/library_provider.dart';
import 'state/settings_provider.dart';
import 'theme/ak_theme.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/screens/downloads_screen.dart';
import 'ui/screens/activity_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = SettingsProvider();
  await settings.load();
  runApp(AudiobookApp(settings: settings));
}

class AudiobookApp extends StatelessWidget {
  final SettingsProvider settings;
  const AudiobookApp({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    final api = AkApi(baseUrl: settings.baseUrl, user: settings.user);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        Provider<AkApi>.value(value: api),
        ChangeNotifierProvider(create: (_) => DownloadService(api)..init()),
        ChangeNotifierProvider(create: (_) => LibraryProvider(api)),
        ChangeNotifierProxyProvider2<DownloadService, AkApi, PlayerService>(
          create: (ctx) => PlayerService(ctx.read<AkApi>(), ctx.read<DownloadService>())..listen(),
          update: (_, dl, api, prev) => prev ?? PlayerService(api, dl),
        ),
      ],
      child: MaterialApp(
        title: 'аудиокниги',
        debugShowCheckedModeBanner: false,
        theme: AkTheme.dark,
        home: const RootShell(),
      ),
    );
  }
}

class RootShell extends StatefulWidget {
  const RootShell({super.key});
  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _idx = 0;
  static const _screens = [HomeScreen(), DownloadsScreen(), ActivityScreen(), SettingsScreen()];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_idx],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.library_music_outlined), selectedIcon: Icon(Icons.library_music), label: 'Библиотека'),
          NavigationDestination(icon: Icon(Icons.download_outlined), selectedIcon: Icon(Icons.download), label: 'Загрузки'),
          NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'Лог'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Настройки'),
        ],
      ),
    );
  }
}
