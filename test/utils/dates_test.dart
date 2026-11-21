import 'package:flutter_test/flutter_test.dart';
import 'package:muuvelo_abp/utils/dates.dart';

void main() {
  final now = DateTime(2026, 11, 20, 15, 30);

  group('describeLastSync', () {
    test('never synced', () {
      expect(describeLastSync(null, now), 'Aún sin sincronizar');
    });

    test('less than a minute ago', () {
      expect(describeLastSync(now.subtract(const Duration(seconds: 20)), now), 'Sincronizado hace un momento');
    });

    test('minutes ago', () {
      expect(describeLastSync(now.subtract(const Duration(minutes: 5)), now), 'Sincronizado hace 5 min');
    });

    test('hours ago', () {
      expect(describeLastSync(now.subtract(const Duration(hours: 3)), now), 'Sincronizado hace 3 h');
    });

    test('days ago shows the date', () {
      expect(describeLastSync(DateTime(2026, 11, 18, 9), now), 'Sincronizado el 18 nov');
    });
  });

  group('formatDateTime', () {
    test('afternoon uses 12h clock with p. m.', () {
      expect(formatDateTime(DateTime(2026, 11, 20, 15, 5)), '20 nov 2026, 3:05 p. m.');
    });

    test('midnight and noon', () {
      expect(formatDateTime(DateTime(2026, 1, 2, 0, 0)), '2 ene 2026, 12:00 a. m.');
      expect(formatDateTime(DateTime(2026, 1, 2, 12, 0)), '2 ene 2026, 12:00 p. m.');
    });
  });

  group('formatRelativeDay', () {
    test('today, yesterday and older', () {
      expect(formatRelativeDay(DateTime(2026, 11, 20, 8), now), 'Hoy');
      expect(formatRelativeDay(DateTime(2026, 11, 19, 23), now), 'Ayer');
      expect(formatRelativeDay(DateTime(2026, 11, 1), now), '1 nov');
    });
  });
}
