import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audio_service/audio_service.dart';
import 'api/ak_api.dart';
import 'services/download_service.dart';
import 'services/player_service.dart';
import 'services/audio_handler.dart';
import 'state/library_provider.dart';
import 'state/settings_provider.dart';
import 'theme/ak_theme.dart';
import 'ui/app_toast.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/screens/downloads_screen.dart';
import 'ui/screens/activity_screen.dart';
import 'config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = SettingsProvider();
  await settings.load();
  final api = AkApi(baseUrl: settings.baseUrl.isEmpty ? 'https://192.168.0.142/audio-kniga' : settings.baseUrl);
  final downloads = DownloadService(api);
  await downloads.init();
  final handler = await AudioService.init(
    builder: () => AkAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.ryanheise.audioservice.channel.audio',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      androidNotificationIcon: 'mipmap/ic_launcher',
    ),
  );
  runApp(AudiobookApp(settings: settings, api: api, downloads: downloads, handler: handler));
}

class AudiobookApp extends StatelessWidget {
  final SettingsProvider settings;
  final AkApi api;
  final DownloadService downloads;
  final AkAudioHandler handler;
  const AudiobookApp({
    super.key,
    required this.settings,
    required this.api,
    required this.downloads,
    required this.handler,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        Provider<AkApi>.value(value: api),
        Provider<AkAudioHandler>.value(value: handler),
        ChangeNotifierProvider.value(value: downloads),
        ChangeNotifierProvider(create: (_) => LibraryProvider(api)),
        ChangeNotifierProxyProvider<DownloadService, PlayerService>(
          create: (ctx) {
            final s = PlayerService(ctx.read<AkApi>(), ctx.read<DownloadService>(), ctx.read<AkAudioHandler>());
            s.listen();
            return s;
          },
          update: (_, _, prev) => prev!,
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (ctx, settings, _) {
          return MaterialApp(
            title: '$kAppName v$kAppVersion',
            debugShowCheckedModeBanner: false,
            scaffoldMessengerKey: appMessengerKey,
            theme: AkTheme.light,
            darkTheme: AkTheme.dark,
            themeMode: settings.theme == 'system' ? ThemeMode.system : (settings.theme == 'light' ? ThemeMode.light : ThemeMode.dark),
            builder: (context, child) {
              AkTheme.brightness = Theme.of(context).brightness;
              return child!;
            },
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

class PlayerOverlay extends StatelessWidget {
  const PlayerOverlay({super.key});

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
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, -2))],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StreamBuilder<Duration>(
                    stream: player.positionStream,
                    builder: (_, snap) {
                      final pos = snap.data ?? Duration.zero;
                      final maxMs = player.duration.inMilliseconds.toDouble();
                      if (maxMs > 0) {
                        return Slider(
                          value: pos.inMilliseconds.toDouble().clamp(0, maxMs),
                          max: maxMs,
                          activeColor: Theme.of(context).colorScheme.primary,
                          onChanged: (v) => player.seek(Duration(milliseconds: v.round())),
                        );
                      } else {
                        return Slider(value: 0, max: 1, onChanged: null);
                      }
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Consumer<PlayerService>(
                                builder: (_, p, _) => Text(
                                  p.currentTrack?.name ?? '',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AkTheme.text),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Consumer<PlayerService>(
                                builder: (_, p, _) => Text(
                                  p.currentBook?.author ?? '',
                                  style: TextStyle(fontSize: 11, color: AkTheme.dim),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(icon: const Icon(Icons.skip_previous), color: AkTheme.text, onPressed: () => player.prev()),
                            const SizedBox(width: 8),
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              child: Consumer<PlayerService>(
                                builder: (_, p, _) => IconButton(
                                  icon: Icon(p.playing ? Icons.pause : Icons.play_arrow, size: 28, color: AkTheme.text),
                                  onPressed: () => player.playPause(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(icon: const Icon(Icons.skip_next), color: AkTheme.text, onPressed: () => player.next()),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
