import 'package:flutter_test/flutter_test.dart';
import 'package:muuvelo_abp/models/bill_item.dart';
import 'package:muuvelo_abp/utils/validators.dart';

void main() {
  group('validateRestaurantName', () {
    test('is required', () {
      expect(validateRestaurantName(null), isNotNull);
      expect(validateRestaurantName('   '), isNotNull);
    });

    test('needs between 2 and 40 characters', () {
      expect(validateRestaurantName('A'), isNotNull);
      expect(validateRestaurantName('A' * 41), isNotNull);
      expect(validateRestaurantName('La Fonda del Parque'), isNull);
    });
  });

  group('validateParticipantName', () {
    test('rejects an empty name', () {
      expect(validateParticipantName('  ', const []), isNotNull);
    });

    test('rejects duplicates ignoring case and spaces', () {
      expect(validateParticipantName(' ana ', const ['Ana']), isNotNull);
    });

    test('rejects an 11th participant', () {
      final ten = List.generate(10, (i) => 'P$i');
      expect(validateParticipantName('Nuevo', ten), isNotNull);
    });

    test('rejects names longer than 20 characters', () {
      expect(validateParticipantName('A' * 21, const []), isNotNull);
    });

    test('accepts a new valid name', () {
      expect(validateParticipantName('Beto', const ['Ana']), isNull);
    });
  });

  group('validateItemDescription', () {
    test('is required and short', () {
      expect(validateItemDescription(''), isNotNull);
      expect(validateItemDescription('A' * 41), isNotNull);
      expect(validateItemDescription('Postre de natas'), isNull);
    });
  });

  group('validateItemPrice', () {
    test('is required', () {
      expect(validateItemPrice(null), isNotNull);
      expect(validateItemPrice(''), isNotNull);
    });

    test('must be a whole number of pesos', () {
      expect(validateItemPrice('12,5'), isNotNull);
      expect(validateItemPrice('abc'), isNotNull);
    });

    test('must be greater than zero and at most 10.000.000', () {
      expect(validateItemPrice('0'), isNotNull);
      expect(validateItemPrice('10000001'), isNotNull);
      expect(validateItemPrice('10.000.000'), isNull);
      expect(validateItemPrice('26000'), isNull);
    });
  });

  group('validateParticipantCount', () {
    test('needs at least 2 people', () {
      expect(validateParticipantCount(0), isNotNull);
      expect(validateParticipantCount(1), isNotNull);
      expect(validateParticipantCount(2), isNull);
    });
  });

  group('validateHost', () {
    test('a host must be chosen', () {
      expect(validateHost(null), isNotNull);
      expect(validateHost('ana'), isNull);
    });
  });

  group('validateItems', () {
    BillItem item(List<String> sharedBy) =>
        BillItem(id: '1', description: 'Postre', price: 1000, sharedBy: sharedBy);

    test('needs at least one item', () {
      expect(validateItems(const []), isNotNull);
    });

    test('every item needs at least one person', () {
      final error = validateItems([item(const [])]);
      expect(error, contains('Postre'));
    });

    test('accepts assigned items', () {
      expect(
        validateItems([
          item(const ['ana']),
        ]),
        isNull,
      );
    });
  });
}
