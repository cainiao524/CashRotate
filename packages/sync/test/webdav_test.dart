import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cashrotate_sync/cashrotate_sync.dart';
import 'package:test/test.dart';

import 'memory_store.dart';

/// A tiny WebDAV server over a [MemoryFolder]: enough of PROPFIND, GET, PUT,
/// MOVE, DELETE and MKCOL to exercise the client, with Basic auth.
class FakeDavServer {
  FakeDavServer._(this._server, this.folder, this.prefix);

  static Future<FakeDavServer> start({String prefix = '/dav/'}) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final dav = FakeDavServer._(server, MemoryFolder(), prefix);
    server.listen(dav._handle);
    return dav;
  }

  final HttpServer _server;
  final MemoryFolder folder;
  final String prefix;
  final methods = <String>[];

  /// Behind-a-proxy servers: refuse an absolute Destination (Apache mod_dav
  /// answers 502 for another scheme/port), or refuse MOVE altogether.
  bool rejectAbsoluteDestination = false;
  bool noMove = false;
  static const auth = 'Basic dXNlcjpwYXNz'; // user:pass

  Uri get base => Uri.parse('http://127.0.0.1:${_server.port}$prefix');

  String _rel(String path) {
    final p = Uri.decodeFull(path);
    final rel = p.startsWith(prefix) ? p.substring(prefix.length) : p;
    return rel.endsWith('/') ? rel.substring(0, rel.length - 1) : rel;
  }

  Future<void> _handle(HttpRequest req) async {
    methods.add(req.method);
    final res = req.response;
    if (req.headers.value(HttpHeaders.authorizationHeader) != auth) {
      res.statusCode = 401;
      await res.close();
      return;
    }
    final path = _rel(req.uri.path);
    final body = await req.fold<List<int>>([], (a, b) => a..addAll(b));
    switch (req.method) {
      case 'PROPFIND':
        final isDir = folder.directories.contains(path);
        if (!isDir && !folder.files.containsKey(path)) {
          res.statusCode = 404;
          break;
        }
        // Nextcloud-style: d: prefix, absolute hrefs, percent-encoding.
        String entry(String rel, bool dir) {
          final href =
              '$prefix${Uri.encodeFull(rel)}${dir && rel.isNotEmpty ? '/' : ''}';
          return '<d:response><d:href>$href</d:href><d:propstat><d:prop>'
              '<d:resourcetype>${dir ? '<d:collection/>' : ''}</d:resourcetype>'
              '</d:prop><d:status>HTTP/1.1 200 OK</d:status></d:propstat></d:response>';
        }

        final entries = [
          entry(path, true),
          for (final e in await folder.list(path))
            entry(path.isEmpty ? e.name : '$path/${e.name}', e.isDirectory),
        ];
        res.statusCode = 207;
        res.write(
          '<?xml version="1.0"?><d:multistatus xmlns:d="DAV:">${entries.join()}</d:multistatus>',
        );
      case 'GET':
        final bytes = await folder.read(path);
        if (bytes == null) {
          res.statusCode = 404;
        } else {
          res.add(bytes);
        }
      case 'PUT':
        try {
          await folder.write(path, body);
          res.statusCode = 201;
        } on StateError {
          res.statusCode = 409; // no parent collection
        }
      case 'MOVE':
        final header = req.headers.value('Destination')!;
        if (noMove ||
            (rejectAbsoluteDestination && header.startsWith('http'))) {
          res.statusCode = 502;
          break;
        }
        final dest = _rel(Uri.parse(header).path);
        try {
          await folder.move(path, dest);
          res.statusCode = 201;
        } on StateError {
          res.statusCode = 404;
        }
      case 'DELETE':
        final existed = folder.files.containsKey(path);
        await folder.delete(path);
        res.statusCode = existed ? 204 : 404;
      case 'MKCOL':
        if (folder.directories.contains(path)) {
          res.statusCode = 405;
        } else {
          await folder.makeDirectory(path);
          res.statusCode = 201;
        }
      default:
        res.statusCode = 405;
    }
    await res.close();
  }

  Future<void> close() => _server.close(force: true);
}

void main() {
  late FakeDavServer server;
  late WebDavFolder dav;

  setUp(() async {
    server = await FakeDavServer.start();
    dav = WebDavFolder(server.base, user: 'user', password: 'pass');
  });
  tearDown(() async {
    dav.close();
    await server.close();
  });

  test('make directories, write, list, read, move, delete', () async {
    await dav.makeDirectory('devices/a b');
    await dav.makeDirectory('devices/a b'); // exists: fine
    await dav.write('devices/a b/1.chg.tmp', [1, 2, 3]);
    await dav.move('devices/a b/1.chg.tmp', 'devices/a b/1.chg');
    expect((await dav.list('devices')).map((e) => e.toString()), ['a b/']);
    expect((await dav.list('devices/a b')).map((e) => e.name), ['1.chg']);
    expect(await dav.read('devices/a b/1.chg'), [1, 2, 3]);
    expect(await dav.read('devices/a b/missing'), isNull);
    expect(await dav.list('nowhere'), isEmpty);
    await dav.delete('devices/a b/1.chg');
    await dav.delete('devices/a b/1.chg'); // gone already: fine
    expect(await dav.list('devices/a b'), isEmpty);
  });

  test('MOVE behind a proxy: retried with a path-only destination', () async {
    server.rejectAbsoluteDestination = true;
    await dav.write('m.tmp', [7]);
    await dav.move('m.tmp', 'manifest.json');
    expect(await dav.read('manifest.json'), [7]);
    expect(await dav.read('m.tmp'), isNull);
  });

  test('a server without a working MOVE: copy, then delete', () async {
    server.noMove = true;
    await dav.write('m.tmp', [8]);
    await dav.move('m.tmp', 'manifest.json');
    expect(await dav.read('manifest.json'), [8]);
    expect(await dav.read('m.tmp'), isNull);
  });

  test('errors name the request and the status', () async {
    server.noMove = true;
    Object? error;
    try {
      await dav.move('missing', 'x');
    } on WebDavException catch (e) {
      error = e;
    }
    expect((error! as WebDavException).summary, 'MOVE missing: HTTP 502');
  });

  test('a wrong password is reported as an auth error', () async {
    final wrong = WebDavFolder(server.base, user: 'user', password: 'nope');
    await expectLater(
      wrong.list(''),
      throwsA(isA<WebDavException>().having((e) => e.isAuth, 'isAuth', true)),
    );
    wrong.close();
  });

  test('the sync engine runs end to end over WebDAV', () async {
    var now = 1_800_000_000_000;
    final a = MemoryStore('a', clock: () => now)
      ..edit('items', '1', {'name': '"Netflix"'});
    final b = MemoryStore('b', clock: () => now);
    SyncEngine engine(MemoryStore s) => SyncEngine(
      store: s,
      remote: dav,
      cipher: const TestCipher(),
      nowMillis: () => now,
      random: Random(2),
    );
    await engine(a).sync();
    now += 1000;
    await engine(b).sync();
    expect(b.rows, a.rows);
    expect(server.methods, containsAll(['PROPFIND', 'PUT', 'MOVE', 'GET']));
  });

  group('multistatus from real servers', () {
    test('Synology / Apache: D: prefix, lp1 properties, absolute URLs', () {
      const xml = '''
<?xml version="1.0" encoding="utf-8"?>
<D:multistatus xmlns:D="DAV:" xmlns:lp1="DAV:">
<D:response><D:href>https://nas.local:5006/home/CashRotate/</D:href>
<D:propstat><D:prop><lp1:resourcetype><D:collection/></lp1:resourcetype></D:prop></D:propstat></D:response>
<D:response><D:href>https://nas.local:5006/home/CashRotate/devices/</D:href>
<D:propstat><D:prop><lp1:resourcetype><D:collection/></lp1:resourcetype></D:prop></D:propstat></D:response>
<D:response><D:href>https://nas.local:5006/home/CashRotate/manifest.json</D:href>
<D:propstat><D:prop><lp1:resourcetype/></D:prop></D:propstat></D:response>
</D:multistatus>''';
      expect(parseMultiStatus(xml, '/home/CashRotate/').map((e) => '$e'), [
        'devices/',
        'manifest.json',
      ]);
    });

    test('堅果雲: no prefix on elements, percent-encoded CJK names', () {
      const xml = '''
<?xml version="1.0" encoding="UTF-8"?>
<multistatus xmlns="DAV:">
<response><href>/dav/%E8%A8%98%E5%B8%B3/</href><propstat><prop><resourcetype><collection/></resourcetype></prop></propstat></response>
<response><href>/dav/%E8%A8%98%E5%B8%B3/snap-1-a.bin</href><propstat><prop><resourcetype/></prop></propstat></response>
</multistatus>''';
      expect(
        parseMultiStatus(xml, '/dav/%E8%A8%98%E5%B8%B3/').map((e) => '$e'),
        ['snap-1-a.bin'],
      );
    });

    test('InfiniCLOUD: d: prefix, self href without trailing slash', () {
      const xml = '''
<d:multistatus xmlns:d="DAV:"><d:response><d:href>/dav/sync</d:href>
<d:propstat><d:prop><d:resourcetype><d:collection /></d:resourcetype></d:prop></d:propstat></d:response>
<d:response><d:href>/dav/sync/a&amp;b.chg</d:href><d:propstat><d:prop><d:resourcetype></d:resourcetype></d:prop></d:propstat></d:response>
</d:multistatus>''';
      expect(parseMultiStatus(xml, '/dav/sync/').map((e) => '$e'), ['a&b.chg']);
    });
  });

  test('credentials are sent only as a Basic header', () {
    expect(
      FakeDavServer.auth,
      'Basic ${base64.encode(utf8.encode('user:pass'))}',
    );
  });
}
