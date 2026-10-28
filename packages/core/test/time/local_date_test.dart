import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:test/test.dart';

LocalDate d(String iso) => LocalDate.parse(iso);

void main() {
  group('construction', () {
    test('parses and prints yyyy-MM-dd', () {
      expect(d('2026-02-03').toString(), '2026-02-03');
      expect(LocalDate(5, 1, 9).toString(), '0005-01-09');
    });

    test('rejects impossible dates', () {
      expect(() => LocalDate(2026, 2, 29), throwsArgumentError);
      expect(() => LocalDate(2026, 4, 31), throwsArgumentError);
      expect(() => LocalDate(2026, 13, 1), throwsArgumentError);
      expect(() => LocalDate(2026, 0, 1), throwsArgumentError);
      expect(() => LocalDate(2026, 1, 0), throwsArgumentError);
      expect(LocalDate(2024, 2, 29).day, 29);
    });

    test('rejects malformed text', () {
      for (final bad in ['2026-2-3', '2026/02/03', '2026-02-03T00:00', '']) {
        expect(() => LocalDate.parse(bad), throwsFormatException, reason: bad);
      }
    });

    test('fromDateTime keeps the wall-clock date of that zone', () {
      // 23:30 UTC on Jan 31 is already Feb 1 in Taipei; the caller decides
      // which zone's date it means by passing a local or UTC DateTime.
      expect(
        LocalDate.fromDateTime(DateTime.utc(2026, 1, 31, 23, 30)),
        d('2026-01-31'),
      );
    });
  });

  group('days in month', () {
    test('leap year rules', () {
      expect(LocalDate.daysInMonth(2024, 2), 29);
      expect(LocalDate.daysInMonth(2026, 2), 28);
      expect(LocalDate.daysInMonth(1900, 2), 28); // divisible by 100
      expect(LocalDate.daysInMonth(2000, 2), 29); // divisible by 400
      expect(LocalDate.daysInMonth(2026, 4), 30);
      expect(LocalDate.daysInMonth(2026, 12), 31);
    });
  });

  group('addMonths clamps to the month end', () {
    test('31st into shorter months', () {
      final jan31 = d('2026-01-31');
      expect(jan31.addMonths(1), d('2026-02-28'));
      expect(jan31.addMonths(2), d('2026-03-31'));
      expect(jan31.addMonths(3), d('2026-04-30'));
      expect(d('2024-01-31').addMonths(1), d('2024-02-29'));
    });

    test('30th and 29th', () {
      expect(d('2026-01-30').addMonths(1), d('2026-02-28'));
      expect(d('2026-01-29').addMonths(1), d('2026-02-28'));
      expect(d('2028-01-29').addMonths(1), d('2028-02-29'));
    });

    test('across year boundaries and backwards', () {
      expect(d('2026-11-30').addMonths(3), d('2027-02-28'));
      expect(d('2026-03-31').addMonths(-1), d('2026-02-28'));
      expect(d('2026-01-15').addMonths(-1), d('2025-12-15'));
      expect(d('2026-01-15').addMonths(-13), d('2024-12-15'));
    });

    test('Feb 29 yearly', () {
      expect(d('2024-02-29').addYears(1), d('2025-02-28'));
      expect(d('2024-02-29').addYears(4), d('2028-02-29'));
    });
  });

  group('day arithmetic', () {
    test('addDays across month, year and leap day', () {
      expect(d('2026-12-31').addDays(1), d('2027-01-01'));
      expect(d('2024-02-28').addDays(1), d('2024-02-29'));
      expect(d('2024-03-01').addDays(-1), d('2024-02-29'));
      expect(d('1970-01-01').addDays(-1), d('1969-12-31'));
    });

    test('daysUntil and epochDay round-trip', () {
      expect(d('2026-01-01').daysUntil(d('2027-01-01')), 365);
      expect(d('2024-01-01').daysUntil(d('2025-01-01')), 366);
      expect(d('2026-03-01').daysUntil(d('2026-02-01')), -28);
      for (final iso in ['1969-07-20', '2000-02-29', '2026-10-28']) {
        expect(LocalDate.fromEpochDay(d(iso).epochDay), d(iso));
      }
    });

    test('weekday', () {
      expect(d('2026-10-28').weekday, DateTime.wednesday);
    });
  });

  test('ordering and equality', () {
    expect(d('2026-01-02') > d('2026-01-01'), isTrue);
    expect(d('2026-01-01') <= d('2026-01-01'), isTrue);
    expect(LocalDate.max(d('2026-01-01'), d('2025-12-31')), d('2026-01-01'));
    expect(d('2026-01-01'), LocalDate(2026, 1, 1));
    expect(d('2026-01-01').hashCode, LocalDate(2026, 1, 1).hashCode);
  });
}
