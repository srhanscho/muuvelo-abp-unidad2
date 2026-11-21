import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/money.dart';
import '../models/vaca.dart';
import '../services/vaca_sync_controller.dart';
import '../utils/constants.dart';
import '../utils/dates.dart';
import '../utils/design_tokens.dart';
import '../widgets/avatar_initials.dart';
import '../widgets/grouped_section.dart';
import '../widgets/money_text.dart';
import '../widgets/primary_button.dart';
import '../widgets/vaca_loader.dart';

enum SuccessKind { created, closed }

/// Arguments of the success route.
class SuccessArgs {
  const SuccessArgs({required this.vacaId, required this.kind});

  final String vacaId;
  final SuccessKind kind;
}

/// Confirmation state shown after creating or closing a vaca: what
/// happened, for whom, how much and when, plus "Compartir resumen".
class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key, required this.controller, required this.args});

  final VacaSyncController controller;
  final SuccessArgs args;

  bool get _created => args.kind == SuccessKind.created;

  void _goHome(BuildContext context) => Navigator.popUntil(context, (route) => route.isFirst);

  @override
  Widget build(BuildContext context) {
    return VacaLoader(
      controller: controller,
      vacaId: args.vacaId,
      title: 'Listo',
      builder: (context, vaca) => Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(Space.l, Space.xxl, Space.l, Space.xl),
            children: [
              const Center(child: _AnimatedCheck()),
              const SizedBox(height: Space.l),
              Text(
                _created ? '¡Vaca guardada!' : '¡Cuenta cerrada!',
                style: AppText.largeTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Space.s),
              Text(
                '${vaca.restaurantName} · ${formatDateTime(_created ? vaca.createdAt : (vaca.closedAt ?? DateTime.now()))}',
                style: AppText.subheadline,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Space.xl),
              _AmountHero(vaca: vaca, created: _created),
              const SizedBox(height: Space.xl),
              GroupedSection(
                header: _created ? 'Cada uno paga' : 'Así quedó',
                separatorInset: 64,
                children: [
                  for (final p in vaca.participants)
                    GroupedRow(
                      leading: AvatarInitials(initials: p.initials, size: 34, highlighted: p.paid),
                      title: p.isHost ? '${p.name} (anfitrión)' : p.name,
                      subtitle: Text(p.paid ? 'Pagó' : 'Pendiente'),
                      trailing: MoneyText(p.amount, style: AppText.money),
                    ),
                ],
              ),
              const SizedBox(height: Space.xl),
              PrimaryButton(
                label: 'Compartir resumen',
                icon: CupertinoIcons.share,
                onPressed: () => SharePlus.instance.share(
                  ShareParams(text: vaca.toSummaryText(), subject: 'Muuvelo · ${vaca.restaurantName}'),
                ),
              ),
              const SizedBox(height: Space.s),
              if (_created)
                PlainButton(
                  label: 'Gestionar cobro',
                  onPressed: () => Navigator.pushReplacementNamed(context, Routes.results, arguments: vaca.id),
                ),
              PlainButton(label: 'Volver al inicio', onPressed: () => _goHome(context)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmountHero extends StatelessWidget {
  const _AmountHero({required this.vaca, required this.created});

  final Vaca vaca;
  final bool created;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(created ? 'Total a repartir' : 'Recogido', style: AppText.subheadline),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: MoneyText(created ? vaca.total : vaca.collected, style: AppText.moneyHero),
        ),
        Text(
          created
              ? 'entre ${vaca.participants.length} personas · guardada en tu cuenta'
              : vaca.pending == 0
              ? 'Todos pagaron su parte'
              : 'de ${formatPesos(vaca.total)} · faltó ${formatPesos(vaca.pending)}',
          style: AppText.footnote,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Green check that scales and fades in once (subtle motion).
class _AnimatedCheck extends StatelessWidget {
  const _AnimatedCheck();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0, 1),
        child: Transform.scale(scale: 0.6 + 0.4 * t, child: child),
      ),
      child: Container(
        width: 88,
        height: 88,
        decoration: const BoxDecoration(color: AppColors.successSoft, shape: BoxShape.circle),
        child: const Icon(CupertinoIcons.checkmark_alt, size: 48, color: AppColors.success),
      ),
    );
  }
}
