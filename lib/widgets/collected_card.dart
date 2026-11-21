import 'package:flutter/cupertino.dart';

import '../models/money.dart';
import '../utils/constants.dart';
import '../utils/design_tokens.dart';
import 'glass_progress.dart';
import 'money_text.dart';

/// CollectedCard: the glass plus "Recogido $ Y de $ Z" and, always next
/// to it, the consequence "Faltan $ X por cobrar".
///
/// Parameters:
/// - [collected] / [total]: pesos.
/// - [percent]: 0..100, passed to [GlassProgress].
/// - [paidCount] / [peopleCount]: e.g. "2 de 3 pagaron".
/// - [isClosed]: caption "Cerrada con" once the account is closed.
///
/// Used in: Gestión de cobro and Detalle.
class CollectedCard extends StatelessWidget {
  const CollectedCard({
    super.key,
    required this.collected,
    required this.total,
    required this.percent,
    required this.paidCount,
    required this.peopleCount,
    required this.isClosed,
  });

  final int collected;
  final int total;
  final int percent;
  final int paidCount;
  final int peopleCount;
  final bool isClosed;

  @override
  Widget build(BuildContext context) {
    final pending = total - collected;
    return Container(
      padding: const EdgeInsets.all(Space.l),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: Radii.largeAll),
      child: Row(
        children: [
          GlassProgress(percent: percent, width: 84, height: 108),
          const SizedBox(width: Space.l),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isClosed ? 'Cerrada con' : 'Recogido', style: AppText.subheadline),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: MoneyText(collected, style: AppText.moneyHero.copyWith(fontSize: 34)),
                ),
                Text('de ${formatPesos(total)}', style: AppText.subheadline),
                const SizedBox(height: Space.s),
                Row(
                  children: [
                    Icon(
                      pending == 0 ? CupertinoIcons.checkmark_seal_fill : CupertinoIcons.hourglass,
                      size: 16,
                      color: pending == 0 ? AppColors.success : AppColors.pending,
                    ),
                    const SizedBox(width: Space.xs),
                    Expanded(
                      child: Text(
                        pending == 0 ? 'Todo cobrado' : 'Faltan ${formatPesos(pending)} por cobrar',
                        style: AppText.subheadline.copyWith(
                          color: pending == 0 ? AppColors.success : AppColors.pending,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Space.xs),
                Text('$paidCount de $peopleCount pagaron', style: AppText.footnote),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
