import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../api/ak_api.dart';
import '../../models/ak_models.dart';
import '../../state/library_provider.dart';
import '../../state/settings_provider.dart';
import '../../theme/ak_theme.dart';
import '../../config.dart';
import 'player_screen.dart';
import 'series_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _query = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<LibraryProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final lib = context.watch<LibraryProvider>();
    final settings = context.watch<SettingsProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('аудиокниги', style: TextStyle(fontFamily: 'monospace', letterSpacing: 0.14, fontSize: 14)),
            Text('v$kAppVersion', style: TextStyle(fontSize: 10, color: AkTheme.dim, fontFamily: 'monospace')),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => lib.load(), tooltip: 'Обновить'),
        ],
      ),
      body: Column(
        children: [
          if (settings.baseUrl.isEmpty)
            MaterialBanner(
              content: const Text('Укажите адрес сервера в настройках'),
              leading: const Icon(Icons.warning, color: Colors.amber),
              actions: [TextButton(onPressed: () {}, child: const Text('Настройки'))],
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Поиск…',
                prefixIcon: const Icon(Icons.search, color: AkTheme.dim),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _query = '';
                            _searchCtrl.clear();
                          });
                        },
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
            ),
          ),
          if (lib.genres.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _genreChip(context, '', 'Все', lib),
                  for (final g in lib.genres) _genreChip(context, g, g, lib),
                ],
              ),
            ),
          Expanded(child: _body(context, lib)),
        ],
      ),
    );
  }

  Widget _genreChip(BuildContext ctx, String value, String label, LibraryProvider lib) {
    final active = lib.genre == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 11, color: active ? Colors.black : AkTheme.text)),
        selected: active,
        selectedColor: AkTheme.accent2,
        backgroundColor: AkTheme.bg3,
        onSelected: (_) => lib.setGenre(value),
      ),
    );
  }

  Widget _body(BuildContext ctx, LibraryProvider lib) {
    if (lib.loading) return const Center(child: CircularProgressIndicator());
    if (lib.error.isNotEmpty) return Center(child: Text('Ошибка: ${lib.error}', style: const TextStyle(color: AkTheme.danger)));
    var groups = lib.grouped;
    if (_query.isNotEmpty) {
      groups = groups.where((g) {
        if (g.display.toLowerCase().contains(_query)) return true;
        return g.books.any((b) =>
            b.title.toLowerCase().contains(_query) || b.author.toLowerCase().contains(_query));
      }).toList();
    }
    if (groups.isEmpty) return const Center(child: Text('Нет книг', style: TextStyle(color: AkTheme.dim)));
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      itemCount: groups.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) => _BookRow(group: groups[i]),
    );
  }
}

class _BookRow extends StatelessWidget {
  final SeriesGroup group;
  const _BookRow({required this.group});

  @override
  Widget build(BuildContext context) {
    final api = context.read<AkApi>();
    final isMulti = group.books.length > 1;
    final first = group.books.first;
    final genre = first.genre;
    final narrator = isMulti ? _joinNarrators(group.books) : first.narrator;
    final durationSec = isMulti ? _sumDurations(group.books) : first.durationSec;
    final seriesName = isMulti ? '' : first.series;

    return GestureDetector(
      onTap: () {
        if (isMulti) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => SeriesScreen(group: group)));
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(book: first)));
        }
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AkTheme.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AkTheme.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Cover(coverPath: group.coverPath, isMulti: isMulti, api: api),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          group.display,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AkTheme.text, fontSize: 14, fontWeight: FontWeight.w600, height: 1.2),
                        ),
                      ),
                      if (isMulti) _CountBadge(count: group.books.length),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _InfoLine(icon: Icons.category_outlined, text: genre),
                  _InfoLine(icon: Icons.person_outline, text: group.author),
                  if (narrator.isNotEmpty) _InfoLine(icon: Icons.mic_none, text: narrator),
                  if (durationSec != null) _InfoLine(icon: Icons.schedule, text: _formatDuration(durationSec)),
                  if (seriesName.isNotEmpty && !isMulti) _InfoLine(icon: Icons.library_books_outlined, text: 'Цикл «$seriesName»'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _joinNarrators(List<AkBook> books) {
    final s = <String>{};
    for (final b in books) {
      if (b.narrator.trim().isNotEmpty) s.add(b.narrator.trim());
    }
    return s.join(', ');
  }

  int? _sumDurations(List<AkBook> books) {
    int total = 0;
    bool any = false;
    for (final b in books) {
      final d = b.durationSec;
      if (d != null) {
        total += d;
        any = true;
      }
    }
    return any ? total : null;
  }

  String _formatDuration(int sec) {
    if (sec < 60) return '$sec с';
    final h = sec ~/ 3600;
    final m = (sec % 3600) ~/ 60;
    if (h > 0) return '$h ч $m мин';
    return '$m мин';
  }
}

class _Cover extends StatelessWidget {
  final String coverPath;
  final bool isMulti;
  final AkApi api;
  const _Cover({required this.coverPath, required this.isMulti, required this.api});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 84,
        height: 122,
        color: AkTheme.bg3,
        child: coverPath.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: api.coverUri(coverPath).toString(),
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _FallbackIcon(isMulti: isMulti),
              )
            : _FallbackIcon(isMulti: isMulti),
      ),
    );
  }
}

class _FallbackIcon extends StatelessWidget {
  final bool isMulti;
  const _FallbackIcon({required this.isMulti});

  @override
  Widget build(BuildContext context) {
    return Center(child: Icon(isMulti ? Icons.menu_book : Icons.book, size: 32, color: AkTheme.dim));
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AkTheme.accent2),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AkTheme.text.withValues(alpha: 0.85), fontSize: 12, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: AkTheme.accent2, borderRadius: BorderRadius.circular(12)),
      child: Text('$count', style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}
