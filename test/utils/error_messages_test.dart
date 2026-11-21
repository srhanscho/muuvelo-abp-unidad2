import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:muuvelo_abp/services/vaca_repository.dart';
import 'package:muuvelo_abp/utils/error_messages.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('friendlyError - auth', () {
    test('wrong email or password', () {
      const error = AuthApiException('Invalid login credentials', statusCode: '400', code: 'invalid_credentials');
      expect(friendlyError(error), 'Correo o contraseña incorrectos.');
    });

    test('wrong credentials detected by message when there is no code', () {
      const error = AuthException('Invalid login credentials', statusCode: '400');
      expect(friendlyError(error), 'Correo o contraseña incorrectos.');
    });

    test('email not confirmed explains what to do', () {
      const error = AuthApiException('Email not confirmed', statusCode: '400', code: 'email_not_confirmed');
      expect(friendlyError(error), contains('confirm'));
      expect(friendlyError(error), contains('correo'));
    });

    test('user already exists', () {
      const error = AuthApiException('User already registered', statusCode: '422', code: 'user_already_exists');
      expect(friendlyError(error), contains('Ya existe una cuenta'));
    });

    test('auth network failure means no connection', () {
      expect(friendlyError(AuthRetryableFetchException()), kNoConnectionMessage);
    });
  });

  group('friendlyError - database', () {
    test('RLS / permission denied', () {
      const error = PostgrestException(message: 'permission denied for table muuvelo_vacas', code: '42501');
      expect(friendlyError(error), 'No tienes permiso para ver esto.');
    });

    test('expired session (JWT)', () {
      const error = PostgrestException(message: 'JWT expired', code: 'PGRST303');
      expect(friendlyError(error), contains('sesión expiró'));
    });

    test('check constraint violation', () {
      const error = PostgrestException(message: 'violates check constraint', code: '23514');
      expect(friendlyError(error), contains('no es válido'));
    });

    test('unknown database error has a generic message', () {
      const error = PostgrestException(message: 'boom', code: 'XX000');
      expect(friendlyError(error), contains('servidor'));
    });
  });

  group('friendlyError - network and others', () {
    test('socket exception', () {
      expect(friendlyError(const SocketException('Failed host lookup')), kNoConnectionMessage);
    });

    test('client exception text from the http package', () {
      expect(friendlyError(Exception('ClientException with SocketException: Connection refused')), kNoConnectionMessage);
    });

    test('timeout', () {
      expect(friendlyError(TimeoutException('slow')), contains('tardó demasiado'));
    });

    test('vaca not found', () {
      expect(friendlyError(const VacaNotFoundException()), contains('No encontramos esta vaca'));
    });

    test('anything else', () {
      expect(friendlyError(StateError('x')), 'Algo salió mal. Intenta de nuevo.');
    });
  });
}
