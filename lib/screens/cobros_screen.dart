import 'package:flutter/cupertino.dart';

import '../services/vaca_sync_controller.dart';
import '../utils/constants.dart';
import '../utils/design_tokens.dart';
import '../utils/error_messages.dart';
import '../widgets/grouped_section.dart';
import '../widgets/large_title_page.dart';
import '../widgets/money_text.dart';
import '../widgets/state_views.dart';
import '../widgets/vaca_tile.dart';

/// Tab "Cobros": shortcut to the main feature. Lists only the open
/// vacas, with how much is still missing, and opens their Gestión de
/// cobro screen directly.
class CobrosScreen extends StatelessWidget {
  const CobrosScreen({super.key, required this.controller});

  final VacaSyncController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final open = controller.openVacas;
        return LargeTitlePage(
          title: 'Cobros',
          onRefresh: controller.refresh,
          bottomPadding: Space.tabBarClearance,
          children: [
            GroupedSection(
              children: [
                Padding(
                  padding: const EdgeInsets.all(Space.l),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Falta por cobrar', style: AppText.subheadline),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: MoneyText(controller.totalPending, style: AppText.moneyHero),
                      ),
                      Text(
                        open.length == 1 ? '1 vaca abierta' : '${open.length} vacas abiertas',
                        style: AppText.footnote,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SectionGap(),
            if (!controller.hasLoaded)
              const SkeletonRows(count: 3)
            else if (controller.error != null && controller.vacas.isEmpty)
              ErrorView(message: friendlyError(controller.error!), onRetry: controller.refresh)
            else if (open.isEmpty)
              const EmptyState(
                illustration: 'paid',
                fallback: CupertinoIcons.checkmark_seal,
                title: 'Todo al día',
                message: 'No tienes vacas abiertas. Cuando registres una, gestiona aquí sus pagos.',
              )
            else
              GroupedSection(
                header: 'Abiertas',
                footer: 'Toca una vaca para marcar quién pagó o cerrarla.',
                separatorInset: 58,
                children: [
                  for (final vaca in open)
                    VacaTile(
                      title: vaca.restaurantName,
                      subtitle: '${vaca.paidCount} de ${vaca.participants.length} pagaron',
                      amount: vaca.pending,
                      amountCaption: 'faltan',
                      percent: vaca.percentCollected,
                      isClosed: false,
                      statusLabel: '${vaca.percentCollected}% recogido',
                      onTap: () => Navigator.pushNamed(context, Routes.results, arguments: vaca.id),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }
}
