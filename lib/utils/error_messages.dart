import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/vaca_repository.dart';

// The ONE place that turns technical errors into Spanish messages a user
// understands. Screens never show `e.toString()`; they call
// friendlyError() and put the result in a SnackBar or an ErrorView.

const kNoConnectionMessage = 'Sin conexión. Revisa tu internet.';
const kGenericMessage = 'Algo salió mal. Intenta de nuevo.';

String friendlyError(Object error) {
  // Network problems first: they can arrive wrapped in several types.
  if (error is SocketException || error is HttpException || error is AuthRetryableFetchException) {
    return kNoConnectionMessage;
  }
  if (error is TimeoutException) {
    return 'El servidor tardó demasiado en responder. Intenta de nuevo.';
  }
  if (error is VacaNotFoundException) {
    return 'No encontramos esta vaca. Puede que la hayan eliminado.';
  }
  if (error is AuthException) return _authMessage(error);
  if (error is PostgrestException) return _databaseMessage(error);

  // The http package throws ClientException, which we do not import:
  // recognise it (and other socket errors) by its text.
  final text = error.toString();
  if (text.contains('SocketException') ||
      text.contains('ClientException') ||
      text.contains('Failed host lookup') ||
      text.contains('Connection refused')) {
    return kNoConnectionMessage;
  }
  return kGenericMessage;
}

/// Supabase Auth errors. `code` is stable; `message` is the fallback for
/// old servers that do not send a code.
String _authMessage(AuthException error) {
  final code = error.code;
  final message = error.message.toLowerCase();
  if (code == 'invalid_credentials' || message.contains('invalid login credentials')) {
    return 'Correo o contraseña incorrectos.';
  }
  if (code == 'email_not_confirmed' || message.contains('email not confirmed')) {
    return 'Tu correo aún no está confirmado. Abre el enlace que te enviamos y vuelve a intentarlo.';
  }
  if (code == 'user_already_exists' || code == 'email_exists' || message.contains('already registered')) {
    return 'Ya existe una cuenta con ese correo. Inicia sesión.';
  }
  if (code == 'weak_password') return 'La contraseña es muy débil. Usa al menos 6 caracteres.';
  if (code == 'email_address_invalid' || code == 'validation_failed') {
    return 'Revisa que el correo esté bien escrito.';
  }
  if (code == 'over_email_send_rate_limit' || code == 'over_request_rate_limit' || error.statusCode == '429') {
    return 'Demasiados intentos. Espera un momento y vuelve a intentarlo.';
  }
  if (code == 'signup_disabled') return 'La creación de cuentas está desactivada.';
  if (code == 'session_expired' || code == 'refresh_token_not_found' || error is AuthSessionMissingException) {
    return 'Tu sesión expiró. Inicia sesión de nuevo.';
  }
  return 'No pudimos completar el acceso. Intenta de nuevo.';
}

/// PostgREST / PostgreSQL errors. Codes: https://postgrest.org/en/stable/references/errors.html
String _databaseMessage(PostgrestException error) {
  switch (error.code) {
    case '42501': // insufficient_privilege: RLS blocked the row
      return 'No tienes permiso para ver esto.';
    case 'PGRST301':
    case 'PGRST302':
    case 'PGRST303':
      return 'Tu sesión expiró. Inicia sesión de nuevo.';
    case 'PGRST116':
      return 'No encontramos esta vaca. Puede que la hayan eliminado.';
    case '23514': // check_violation
    case '23502': // not_null_violation
    case '22001': // string too long
      return 'Algún dato no es válido. Revisa el formulario.';
  }
  if (error.message.toLowerCase().contains('jwt')) return 'Tu sesión expiró. Inicia sesión de nuevo.';
  return 'El servidor no pudo completar la operación. Intenta de nuevo.';
}
