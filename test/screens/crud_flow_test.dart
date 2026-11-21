import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muuvelo_abp/main.dart';
import 'package:muuvelo_abp/models/vaca.dart';
import 'package:muuvelo_abp/models/vaca_draft.dart';
import 'package:muuvelo_abp/widgets/custom_text_field.dart';

import '../fakes.dart';

/// Mimics SupabaseVacaRepository.updateVaca, which writes several tables
/// one after another: it stops right after deleting the items, emits a
/// Realtime change, and only writes the final rows on [finish].
class HalfwayUpdateRepository extends FakeVacaRepository {
  final _gate = Completer<void>();
  VacaDraft? _pending;

  void finish(String id) => _gate.complete();

  @override
  Future<void> updateVaca(String id, VacaDraft draft) async {
    _pending = draft;
    rows[id] = {...rows[id]!, 'muuvelo_items': <Map<String, dynamic>>[]};
    emitChange();
    await _gate.future;
    await super.updateVaca(id, _pending!);
  }
}

/// Reads from the database can be held, like a slow network.
class SlowReadsRepository extends FakeVacaRepository {
  Completer<void>? _gate;

  void holdReads() => _gate = Completer<void>();

  void releaseReads() {
    _gate?.complete();
    _gate = null;
  }

  @override
  Future<List<Vaca>> fetchVacas() async {
    final gate = _gate;
    if (gate != null) await gate.future;
    return super.fetchVacas();
  }
}

/// Reads fail (like a 401 with an expired token) until [tokenValid].
class ExpiredTokenRepository extends FakeVacaRepository {
  bool tokenValid = false;

  @override
  Future<List<Vaca>> fetchVacas() async {
    if (!tokenValid) throw Exception('JWT expired');
    return super.fetchVacas();
  }
}

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

  testWidgets('the list survives a first frame with zero width (Android cold start)', (tester) async {
    // Android can hand Flutter a 0x0 window on the very first frame. The
    // segmented filter used to throw there and leave "Mis vacas" blank.
    tester.view.physicalSize = Size.zero;
    addTearDown(tester.view.reset);
    repository = FakeVacaRepository()..seed();
    await tester.pumpWidget(
      MuuveloApp(auth: FakeAuthService(signedIn: true), createRepository: () => repository),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);

    usePhoneSize(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mis vacas').last);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Todas'), findsOneWidget);
    expect(find.text('La Fonda del Parque'), findsWidgets);
  });

  testWidgets('a cold start with an expired token re-syncs once the token is refreshed', (tester) async {
    // On launch the stored token may be expired: the first read fails (401)
    // and Supabase renews the token a moment later. The app must retry then.
    usePhoneSize(tester);
    final expired = ExpiredTokenRepository()..seed();
    final auth = FakeAuthService(signedIn: true);
    await tester.pumpWidget(MuuveloApp(auth: auth, createRepository: () => expired));
    await tester.pumpAndSettle();
    expect(find.text('Sin sincronizar · Reintentar'), findsOneWidget);

    expired.tokenValid = true;
    auth.emitTokenRefreshed();
    await tester.pumpAndSettle();

    expect(find.text('Sin sincronizar · Reintentar'), findsNothing);
    expect(find.text('La Fonda del Parque'), findsWidgets);
  });

  testWidgets('home counts a single saved vaca in singular', (tester) async {
    usePhoneSize(tester);
    repository = FakeVacaRepository()..seed();
    await tester.pumpWidget(MuuveloApp(auth: FakeAuthService(signedIn: true), createRepository: () => repository));
    await tester.pumpAndSettle();

    expect(find.text('1 guardadas en tu cuenta'), findsNothing);
    expect(find.text('1 guardada en tu cuenta'), findsOneWidget);
  });

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

  testWidgets('a realtime refresh in the middle of a save does not reset the edit form', (tester) async {
    usePhoneSize(tester);
    final slow = HalfwayUpdateRepository();
    repository = slow;
    final id = slow.seed();
    await tester.pumpWidget(
      MuuveloApp(auth: FakeAuthService(signedIn: true), createRepository: () => slow),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mis vacas').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('La Fonda del Parque').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar').first);
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(CustomTextField, 'Nombre del restaurante'), 'Salón Bogotá');
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar cambios'));
    // Supabase is halfway: items deleted, not inserted yet. Realtime fires
    // and the debounced refresh reads that half-saved vaca.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(find.text('Editar vaca'), findsWidgets);
    expect(find.text('Bandeja'), findsOneWidget, reason: 'the form must keep what the user is saving');

    slow.finish(id);
    await tester.pumpAndSettle();

    expect(find.text('Cambios guardados y sincronizados'), findsOneWidget);
    expect(find.text('Detalle'), findsWidgets);
    expect((await slow.fetchVacas()).single.items, hasLength(2));
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

  testWidgets('deleting never flashes "Esta vaca ya no existe" while the list re-syncs', (tester) async {
    usePhoneSize(tester);
    final slow = SlowReadsRepository();
    repository = slow;
    slow.seed();
    await tester.pumpWidget(
      MuuveloApp(auth: FakeAuthService(signedIn: true), createRepository: () => slow),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mis vacas').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('La Fonda del Parque').last);
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Eliminar vaca'));

    slow.holdReads();
    await tester.tap(find.text('Eliminar'));
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.text('Esta vaca ya no existe'), findsNothing, reason: 'frame $i');
    }
    slow.releaseReads();
    await tester.pumpAndSettle();

    expect(find.text('Esta vaca ya no existe'), findsNothing);
    expect(find.text('Vaca de La Fonda del Parque eliminada'), findsOneWidget);
    expect(slow.rows, isEmpty);
  });
}
