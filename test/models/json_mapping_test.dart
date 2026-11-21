import 'package:flutter_test/flutter_test.dart';
import 'package:muuvelo_abp/models/bill_item.dart';
import 'package:muuvelo_abp/models/participant.dart';
import 'package:muuvelo_abp/models/vaca.dart';
import 'package:muuvelo_abp/models/vaca_draft.dart';

/// A row exactly as Supabase returns it for
/// `select('*, muuvelo_participantes(*), muuvelo_items(*, muuvelo_item_shares(participant_id))')`.
Map<String, dynamic> vacaRow() => {
  'id': 'v1',
  'owner_id': 'u1',
  'restaurant_name': 'La Fonda del Parque',
  'tip_enabled': true,
  'tip_percent': 10,
  'status': 'abierta',
  'created_at': '2026-11-20T15:00:00+00:00',
  'updated_at': '2026-11-20T15:00:00+00:00',
  'closed_at': null,
  // Out of order on purpose: the model sorts by position.
  'muuvelo_participantes': [
    {
      'id': 'p2',
      'vaca_id': 'v1',
      'name': 'Beto',
      'is_host': false,
      'amount': 11000,
      'paid': true,
      'paid_at': '2026-11-20T16:00:00+00:00',
      'position': 1,
    },
    {
      'id': 'p1',
      'vaca_id': 'v1',
      'name': 'Ana',
      'is_host': true,
      'amount': 33000,
      'paid': false,
      'paid_at': null,
      'position': 0,
    },
  ],
  'muuvelo_items': [
    {
      'id': 'i2',
      'vaca_id': 'v1',
      'description': 'Limonada',
      'price': 10000,
      'position': 1,
      'muuvelo_item_shares': [
        {'participant_id': 'p2'},
      ],
    },
    {
      'id': 'i1',
      'vaca_id': 'v1',
      'description': 'Churrasco',
      'price': 30000,
      'position': 0,
      'muuvelo_item_shares': [
        {'participant_id': 'p1'},
      ],
    },
  ],
};

void main() {
  group('Participant', () {
    test('fromJson reads every column', () {
      final p = Participant.fromJson(vacaRow()['muuvelo_participantes'][0] as Map<String, dynamic>);
      expect(p.id, 'p2');
      expect(p.name, 'Beto');
      expect(p.isHost, isFalse);
      expect(p.amount, 11000);
      expect(p.paid, isTrue);
      expect(p.paidAt, DateTime.parse('2026-11-20T16:00:00+00:00'));
      expect(p.position, 1);
    });

    test('toInsertJson never sends id or owner_id (the database fills them)', () {
      const p = Participant(id: 'local-1', name: 'Ana');
      final json = p.toInsertJson(vacaId: 'v1', position: 2, isHost: true, amount: 5000);
      expect(json, {
        'vaca_id': 'v1',
        'name': 'Ana',
        'is_host': true,
        'amount': 5000,
        'paid': false,
        'paid_at': null,
        'position': 2,
      });
    });
  });

  group('BillItem', () {
    test('fromJson collects who shared the item', () {
      final item = BillItem.fromJson(vacaRow()['muuvelo_items'][1] as Map<String, dynamic>);
      expect(item.id, 'i1');
      expect(item.description, 'Churrasco');
      expect(item.price, 30000);
      expect(item.sharedBy, ['p1']);
      expect(item.position, 0);
    });

    test('toInsertJson', () {
      const item = BillItem(id: 'x', description: 'Postre', price: 18000, sharedBy: ['a']);
      expect(item.toInsertJson(vacaId: 'v1', position: 3), {
        'vaca_id': 'v1',
        'description': 'Postre',
        'price': 18000,
        'position': 3,
      });
    });
  });

  group('Vaca.fromJson', () {
    final vaca = Vaca.fromJson(vacaRow());

    test('reads the vaca columns', () {
      expect(vaca.id, 'v1');
      expect(vaca.restaurantName, 'La Fonda del Parque');
      expect(vaca.tipEnabled, isTrue);
      expect(vaca.tipPercent, 10);
      expect(vaca.isClosed, isFalse);
      expect(vaca.createdAt, DateTime.parse('2026-11-20T15:00:00+00:00'));
      expect(vaca.closedAt, isNull);
    });

    test('sorts participants and items by position', () {
      expect(vaca.participants.map((p) => p.name), ['Ana', 'Beto']);
      expect(vaca.items.map((i) => i.description), ['Churrasco', 'Limonada']);
    });

    test('derives host and money from the stored amounts', () {
      expect(vaca.host.name, 'Ana');
      expect(vaca.total, 44000);
      expect(vaca.collected, 11000);
      expect(vaca.pending, 33000);
      expect(vaca.percentCollected, 25);
      expect(vaca.paidCount, 1);
      expect(vaca.subtotal, 40000);
      expect(vaca.tip, 4000);
    });

    test('a closed vaca', () {
      final row = vacaRow()
        ..['status'] = 'cerrada'
        ..['closed_at'] = '2026-11-21T10:00:00+00:00';
      final closed = Vaca.fromJson(row);
      expect(closed.isClosed, isTrue);
      expect(closed.closedAt, DateTime.parse('2026-11-21T10:00:00+00:00'));
    });

    test('tolerates a vaca without children', () {
      final row = vacaRow()
        ..['muuvelo_participantes'] = []
        ..['muuvelo_items'] = null;
      final empty = Vaca.fromJson(row);
      expect(empty.participants, isEmpty);
      expect(empty.items, isEmpty);
      expect(empty.total, 0);
      expect(empty.percentCollected, 0);
    });
  });

  group('VacaDraft', () {
    VacaDraft draft() => const VacaDraft(
      restaurantName: '  La Fonda  ',
      participants: [
        Participant(id: 'a', name: 'Ana'),
        Participant(id: 'b', name: 'Beto'),
        Participant(id: 'c', name: 'Caro'),
      ],
      hostId: 'a',
      items: [
        BillItem(id: 'i1', description: 'Postre', price: 10000, sharedBy: ['a', 'b', 'c']),
        BillItem(id: 'i2', description: 'Vino', price: 20000, sharedBy: ['c']),
      ],
      tipEnabled: false,
      tipPercent: 15,
    );

    test('toVacaRow trims the name and keeps the chosen percent', () {
      expect(draft().toVacaRow(), {'restaurant_name': 'La Fonda', 'tip_enabled': false, 'tip_percent': 15});
    });

    test('participantRows store the computed split (no tip when disabled)', () {
      final rows = draft().participantRows('v1');
      expect(rows.map((r) => r['amount']), [3334, 3333, 23333]);
      expect(rows.map((r) => r['is_host']), [true, false, false]);
      expect(rows.map((r) => r['position']), [0, 1, 2]);
      expect(rows.fold<int>(0, (sum, r) => sum + (r['amount'] as int)), 30000);
    });

    test('shareRows translate local ids into database ids by position', () {
      final rows = draft().shareRows(participantDbIds: ['P0', 'P1', 'P2'], itemDbIds: ['I0', 'I1']);
      expect(rows, [
        {'item_id': 'I0', 'participant_id': 'P0'},
        {'item_id': 'I0', 'participant_id': 'P1'},
        {'item_id': 'I0', 'participant_id': 'P2'},
        {'item_id': 'I1', 'participant_id': 'P2'},
      ]);
    });

    test('fromVaca pre-fills the edit form', () {
      final copy = VacaDraft.fromVaca(Vaca.fromJson(vacaRow()));
      expect(copy.restaurantName, 'La Fonda del Parque');
      expect(copy.hostId, 'p1');
      expect(copy.participants.map((p) => p.name), ['Ana', 'Beto']);
      expect(copy.items.first.sharedBy, ['p1']);
      expect(copy.tipEnabled, isTrue);
      expect(copy.tipPercent, 10);
    });

    test('an edited participant keeps its paid state', () {
      final copy = VacaDraft.fromVaca(Vaca.fromJson(vacaRow()));
      final rows = copy.participantRows('v1');
      expect(rows[1]['paid'], isTrue);
      expect(rows[1]['paid_at'], '2026-11-20T16:00:00.000Z');
    });
  });
}
