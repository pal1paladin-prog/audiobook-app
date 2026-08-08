class AkBook {
  final String dir;
  final String path;
  final String title;
  final String author;
  final String narrator;
  final String series;
  final String description;
  final String coverPath;
  final bool hasCover;
  final String genre;
  final String duration;
  final int? durationSec;

  AkBook({
    required this.dir,
    required this.path,
    required this.title,
    required this.author,
    required this.narrator,
    required this.series,
    required this.description,
    required this.coverPath,
    required this.hasCover,
    required this.genre,
    this.duration = '',
    this.durationSec,
  });

  factory AkBook.fromJson(Map<String, dynamic> j) => AkBook(
        dir: j['dir'] ?? '',
        path: j['path'] ?? '',
        title: j['title'] ?? '',
        author: j['author'] ?? '',
        narrator: j['narrator'] ?? '',
        series: j['series'] ?? '',
        description: j['description'] ?? '',
        coverPath: j['cover_path'] ?? '',
        hasCover: j['has_cover'] ?? false,
        genre: j['genre'] ?? '',
        duration: j['duration'] ?? '',
        durationSec: (j['duration_sec'] as num?)?.toInt(),
      );
}

class AkTrack {
  final String name;
  final String path;
  final int size;

  AkTrack({required this.name, required this.path, required this.size});

  factory AkTrack.fromJson(Map<String, dynamic> j) =>
      AkTrack(name: j['name'] ?? '', path: j['path'] ?? '', size: j['size'] ?? 0);
}

class AkBookInfo {
  final String title;
  final String author;
  final String narrator;
  final String series;
  final String description;
  final String coverPath;
  final bool hasCover;
  final List<String> tracks;

  AkBookInfo({
    required this.title,
    required this.author,
    required this.narrator,
    required this.series,
    required this.description,
    required this.coverPath,
    required this.hasCover,
    required this.tracks,
  });

  factory AkBookInfo.fromJson(Map<String, dynamic> j) {
    final info = j['info'] ?? {};
    final List<String> tracks = [];
    if (info['tracks'] is List) {
      for (final t in info['tracks']) {
        tracks.add(t.toString());
      }
    }
    return AkBookInfo(
      title: info['title'] ?? '',
      author: info['author'] ?? '',
      narrator: info['narrator'] ?? '',
      series: info['series'] ?? '',
      description: info['description'] ?? '',
      coverPath: j['cover_path'] ?? '',
      hasCover: j['has_cover'] ?? false,
      tracks: tracks,
    );
  }
}

class ActivityEvent {
  final String directory;
  final String title;
  final String author;
  final String status;
  final String manual;
  final String site;
  final DateTime at;

  ActivityEvent({
    required this.directory,
    required this.title,
    required this.author,
    required this.status,
    required this.manual,
    required this.site,
    required this.at,
  });

  bool get isDownload => status == 'downloaded';

  factory ActivityEvent.fromJson(Map<String, dynamic> j) => ActivityEvent(
        directory: j['directory'] ?? '',
        title: j['title'] ?? '',
        author: j['author'] ?? '',
        status: j['status'] ?? '',
        manual: j['manual'] ?? '',
        site: j['site'] ?? '',
        at: DateTime.tryParse(j['at'] ?? '') ?? DateTime.now(),
      );
}
