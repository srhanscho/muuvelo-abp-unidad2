import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/vaca.dart';
import '../services/vaca_sync_controller.dart';
import '../utils/constants.dart';
import '../utils/dates.dart';
import '../utils/design_tokens.dart';
import '../widgets/grouped_section.dart';
import '../widgets/large_title_page.dart';
import '../widgets/money_text.dart';
import '../widgets/muuvelo_icon.dart';
import '../widgets/state_views.dart';
import '../widgets/sync_status_badge.dart';
import '../widgets/vaca_tile.dart';

/// Screen 1 - Inicio.
///
/// Greets the user, shows the summary that matters (money still to
/// collect, open vacas), the sync status and the way into every feature.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.controller,
    required this.email,
    required this.onNewVaca,
    required this.onOpenList,
    required this.onOpenCobros,
  });

  final VacaSyncController controller;
  final String? email;
  final VoidCallback onNewVaca;
  final VoidCallback onOpenList;
  final VoidCallback onOpenCobros;

  /// "ana.diaz@correo.com" -> "ana.diaz".
  String get _userName => (email ?? '').split('@').first;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final open = controller.openVacas;
        final latest = open.isEmpty ? null : open.first;
        return LargeTitlePage(
          title: 'Inicio',
          onRefresh: controller.refresh,
          bottomPadding: Space.tabBarClearance,
          children: [
            _Greeting(name: _userName),
            const SizedBox(height: Space.m),
            Align(
              alignment: Alignment.centerLeft,
              child: SyncStatusBadge(
                state: controller.state,
                lastSync: controller.lastSync,
                onRetry: controller.refresh,
              ),
            ),
            const SizedBox(height: Space.l),
            _PendingCard(
              loading: !controller.hasLoaded,
              pending: controller.totalPending,
              openCount: open.length,
              onTap: onOpenCobros,
            ),
            const SectionGap(),
            GroupedSection(
              header: 'Empezar',
              separatorInset: 58,
              children: [
                GroupedRow(
                  leading: const IconTile(icon: Icon(CupertinoIcons.plus), color: AppColors.tabNew),
                  title: 'Nueva vaca',
                  subtitle: const Text('Registra la cuenta y quién pidió qué'),
                  onTap: onNewVaca,
                ),
                GroupedRow(
                  leading: const IconTile(icon: Icon(CupertinoIcons.square_stack_3d_up_fill), color: AppColors.tabVacas),
                  title: 'Mis vacas',
                  subtitle: Text('${controller.vacas.length} guardadas en tu cuenta'),
                  onTap: onOpenList,
                ),
                GroupedRow(
                  leading: const IconTile(icon: Icon(CupertinoIcons.money_dollar), color: AppColors.tabCobros),
                  title: 'Gestionar cobros',
                  subtitle: const Text('Marca quién ya pagó y cierra la cuenta'),
                  onTap: onOpenCobros,
                ),
              ],
            ),
            const SectionGap(),
            if (latest != null)
              GroupedSection(
                header: 'Vaca activa',
                trailingHeader: GestureDetector(
                  onTap: onOpenList,
                  child: Text('Ver todas', style: AppText.subheadline.copyWith(color: AppColors.primary)),
                ),
                children: [_tileFor(context, latest)],
              )
            else if (controller.hasLoaded)
              GroupedSection(
                header: 'Vaca activa',
                children: [
                  EmptyState(
                    illustration: 'empty_vacas',
                    fallback: CupertinoIcons.tray,
                    title: 'Nada por cobrar',
                    message: 'Cuando registres una vaca, aquí verás cuánto falta por recoger.',
                    actionLabel: 'Nueva vaca',
                    onAction: onNewVaca,
                  ),
                ],
              ),
            const SectionGap(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: Space.l),
              child: Text(
                'Muuvelo reparte cada ítem entre quienes lo consumieron y la propina en proporción. '
                'Si sobra un peso por redondeo, lo asume el anfitrión.',
                style: AppText.footnote,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _tileFor(BuildContext context, Vaca vaca) => VacaTile(
    title: vaca.restaurantName,
    subtitle: '${formatRelativeDay(vaca.createdAt, DateTime.now())} · ${vaca.participants.length} personas',
    amount: vaca.pending,
    amountCaption: 'por cobrar',
    percent: vaca.percentCollected,
    isClosed: false,
    statusLabel: 'Abierta · ${vaca.paidCount} de ${vaca.participants.length}',
    onTap: () => Navigator.pushNamed(context, Routes.detail, arguments: vaca.id),
  );
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // App-icon style mark.
        ClipRRect(
          borderRadius: Radii.smallAll,
          child: Image.asset('assets/images/logo.png', width: 44, height: 44, semanticLabel: 'Logo de Muuvelo'),
        ),
        const SizedBox(width: Space.m),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.isEmpty ? 'Hola' : 'Hola, $name',
                style: AppText.footnote,
                overflow: TextOverflow.ellipsis,
              ),
              const Text('¿Quién invita hoy?', style: AppText.title2),
            ],
          ),
        ),
      ],
    );
  }
}

/// Dark card with the most important number of the app: money still to
/// collect across every open vaca.
class _PendingCard extends StatelessWidget {
  const _PendingCard({required this.loading, required this.pending, required this.openCount, required this.onTap});

  final bool loading;
  final int pending;
  final int openCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.night,
      borderRadius: Radii.largeAll,
      child: InkWell(
        borderRadius: Radii.largeAll,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Space.l),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'POR COBRAR',
                      style: AppText.sectionHeader.copyWith(color: Colors.white.withValues(alpha: 0.7)),
                    ),
                    const SizedBox(height: Space.xs),
                    if (loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: Space.m),
                        child: CupertinoActivityIndicator(color: Colors.white),
                      )
                    else
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: MoneyText(pending, style: AppText.moneyHero.copyWith(color: Colors.white)),
                      ),
                    Text(
                      openCount == 1 ? 'en 1 vaca abierta' : 'en $openCount vacas abiertas',
                      style: AppText.subheadline.copyWith(color: Colors.white.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
              const MuuveloIcon('glass_full', size: 56, fallback: CupertinoIcons.chart_pie_fill, color: AppColors.gold),
            ],
          ),
        ),
      ),
    );
  }
}
