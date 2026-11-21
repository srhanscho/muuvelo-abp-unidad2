/// One line of the restaurant bill, e.g. "Postre de natas - $ 18.000"
/// (row of `muuvelo_items` plus its `muuvelo_item_shares`).
///
/// The class is immutable: to change it we create a copy with [copyWith].
/// That keeps state changes explicit inside `setState`.
class BillItem {
  const BillItem({
    required this.id,
    required this.description,
    required this.price,
    this.sharedBy = const [],
    this.position = 0,
  });

  final String id;
  final String description;

  /// Price in pesos (int, never double).
  final int price;

  /// Ids of the participants who shared this item. If 3 people shared it,
  /// each one pays 1/3. In the database this list is the join table
  /// `muuvelo_item_shares` (many-to-many).
  final List<String> sharedBy;

  final int position;

  bool get isAssigned => sharedBy.isNotEmpty;

  /// Reads an item row with its nested `muuvelo_item_shares(participant_id)`.
  factory BillItem.fromJson(Map<String, dynamic> json) => BillItem(
    id: json['id'] as String,
    description: json['description'] as String,
    price: (json['price'] as num).toInt(),
    position: (json['position'] as num?)?.toInt() ?? 0,
    sharedBy: [
      for (final share in (json['muuvelo_item_shares'] as List?) ?? const [])
        (share as Map<String, dynamic>)['participant_id'] as String,
    ],
  );

  /// Row to INSERT (the shares go to their own table).
  Map<String, dynamic> toInsertJson({required String vacaId, required int position}) => {
    'vaca_id': vacaId,
    'description': description,
    'price': price,
    'position': position,
  };

  BillItem copyWith({String? description, int? price, List<String>? sharedBy}) => BillItem(
    id: id,
    description: description ?? this.description,
    price: price ?? this.price,
    sharedBy: sharedBy ?? this.sharedBy,
    position: position,
  );
}
