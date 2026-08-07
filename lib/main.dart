import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:audio_session/audio_session.dart';
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
import 'ui/screens/player_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await just_audio_background.init(
    androidNotificationChannelId: 'com.pal.audiobook.background',
    androidNotificationChannelName: 'Аудиокниги',
    androidNotificationOngoing: true,
  );
  final settings = SettingsProvider();
  await settings.load();
  final api = AkApi(baseUrl: 'https://192.168.0.142/audio-kniga/ak.php');
  runApp(AudiobookApp(settings: settings, api: api));
}

class AudiobookApp extends StatelessWidget {
  final SettingsProvider settings;
  final AkApi api;
  const AudiobookApp({super.key, required this.settings, required this.api});

  @override
  Widget build(BuildContext context) {
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
      child: Consumer<SettingsProvider>(
        builder: (ctx, settings, _) {
          return MaterialApp(
            title: 'аудиокниги',
            debugShowCheckedModeBanner: false,
            theme: AkTheme.light,
            darkTheme: AkTheme.dark,
            themeMode: settings.theme == 'system' ? ThemeMode.system : (settings.theme == 'light' ? ThemeMode.light : ThemeMode.dark),
            home: const RootShell(),
          );
        },
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
  final GlobalKey<PlayerOverlayState> _playerKey = GlobalKey<PlayerOverlayState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _idx,
            children: const [HomeScreen(), DownloadsScreen(), ActivityScreen(), SettingsScreen()],
          ),
          const PlayerOverlay(),
        ],
      ),
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

class PlayerOverlay extends StatefulWidget {
  const PlayerOverlay({super.key});
  @override
  State<PlayerOverlay> createState() => _PlayerOverlayState();
}

class _PlayerOverlayState extends State<PlayerOverlay> {
  final PlayerService _player = PlayerService(null, null);
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _initAudioSession();
  }

  Future<void> _initAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    await session.setActive(true);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerService>(
      builder: (ctx, player, _) {
        if (!player.hasTrack) return const SizedBox.shrink();
        return AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          bottom: 0,
          left: 0, right: 0,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, -2))],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Progress bar
                  StreamBuilder<Duration>(
                    stream: _player.positionStream,
                    builder: (_, snap) => SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 3,
                        activeTrackColor: Theme.of(context).colorScheme.primary,
                        inactiveTrackColor: Colors.grey.withOpacity(0.3),
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                        overlayShape: SliderComponentShape.noOverlay,
                      ),
                      child: Slider(
                        value: (_player.position.inMilliseconds.toDouble()).clamp(0, _player.duration.inMilliseconds.toDouble()),
                        max: _player.duration.inMilliseconds.toDouble() > 0 ? _player.duration.inMilliseconds.toDouble() : 1,
                        onChanged: (v) => context.read<PlayerService>().seek(Duration(milliseconds: v.round())),
                      ),
                    ),
                  ),
                  // Controls row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        // Track info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Consumer<PlayerService>(
                                builder: (_, p, _) => Text(
                                  p.currentTrack?.name ?? '',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Consumer<PlayerService>(
                                builder: (_, p, _) => Text(
                                  p.currentBook?.author ?? '',
                                  style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Controls
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.skip_previous, size: 28),
                              color: Colors.white,
                              onPressed: () => context.read<PlayerService>().prev(),
                            ),
                            Container(
                              width: 56, height: 56,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: Icon(
                                  context.read<PlayerService>().playing ? Icons.pause : Icons.play_arrow,
                                  size: 28,
                                ),
                                color: Colors.white,
                                onPressed: () => context.read<PlayerService>().playPause(),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.skip_next, size: 28),
                              color: Colors.white,
                              onPressed: () => context.read<PlayerService>().next(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }
}