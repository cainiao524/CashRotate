import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'remote_folder.dart';

/// A WebDAV server failed or refused a request.
class WebDavException implements Exception {
  const WebDavException(this.method, this.path, this.status, [this.body = '']);

  final String method;
  final String path;
  final int status;
  final String body;

  /// Wrong user name or (app) password.
  bool get isAuth => status == 401 || status == 403;

  @override
  String toString() => 'WebDavException: $method $path → $status';
}

/// The user's folder on a WebDAV server (Nextcloud, Synology, 堅果雲,
/// InfiniCLOUD …), with only the requests the sync protocol needs:
/// PROPFIND (depth 1), GET, PUT, MOVE, DELETE and MKCOL.
///
/// Credentials go only to [base]'s host, over HTTPS unless the user enters
/// an http:// address for a server on their own network.
class WebDavFolder implements RemoteFolder {
  WebDavFolder(
    Uri base, {
    required String user,
    required String password,
    HttpClient? client,
    this.timeout = const Duration(seconds: 30),
  }) : base = base.path.endsWith('/')
           ? base
           : base.replace(path: '${base.path}/'),
       _auth = 'Basic ${base64.encode(utf8.encode('$user:$password'))}',
       _client = client ?? HttpClient();

  final Uri base;
  final String _auth;
  final HttpClient _client;
  final Duration timeout;

  Uri _uri(String path, {bool directory = false}) {
    final segments = [
      ...base.pathSegments.where((s) => s.isNotEmpty),
      ...path.split('/').where((s) => s.isNotEmpty),
    ];
    return base.replace(pathSegments: [...segments, if (directory) '']);
  }

  Future<(int, Uint8List)> _send(
    String method,
    Uri uri, {
    List<int>? body,
    Map<String, String> headers = const {},
  }) async {
    final request = await _client.openUrl(method, uri).timeout(timeout);
    request.followRedirects = false;
    request.headers.set(HttpHeaders.authorizationHeader, _auth);
    headers.forEach(request.headers.set);
    if (body != null) {
      request.contentLength = body.length;
      request.add(body);
    }
    final response = await request.close().timeout(timeout);
    final builder = BytesBuilder(copy: false);
    await response.forEach(builder.add).timeout(timeout);
    return (response.statusCode, builder.takeBytes());
  }

  Never _fail(String method, String path, int status, Uint8List body) =>
      throw WebDavException(
        method,
        path,
        status,
        utf8.decode(body, allowMalformed: true),
      );

  @override
  Future<List<RemoteEntry>> list(String dir) async {
    final uri = _uri(dir, directory: true);
    final (status, body) = await _send(
      'PROPFIND',
      uri,
      headers: {'Depth': '1', 'Content-Type': 'application/xml; charset=utf-8'},
      body: utf8.encode(
        '<?xml version="1.0" encoding="utf-8"?>'
        '<d:propfind xmlns:d="DAV:"><d:prop><d:resourcetype/></d:prop></d:propfind>',
      ),
    );
    if (status == 404) return const [];
    if (status != 207 && status != 200) _fail('PROPFIND', dir, status, body);
    return parseMultiStatus(utf8.decode(body, allowMalformed: true), uri.path);
  }

  @override
  Future<Uint8List?> read(String path) async {
    final (status, body) = await _send('GET', _uri(path));
    if (status == 404) return null;
    if (status != 200) _fail('GET', path, status, body);
    return body;
  }

  @override
  Future<void> write(String path, List<int> bytes) async {
    final (status, body) = await _send(
      'PUT',
      _uri(path),
      body: bytes,
      headers: {'Content-Type': 'application/octet-stream'},
    );
    if (status != 200 && status != 201 && status != 204) {
      _fail('PUT', path, status, body);
    }
  }

  @override
  Future<void> move(String from, String to) async {
    final (status, body) = await _send(
      'MOVE',
      _uri(from),
      headers: {'Destination': _uri(to).toString(), 'Overwrite': 'T'},
    );
    if (status != 201 && status != 204) _fail('MOVE', from, status, body);
  }

  @override
  Future<void> delete(String path) async {
    final (status, body) = await _send('DELETE', _uri(path));
    if (status != 200 && status != 204 && status != 404) {
      _fail('DELETE', path, status, body);
    }
  }

  @override
  Future<void> makeDirectory(String dir) async {
    var current = '';
    for (final part in dir.split('/').where((s) => s.isNotEmpty)) {
      current = current.isEmpty ? part : '$current/$part';
      final (status, body) = await _send(
        'MKCOL',
        _uri(current, directory: true),
      );
      // 405: already exists. Some servers answer 409/301 for existing ones.
      if (status != 201 && status != 405 && status != 301 && status != 409) {
        _fail('MKCOL', current, status, body);
      }
    }
  }

  void close() => _client.close();
}

final _response = RegExp(
  r'<(?:[\w-]+:)?response\b[^>]*>(.*?)</(?:[\w-]+:)?response>',
  dotAll: true,
  caseSensitive: false,
);
final _href = RegExp(
  r'<(?:[\w-]+:)?href\b[^>]*>(.*?)</(?:[\w-]+:)?href>',
  dotAll: true,
  caseSensitive: false,
);
final _collection = RegExp(
  r'<(?:[\w-]+:)?collection\b[^>]*/?>',
  caseSensitive: false,
);

/// Entries of a PROPFIND multistatus body, without the listed directory
/// itself ([selfPath]). Tolerates any namespace prefix (`d:`, `D:`, `lp1:`,
/// none), absolute or relative hrefs, and percent-encoded names, as the
/// servers above send them.
List<RemoteEntry> parseMultiStatus(String xml, String selfPath) {
  String norm(String p) {
    final path = p.startsWith('http') ? Uri.parse(p).path : p;
    final decoded = Uri.decodeFull(path.trim());
    return decoded.endsWith('/')
        ? decoded.substring(0, decoded.length - 1)
        : decoded;
  }

  final self = norm(selfPath);
  final entries = <RemoteEntry>[];
  for (final m in _response.allMatches(xml)) {
    final block = m[1]!;
    final href = _href.firstMatch(block)?[1];
    if (href == null) continue;
    final path = norm(_unescape(href));
    if (path == self || path.isEmpty) continue;
    final name = path.substring(path.lastIndexOf('/') + 1);
    entries.add(RemoteEntry(name, isDirectory: _collection.hasMatch(block)));
  }
  return entries;
}

String _unescape(String s) => s
    .replaceAll('&amp;', '&')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&apos;', "'");
