import 'package:flutter/material.dart';

import '../services/vaca_store.dart';
import '../utils/constants.dart';
import '../widgets/action_card.dart';
import '../widgets/info_banner.dart';
import '../widgets/section_header.dart';
import '../widgets/vaca_tile.dart';

/// Screen 1 - Pantalla principal.
///
/// Presents the app, explains the problem and leads to the other two
/// screens. It also lists the vacas calculated during this session.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.store});

  final VacaStore store;

  void _openResults(BuildContext context, String vacaId) =>
      Navigator.pushNamed(context, Routes.results, arguments: vacaId);

  @override
  Widget build(BuildContext context) {
    // Rebuild when a vaca is added, paid or closed.
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final latest = store.latest;
        return Scaffold(
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                const _BrandHeader(),
                const SizedBox(height: 20),
                const InfoBanner(
                  icon: Icons.lightbulb_outline,
                  title: 'El problema',
                  message:
                      'Varios amigos comen juntos, uno paga todo y luego pasa semanas cobrando. '
                      'Muuvelo calcula lo justo para cada uno y te deja marcar quién ya pagó.',
                ),
                const SectionHeader('Empezar'),
                ActionCard(
                  icon: Icons.add_circle_outline,
                  title: 'Nueva vaca',
                  subtitle: 'Registra la cuenta, las personas y quién pidió qué',
                  highlighted: true,
                  onTap: () => Navigator.pushNamed(context, Routes.register),
                ),
                const SizedBox(height: 12),
                ActionCard(
                  icon: Icons.local_drink_outlined,
                  title: 'Ver resultados',
                  subtitle: latest == null
                      ? 'Disponible cuando calcules tu primera vaca'
                      : 'Última vaca: ${latest.restaurantName}',
                  // null disables the card while nothing has been calculated.
                  onTap: latest == null ? null : () => _openResults(context, latest.id),
                ),
                SectionHeader(
                  'Vacas de esta sesión',
                  trailing: Text('${store.vacas.length}', style: const TextStyle(color: AppColors.muted)),
                ),
                if (store.isEmpty)
                  const InfoBanner(
                    icon: Icons.inbox_outlined,
                    title: 'Todavía no hay vacas',
                    message: 'Se guardan solo mientras la app esté abierta.',
                    color: AppColors.muted,
                    background: AppColors.border,
                  ),
                for (final vaca in store.vacas)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: VacaTile(
                      title: vaca.restaurantName,
                      subtitle: '${vaca.participants.length} personas · ${vaca.paidCount} pagaron',
                      collected: vaca.collected,
                      total: vaca.total,
                      percent: vaca.percentCollected,
                      isClosed: vaca.isClosed,
                      onTap: () => _openResults(context, vaca.id),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Logo, app name and tagline. Private because only this screen uses it.
class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // The logo PNG already includes its purple rounded background.
        Image.asset(
          'assets/images/logo.png',
          width: 60,
          height: 60,
          semanticLabel: 'Logo de Muuvelo',
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Muuvelo',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.ink),
              ),
              Text(
                'Divide la cuenta por lo que cada uno consumió',
                style: TextStyle(color: AppColors.muted, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
