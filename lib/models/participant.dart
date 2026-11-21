/// One person at the table (row of `muuvelo_participantes`).
///
/// We use an [id] instead of the name to link people with items, so the
/// code never depends on how a name is written. While a form is being
/// filled the id is a local one ("p1"); once saved it is the database uuid.
class Participant {
  const Participant({
    required this.id,
    required this.name,
    this.isHost = false,
    this.amount = 0,
    this.paid = false,
    this.paidAt,
    this.position = 0,
  });

  final String id;
  final String name;
  final bool isHost;

  /// What this person owes, tip included, in pesos (int, never double).
  /// Computed by split_service when the vaca is saved.
  final int amount;
  final bool paid;
  final DateTime? paidAt;

  /// Order in which the person was added (lists keep that order).
  final int position;

  /// Reads one row returned by Supabase.
  factory Participant.fromJson(Map<String, dynamic> json) => Participant(
    id: json['id'] as String,
    name: json['name'] as String,
    isHost: json['is_host'] as bool? ?? false,
    amount: (json['amount'] as num?)?.toInt() ?? 0,
    paid: json['paid'] as bool? ?? false,
    paidAt: json['paid_at'] == null ? null : DateTime.parse(json['paid_at'] as String),
    position: (json['position'] as num?)?.toInt() ?? 0,
  );

  /// Row to INSERT. `id` and `owner_id` are not sent: the database fills
  /// them (gen_random_uuid() and auth.uid()), so a user can never write a
  /// row in someone else's name.
  Map<String, dynamic> toInsertJson({
    required String vacaId,
    required int position,
    required bool isHost,
    required int amount,
  }) => {
    'vaca_id': vacaId,
    'name': name,
    'is_host': isHost,
    'amount': amount,
    'paid': paid,
    'paid_at': paidAt?.toUtc().toIso8601String(),
    'position': position,
  };

  Participant copyWith({String? name}) => Participant(
    id: id,
    name: name ?? this.name,
    isHost: isHost,
    amount: amount,
    paid: paid,
    paidAt: paidAt,
    position: position,
  );

  /// "Juliana Díaz" -> "JD", "Nico" -> "NI". Shown inside the avatars.
  String get initials {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    if (words.length >= 2) return (words[0][0] + words[1][0]).toUpperCase();
    final word = words.first;
    return word.substring(0, word.length < 2 ? word.length : 2).toUpperCase();
  }
}
