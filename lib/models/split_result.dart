/// The part of one item that one person pays, e.g. "Postre (1/3)" = $ 6.000.
class ItemShare {
  const ItemShare({required this.description, required this.sharers, required this.amount});

  final String description;

  /// How many people shared the item (3 means each pays 1/3).
  final int sharers;

  /// Pesos this person pays for the item (tip not included).
  final int amount;

  /// "Postre (1/3)" for shared items, just "Bandeja" when it is only yours.
  String get label => sharers > 1 ? '$description (1/$sharers)' : description;
}

/// Output of the split calculation. Every number is in pesos.
class SplitResult {
  const SplitResult({required this.subtotal, required this.tip, required this.amounts, required this.shares});

  /// Sum of all item prices.
  final int subtotal;

  /// Tip on the whole bill.
  final int tip;

  /// What each participant pays, tip included. Key = participant id.
  final Map<String, int> amounts;

  /// Items each participant consumed. Key = participant id.
  final Map<String, List<ItemShare>> shares;

  int get total => subtotal + tip;

  int amountFor(String participantId) => amounts[participantId] ?? 0;

  List<ItemShare> sharesFor(String participantId) => shares[participantId] ?? const [];
}
