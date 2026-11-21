import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/vaca_sync_controller.dart';
import '../utils/constants.dart';
import '../utils/design_tokens.dart';
import '../utils/error_messages.dart';
import '../widgets/confirm_dialogs.dart';
import '../widgets/glass_tab_bar.dart';
import '../widgets/primary_button.dart';
import 'cobros_screen.dart';
import 'home_screen.dart';
import 'vacas_list_screen.dart';

/// The logged-in app: three tab screens (Inicio, Mis vacas, Cobros) under
/// the floating glass tab bar. "Nueva" is an action: it opens Registro.
/// The round logo button opens the profile (email + Cerrar sesión).
///
/// Detalle, Edición, Gestión and the success screen are pushed routes on
/// top of this shell.
class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.controller, required this.auth});

  final VacaSyncController controller;
  final AuthService auth;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  /// 0 = Inicio, 1 = Mis vacas, 2 = Cobros.
  int _tab = 0;

  static const _tabs = [
    GlassTab(label: 'Inicio', asset: 'tab_home', fallback: CupertinoIcons.house_fill, color: AppColors.tabHome),
    GlassTab(
      label: 'Mis vacas',
      asset: 'tab_vacas',
      fallback: CupertinoIcons.square_stack_3d_up_fill,
      color: AppColors.tabVacas,
    ),
    GlassTab(label: 'Nueva', asset: 'tab_new', fallback: CupertinoIcons.plus_circle_fill, color: AppColors.tabNew),
    GlassTab(
      label: 'Cobros',
      asset: 'tab_cobros',
      fallback: CupertinoIcons.money_dollar_circle_fill,
      color: AppColors.tabCobros,
    ),
  ];

  void _onBarTap(int barIndex) {
    switch (barIndex) {
      case 2:
        Navigator.pushNamed(context, Routes.register);
      case 3:
        setState(() => _tab = 2);
      default:
        setState(() => _tab = barIndex);
    }
  }

  void _openNew() => Navigator.pushNamed(context, Routes.register);

  Future<void> _openProfile() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => _ProfileSheet(
        email: widget.auth.currentEmail ?? '',
        onSignOut: () async {
          final confirmed = await showConfirmDialog(
            sheetContext,
            title: '¿Cerrar sesión?',
            message: 'Tendrás que volver a escribir tu correo y contraseña para entrar.',
            confirmLabel: 'Cerrar sesión',
            destructive: true,
          );
          if (!confirmed) return;
          try {
            // main.dart hears the change and shows the LoginScreen.
            await widget.auth.signOut();
          } catch (e) {
            if (sheetContext.mounted) {
              ScaffoldMessenger.of(sheetContext).showSnackBar(SnackBar(content: Text(friendlyError(e))));
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: IndexedStack(
        index: _tab,
        children: [
          HomeScreen(
            controller: widget.controller,
            email: widget.auth.currentEmail,
            onNewVaca: _openNew,
            onOpenList: () => setState(() => _tab = 1),
            onOpenCobros: () => setState(() => _tab = 2),
          ),
          VacasListScreen(controller: widget.controller, onNewVaca: _openNew),
          CobrosScreen(controller: widget.controller),
        ],
      ),
      bottomNavigationBar: GlassTabBar(
        tabs: _tabs,
        selectedIndex: _tab == 2 ? 3 : _tab,
        onTap: _onBarTap,
        onProfile: _openProfile,
      ),
    );
  }
}

class _ProfileSheet extends StatelessWidget {
  const _ProfileSheet({required this.email, required this.onSignOut});

  final String email;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: ClipOval(child: Image.asset('assets/images/logo.png', width: 72, height: 72)),
            ),
            const SizedBox(height: Space.m),
            const Text('Sesión iniciada como', style: AppText.footnote, textAlign: TextAlign.center),
            const SizedBox(height: Space.xs),
            Text(email, style: AppText.headline, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
            const SizedBox(height: Space.xl),
            Container(
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: Radii.largeAll),
              child: PlainButton(
                label: 'Cerrar sesión',
                icon: CupertinoIcons.square_arrow_right,
                color: AppColors.error,
                onPressed: onSignOut,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
