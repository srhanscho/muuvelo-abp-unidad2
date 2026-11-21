import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muuvelo_abp/main.dart';
import 'package:muuvelo_abp/widgets/custom_text_field.dart';

import '../fakes.dart';

/// Consulta -> Detalle -> Edición -> Eliminación, with the in-memory
/// repository standing in for Supabase.
void main() {
  late FakeVacaRepository repository;

  Future<void> openDetail(WidgetTester tester) async {
    usePhoneSize(tester);
    repository = FakeVacaRepository()..seed();
    await tester.pumpWidget(
      MuuveloApp(auth: FakeAuthService(signedIn: true), createRepository: () => repository),
    );
    await tester.pumpAndSettle();

    // Listado (tab "Mis vacas") reads the vaca from the repository.
    await tester.tap(find.text('Mis vacas').last);
    await tester.pumpAndSettle();
    expect(find.text('La Fonda del Parque'), findsWidgets);

    await tester.tap(find.text('La Fonda del Parque').last);
    await tester.pumpAndSettle();
    expect(find.text('Detalle'), findsWidgets);
  }

  testWidgets('detail shows items, people and what is missing', (tester) async {
    await openDetail(tester);

    expect(find.text(r'Faltan $ 20.000 por cobrar'), findsOneWidget);
    expect(find.text('Bandeja'), findsOneWidget);
    expect(find.text('Ana'), findsWidgets);
    expect(find.text('Beto'), findsWidgets);
  });

  testWidgets('edit changes the restaurant name in the database', (tester) async {
    await openDetail(tester);

    await tester.tap(find.text('Editar').first);
    await tester.pumpAndSettle();
    expect(find.text('Editar vaca'), findsWidgets);

    await tester.enterText(find.widgetWithText(CustomTextField, 'Nombre del restaurante'), 'Salón Bogotá');
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar cambios'));
    await tester.pumpAndSettle();

    expect(find.text('Cambios guardados y sincronizados'), findsOneWidget);
    expect(find.text('Salón Bogotá'), findsWidgets);
    expect((await repository.fetchVacas()).single.restaurantName, 'Salón Bogotá');
  });

  testWidgets('delete asks for confirmation and removes the vaca', (tester) async {
    await openDetail(tester);

    await tapVisible(tester, find.text('Eliminar vaca'));
    expect(find.text('¿Eliminar la vaca de La Fonda del Parque?'), findsOneWidget);
    expect(find.text('Esta acción no se puede deshacer.'), findsOneWidget);

    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    expect(repository.rows, isEmpty);
    expect(find.text('Vaca de La Fonda del Parque eliminada'), findsOneWidget);
    expect(find.text('Aún no tienes vacas'), findsOneWidget);
  });
}
