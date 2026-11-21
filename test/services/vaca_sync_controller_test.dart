import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:muuvelo_abp/models/vaca.dart';
import 'package:muuvelo_abp/services/vaca_sync_controller.dart';

import '../fakes.dart';

/// Repository whose reads fail until [online] becomes true.
class FlakyRepository extends FakeVacaRepository {
  bool online = false;

  @override
  Future<List<Vaca>> fetchVacas() async {
    if (!online) throw const SocketException('offline');
    return super.fetchVacas();
  }
}

/// Repository whose reads take a snapshot right away but only answer once
/// [gate] completes, like a slow network request.
class SlowRepository extends FakeVacaRepository {
  Completer<void>? gate;

  @override
  Future<List<Vaca>> fetchVacas() async {
    final snapshot = await super.fetchVacas();
    final wait = gate;
    if (wait != null) await wait.future;
    return snapshot;
  }
}

void main() {
  final now = DateTime(2026, 11, 20, 15);

  test('refresh loads the vacas and records when it synced', () async {
    final repository = FakeVacaRepository()..seed();
    final controller = VacaSyncController(repository, clock: () => now);
    expect(controller.hasLoaded, isFalse);

    await controller.refresh();

    expect(controller.hasLoaded, isTrue);
    expect(controller.vacas, hasLength(1));
    expect(controller.state, SyncState.synced);
    expect(controller.lastSync, now);
    expect(controller.totalPending, 20000);
  });

  test('a failed refresh keeps the error and recovers on retry', () async {
    final repository = FlakyRepository()..seed();
    final controller = VacaSyncController(repository, clock: () => now);

    await controller.refresh();
    expect(controller.state, SyncState.error);
    expect(controller.error, isA<SocketException>());
    expect(controller.lastSync, isNull);

    repository.online = true;
    await controller.refresh();
    expect(controller.state, SyncState.synced);
    expect(controller.error, isNull);
  });

  test('changes made directly in the database appear after refresh (DB -> app)', () async {
    final repository = FakeVacaRepository();
    final id = repository.seed();
    final controller = VacaSyncController(repository);
    await controller.refresh();

    // Someone edits the row in the Supabase dashboard.
    repository.rows[id]!['restaurant_name'] = 'Café Tostao';
    await controller.refresh();

    expect(controller.byId(id)!.restaurantName, 'Café Tostao');
  });

  test('a realtime change from the database refreshes the list by itself', () async {
    final repository = FakeVacaRepository();
    final id = repository.seed();
    final controller = VacaSyncController(repository)..startRealtime();
    await controller.refresh();

    repository.rows[id]!['restaurant_name'] = 'Salón Bogotá';
    repository.emitChange();
    await Future<void>.delayed(const Duration(milliseconds: 600));

    expect(controller.byId(id)!.restaurantName, 'Salón Bogotá');
    controller.dispose();
    expect(repository.isWatching, isFalse);
  });

  test('a refresh asked for while another is reading still returns fresh data', () async {
    // Realtime starts a refresh in the middle of a multi-row save; the save
    // then asks for its own refresh. It must not reuse the stale read.
    final repository = SlowRepository();
    final id = repository.seed();
    final controller = VacaSyncController(repository);
    await controller.refresh();

    repository.gate = Completer<void>();
    final staleRead = controller.refresh(); // reads the old name
    await Future<void>.delayed(Duration.zero);
    repository.rows[id]!['restaurant_name'] = 'La Fonda - Mesa 7'; // the save finishes
    final afterSave = controller.refresh();
    repository.gate!.complete();
    repository.gate = null;
    await Future.wait([staleRead, afterSave]);

    expect(controller.byId(id)!.restaurantName, 'La Fonda - Mesa 7');
  });

  test('mutations go to the repository and the list is re-read', () async {
    final repository = FakeVacaRepository();
    final id = repository.seed();
    final controller = VacaSyncController(repository);
    await controller.refresh();

    await controller.setPaid(controller.byId(id)!.participants.first.id, true);
    expect(controller.byId(id)!.collected, 10000);

    final closed = await controller.close(id);
    expect(closed.isClosed, isTrue);
    expect(controller.openVacas, isEmpty);

    await controller.delete(id);
    expect(controller.vacas, isEmpty);
    expect(repository.rows, isEmpty);
  });
}
