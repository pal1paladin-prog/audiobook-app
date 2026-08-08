import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/download_service.dart';
import '../../theme/ak_theme.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dl = context.watch<DownloadService>();
    final items = dl.items.values.toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Загрузки'),
        actions: [
          FutureBuilder<int>(
            future: dl.cacheSizeBytes(),
            builder: (_, snap) {
              final mb = ((snap.data ?? 0) / 1024 / 1024).round();
              return Padding(
                padding: const EdgeInsets.all(12),
                child: Center(child: Text('$mb MB', style: TextStyle(color: AkTheme.dim))),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.delete_sweep, color: AkTheme.danger),
            onPressed: () => _confirmClear(context, dl),
            tooltip: 'Очистить кэш',
          ),
        ],
      ),
      body: items.isEmpty
          ? Center(child: Text('Нет активных загрузок', style: TextStyle(color: AkTheme.dim)))
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (ctx, i) {
                final it = items[i];
                return ListTile(
                  dense: true,
                  title: Text(it.trackPath, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AkTheme.text, fontSize: 12)),
                  subtitle: LinearProgressIndicator(value: it.done ? 1 : it.progress),
                  trailing: it.error != null
                      ? Icon(Icons.error, color: AkTheme.danger, size: 18)
                      : it.done
                          ? Icon(Icons.check, color: AkTheme.ok, size: 18)
                          : IconButton(
                              icon: Icon(Icons.cancel, color: AkTheme.dim, size: 18),
                              onPressed: () => dl.cancelTrack(it.trackPath),
                            ),
                );
              },
            ),
    );
  }

  void _confirmClear(BuildContext ctx, DownloadService dl) {
    showDialog(
      context: ctx,
      builder: (ctx) => AlertDialog(
        backgroundColor: AkTheme.bg2,
        title: Text('Очистить кэш?', style: TextStyle(color: AkTheme.text)),
        content: Text('Все скачанные файлы будут удалены.', style: TextStyle(color: AkTheme.dim)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              dl.clearCache();
            },
            child: Text('Очистить', style: TextStyle(color: AkTheme.danger)),
          ),
        ],
      ),
    );
  }
}
