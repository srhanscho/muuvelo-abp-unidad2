import '../services/split_service.dart';
import 'bill_item.dart';
import 'participant.dart';
import 'split_result.dart';
import 'vaca.dart';

/// What the user typed in the Registro / Edición form, before it is saved.
///
/// It knows how to turn itself into database rows (toJson side of the
/// mapping). The repository only sends those rows; it does no math.
class VacaDraft {
  const VacaDraft({
    required this.restaurantName,
    required this.participants,
    required this.hostId,
    required this.items,
    required this.tipEnabled,
    required this.tipPercent,
  });

  /// Pre-fills the Edición form with a saved vaca.
  factory VacaDraft.fromVaca(Vaca vaca) => VacaDraft(
    restaurantName: vaca.restaurantName,
    participants: List.of(vaca.participants),
    hostId: vaca.host.id,
    items: List.of(vaca.items),
    tipEnabled: vaca.tipEnabled,
    tipPercent: vaca.tipPercent,
  );

  final String restaurantName;
  final List<Participant> participants;
  final String hostId;
  final List<BillItem> items;
  final bool tipEnabled;
  final int tipPercent;

  int get effectiveTipPercent => tipEnabled ? tipPercent : 0;

  /// The pure split (split_service.dart): who pays how much.
  SplitResult computeSplit() => calculateSplit(
    participants: participants,
    items: items,
    hostId: hostId,
    tipPercent: effectiveTipPercent,
  );

  /// Columns of `muuvelo_vacas` that the user controls.
  Map<String, dynamic> toVacaRow() => {
    'restaurant_name': restaurantName.trim(),
    'tip_enabled': tipEnabled,
    'tip_percent': tipPercent,
  };

  /// One row per person with the amount ALREADY computed, so the database
  /// always stores a split that adds up exactly to the total.
  List<Map<String, dynamic>> participantRows(String vacaId) {
    final split = computeSplit();
    return [
      for (var i = 0; i < participants.length; i++)
        participants[i].toInsertJson(
          vacaId: vacaId,
          position: i,
          isHost: participants[i].id == hostId,
          amount: split.amountFor(participants[i].id),
        ),
    ];
  }

  List<Map<String, dynamic>> itemRows(String vacaId) => [
    for (var i = 0; i < items.length; i++) items[i].toInsertJson(vacaId: vacaId, position: i),
  ];

  /// Rows of the join table. The form uses local ids ("p1"); the database
  /// created new uuids. Both lists are in the same order (position), so
  /// position i of the form = [participantDbIds][i].
  List<Map<String, dynamic>> shareRows({
    required List<String> participantDbIds,
    required List<String> itemDbIds,
  }) {
    final dbIdOf = {for (var i = 0; i < participants.length; i++) participants[i].id: participantDbIds[i]};
    return [
      for (var i = 0; i < items.length; i++)
        for (final localId in items[i].sharedBy) {'item_id': itemDbIds[i], 'participant_id': dbIdOf[localId]!},
    ];
  }
}
