/// Small date helpers in Spanish, written by hand so the app does not need
/// the `intl` package for three formats.
library;

const _months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

/// Text for the sync indicator: "Sincronizado hace un momento", "hace 5 min"...
String describeLastSync(DateTime? last, DateTime now) {
  if (last == null) return 'Aún sin sincronizar';
  final elapsed = now.difference(last);
  if (elapsed.inSeconds < 60) return 'Sincronizado hace un momento';
  if (elapsed.inMinutes < 60) return 'Sincronizado hace ${elapsed.inMinutes} min';
  if (elapsed.inHours < 24) return 'Sincronizado hace ${elapsed.inHours} h';
  return 'Sincronizado el ${last.day} ${_months[last.month - 1]}';
}

/// "20 nov 2026, 3:05 p. m." (local time).
String formatDateTime(DateTime date) {
  final local = date.toLocal();
  final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minutes = local.minute.toString().padLeft(2, '0');
  final period = local.hour < 12 ? 'a. m.' : 'p. m.';
  return '${local.day} ${_months[local.month - 1]} ${local.year}, $hour12:$minutes $period';
}

/// "Hoy", "Ayer" or "1 nov". Used in the list of vacas.
String formatRelativeDay(DateTime date, DateTime now) {
  final local = date.toLocal();
  final day = DateTime(local.year, local.month, local.day);
  final today = DateTime(now.year, now.month, now.day);
  final days = today.difference(day).inDays;
  if (days == 0) return 'Hoy';
  if (days == 1) return 'Ayer';
  return '${local.day} ${_months[local.month - 1]}';
}
