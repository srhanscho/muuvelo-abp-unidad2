import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muuvelo_abp/main.dart';
import 'package:muuvelo_abp/services/vaca_store.dart';
import 'package:muuvelo_abp/utils/constants.dart';

/// Phone-like viewport (360 x 780 logical pixels).
void usePhoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  // ListView builds lazily: scroll until the widget exists, then show it.
  await tester.scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Finder field(String label) => find.widgetWithText(TextFormField, label);

void main() {
  testWidgets('submitting the empty form shows the errors', (tester) async {
    usePhoneSize(tester);
    final store = VacaStore();
    await tester.pumpWidget(MuuveloApp(store: store, initialRoute: Routes.register));
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text('Calcular reparto'));

    // SnackBar with the first problem found.
    expect(find.widgetWithText(SnackBar, 'Escribe el nombre del restaurante'), findsOneWidget);
    expect(find.text('Agrega al menos un ítem de la cuenta'), findsOneWidget);

    // Back to the top: inline errors under the fields.
    await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, 3000));
    await tester.pumpAndSettle();
    expect(find.text('Escribe el nombre del restaurante'), findsNWidgets(2)); // field + SnackBar
    expect(find.text('Agrega al menos 2 personas'), findsOneWidget);
    expect(store.isEmpty, isTrue);
  });

  testWidgets('a field error disappears once the user fixes it', (tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(MuuveloApp(store: VacaStore(), initialRoute: Routes.register));
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text('Calcular reparto'));
    await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, 3000));
    await tester.pumpAndSettle();
    ScaffoldMessenger.of(tester.element(find.byType(Scaffold))).removeCurrentSnackBar();
    await tester.pumpAndSettle();
    expect(find.text('Escribe el nombre del restaurante'), findsOneWidget);

    await tester.enterText(field('Nombre del restaurante'), 'La Fonda');
    await tester.pump();
    expect(find.text('Escribe el nombre del restaurante'), findsNothing);
  });

  testWidgets('blocks duplicated participant names', (tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(MuuveloApp(store: VacaStore(), initialRoute: Routes.register));
    await tester.pumpAndSettle();

    for (final name in ['Ana', 'ana']) {
      await tester.enterText(field('Nombre de la persona'), name);
      await tester.tap(find.byTooltip('Agregar persona'));
      await tester.pumpAndSettle();
    }

    expect(find.text('ana ya está en la mesa'), findsOneWidget);
    expect(find.byType(InputChip), findsOneWidget);
  });

  testWidgets('happy path: fill the form and land on the results', (tester) async {
    usePhoneSize(tester);
    final store = VacaStore();
    await tester.pumpWidget(MuuveloApp(store: store, initialRoute: Routes.register));
    await tester.pumpAndSettle();

    await tester.enterText(field('Nombre del restaurante'), 'La Fonda');

    for (final name in ['Ana', 'Beto', 'Caro']) {
      await tester.enterText(field('Nombre de la persona'), name);
      await tester.tap(find.byTooltip('Agregar persona'));
      await tester.pumpAndSettle();
    }

    // Add one item through the dialog.
    await tapVisible(tester, find.text('Agregar ítem'));
    await tester.enterText(field('Descripción'), 'Postre');
    await tester.enterText(field('Precio en pesos'), '10000');
    await tester.tap(find.widgetWithText(FilledButton, 'Agregar'));
    await tester.pumpAndSettle();

    // Shared by the three of them.
    for (final name in ['Ana', 'Beto', 'Caro']) {
      await tapVisible(tester, find.widgetWithText(FilterChip, name));
    }

    // Live preview: 10% default tip on $ 10.000.
    expect(find.text(r'$ 11.000'), findsOneWidget);

    await tapVisible(tester, find.text('Calcular reparto'));

    expect(find.text('Resultados'), findsOneWidget);
    expect(find.text('La Fonda'), findsOneWidget);
    final vaca = store.latest!;
    expect(vaca.total, 11000);
    // Ana is the host (first added) and absorbs the residue.
    expect(vaca.result.amounts.values.reduce((a, b) => a + b), 11000);
  });
}
