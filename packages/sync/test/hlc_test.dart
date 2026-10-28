import 'dart:math';

import 'package:cashrotate_sync/cashrotate_sync.dart';
import 'package:test/test.dart';

void main() {
  group('send', () {
    test('uses wall time when it moves forward', () {
      expect(const Hlc(100, 7, 'a').send(200), const Hlc(200, 0, 'a'));
    });

    test('counts up when the wall clock stalls or goes backwards', () {
      var clock = const Hlc(500, 0, 'a');
      clock = clock.send(500);
      expect(clock, const Hlc(500, 1, 'a'));
      clock = clock.send(400); // clock set back
      expect(clock, const Hlc(500, 2, 'a'));
    });

    test('counter overflow borrows the next millisecond', () {
      expect(const Hlc(500, 0xFFFF, 'a').send(500), const Hlc(501, 0, 'a'));
    });
  });

  group('receive', () {
    test('jumps to a later remote time', () {
      expect(
        const Hlc(100, 0, 'a').receive(const Hlc(150, 3, 'b'), 120),
        const Hlc(150, 4, 'a'),
      );
    });

    test('wall time ahead of both resets the counter', () {
      expect(
        const Hlc(100, 5, 'a').receive(const Hlc(150, 3, 'b'), 200),
        const Hlc(200, 0, 'a'),
      );
    });

    test('equal millis takes the larger counter plus one', () {
      expect(
        const Hlc(150, 9, 'a').receive(const Hlc(150, 3, 'b'), 100),
        const Hlc(150, 10, 'a'),
      );
    });

    test('rejects a remote clock too far in the future', () {
      const now = 1000000;
      final ahead = Hlc(now + Hlc.maxDrift.inMilliseconds + 1, 0, 'b');
      expect(
        () => const Hlc(now, 0, 'a').receive(ahead, now),
        throwsA(isA<ClockDriftException>()),
      );
    });
  });

  group('ordering and packing', () {
    test('node breaks ties', () {
      expect(const Hlc(1, 1, 'a') < const Hlc(1, 1, 'b'), isTrue);
    });

    test('pack round-trips and sorts like compareTo', () {
      final rnd = Random(42);
      final clocks = [
        for (var i = 0; i < 500; i++)
          Hlc(
            rnd.nextInt(1 << 32) * 256 + rnd.nextInt(256), // up to 2^40
            rnd.nextInt(0x10000),
            ['dev-1', 'dev-2', 'x'][rnd.nextInt(3)],
          ),
      ];
      for (final c in clocks) {
        expect(Hlc.parse(c.pack()), c);
      }
      final byValue = [...clocks]..sort();
      final byText = [...clocks]..sort((a, b) => a.pack().compareTo(b.pack()));
      expect(byText, byValue);
    });

    test('node ids may contain dashes', () {
      const c = Hlc(42, 1, '018f-uuid-like');
      expect(Hlc.parse(c.pack()), c);
    });

    test('rejects malformed text', () {
      expect(() => Hlc.parse('nope'), throwsFormatException);
    });
  });

  test('timestamps from one device are strictly increasing', () {
    final rnd = Random(7);
    var clock = const Hlc.zero('a');
    var wall = 1000;
    for (var i = 0; i < 10000; i++) {
      wall += rnd.nextInt(3) - 1; // stalls and steps back too
      final next = rnd.nextBool()
          ? clock.send(wall)
          : clock.receive(
              Hlc(wall + rnd.nextInt(50), rnd.nextInt(10), 'b'),
              wall,
            );
      expect(next > clock, isTrue);
      clock = next;
    }
  });
}
