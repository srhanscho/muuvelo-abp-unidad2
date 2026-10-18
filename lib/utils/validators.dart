import '../models/bill_item.dart';
import '../models/money.dart';
import 'constants.dart';

/// Pure validation functions.
///
/// Each one returns a Spanish error message, or `null` when the value is
/// valid. That is exactly the signature `TextFormField.validator` expects,
/// so they plug straight into the form AND are easy to unit test.

String? validateRestaurantName(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'Escribe el nombre del restaurante';
  if (text.length < Limits.minRestaurantName) {
    return 'Usa al menos ${Limits.minRestaurantName} caracteres';
  }
  if (text.length > Limits.maxRestaurantName) {
    return 'Máximo ${Limits.maxRestaurantName} caracteres';
  }
  return null;
}

/// [existingNames] are the people already added, used to block duplicates.
String? validateParticipantName(String value, List<String> existingNames) {
  final name = value.trim();
  if (name.isEmpty) return 'Escribe un nombre';
  if (name.length > Limits.maxParticipantName) {
    return 'Máximo ${Limits.maxParticipantName} caracteres';
  }
  if (existingNames.length >= Limits.maxParticipants) {
    return 'Máximo ${Limits.maxParticipants} personas por vaca';
  }
  final lower = name.toLowerCase();
  if (existingNames.any((n) => n.trim().toLowerCase() == lower)) {
    return '$name ya está en la mesa';
  }
  return null;
}

String? validateItemDescription(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'Escribe qué se pidió';
  if (text.length > Limits.maxItemDescription) {
    return 'Máximo ${Limits.maxItemDescription} caracteres';
  }
  return null;
}

String? validateItemPrice(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'Escribe el precio';
  final pesos = parsePesos(text);
  if (pesos == null) return 'Solo números enteros, sin centavos';
  if (pesos <= 0) return 'El precio debe ser mayor a cero';
  if (pesos > Limits.maxItemPrice) {
    return 'El precio máximo es ${formatPesos(Limits.maxItemPrice)}';
  }
  return null;
}

String? validateParticipantCount(int count) {
  if (count < Limits.minParticipants) {
    return 'Agrega al menos ${Limits.minParticipants} personas';
  }
  return null;
}

String? validateHost(String? hostId) {
  if (hostId == null) return 'Elige quién es el anfitrión';
  return null;
}

String? validateItems(List<BillItem> items) {
  if (items.isEmpty) return 'Agrega al menos un ítem de la cuenta';
  for (final item in items) {
    if (!item.isAssigned) return 'Elige quién consumió "${item.description}"';
  }
  return null;
}
