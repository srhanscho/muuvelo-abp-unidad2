import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/edit_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'screens/register_screen.dart';
import 'screens/results_screen.dart';
import 'screens/success_screen.dart';
import 'screens/vaca_detail_screen.dart';
import 'services/auth_service.dart';
import 'services/vaca_repository.dart';
import 'services/vaca_sync_controller.dart';
import 'utils/app_theme.dart';
import 'utils/constants.dart';
import 'utils/supabase_config.dart';

/// Entry point: connect to the Muuvelo backend, then start the app.
/// supabase_flutter restores the saved session (if any) during
/// initialize(), so a logged-in user goes straight to the app.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: SupabaseConfig.url, publishableKey: SupabaseConfig.publishableKey);
  final client = Supabase.instance.client;
  runApp(
    MuuveloApp(
      auth: SupabaseAuthService(client.auth),
      createRepository: () => SupabaseVacaRepository(client),
    ),
  );
}

/// Root widget and AUTH GATE.
///
/// - Listens to the auth state: no session -> LoginScreen; session -> the
///   app (MainShell). The MaterialApp gets a new key when that changes, so
///   logging out also clears every open screen.
/// - Owns the VacaSyncController of the logged-in user (a new one per
///   session, so a second user never sees the first user's list).
/// - Re-syncs with the database when the app comes back to the foreground.
///
/// Services arrive through the constructor so tests can inject fakes.
class MuuveloApp extends StatefulWidget {
  const MuuveloApp({super.key, required this.auth, required this.createRepository});

  final AuthService auth;
  final VacaRepository Function() createRepository;

  @override
  State<MuuveloApp> createState() => _MuuveloAppState();
}

class _MuuveloAppState extends State<MuuveloApp> with WidgetsBindingObserver {
  StreamSubscription<bool>? _authSubscription;
  late bool _signedIn = widget.auth.isSignedIn;
  VacaSyncController? _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_signedIn) _startSession();
    _authSubscription = widget.auth.signedInChanges.listen((signedIn) {
      if (signedIn == _signedIn) return; // e.g. token refreshed
      setState(() {
        _signedIn = signedIn;
        signedIn ? _startSession() : _endSession();
      });
    });
  }

  void _startSession() {
    _controller?.dispose();
    _controller = VacaSyncController(widget.createRepository())..refresh();
  }

  void _endSession() {
    // Dispose after this frame: the old screens still listen while they
    // are being removed.
    final old = _controller;
    _controller = null;
    WidgetsBinding.instance.addPostFrameCallback((_) => old?.dispose());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // DB -> app: changes made elsewhere appear when the user comes back.
    if (state == AppLifecycleState.resumed) _controller?.refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    final controller = _controller!;
    final Widget screen = switch (settings.name) {
      Routes.register => RegisterScreen(controller: controller),
      Routes.detail => VacaDetailScreen(controller: controller, vacaId: settings.arguments as String),
      Routes.edit => EditScreen(controller: controller, vacaId: settings.arguments as String),
      Routes.results => ResultsScreen(controller: controller, vacaId: settings.arguments as String),
      Routes.success => SuccessScreen(controller: controller, args: settings.arguments as SuccessArgs),
      _ => MainShell(controller: controller, auth: widget.auth),
    };
    // CupertinoPageRoute: iOS slide transition and swipe-back gesture.
    return CupertinoPageRoute(builder: (_) => screen, settings: settings);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return MaterialApp(
      key: ValueKey(_signedIn),
      title: 'Muuvelo',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: _signedIn && controller != null
          ? MainShell(controller: controller, auth: widget.auth)
          : LoginScreen(auth: widget.auth),
      onGenerateRoute: _onGenerateRoute,
    );
  }
}
