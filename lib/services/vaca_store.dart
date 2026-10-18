import 'package:flutter/foundation.dart';

import '../models/vaca.dart';

/// In-memory list of the vacas calculated during this session.
///
/// Nothing is saved: closing the app erases everything (assignment rule:
/// no database, no storage, no network).
///
/// WHY a ChangeNotifier passed by constructor:
/// - The assignment forbids third-party packages (no `provider`), and
///   ChangeNotifier ships with Flutter itself.
/// - When someone is marked as paid, every screen showing that vaca must
///   update. Screens wrap their content in a `ListenableBuilder(listenable:
///   store)` and rebuild automatically after [notifyListeners].
/// - Passing it through constructors makes the dependency visible and lets
///   tests create a fresh store for each test.
class VacaStore extends ChangeNotifier {
  final List<Vaca> _vacas = [];
  int _lastId = 0;

  /// Newest first, read-only so screens cannot modify the list directly.
  List<Vaca> get vacas => List.unmodifiable(_vacas.reversed);

  bool get isEmpty => _vacas.isEmpty;

  Vaca? get latest => _vacas.isEmpty ? null : _vacas.last;

  Vaca? byId(String id) {
    for (final vaca in _vacas) {
      if (vaca.id == id) return vaca;
    }
    return null;
  }

  /// A simple incremental id is enough because data lives only in memory.
  String nextId() => 'vaca-${++_lastId}';

  void add(Vaca vaca) {
    _vacas.add(vaca);
    notifyListeners();
  }

  void setPaid(String vacaId, String participantId, bool paid) {
    final vaca = byId(vacaId);
    if (vaca == null || vaca.isClosed) return;
    paid ? vaca.paidIds.add(participantId) : vaca.paidIds.remove(participantId);
    notifyListeners();
  }

  void close(String vacaId) {
    final vaca = byId(vacaId);
    if (vaca == null) return;
    vaca.isClosed = true;
    notifyListeners();
  }
}
