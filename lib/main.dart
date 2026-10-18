import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/register_screen.dart';
import 'screens/results_screen.dart';
import 'services/vaca_store.dart';
import 'utils/app_theme.dart';
import 'utils/constants.dart';

/// Entry point. The store is created ONCE here and lives in memory while
/// the app is open (no database, no network).
void main() => runApp(MuuveloApp(store: VacaStore()));

/// Root widget: theme + the 3 routes of the app.
class MuuveloApp extends StatelessWidget {
  const MuuveloApp({super.key, required this.store, this.initialRoute = Routes.home});

  final VacaStore store;

  /// Tests can start directly on another screen.
  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Muuvelo',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      initialRoute: initialRoute,
      // onGenerateRoute (instead of a `routes` map) lets us pass the store
      // and the route arguments to each screen through its constructor.
      onGenerateRoute: (settings) {
        final Widget screen = switch (settings.name) {
          Routes.register => RegisterScreen(store: store),
          Routes.results => ResultsScreen(store: store, vacaId: settings.arguments as String),
          _ => HomeScreen(store: store),
        };
        return MaterialPageRoute(builder: (_) => screen, settings: settings);
      },
    );
  }
}
