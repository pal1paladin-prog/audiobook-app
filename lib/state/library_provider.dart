import 'package:flutter/foundation.dart';
import '../api/ak_api.dart';
import '../models/ak_models.dart';

class SeriesGroup {
  final String key;
  final String display;
  final String author;
  final String coverPath;
  final List<AkBook> books;
  SeriesGroup({required this.key, required this.display, required this.author, required this.coverPath, required this.books});
}

class LibraryProvider extends ChangeNotifier {
  final AkApi api;
  List<AkBook> _all = [];
  bool _loading = false;
  String _error = '';
  String _genre = '';

  LibraryProvider(this.api);

  List<AkBook> get all => _all;
  bool get loading => _loading;
  String get error => _error;
  String get genre => _genre;

  List<String> get genres {
    final g = <String>{};
    for (final b in _all) {
      if (b.genre.isNotEmpty) g.add(b.genre);
    }
    return g.toList()..sort();
  }

  Future<void> load() async {
    _loading = true;
    _error = '';
    notifyListeners();
    try {
      _all = await api.books();
    } catch (e) {
      _error = '$e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void setGenre(String g) {
    _genre = g;
    notifyListeners();
  }

  List<AkBook> get _filtered {
    if (_genre.isEmpty) return _all;
    return _all.where((b) => b.genre.toLowerCase() == _genre.toLowerCase()).toList();
  }

  String _baseTitle(String title) {
    var t = title;
    t = t.replaceAll(RegExp(r'\s*/\s*.*$'), '');
    t = t.replaceAll(RegExp(r'\s*\([^)]*\)\s*$'), '');
    const roman = 'IVXLCХ';
    final rc = '[$roman]';
    final patterns = [
      RegExp(r'\s+(Том|Книга|Часть| Book|Part|Vol\.?)\s+' + rc + r'+(\s*[-–—]\s+' + rc + r'+)?[.:]?\s*.*'),
      RegExp(r'\s+' + rc + r'+(\s*[-–—]\s+' + rc + r'+)?[.:]?\s*$'),
      RegExp(r'[-–—]\s+' + rc + r'+(\s*[-–—]\s+' + rc + r'+)?\s*$'),
      RegExp(r'\s+\d+\s*[-–—:.]\s*.*$'),
      RegExp(r'\s+\d+\s*$'),
      RegExp(r'[.:]\s+.*$'),
      RegExp(r'\s*#\d+\s*$'),
      RegExp(r'\s*-\s*Глава\s+.*$', caseSensitive: false),
    ];
    for (final p in patterns) {
      t = t.replaceFirst(p, '');
    }
    return t.trim();
  }

  List<SeriesGroup> get grouped {
    final books = _filtered;
    final groups = <String, _Group>{};
    for (final b in books) {
      final series = b.series.trim();
      final bt = _baseTitle(b.title);
      final key = (series.isNotEmpty ? series : bt).toLowerCase();
      final g = groups.putIfAbsent(
          key,
          () => _Group(key: key, display: series.isNotEmpty ? series : bt, coverPath: b.hasCover ? b.coverPath : ''));
      g.books.add(b);
      if (!g.authors.contains(b.author)) g.authors.add(b.author);
      if (g.coverPath.isEmpty && b.hasCover) g.coverPath = b.coverPath;
    }
    final list = groups.values.map((g) => SeriesGroup(
        key: g.key,
        display: g.display,
        author: g.authors.join(', '),
        coverPath: g.coverPath,
        books: g.books..sort((a, b) => a.title.compareTo(b.title)))).toList();
    list.sort((a, b) {
      if (b.books.length != a.books.length) return b.books.length - a.books.length;
      return a.display.compareTo(b.display);
    });
    return list;
  }
}

class _Group {
  final String key;
  final String display;
  String coverPath;
  final List<String> authors = [];
  final List<AkBook> books = [];
  _Group({required this.key, required this.display, this.coverPath = ''});
}
