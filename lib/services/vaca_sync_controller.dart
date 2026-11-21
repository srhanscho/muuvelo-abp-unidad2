import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/vaca.dart';
import '../models/vaca_draft.dart';
import 'vaca_repository.dart';

enum SyncState { syncing, synced, error }

/// Keeps the app and the database in sync.
///
/// - App -> DB: every create / update / delete / pay / close goes straight
///   to the repository (no local-only changes).
/// - DB -> app: after every mutation, on pull-to-refresh and when the app
///   comes back to the foreground we call [refresh], which re-reads the
///   list from Supabase. Changes made elsewhere (another phone, the
///   Supabase dashboard) appear then.
///
/// It is a ChangeNotifier (ships with Flutter) passed through
/// constructors; screens wrap their content in `ListenableBuilder`.
class VacaSyncController extends ChangeNotifier {
  VacaSyncController(this._repository, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final VacaRepository _repository;
  final DateTime Function() _clock;

  List<Vaca> _vacas = const [];
  bool _hasLoaded = false;
  bool _isSyncing = false;
  Object? _error;
  DateTime? _lastSync;
  Future<void>? _running;
  Future<void>? _queued;
  VoidCallback? _stopWatching;
  Timer? _debounce;

  /// DB -> app in real time: when the database reports a change, re-read the
  /// list. One save writes several rows, so we wait a moment (debounce) and
  /// refresh once instead of once per row.
  void startRealtime() {
    _stopWatching ??= _repository.watchChanges(() {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 400), refresh);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _stopWatching?.call();
    super.dispose();
  }

  List<Vaca> get vacas => _vacas;

  /// False until the first successful (or failed) load: shows skeletons.
  bool get hasLoaded => _hasLoaded;
  bool get isSyncing => _isSyncing;

  /// Last refresh error (null when the last refresh worked).
  Object? get error => _error;
  DateTime? get lastSync => _lastSync;

  SyncState get state => _isSyncing
      ? SyncState.syncing
      : _error != null
      ? SyncState.error
      : SyncState.synced;

  List<Vaca> get openVacas => _vacas.where((v) => !v.isClosed).toList();

  /// Money still to collect across all open vacas.
  int get totalPending => openVacas.fold(0, (sum, v) => sum + v.pending);

  Vaca? byId(String id) {
    for (final vaca in _vacas) {
      if (vaca.id == id) return vaca;
    }
    return null;
  }

  /// Re-reads everything from the database.
  ///
  /// If a refresh is already running, that read may have started before the
  /// caller's write landed (e.g. Realtime fires halfway through a save), so
  /// reusing it could hand back stale data. Instead one more refresh is
  /// queued after it; every caller arriving meanwhile shares that queued one.
  Future<void> refresh() {
    final running = _running;
    if (running != null) {
      return _queued ??= running.then((_) {
        _queued = null;
        return refresh();
      });
    }
    return _running = _doRefresh().whenComplete(() => _running = null);
  }

  Future<void> _doRefresh() async {
    _isSyncing = true;
    notifyListeners();
    try {
      _vacas = await _repository.fetchVacas();
      _error = null;
      _lastSync = _clock();
    } catch (e) {
      _error = e;
    } finally {
      _isSyncing = false;
      _hasLoaded = true;
      notifyListeners();
    }
  }

  /// Reads one vaca (used when a screen opens a vaca not in the list yet).
  Future<Vaca> fetch(String id) => _repository.fetchVaca(id);

  // ---- Mutations: write to the DB, then pull the fresh state. ----
  // They rethrow errors so the screen can show them in a SnackBar.

  Future<Vaca> create(VacaDraft draft) async {
    final id = await _repository.createVaca(draft);
    await refresh();
    return byId(id) ?? await _repository.fetchVaca(id);
  }

  Future<Vaca> update(String id, VacaDraft draft) async {
    await _repository.updateVaca(id, draft);
    await refresh();
    return byId(id) ?? await _repository.fetchVaca(id);
  }

  Future<void> setPaid(String participantId, bool paid) async {
    await _repository.setPaid(participantId: participantId, paid: paid);
    await refresh();
  }

  Future<Vaca> close(String id) async {
    await _repository.closeVaca(id);
    await refresh();
    return byId(id) ?? await _repository.fetchVaca(id);
  }

  Future<void> delete(String id) async {
    await _repository.deleteVaca(id);
    // Remove it at once so the list does not flash the deleted vaca.
    _vacas = _vacas.where((v) => v.id != id).toList();
    notifyListeners();
    // Re-sync in the background: the delete is already done, and making the
    // caller wait here kept the Detalle open on "Esta vaca ya no existe".
    unawaited(refresh());
  }
}
