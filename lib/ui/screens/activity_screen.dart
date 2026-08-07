import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/ak_api.dart';
import '../models/ak_models.dart';
import '../theme/ak_theme.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});
  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  List<ActivityEvent>? _events;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = context.read<AkApi>();
    try {
      final ev = await api.log(days: 7);
      if (mounted) setState(() { _events = ev; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final evs = _events ?? [];
    final up = evs.where((e) => e.isDownload).length;
    final down = evs.where((e) => !e.isDownload).length;
    return Scaffold(
      appBar: AppBar(title: const Text('За неделю')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      _stat('Загружено', up, AkTheme.ok),
                      const SizedBox(width: 16),
                      _stat('Удалено', down, AkTheme.danger),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: evs.length,
                    itemBuilder: (ctx, i) {
                      final e = evs[i];
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: e.isDownload ? AkTheme.ok : AkTheme.danger,
                          child: Icon(e.isDownload ? Icons.add : Icons.remove, size: 14, color: Colors.white),
                        ),
                        title: Text(e.title.isNotEmpty ? e.title : e.directory,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AkTheme.text, fontSize: 12)),
                        subtitle: Text('${e.author} · ${e.manual.isNotEmpty ? e.manual : e.site}',
                            style: const TextStyle(color: AkTheme.dim, fontSize: 10)),
                        trailing: Text(_fmt(e.at), style: const TextStyle(color: AkTheme.dim, fontSize: 10)),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _stat(String label, int count, Color color) => Row(
        children: [Text('$count', style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: AkTheme.dim, fontSize: 12))],
      );

  String _fmt(DateTime d) =>
      '${d.day}.${d.month.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
