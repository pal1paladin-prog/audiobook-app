import 'dart:convert';
import 'package:dio/dio.dart';
import 'models/ak_models.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class AkApi {
  final Dio _dio;
  String _baseUrl;
  String _user;

  AkApi({required String baseUrl, String user = 'default'})
      : _baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), ''),
        _user = user,
        _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 15),
          validateStatus: (s) => s != null && s < 500,
        ));

  String get baseUrl => _baseUrl;
  set baseUrl(String v) => _baseUrl = v.replaceAll(RegExp(r'/+$'), '');
  set user(String v) => _user = v;

  String _qs(Map<String, dynamic> q) => q.entries
      .where((e) => e.value != null)
      .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent('${e.value}')}')
      .join('&');

  Uri _uri(String action, [Map<String, dynamic>? extra]) {
    final q = <String, dynamic>{'action': action, 'user': _user, ...?extra};
    return Uri.parse('$_baseUrl/ak.php?${_qs(q)}');
  }

  void _checkOk(Map<String, dynamic> j) {
    if (j['ok'] != true) {
      throw ApiException(j['error']?.toString() ?? 'unknown error');
    }
  }

  Future<List<AkBook>> books({String? genre}) async {
    final r = await _dio.getUri(_uri('books', genre != null ? {'genre': genre} : null));
    final j = _json(r.data);
    _checkOk(j);
    return (j['books'] as List? ?? []).map((e) => AkBook.fromJson(e)).toList();
  }

  Future<List<AkTrack>> bookTracks(String path) async {
    final r = await _dio.getUri(_uri('booktracks', {'path': path}));
    final j = _json(r.data);
    _checkOk(j);
    return (j['files'] as List? ?? []).map((e) => AkTrack.fromJson(e)).toList();
  }

  Future<AkBookInfo> bookInfo(String firstTrackPath) async {
    final r = await _dio.getUri(_uri('bookinfo', {'path': firstTrackPath}));
    final j = _json(r.data);
    _checkOk(j);
    return AkBookInfo.fromJson(j);
  }

  Uri streamUri(String trackPath) =>
      Uri.parse('$_baseUrl/ak.php?action=${Uri.encodeComponent('stream')}&path=${Uri.encodeComponent(trackPath)}&user=$_user');

  Uri coverUri(String coverPath) => Uri.parse('$_baseUrl/$coverPath');

  Future<double?> getProgress(String trackPath) async {
    final r = await _dio.getUri(_uri('progress', {'path': trackPath}));
    final j = _json(r.data);
    _checkOk(j);
    final p = j['progress'];
    if (p == null) return null;
    return (p['pos'] as num?)?.toDouble();
  }

  Future<void> saveProgress(String trackPath, double pos, {double? dur}) async {
    final fd = FormData.fromMap({'action': 'progress', 'path': trackPath, 'pos': pos, 'user': _user, if (dur != null) 'dur': dur});
    await _dio.post('$_baseUrl/ak.php', data: fd);
  }

  Future<List<ActivityEvent>> log({int days = 7}) async {
    final r = await _dio.getUri(_uri('log', {'days': days}));
    final j = _json(r.data);
    _checkOk(j);
    return (j['events'] as List? ?? []).map((e) => ActivityEvent.fromJson(e)).toList();
  }

  Future<void> deleteBook(String path) async {
    final r = await _dio.getUri(_uri('delete_book', {'path': path}));
    final j = _json(r.data);
    _checkOk(j);
  }

  Future<void> deleteSeries(List<String> paths) async {
    final r = await _dio.post('$_baseUrl/ak.php?action=delete_series', data: {'paths': paths});
    final j = _json(r.data);
    _checkOk(j);
  }

  Map<String, dynamic> _json(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is String) {
      return Map<String, dynamic>.from(
        const JsonDecoder().convert(data) as Map,
      );
    }
    throw ApiException('unexpected response type: ${data.runtimeType}');
  }
}
