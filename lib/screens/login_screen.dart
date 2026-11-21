import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../utils/design_tokens.dart';
import '../utils/error_messages.dart';
import '../utils/validators.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/info_banner.dart';
import '../widgets/muuvelo_icon.dart';
import '../widgets/primary_button.dart';

/// Pantalla de autenticación (Iniciar sesión / Crear cuenta).
///
/// Nothing else of the app is reachable without a session: main.dart
/// shows this screen whenever Supabase reports "no session". When the
/// login works, Supabase emits the new session and main.dart swaps this
/// screen for the app by itself; this screen does not navigate.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.auth});

  final AuthService auth;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _signUpMode = false;
  bool _loading = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleMode() => setState(() {
    _signUpMode = !_signUpMode;
    _error = null;
    _info = null;
  });

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _error = null;
      _info = null;
    });
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      if (_signUpMode) {
        final outcome = await widget.auth.signUp(email: email, password: password);
        if (!mounted) return;
        if (outcome == SignUpOutcome.needsEmailConfirmation) {
          setState(() {
            _info = 'Te enviamos un correo para confirmar tu cuenta. Ábrelo y luego inicia sesión.';
            _signUpMode = false;
          });
        } else if (outcome == SignUpOutcome.alreadyRegistered) {
          setState(() {
            _error = 'Ya existe una cuenta con este correo. Inicia sesión con tu contraseña.';
            _signUpMode = false;
          });
        }
      } else {
        await widget.auth.signIn(email: email, password: password);
      }
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: Space.page, vertical: Space.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _Hero(),
                      const SizedBox(height: Space.xxl),
                      Container(
                        padding: const EdgeInsets.all(Space.l),
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: Radii.largeAll),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            CustomTextField(
                              label: 'Correo electrónico',
                              hint: 'tu@correo.com',
                              icon: CupertinoIcons.mail,
                              controller: _emailController,
                              validator: validateEmail,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: Space.l),
                            CustomTextField(
                              label: 'Contraseña',
                              hint: _signUpMode ? 'Mínimo ${Limits.minPasswordLength} caracteres' : 'Tu contraseña',
                              icon: CupertinoIcons.lock,
                              controller: _passwordController,
                              validator: validatePassword,
                              obscure: true,
                              keyboardType: TextInputType.visiblePassword,
                              autofillHints: [_signUpMode ? AutofillHints.newPassword : AutofillHints.password],
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _submit(),
                            ),
                          ],
                        ),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        child: Column(
                          children: [
                            if (_error != null) ...[
                              const SizedBox(height: Space.l),
                              InfoBanner(
                                icon: const Icon(CupertinoIcons.exclamationmark_circle_fill),
                                title: _signUpMode ? 'No pudimos crear la cuenta' : 'No pudimos iniciar sesión',
                                message: _error!,
                                color: AppColors.error,
                                background: AppColors.errorSoft,
                              ),
                            ],
                            if (_info != null) ...[
                              const SizedBox(height: Space.l),
                              InfoBanner(
                                icon: const Icon(CupertinoIcons.envelope_badge_fill),
                                title: 'Revisa tu correo',
                                message: _info!,
                                color: AppColors.success,
                                background: AppColors.successSoft,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: Space.xl),
                      PrimaryButton(
                        label: _signUpMode ? 'Crear cuenta' : 'Iniciar sesión',
                        loading: _loading,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: Space.s),
                      PlainButton(
                        label: _signUpMode ? '¿Ya tienes cuenta? Inicia sesión' : '¿No tienes cuenta? Crear cuenta',
                        onPressed: _loading ? null : _toggleMode,
                      ),
                      const SizedBox(height: Space.l),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          MuuveloIcon('lock', size: 14, fallback: CupertinoIcons.lock_shield_fill, color: AppColors.muted),
                          SizedBox(width: Space.xs),
                          Flexible(
                            child: Text(
                              'Tus vacas solo las ves tú.',
                              style: AppText.footnote,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Logo + large title + subtitle, centered.
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: Radii.largeAll,
            boxShadow: const [BoxShadow(color: Color(0x225B21D6), blurRadius: 24, offset: Offset(0, 10))],
          ),
          child: ClipRRect(
            borderRadius: Radii.largeAll,
            child: Image.asset('assets/images/logo.png', width: 96, height: 96, semanticLabel: 'Logo de Muuvelo'),
          ),
        ),
        const SizedBox(height: Space.l),
        const Text('Muuvelo', style: AppText.largeTitle),
        const SizedBox(height: Space.xs),
        const Text(
          'Divide la cuenta por lo que cada uno consumió',
          style: AppText.subheadline,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
