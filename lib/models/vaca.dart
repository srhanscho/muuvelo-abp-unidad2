import '../services/split_service.dart';
import '../utils/dates.dart';
import 'bill_item.dart';
import 'money.dart';
import 'participant.dart';
import 'split_result.dart';

/// A "vaca": one shared bill saved in Supabase (`muuvelo_vacas`) with its
/// participants and items.
///
/// The object is immutable. To change a vaca the app asks the repository
/// to update the database and then reads it again ("DB -> app" sync).
class Vaca {
  Vaca({
    required this.id,
    required this.restaurantName,
    required this.participants,
    required this.items,
    required this.tipEnabled,
    required this.tipPercent,
    required this.isClosed,
    required this.createdAt,
    this.closedAt,
  });

  final String id;
  final String restaurantName;
  final List<Participant> participants;
  final List<BillItem> items;
  final bool tipEnabled;

  /// The percent the user chose; only applied when [tipEnabled].
  final int tipPercent;
  final bool isClosed;
  final DateTime createdAt;
  final DateTime? closedAt;

  /// Reads a row of
  /// `select('*, muuvelo_participantes(*), muuvelo_items(*, muuvelo_item_shares(participant_id))')`.
  factory Vaca.fromJson(Map<String, dynamic> json) {
    final participants = [
      for (final row in (json['muuvelo_participantes'] as List?) ?? const [])
        Participant.fromJson(row as Map<String, dynamic>),
    ]..sort((a, b) => a.position.compareTo(b.position));
    final items = [
      for (final row in (json['muuvelo_items'] as List?) ?? const []) BillItem.fromJson(row as Map<String, dynamic>),
    ]..sort((a, b) => a.position.compareTo(b.position));

    return Vaca(
      id: json['id'] as String,
      restaurantName: json['restaurant_name'] as String,
      participants: participants,
      items: items,
      tipEnabled: json['tip_enabled'] as bool? ?? true,
      tipPercent: (json['tip_percent'] as num?)?.toInt() ?? 0,
      isClosed: json['status'] == 'cerrada',
      createdAt: DateTime.parse(json['created_at'] as String),
      closedAt: json['closed_at'] == null ? null : DateTime.parse(json['closed_at'] as String),
    );
  }

  int get effectiveTipPercent => tipEnabled ? tipPercent : 0;

  int get subtotal => items.fold(0, (sum, item) => sum + item.price);

  int get tip => percentOf(subtotal, effectiveTipPercent);

  /// What everybody owes, as stored in the database (sum of amounts).
  int get total => participants.fold(0, (sum, p) => sum + p.amount);

  int get paidCount => participants.where((p) => p.paid).length;

  /// Pesos already collected: the sum of what the paid people owed.
  int get collected => participants.where((p) => p.paid).fold(0, (sum, p) => sum + p.amount);

  int get pending => total - collected;

  /// 0..100, rounded DOWN so it only shows 100% when everybody paid.
  int get percentCollected => total == 0 ? 0 : collected * 100 ~/ total;

  Participant get host => participants.firstWhere((p) => p.isHost, orElse: () => participants.first);

  List<Participant> get unpaid => participants.where((p) => !p.paid).toList();

  Participant? participantById(String id) {
    for (final p in participants) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Item breakdown per person ("Postre (1/3)"), recomputed with the pure
  /// split function. Null if the data cannot be split (e.g. someone edited
  /// the rows by hand in the dashboard and left an item without people).
  late final SplitResult? breakdown = _computeBreakdown();

  SplitResult? _computeBreakdown() {
    if (participants.isEmpty) return null;
    try {
      return calculateSplit(
        participants: participants,
        items: items,
        hostId: host.id,
        tipPercent: effectiveTipPercent,
      );
    } on ArgumentError {
      return null;
    }
  }

  List<ItemShare> sharesFor(String participantId) => breakdown?.sharesFor(participantId) ?? const [];

  /// Names of the people who shared [item], e.g. "Ana, Beto".
  String sharedByNames(BillItem item) =>
      item.sharedBy.map((id) => participantById(id)?.name).whereType<String>().join(', ');

  /// Plain text summary for the share sheet (to paste in WhatsApp).
  String toSummaryText() {
    final lines = <String>[
      'Muuvelo · $restaurantName',
      formatDateTime(createdAt),
      '',
      'Subtotal: ${formatPesos(subtotal)}',
      'Propina ($effectiveTipPercent%): ${formatPesos(tip)}',
      'Total: ${formatPesos(total)}',
      '',
      for (final p in participants)
        '${p.name}${p.isHost ? ' (anfitrión)' : ''}: ${formatPesos(p.amount)} · ${p.paid ? 'pagó' : 'pendiente'}',
      '',
      'Recogido: ${formatPesos(collected)} de ${formatPesos(total)} ($percentCollected%)',
      if (pending > 0) 'Faltan ${formatPesos(pending)} por cobrar',
      if (isClosed && closedAt != null) 'Cuenta cerrada el ${formatDateTime(closedAt!)}',
    ];
    return lines.join('\n');
  }
}
