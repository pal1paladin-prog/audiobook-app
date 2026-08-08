import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../api/ak_api.dart';
import '../../models/ak_models.dart';
import '../../state/library_provider.dart';
import '../../state/settings_provider.dart';
import '../../services/player_service.dart';
import '../../services/download_service.dart';
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
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _query = ''))
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
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 160, childAspectRatio: 0.62, crossAxisSpacing: 12, mainAxisSpacing: 12),
      itemCount: groups.length,
      itemBuilder: (ctx, i) => _GroupTile(group: groups[i]),
    );
  }
}

class _GroupTile extends StatelessWidget {
  final SeriesGroup group;
  const _GroupTile({required this.group});

  @override
  Widget build(BuildContext context) {
    final api = context.read<AkApi>();
    final isMulti = group.books.length > 1;
    return GestureDetector(
      onTap: () {
        if (isMulti) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => SeriesScreen(group: group)));
        } else {
          _openBook(context, group.books.first);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AkTheme.bg3,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AkTheme.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: group.coverPath.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: api.coverUri(group.coverPath).toString(),
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Center(child: Icon(isMulti ? Icons.menu_book : Icons.book, size: 40, color: AkTheme.dim)),
                        )
                      : Center(child: Icon(isMulti ? Icons.menu_book : Icons.book, size: 40, color: AkTheme.dim)),
                ),
                if (isMulti)
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: AkTheme.accent2, borderRadius: BorderRadius.circular(10)),
                      child: Text('${group.books.length}', style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(group.display, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AkTheme.text, fontSize: 11)),
          Text(group.author, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AkTheme.dim, fontSize: 10)),
        ],
      ),
    );
  }

  void _openBook(BuildContext ctx, AkBook book) {
    Navigator.push(ctx, MaterialPageRoute(builder: (_) => PlayerScreen(book: book)));
  }
}
