import 'package:flutter_test/flutter_test.dart';
import 'package:muuvelo_abp/models/bill_item.dart';
import 'package:muuvelo_abp/models/participant.dart';
import 'package:muuvelo_abp/services/split_service.dart';

void main() {
  const ana = Participant(id: 'ana', name: 'Ana');
  const beto = Participant(id: 'beto', name: 'Beto');
  const caro = Participant(id: 'caro', name: 'Caro');
  const people = [ana, beto, caro];

  BillItem item(String id, int price, List<String> sharedBy) =>
      BillItem(id: id, description: id, price: price, sharedBy: sharedBy);

  group('calculateSplit', () {
    test('a single owner pays the whole item', () {
      final result = calculateSplit(
        participants: const [ana, beto],
        items: [
          item('Bandeja', 10000, ['ana']),
        ],
        hostId: 'beto',
        tipPercent: 0,
      );

      expect(result.amountFor('ana'), 10000);
      expect(result.amountFor('beto'), 0);
      expect(result.subtotal, 10000);
      expect(result.tip, 0);
      expect(result.total, 10000);
    });

    test('a 3-way shared item gives the rounding residue to the host', () {
      final result = calculateSplit(
        participants: people,
        items: [
          item('Postre', 10000, ['ana', 'beto', 'caro']),
        ],
        hostId: 'ana',
        tipPercent: 0,
      );

      expect(result.amountFor('beto'), 3333);
      expect(result.amountFor('caro'), 3333);
      expect(result.amountFor('ana'), 3334); // host absorbs the extra peso
    });

    test('the tip is distributed in proportion to consumption', () {
      final result = calculateSplit(
        participants: const [ana, beto],
        items: [
          item('Churrasco', 30000, ['ana']),
          item('Limonada', 10000, ['beto']),
        ],
        hostId: 'ana',
        tipPercent: 10,
      );

      expect(result.tip, 4000);
      expect(result.amountFor('ana'), 33000);
      expect(result.amountFor('beto'), 11000);
    });

    test('the tip residue also goes to the host', () {
      final result = calculateSplit(
        participants: people,
        items: [
          item('A', 1000, ['ana']),
          item('B', 1000, ['beto']),
          item('C', 1001, ['caro']),
        ],
        hostId: 'caro',
        tipPercent: 10,
      );

      expect(result.tip, 300);
      expect(result.amountFor('ana'), 1099);
      expect(result.amountFor('beto'), 1099);
      expect(result.amountFor('caro'), 1103);
    });

    test('the sum of all amounts always equals the total', () {
      final result = calculateSplit(
        participants: people,
        items: [
          item('Picada', 9999, ['ana', 'beto', 'caro']),
          item('Vino', 7777, ['beto', 'caro']),
          item('Cafe', 3301, ['ana']),
        ],
        hostId: 'beto',
        tipPercent: 15,
      );

      final sum = result.amounts.values.fold(0, (a, b) => a + b);
      expect(sum, result.total);
      expect(result.total, result.subtotal + result.tip);
    });

    test('the tip is rounded to the nearest peso (half up)', () {
      final up = calculateSplit(
        participants: const [ana, beto],
        items: [
          item('X', 10005, ['ana']),
        ],
        hostId: 'ana',
        tipPercent: 10,
      );
      final down = calculateSplit(
        participants: const [ana, beto],
        items: [
          item('X', 10004, ['ana']),
        ],
        hostId: 'ana',
        tipPercent: 10,
      );

      expect(up.tip, 1001); // 1000.5 -> 1001
      expect(down.tip, 1000); // 1000.4 -> 1000
    });

    test('lists each person items with their fraction', () {
      final result = calculateSplit(
        participants: people,
        items: [
          item('Bandeja', 26000, ['ana']),
          item('Postre', 18000, ['ana', 'beto', 'caro']),
        ],
        hostId: 'ana',
        tipPercent: 0,
      );

      final betoShares = result.sharesFor('beto');
      expect(betoShares, hasLength(1));
      expect(betoShares.first.label, 'Postre (1/3)');
      expect(betoShares.first.amount, 6000);

      final anaShares = result.sharesFor('ana');
      expect(anaShares.map((s) => s.label), ['Bandeja', 'Postre (1/3)']);
    });

    test('rejects a host who is not a participant', () {
      expect(
        () => calculateSplit(
          participants: const [ana, beto],
          items: [
            item('X', 1000, ['ana']),
          ],
          hostId: 'caro',
          tipPercent: 0,
        ),
        throwsArgumentError,
      );
    });

    test('rejects an item that nobody shared', () {
      expect(
        () => calculateSplit(
          participants: const [ana, beto],
          items: [item('X', 1000, [])],
          hostId: 'ana',
          tipPercent: 0,
        ),
        throwsArgumentError,
      );
    });
  });
}
