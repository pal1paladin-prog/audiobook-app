import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../api/ak_api.dart';
import '../models/ak_models.dart';
import '../state/library_provider.dart';
import '../services/player_service.dart';
import '../services/download_service.dart';
import '../theme/ak_theme.dart';

class PlayerScreen extends StatefulWidget {
  final AkBook book;
  const PlayerScreen({super.key, required this.book});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  List<AkTrack>? _tracks;
  AkBookInfo? _info;
  bool _loading = true;
  String _err = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = context.read<AkApi>();
    try {
      final tracks = await api.bookTracks(widget.book.path);
      final info = await api.bookInfo(tracks.isNotEmpty ? tracks.first.path : '${widget.book.path}/01.mp3');
      if (!mounted) return;
      setState(() {
        _tracks = tracks;
        _info = info;
        _loading = false;
      });
      final player = context.read<PlayerService>();
      if (player.currentBook?.path != widget.book.path) {
        await player.playBook(widget.book, tracks);
      }
    } catch (e) {
      if (mounted) setState(() {
        _err = '$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerService>();
    final track = player.currentTrack;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.title, style: const TextStyle(fontSize: 14)),
        actions: [
          IconButton(
            icon: Icon(player.playing ? Icons.pause : Icons.play_arrow),
            onPressed: () => player.playPause(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _err.isNotEmpty
              ? Center(child: Text(_err, style: const TextStyle(color: AkTheme.danger)))
              : _content(context, player, track),
    );
  }

  Widget _content(BuildContext ctx, PlayerService player, AkTrack? track) {
    final info = _info;
    return Column(
      children: [
        const SizedBox(height: 24),
        _art(ctx, info),
        const SizedBox(height: 16),
        Text(info?.title ?? widget.book.title,
            textAlign: TextAlign.center, style: const TextStyle(color: AkTheme.accent, fontSize: 16)),
        Text(info?.author ?? widget.book.author,
            textAlign: TextAlign.center, style: const TextStyle(color: AkTheme.accent2, fontSize: 13)),
        const Spacer(),
        _seekbar(player),
        _mainControls(player),
        const SizedBox(height: 8),
        _subControls(player),
        const SizedBox(height: 24),
        _queue(ctx, player),
      ],
    );
  }

  Widget _art(BuildContext ctx, AkBookInfo? info) {
    final api = ctx.read<AkApi>();
    final cover = info?.hasCover == true ? info!.coverPath : widget.book.hasCover ? widget.book.coverPath : '';
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        color: AkTheme.bg3,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AkTheme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: cover.isNotEmpty
          ? CachedNetworkImage(imageUrl: api.coverUri(cover).toString(), fit: BoxFit.cover,
              errorWidget: (_, __, ___) => const Center(child: Icon(Icons.album, size: 60, color: AkTheme.dim)))
          : const Center(child: Icon(Icons.album, size: 60, color: AkTheme.dim)),
    );
  }

  Widget _seekbar(PlayerService player) {
    final dur = player.duration;
    final pos = player.position > dur ? dur : player.position;
    final maxMs = dur.inMilliseconds.toDouble();
    final posMs = pos.inMilliseconds.toDouble().clamp(0.0, maxMs);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Slider(
            value: maxMs > 0 ? posMs : 0,
            max: maxMs > 0 ? maxMs : 1,
            activeColor: AkTheme.accent2,
            onChanged: maxMs > 0 ? (v) => player.seek(Duration(milliseconds: v.round())) : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_fmt(pos.inSeconds), style: const TextStyle(color: AkTheme.dim, fontSize: 11)),
                Text(_fmt(dur.inSeconds), style: const TextStyle(color: AkTheme.dim, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mainControls(PlayerService player) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(icon: const Icon(Icons.replay_30), color: AkTheme.dim, onPressed: () => player.skip30(-30)),
        IconButton(icon: const Icon(Icons.skip_previous), color: AkTheme.dim, onPressed: () => player.prev()),
        const SizedBox(width: 8),
        CircleAvatar(
          radius: 28,
          backgroundColor: AkTheme.accent2,
          child: IconButton(
            icon: Icon(player.playing ? Icons.pause : Icons.play_arrow, color: Colors.black),
            onPressed: () => player.playPause(),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(icon: const Icon(Icons.skip_next), color: AkTheme.dim, onPressed: () => player.next()),
        IconButton(icon: const Icon(Icons.forward_30), color: AkTheme.dim, onPressed: () => player.skip30(30)),
      ],
    );
  }

  Widget _subControls(PlayerService player) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        PopupMenuButton<double>(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Text('${player.raw.speed}x', style: const TextStyle(color: AkTheme.accent2)),
          ),
          itemBuilder: (_) => [0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5]
              .map((s) => PopupMenuItem(value: s, child: Text('${s}x')))
              .toList(),
          onSelected: (s) => player.setSpeed(s),
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: const Icon(Icons.download_done),
          color: _tracks != null && context.read<DownloadService>().isBookDownloaded(widget.book.path, _tracks!)
              ? AkTheme.ok
              : AkTheme.dim,
          onPressed: _tracks == null ? null : () => context.read<DownloadService>().downloadBook(widget.book, _tracks!),
          tooltip: 'Скачать',
        ),
      ],
    );
  }

  Widget _queue(BuildContext ctx, PlayerService player) {
    final tracks = player.queue;
    return SizedBox(
      height: 200,
      child: ListView.builder(
        itemCount: tracks.length,
        itemBuilder: (ctx, i) {
          final t = tracks[i];
          final active = i == player.index;
          return ListTile(
            dense: true,
            leading: Text('${i + 1}', style: TextStyle(color: active ? AkTheme.accent2 : AkTheme.dim)),
            title: Text(t.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: active ? AkTheme.accent2 : AkTheme.text, fontSize: 12)),
            trailing: Text(_fmt((t.size / 1024 / 1024)), style: const TextStyle(color: AkTheme.dim, fontSize: 10)),
            onTap: () => player.seek(Duration.zero),
            selected: active,
            selectedTileColor: AkTheme.bg3,
          );
        },
      ),
    );
  }

  String _fmt(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
