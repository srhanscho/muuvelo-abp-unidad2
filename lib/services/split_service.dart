import '../models/bill_item.dart';
import '../models/money.dart';
import '../models/participant.dart';
import '../models/split_result.dart';

/// Splits a bill between participants. This is the heart of the app.
///
/// It is a pure function (no Flutter, no state, no I/O), which is why it
/// is easy to unit test.
///
/// Rules (PRD section 6):
/// 1. Each item is divided in EQUAL parts between the people who shared it,
///    using integer division.
/// 2. The tip is computed on the whole bill and distributed in proportion
///    to what each person consumed.
/// 3. Whatever does not divide evenly (the "residue") goes to the host.
///    This guarantees that the sum of all amounts is EXACTLY the total.
SplitResult calculateSplit({
  required List<Participant> participants,
  required List<BillItem> items,
  required String hostId,
  required int tipPercent,
}) {
  final ids = participants.map((p) => p.id).toList();
  if (!ids.contains(hostId)) {
    throw ArgumentError('The host must be one of the participants');
  }

  final subtotals = {for (final id in ids) id: 0};
  final shares = {for (final id in ids) id: <ItemShare>[]};
  var subtotal = 0;

  // 1. Split every item between the people who share it.
  for (final item in items) {
    if (!item.isAssigned) {
      throw ArgumentError('Item "${item.description}" has nobody assigned');
    }
    final count = item.sharedBy.length;
    final share = item.price ~/ count;
    final residue = item.price - share * count;

    for (final id in item.sharedBy) {
      // The host pays the residue on top of their share, if they shared it.
      final amount = id == hostId ? share + residue : share;
      subtotals[id] = subtotals[id]! + amount;
      shares[id]!.add(ItemShare(description: item.description, sharers: count, amount: amount));
    }
    // If the host did NOT share this item, they still absorb its residue.
    // We list it so the host can see where that extra peso came from.
    if (!item.sharedBy.contains(hostId) && residue > 0) {
      subtotals[hostId] = subtotals[hostId]! + residue;
      shares[hostId]!.add(
        ItemShare(description: 'Redondeo de ${item.description}', sharers: 1, amount: residue),
      );
    }
    subtotal += item.price;
  }

  // 2. Tip on the whole bill, rounded to the nearest peso.
  final tip = percentOf(subtotal, tipPercent);

  // 3. Each person pays tip in proportion to what they consumed.
  //    Integer division rounds down; the leftover goes to the host again.
  final amounts = <String, int>{};
  var tipAssigned = 0;
  for (final id in ids) {
    final tipShare = subtotal == 0 ? 0 : tip * subtotals[id]! ~/ subtotal;
    amounts[id] = subtotals[id]! + tipShare;
    tipAssigned += tipShare;
  }
  amounts[hostId] = amounts[hostId]! + (tip - tipAssigned);

  return SplitResult(subtotal: subtotal, tip: tip, amounts: amounts, shares: shares);
}

/// Live preview used while the form is being filled: subtotal of the items
/// typed so far and the tip on top of it.
({int subtotal, int tip, int total}) previewTotals(List<BillItem> items, int tipPercent) {
  final subtotal = items.fold(0, (sum, item) => sum + item.price);
  final tip = percentOf(subtotal, tipPercent);
  return (subtotal: subtotal, tip: tip, total: subtotal + tip);
}
