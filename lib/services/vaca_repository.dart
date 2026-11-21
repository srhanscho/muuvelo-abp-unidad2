import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/vaca.dart';
import '../models/vaca_draft.dart';

/// Thrown when a vaca id does not exist (or RLS hides it from this user).
class VacaNotFoundException implements Exception {
  const VacaNotFoundException();
}

/// Contract of the data layer. Screens and the sync controller depend on
/// this abstraction, so tests can pass an in-memory fake and never touch
/// the network.
abstract class VacaRepository {
  /// Every vaca of the logged-in user, newest first, with children.
  Future<List<Vaca>> fetchVacas();

  Future<Vaca> fetchVaca(String id);

  /// Returns the id of the new vaca.
  Future<String> createVaca(VacaDraft draft);

  Future<void> updateVaca(String id, VacaDraft draft);

  Future<void> setPaid({required String participantId, required bool paid});

  Future<void> closeVaca(String id);

  Future<void> deleteVaca(String id);

  /// Calls [onChange] whenever this user's vacas or participants change in
  /// the database (from this phone, another one, or the dashboard).
  /// Returns a function that stops listening.
  VoidCallback watchChanges(VoidCallback onChange);
}

/// The ONLY class in the app that talks to the Supabase database.
///
/// Security note: we never send `owner_id`. The column defaults to
/// `auth.uid()` and Row Level Security only lets each user read and write
/// their own rows, so even a modified app cannot touch other people's data.
class SupabaseVacaRepository implements VacaRepository {
  SupabaseVacaRepository(this._client);

  final SupabaseClient _client;

  /// Every request gives up after this time and shows "tardó demasiado".
  static const _timeout = Duration(seconds: 15);

  static const _vacas = 'muuvelo_vacas';
  static const _participantes = 'muuvelo_participantes';
  static const _items = 'muuvelo_items';
  static const _shares = 'muuvelo_item_shares';

  /// One query brings the vaca with its people, items and who shared what
  /// (PostgREST embeds related tables through the foreign keys).
  static const _fullSelect = '*, $_participantes(*), $_items(*, $_shares(participant_id))';

  @override
  Future<List<Vaca>> fetchVacas() async {
    final rows = await _client.from(_vacas).select(_fullSelect).order('created_at', ascending: false).timeout(_timeout);
    return rows.map(Vaca.fromJson).toList();
  }

  @override
  Future<Vaca> fetchVaca(String id) async {
    final row = await _client.from(_vacas).select(_fullSelect).eq('id', id).maybeSingle().timeout(_timeout);
    if (row == null) throw const VacaNotFoundException();
    return Vaca.fromJson(row);
  }

  @override
  Future<String> createVaca(VacaDraft draft) async {
    final vaca = await _client.from(_vacas).insert(draft.toVacaRow()).select('id').single().timeout(_timeout);
    final vacaId = vaca['id'] as String;
    try {
      await _insertChildren(vacaId, draft);
    } catch (_) {
      // The client API has no multi-table transaction. If a child insert
      // fails we delete the half-saved vaca (ON DELETE CASCADE removes any
      // child already inserted) so the user never sees a broken vaca.
      await _client.from(_vacas).delete().eq('id', vacaId);
      rethrow;
    }
    return vacaId;
  }

  /// UPDATE strategy, chosen because it is the simplest correct one:
  /// 1. update the columns of the vaca row;
  /// 2. delete ALL its participants and items (cascade also deletes the
  ///    item_shares);
  /// 3. insert them again from the form, with the split recomputed.
  /// Diffing row by row would save a few requests but is much harder to
  /// get right; a vaca has at most 10 people and a handful of items.
  /// The "paid" state of each person travels inside the draft, so it is
  /// preserved.
  @override
  Future<void> updateVaca(String id, VacaDraft draft) async {
    await _client.from(_vacas).update(draft.toVacaRow()).eq('id', id).timeout(_timeout);
    await _client.from(_participantes).delete().eq('vaca_id', id).timeout(_timeout);
    await _client.from(_items).delete().eq('vaca_id', id).timeout(_timeout);
    await _insertChildren(id, draft);
  }

  Future<void> _insertChildren(String vacaId, VacaDraft draft) async {
    final people = await _client
        .from(_participantes)
        .insert(draft.participantRows(vacaId))
        .select('id, position')
        .timeout(_timeout);
    final items = await _client.from(_items).insert(draft.itemRows(vacaId)).select('id, position').timeout(_timeout);

    final shares = draft.shareRows(participantDbIds: _idsByPosition(people), itemDbIds: _idsByPosition(items));
    if (shares.isNotEmpty) await _client.from(_shares).insert(shares).timeout(_timeout);
  }

  /// Sorts inserted rows by `position` and keeps only their ids.
  List<String> _idsByPosition(List<Map<String, dynamic>> rows) {
    final sorted = [...rows]..sort((a, b) => (a['position'] as num).compareTo(b['position'] as num));
    return [for (final row in sorted) row['id'] as String];
  }

  @override
  Future<void> setPaid({required String participantId, required bool paid}) async {
    await _client
        .from(_participantes)
        .update({'paid': paid, 'paid_at': paid ? DateTime.now().toUtc().toIso8601String() : null})
        .eq('id', participantId)
        .timeout(_timeout);
  }

  @override
  Future<void> closeVaca(String id) async {
    await _client
        .from(_vacas)
        .update({'status': 'cerrada', 'closed_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id)
        .timeout(_timeout);
  }

  @override
  Future<void> deleteVaca(String id) async {
    // Participants, items and shares disappear too (ON DELETE CASCADE).
    await _client.from(_vacas).delete().eq('id', id).timeout(_timeout);
  }

  /// Supabase Realtime: the database pushes a message over a WebSocket on
  /// every INSERT / UPDATE / DELETE. Realtime applies the same RLS policies,
  /// so a user only hears about their own rows.
  @override
  VoidCallback watchChanges(VoidCallback onChange) {
    final channel = _client
        .channel('muuvelo-changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: _vacas,
          callback: (_) => onChange(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: _participantes,
          callback: (_) => onChange(),
        )
        .subscribe();
    return () => _client.removeChannel(channel);
  }
}
