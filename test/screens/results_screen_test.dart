import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muuvelo_abp/screens/results_screen.dart';
import 'package:muuvelo_abp/screens/success_screen.dart';
import 'package:muuvelo_abp/services/vaca_sync_controller.dart';
import 'package:muuvelo_abp/utils/constants.dart';

import '../fakes.dart';

void main() {
  late FakeVacaRepository repository;
  late VacaSyncController controller;
  late String vacaId;

  setUp(() async {
    repository = FakeVacaRepository();
    vacaId = repository.seed(); // Ana and Beto owe $ 10.000 each
    controller = VacaSyncController(repository);
    await controller.refresh();
  });

  Future<void> pumpResults(WidgetTester tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: ResultsScreen(controller: controller, vacaId: vacaId),
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (_) => settings.name == Routes.success
              ? SuccessScreen(controller: controller, args: settings.arguments as SuccessArgs)
              : const SizedBox(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows what is still missing next to what was collected', (tester) async {
    await pumpResults(tester);
    expect(find.text('0%'), findsOneWidget);
    expect(find.text(r'Faltan $ 20.000 por cobrar'), findsOneWidget);
  });

  testWidgets('marking someone as paid is saved and the glass fills', (tester) async {
    await pumpResults(tester);

    await tester.tap(find.byType(CupertinoSwitch).first);
    await tester.pumpAndSettle();

    expect(find.text('50%'), findsOneWidget);
    expect(find.text(r'Ana pagó $ 10.000'), findsOneWidget); // SnackBar
    expect(find.text(r'Faltan $ 10.000 por cobrar'), findsOneWidget);
    final saved = await repository.fetchVaca(vacaId);
    expect(saved.participants.first.paid, isTrue);
    expect(saved.participants.first.paidAt, isNotNull);
  });

  testWidgets('closing incomplete asks for confirmation and persists the state', (tester) async {
    await pumpResults(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Cerrar cuenta'));
    await tester.pumpAndSettle();
    expect(find.text('¿Cerrar la cuenta?'), findsOneWidget);
    expect(find.textContaining('Ana, Beto'), findsOneWidget);

    await tester.tap(find.text('Cerrar igual'));
    await tester.pumpAndSettle();

    expect(find.text('¡Cuenta cerrada!'), findsOneWidget);
    final saved = await repository.fetchVaca(vacaId);
    expect(saved.isClosed, isTrue);
    expect(saved.closedAt, isNotNull);
  });
}
