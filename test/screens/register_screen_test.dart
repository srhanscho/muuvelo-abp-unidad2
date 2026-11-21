import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muuvelo_abp/main.dart';
import 'package:muuvelo_abp/widgets/bill_item_card.dart';
import 'package:muuvelo_abp/widgets/custom_text_field.dart';

import '../fakes.dart';

Finder field(String label) => find.widgetWithText(CustomTextField, label);

void main() {
  late FakeVacaRepository repository;

  /// Logged-in app, then "Nueva" in the tab bar opens Registro.
  Future<void> openRegister(WidgetTester tester) async {
    usePhoneSize(tester);
    repository = FakeVacaRepository();
    await tester.pumpWidget(
      MuuveloApp(auth: FakeAuthService(signedIn: true), createRepository: () => repository),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nueva'));
    await tester.pumpAndSettle();
    expect(find.text('Nueva vaca'), findsWidgets);
  }

  Future<void> submit(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, 'Calcular y guardar'));
    await tester.pumpAndSettle();
  }

  Future<void> addPerson(WidgetTester tester, String name) async {
    await tester.enterText(field('Nombre de la persona'), name);
    await tester.tap(find.byTooltip('Agregar persona'));
    await tester.pumpAndSettle();
  }

  testWidgets('submitting the empty form shows the errors and saves nothing', (tester) async {
    await openRegister(tester);

    await submit(tester);

    expect(find.widgetWithText(SnackBar, 'Escribe el nombre del restaurante'), findsOneWidget);
    expect(find.text('Escribe el nombre del restaurante'), findsNWidgets(2)); // field + SnackBar
    expect(find.text('Agrega al menos 2 personas'), findsOneWidget);
    expect(repository.rows, isEmpty);
  });

  testWidgets('a field error disappears once the user fixes it', (tester) async {
    await openRegister(tester);
    await submit(tester);
    ScaffoldMessenger.of(tester.element(find.byType(Scaffold).last)).removeCurrentSnackBar();
    await tester.pumpAndSettle();
    expect(find.text('Escribe el nombre del restaurante'), findsOneWidget);

    await tester.enterText(field('Nombre del restaurante'), 'La Fonda');
    await tester.pump();
    expect(find.text('Escribe el nombre del restaurante'), findsNothing);
  });

  testWidgets('blocks duplicated participant names', (tester) async {
    await openRegister(tester);

    await addPerson(tester, 'Ana');
    await addPerson(tester, 'ana');

    expect(find.text('ana ya está en la mesa'), findsOneWidget);
    expect(find.byTooltip('Quitar a Ana'), findsOneWidget);
  });

  testWidgets('happy path: the vaca is saved in the repository and the success state appears', (tester) async {
    await openRegister(tester);

    await tester.enterText(field('Nombre del restaurante'), 'La Fonda');
    for (final name in ['Ana', 'Beto', 'Caro']) {
      await addPerson(tester, name);
    }

    // Add one item through the bottom sheet.
    await tapVisible(tester, find.text('Agregar ítem'));
    await tester.enterText(field('Descripción'), 'Postre');
    await tester.enterText(field('Precio en pesos'), '10000');
    await tester.tap(find.widgetWithText(FilledButton, 'Agregar'));
    await tester.pumpAndSettle();

    // Shared by the three of them.
    for (final name in ['Ana', 'Beto', 'Caro']) {
      await tapVisible(tester, find.widgetWithText(SharerPill, name));
    }

    // Live preview: 10% default tip on $ 10.000.
    expect(find.text(r'$ 11.000'), findsOneWidget);

    await submit(tester);

    expect(find.text('¡Vaca guardada!'), findsOneWidget);
    expect(find.text('Compartir resumen'), findsOneWidget);
    expect(repository.rows, hasLength(1));
    final saved = await repository.fetchVacas();
    expect(saved.single.restaurantName, 'La Fonda');
    expect(saved.single.total, 11000);
    // Ana is the host (first added) and absorbs the residue.
    expect(saved.single.participants.map((p) => p.amount), [3668, 3666, 3666]);
  });
}
