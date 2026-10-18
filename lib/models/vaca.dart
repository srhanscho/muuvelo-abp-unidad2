import 'bill_item.dart';
import 'money.dart';
import 'participant.dart';
import 'split_result.dart';

/// A "vaca": one shared bill already calculated, plus who has paid.
///
/// The bill data (restaurant, people, items, result) never changes after
/// the calculation. Only [paidIds] and [isClosed] change, and only through
/// `VacaStore`, which notifies the screens.
class Vaca {
  Vaca({
    required this.id,
    required this.restaurantName,
    required this.participants,
    required this.hostId,
    required this.items,
    required this.tipPercent,
    required this.result,
  });

  final String id;
  final String restaurantName;
  final List<Participant> participants;
  final String hostId;
  final List<BillItem> items;
  final int tipPercent;
  final SplitResult result;

  /// Ids of the people who already paid their part.
  final Set<String> paidIds = {};

  /// PRD section 6: a vaca can be closed even if someone did not pay.
  bool isClosed = false;

  int get total => result.total;

  bool isPaid(String participantId) => paidIds.contains(participantId);

  int get paidCount => paidIds.length;

  /// Pesos already collected: the sum of what the paid people owed.
  int get collected => paidIds.fold(0, (sum, id) => sum + result.amountFor(id));

  int get pending => total - collected;

  /// 0..100, rounded DOWN so it only shows 100% when everybody paid.
  int get percentCollected => total == 0 ? 0 : collected * 100 ~/ total;

  Participant get host => participants.firstWhere((p) => p.id == hostId);

  List<Participant> get unpaid => participants.where((p) => !isPaid(p.id)).toList();

  /// Plain text summary for the clipboard (to paste in WhatsApp).
  String toSummaryText() {
    final lines = <String>[
      'Muuvelo - $restaurantName',
      'Subtotal: ${formatPesos(result.subtotal)}',
      'Propina ($tipPercent%): ${formatPesos(result.tip)}',
      'Total: ${formatPesos(total)}',
      '',
      for (final p in participants)
        '${p.name}${p.id == hostId ? ' (anfitrión)' : ''}: '
            '${formatPesos(result.amountFor(p.id))} - ${isPaid(p.id) ? 'pagó' : 'pendiente'}',
      '',
      'Recogido: ${formatPesos(collected)} de ${formatPesos(total)} ($percentCollected%)',
      if (isClosed) 'Cuenta cerrada',
    ];
    return lines.join('\n');
  }
}
