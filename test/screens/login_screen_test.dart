import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muuvelo_abp/main.dart';
import 'package:muuvelo_abp/screens/login_screen.dart';
import 'package:muuvelo_abp/services/auth_service.dart';
import 'package:muuvelo_abp/widgets/custom_text_field.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthApiException;

import '../fakes.dart';

Finder field(String label) => find.widgetWithText(CustomTextField, label);

void main() {
  late FakeAuthService auth;

  setUp(() => auth = FakeAuthService());

  Future<void> pumpLogin(WidgetTester tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(MaterialApp(home: LoginScreen(auth: auth)));
    await tester.pumpAndSettle();
  }

  testWidgets('empty form shows the validation errors and does not call the server', (tester) async {
    await pumpLogin(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('Escribe tu correo'), findsOneWidget);
    expect(find.text('Escribe tu contraseña'), findsOneWidget);
    expect(auth.signInCalls, 0);
  });

  testWidgets('invalid email and short password', (tester) async {
    await pumpLogin(tester);

    await tester.enterText(field('Correo electrónico'), 'ana');
    await tester.enterText(field('Contraseña'), '123');
    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('Revisa que el correo esté bien escrito'), findsOneWidget);
    expect(find.text('Usa al menos 6 caracteres'), findsOneWidget);
  });

  testWidgets('wrong credentials show a clear Spanish message', (tester) async {
    auth.error = const AuthApiException('Invalid login credentials', statusCode: '400', code: 'invalid_credentials');
    await pumpLogin(tester);

    await tester.enterText(field('Correo electrónico'), 'ana@correo.com');
    await tester.enterText(field('Contraseña'), 'equivocada');
    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(auth.signInCalls, 1);
    expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
    expect(find.text('No pudimos iniciar sesión'), findsOneWidget);
  });

  testWidgets('the password can be shown and hidden', (tester) async {
    await pumpLogin(tester);

    EditableText password() =>
        tester.widget<EditableText>(find.descendant(of: field('Contraseña'), matching: find.byType(EditableText)));

    expect(password().obscureText, isTrue);
    await tester.tap(find.byTooltip('Mostrar contraseña'));
    await tester.pump();
    expect(password().obscureText, isFalse);
  });

  testWidgets('sign up with email confirmation explains what to do', (tester) async {
    auth.signUpOutcome = SignUpOutcome.needsEmailConfirmation;
    await pumpLogin(tester);

    await tester.tap(find.text('¿No tienes cuenta? Crear cuenta'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'Crear cuenta'), findsOneWidget);

    await tester.enterText(field('Correo electrónico'), 'nuevo@correo.com');
    await tester.enterText(field('Contraseña'), 'secreta1');
    await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Te enviamos un correo para confirmar tu cuenta'), findsOneWidget);
  });

  testWidgets('auth gate: the app is only reachable after logging in', (tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(MuuveloApp(auth: auth, createRepository: FakeVacaRepository.new));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Mis vacas'), findsNothing);

    await tester.enterText(field('Correo electrónico'), 'ana@correo.com');
    await tester.enterText(field('Contraseña'), 'correcta1');
    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsNothing);
    expect(find.text('Hola, ana'), findsOneWidget);
  });
}
