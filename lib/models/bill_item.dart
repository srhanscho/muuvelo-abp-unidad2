/// One line of the restaurant bill, e.g. "Postre de natas - $ 18.000".
///
/// The class is immutable: to change who shared it we create a copy with
/// [copyWith]. That keeps state changes explicit inside `setState`.
class BillItem {
  const BillItem({
    required this.id,
    required this.description,
    required this.price,
    this.sharedBy = const [],
  });

  final String id;
  final String description;

  /// Price in pesos (int, never double).
  final int price;

  /// Ids of the participants who shared this item. If 3 people shared it,
  /// each one pays 1/3.
  final List<String> sharedBy;

  bool get isAssigned => sharedBy.isNotEmpty;

  BillItem copyWith({List<String>? sharedBy}) =>
      BillItem(id: id, description: description, price: price, sharedBy: sharedBy ?? this.sharedBy);
}
