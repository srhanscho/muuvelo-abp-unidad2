import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muuvelo_abp/models/bill_item.dart';
import 'package:muuvelo_abp/models/participant.dart';
import 'package:muuvelo_abp/models/vaca.dart';
import 'package:muuvelo_abp/screens/results_screen.dart';
import 'package:muuvelo_abp/services/split_service.dart';
import 'package:muuvelo_abp/services/vaca_store.dart';

/// A vaca where Ana and Beto each owe $ 10.000 (no tip).
Vaca sampleVaca(VacaStore store) {
  const people = [Participant(id: 'ana', name: 'Ana'), Participant(id: 'beto', name: 'Beto')];
  final items = [
    const BillItem(id: '1', description: 'Bandeja', price: 10000, sharedBy: ['ana']),
    const BillItem(id: '2', description: 'Churrasco', price: 10000, sharedBy: ['beto']),
  ];
  return Vaca(
    id: store.nextId(),
    restaurantName: 'La Fonda',
    participants: people,
    hostId: 'ana',
    items: items,
    tipPercent: 0,
    result: calculateSplit(participants: people, items: items, hostId: 'ana', tipPercent: 0),
  );
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  // ListView builds lazily: scroll until the widget exists, then show it.
  await tester.scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  late VacaStore store;
  late Vaca vaca;

  setUp(() {
    store = VacaStore();
    vaca = sampleVaca(store);
    store.add(vaca);
  });

  Future<void> pumpResults(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: ResultsScreen(store: store, vacaId: vaca.id),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('marking someone as paid updates the percentage', (tester) async {
    await pumpResults(tester);
    expect(find.text('0%'), findsOneWidget);

    await tapVisible(tester, find.byType(Checkbox).first);

    expect(find.text('50%'), findsOneWidget);
    expect(find.text(r'Ana pagó $ 10.000'), findsOneWidget); // SnackBar
    expect(vaca.collected, 10000);
  });

  testWidgets('closing incomplete asks for confirmation and locks the vaca', (tester) async {
    await pumpResults(tester);

    await tapVisible(tester, find.text('Cerrar cuenta'));
    expect(find.text('¿Cerrar la cuenta?'), findsOneWidget);
    expect(find.textContaining('Ana, Beto'), findsOneWidget);

    await tester.tap(find.text('Cerrar igual'));
    await tester.pumpAndSettle();

    expect(vaca.isClosed, isTrue);
    expect(find.text('La vaca quedó cerrada'), findsOneWidget);
    final checkbox = tester.widget<Checkbox>(find.byType(Checkbox).first);
    expect(checkbox.onChanged, isNull);
  });
}
