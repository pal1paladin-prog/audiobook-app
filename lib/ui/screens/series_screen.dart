import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api/ak_api.dart';
import '../../models/ak_models.dart';
import '../../services/player_service.dart';
import '../../state/library_provider.dart';
import '../../theme/ak_theme.dart';
import '../app_toast.dart';
import 'player_screen.dart';

class SeriesScreen extends StatelessWidget {
  final SeriesGroup group;
  const SeriesScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final api = context.read<AkApi>();
    return Scaffold(
      appBar: AppBar(title: Text(group.display)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text('Автор: ${group.author.isEmpty ? '—' : group.author}', style: TextStyle(color: AkTheme.dim)),
          Text('Книг: ${group.books.length}', style: TextStyle(color: AkTheme.dim)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              final first = group.books.first;
              try {
                final tracks = await context.read<AkApi>().bookTracks(first.path);
                if (!context.mounted) return;
                await context.read<PlayerService>().playBook(first, tracks);
              } catch (_) {
                showToast('Не удалось загрузить треки', error: true);
              }
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Слушать с первой'),
            style: ElevatedButton.styleFrom(backgroundColor: AkTheme.accent2, foregroundColor: Colors.black),
          ),
          const SizedBox(height: 16),
              ...group.books.map((b) => Card(
                  color: Theme.of(context).cardColor,
                  child: ListTile(
                  title: Text(b.title, style: TextStyle(color: AkTheme.text, fontSize: 13)),
                  subtitle: b.author.isNotEmpty ? Text(b.author, style: TextStyle(color: AkTheme.dim, fontSize: 11)) : null,
                  trailing: IconButton(
                    icon: Icon(Icons.delete_outline, color: AkTheme.danger),
                    onPressed: () => _confirmDelete(context, api, b),
                  ),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(book: b))),
                ),
              )),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext ctx, AkApi api, AkBook b) {
    showDialog(
      context: ctx,
      builder: (ctx) => AlertDialog(
        backgroundColor: AkTheme.bg2,
        title: Text('Удалить книгу?', style: TextStyle(color: AkTheme.text)),
        content: Text(b.title, style: TextStyle(color: AkTheme.dim)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await api.deleteBook(b.path);
              if (ctx.mounted) ctx.read<LibraryProvider>().load();
            },
            child: Text('Удалить', style: TextStyle(color: AkTheme.danger)),
          ),
        ],
      ),
    );
  }
}
