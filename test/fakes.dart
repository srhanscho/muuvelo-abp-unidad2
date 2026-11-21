import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muuvelo_abp/models/bill_item.dart';
import 'package:muuvelo_abp/models/participant.dart';
import 'package:muuvelo_abp/models/vaca.dart';
import 'package:muuvelo_abp/models/vaca_draft.dart';
import 'package:muuvelo_abp/services/auth_service.dart';
import 'package:muuvelo_abp/services/vaca_repository.dart';

/// Auth without network. Tests decide what each call does.
class FakeAuthService implements AuthService {
  FakeAuthService({bool signedIn = false, this.email = 'ana@correo.com'}) {
    _signedIn = signedIn;
  }

  late bool _signedIn;
  final String email;
  final _changes = StreamController<bool>.broadcast();

  /// Error thrown by [signIn] / [signUp] (null = success).
  Object? error;
  SignUpOutcome signUpOutcome = SignUpOutcome.signedIn;
  int signInCalls = 0;

  @override
  bool get isSignedIn => _signedIn;

  @override
  String? get currentEmail => _signedIn ? email : null;

  @override
  Stream<bool> get signedInChanges => _changes.stream;

  void _set(bool value) {
    _signedIn = value;
    _changes.add(value);
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    signInCalls++;
    if (error != null) throw error!;
    _set(true);
  }

  @override
  Future<SignUpOutcome> signUp({required String email, required String password}) async {
    if (error != null) throw error!;
    if (signUpOutcome == SignUpOutcome.signedIn) _set(true);
    return signUpOutcome;
  }

  @override
  Future<void> signOut() async => _set(false);

  /// Supabase renewed the access token: same user, still signed in.
  void emitTokenRefreshed() => _changes.add(_signedIn);
}

/// In-memory "database" with the same JSON shape Supabase returns, so the
/// real fromJson / toJson mapping is exercised.
class FakeVacaRepository implements VacaRepository {
  final Map<String, Map<String, dynamic>> rows = {};
  int _next = 0;
  VoidCallback? _listener;

  bool get isWatching => _listener != null;

  /// Simulates Supabase Realtime telling the app that a row changed.
  void emitChange() => _listener?.call();

  @override
  VoidCallback watchChanges(VoidCallback onChange) {
    _listener = onChange;
    return () => _listener = null;
  }

  Map<String, dynamic> _rowFrom(String id, VacaDraft draft, {String status = 'abierta'}) {
    final people = draft.participantRows(id);
    final personIds = [for (var i = 0; i < people.length; i++) '$id-p$i'];
    final items = draft.itemRows(id);
    final itemIds = [for (var i = 0; i < items.length; i++) '$id-i$i'];
    final shares = draft.shareRows(participantDbIds: personIds, itemDbIds: itemIds);
    return {
      'id': id,
      ...draft.toVacaRow(),
      'status': status,
      'created_at': DateTime(2026, 11, 20, 15).toUtc().toIso8601String(),
      'closed_at': null,
      'muuvelo_participantes': [
        for (var i = 0; i < people.length; i++) {...people[i], 'id': personIds[i]},
      ],
      'muuvelo_items': [
        for (var i = 0; i < items.length; i++)
          {
            ...items[i],
            'id': itemIds[i],
            'muuvelo_item_shares': [
              for (final s in shares)
                if (s['item_id'] == itemIds[i]) {'participant_id': s['participant_id']},
            ],
          },
      ],
    };
  }

  /// Adds a ready-made vaca: Ana (host) and Beto owe $ 10.000 each.
  String seed({String name = 'La Fonda del Parque'}) {
    final id = 'v${++_next}';
    rows[id] = _rowFrom(
      id,
      VacaDraft(
        restaurantName: name,
        participants: const [Participant(id: 'a', name: 'Ana'), Participant(id: 'b', name: 'Beto')],
        hostId: 'a',
        items: const [
          BillItem(id: '1', description: 'Bandeja', price: 10000, sharedBy: ['a']),
          BillItem(id: '2', description: 'Churrasco', price: 10000, sharedBy: ['b']),
        ],
        tipEnabled: false,
        tipPercent: 10,
      ),
    );
    return id;
  }

  Map<String, dynamic> _participantRow(String participantId) {
    for (final vaca in rows.values) {
      for (final p in vaca['muuvelo_participantes'] as List) {
        if ((p as Map<String, dynamic>)['id'] == participantId) return p;
      }
    }
    throw const VacaNotFoundException();
  }

  @override
  Future<List<Vaca>> fetchVacas() async => rows.values.map(Vaca.fromJson).toList().reversed.toList();

  @override
  Future<Vaca> fetchVaca(String id) async {
    final row = rows[id];
    if (row == null) throw const VacaNotFoundException();
    return Vaca.fromJson(row);
  }

  @override
  Future<String> createVaca(VacaDraft draft) async {
    final id = 'v${++_next}';
    rows[id] = _rowFrom(id, draft);
    return id;
  }

  @override
  Future<void> updateVaca(String id, VacaDraft draft) async {
    rows[id] = _rowFrom(id, draft, status: rows[id]!['status'] as String);
  }

  @override
  Future<void> setPaid({required String participantId, required bool paid}) async {
    final row = _participantRow(participantId);
    row['paid'] = paid;
    row['paid_at'] = paid ? DateTime(2026, 11, 20, 16).toUtc().toIso8601String() : null;
  }

  @override
  Future<void> closeVaca(String id) async {
    rows[id]!['status'] = 'cerrada';
    rows[id]!['closed_at'] = DateTime(2026, 11, 20, 17).toUtc().toIso8601String();
  }

  @override
  Future<void> deleteVaca(String id) async => rows.remove(id);
}

/// Phone-like viewport (360 x 780 logical pixels).
void usePhoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// Scrolls until [finder] is on screen, then taps it.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
