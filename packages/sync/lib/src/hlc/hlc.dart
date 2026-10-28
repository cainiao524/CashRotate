import 'package:meta/meta.dart';

/// A hybrid logical clock timestamp: wall-clock milliseconds, a counter for
/// events within the same millisecond, and the device that produced it.
///
/// Ordering is total (ties broken by [node]), so "the newer write wins" has
/// exactly one answer on every device. The packed string form sorts the same
/// way as [compareTo], so it can be indexed and compared as text.
@immutable
final class Hlc implements Comparable<Hlc> {
  const Hlc(this.millis, this.counter, this.node)
    : assert(millis >= 0 && millis <= _maxMillis),
      assert(counter >= 0 && counter <= _maxCounter);

  const Hlc.zero(this.node) : millis = 0, counter = 0;

  /// Parses the output of [pack].
  factory Hlc.parse(String packed) {
    final match = _packed.firstMatch(packed);
    if (match == null) throw FormatException('Not a packed HLC', packed);
    return Hlc(
      int.parse(match[1]!, radix: 16),
      int.parse(match[2]!, radix: 16),
      match[3]!,
    );
  }

  static final _packed = RegExp(r'^([0-9a-f]{12})-([0-9a-f]{4})-(.+)$');
  static const _maxMillis = 0xFFFFFFFFFFFF; // year 10889
  static const _maxCounter = 0xFFFF;

  /// Remote clocks this far ahead of ours are rejected rather than letting
  /// one device with a wrong clock drag every other device into the future.
  static const maxDrift = Duration(minutes: 5);

  final int millis;
  final int counter;
  final String node;

  /// Timestamp for a local event at wall-clock [nowMillis].
  Hlc send(int nowMillis) {
    if (nowMillis > millis) return Hlc(nowMillis, 0, node);
    return _bump(millis, counter + 1, node);
  }

  /// Merges a timestamp [remote] received from another device into this
  /// clock, at local wall-clock [nowMillis].
  Hlc receive(Hlc remote, int nowMillis) {
    if (remote.millis - nowMillis > maxDrift.inMilliseconds) {
      throw ClockDriftException(remote, nowMillis);
    }
    final m = [
      millis,
      remote.millis,
      nowMillis,
    ].reduce((a, b) => a > b ? a : b);
    final c = switch (m) {
      _ when m == millis && m == remote.millis =>
        (counter > remote.counter ? counter : remote.counter) + 1,
      _ when m == millis => counter + 1,
      _ when m == remote.millis => remote.counter + 1,
      _ => 0,
    };
    return _bump(m, c, node);
  }

  static Hlc _bump(int millis, int counter, String node) {
    if (counter > _maxCounter) {
      // 65 536 events in one millisecond: borrow the next millisecond.
      return Hlc(millis + 1, 0, node);
    }
    return Hlc(millis, counter, node);
  }

  /// `<12 hex millis>-<4 hex counter>-<node>`, sortable as text.
  String pack() =>
      '${millis.toRadixString(16).padLeft(12, '0')}-'
      '${counter.toRadixString(16).padLeft(4, '0')}-$node';

  @override
  int compareTo(Hlc other) {
    if (millis != other.millis) return millis.compareTo(other.millis);
    if (counter != other.counter) return counter.compareTo(other.counter);
    return node.compareTo(other.node);
  }

  bool operator >(Hlc other) => compareTo(other) > 0;
  bool operator <(Hlc other) => compareTo(other) < 0;

  @override
  bool operator ==(Object other) =>
      other is Hlc &&
      other.millis == millis &&
      other.counter == counter &&
      other.node == node;

  @override
  int get hashCode => Object.hash(millis, counter, node);

  @override
  String toString() => pack();
}

class ClockDriftException implements Exception {
  ClockDriftException(this.remote, this.nowMillis);

  final Hlc remote;
  final int nowMillis;

  @override
  String toString() =>
      'ClockDriftException: ${remote.node} is '
      '${remote.millis - nowMillis} ms ahead of this device';
}
