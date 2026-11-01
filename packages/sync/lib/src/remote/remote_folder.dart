import 'dart:typed_data';

/// One entry of a remote directory listing.
class RemoteEntry {
  const RemoteEntry(this.name, {required this.isDirectory});

  final String name;
  final bool isDirectory;

  @override
  String toString() => isDirectory ? '$name/' : name;
}

/// The user's sync folder (WebDAV in the app, in memory in tests). Paths are
/// relative to the folder and use `/`.
abstract interface class RemoteFolder {
  /// Entries directly inside [dir]; empty when it does not exist.
  Future<List<RemoteEntry>> list(String dir);

  /// The file's bytes, or null when it does not exist.
  Future<Uint8List?> read(String path);

  /// Creates or replaces a file. Parent directories must exist.
  Future<void> write(String path, List<int> bytes);

  /// Renames [from] to [to], replacing [to].
  Future<void> move(String from, String to);

  /// Deletes a file; no error when it is already gone.
  Future<void> delete(String path);

  /// Creates a directory; no error when it exists.
  Future<void> makeDirectory(String dir);
}

/// An in-memory folder, for tests and for trying sync without a server.
class MemoryFolder implements RemoteFolder {
  final files = <String, Uint8List>{};
  final directories = <String>{''};

  /// Every write, for tests that check the temp-name-then-move protocol.
  final writes = <String>[];

  String _parent(String path) {
    final i = path.lastIndexOf('/');
    return i < 0 ? '' : path.substring(0, i);
  }

  @override
  Future<List<RemoteEntry>> list(String dir) async {
    if (!directories.contains(dir)) return const [];
    final prefix = dir.isEmpty ? '' : '$dir/';
    String? child(String p) {
      if (!p.startsWith(prefix) || p == dir) return null;
      final rest = p.substring(prefix.length);
      return rest.contains('/') ? null : rest;
    }

    return [
      for (final d in directories)
        if (child(d) case final name?) RemoteEntry(name, isDirectory: true),
      for (final f in files.keys)
        if (child(f) case final name?) RemoteEntry(name, isDirectory: false),
    ];
  }

  @override
  Future<Uint8List?> read(String path) async => files[path];

  @override
  Future<void> write(String path, List<int> bytes) async {
    if (!directories.contains(_parent(path))) {
      throw StateError('No directory for $path');
    }
    writes.add(path);
    files[path] = Uint8List.fromList(bytes);
  }

  @override
  Future<void> move(String from, String to) async {
    final bytes = files.remove(from);
    if (bytes == null) throw StateError('No file $from');
    files[to] = bytes;
  }

  @override
  Future<void> delete(String path) async => files.remove(path);

  @override
  Future<void> makeDirectory(String dir) async {
    var d = dir;
    while (d.isNotEmpty) {
      directories.add(d);
      d = _parent(d);
    }
  }
}
