import 'package:flutter_test/flutter_test.dart';
import 'package:muuvelo_abp/models/money.dart';

void main() {
  group('formatPesos', () {
    test('uses a dot as thousands separator', () {
      expect(formatPesos(79200), r'$ 79.200');
      expect(formatPesos(1000000), r'$ 1.000.000');
    });

    test('small amounts have no separator', () {
      expect(formatPesos(0), r'$ 0');
      expect(formatPesos(950), r'$ 950');
    });
  });

  group('percentOf', () {
    test('rounds half up using only integers', () {
      expect(percentOf(72000, 10), 7200);
      expect(percentOf(10005, 10), 1001);
      expect(percentOf(10004, 10), 1000);
      expect(percentOf(0, 30), 0);
    });
  });

  group('parsePesos', () {
    test('accepts digits and dots used as thousands separators', () {
      expect(parsePesos('26000'), 26000);
      expect(parsePesos('26.000'), 26000);
      expect(parsePesos(' 7600 '), 7600);
    });

    test('returns null for anything that is not a whole amount', () {
      expect(parsePesos(''), isNull);
      expect(parsePesos('abc'), isNull);
      expect(parsePesos('12,5'), isNull);
      expect(parsePesos('-5'), isNull);
    });
  });
}
