/// One person at the table.
///
/// We use an [id] instead of the name to link people with items, so the
/// code never depends on how a name is written.
class Participant {
  const Participant({required this.id, required this.name});

  final String id;
  final String name;

  /// "Juliana Díaz" -> "JD", "Nico" -> "NI". Shown inside the avatars.
  String get initials {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    if (words.length >= 2) return (words[0][0] + words[1][0]).toUpperCase();
    final word = words.first;
    return word.substring(0, word.length < 2 ? word.length : 2).toUpperCase();
  }
}
