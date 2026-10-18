import 'package:flutter/material.dart';

import '../models/money.dart';

/// MoneyText: shows an amount of pesos as "$ 79.200".
///
/// Always use it instead of formatting by hand, so every amount in the app
/// looks the same.
///
/// Parameters:
/// - [pesos]: the amount (int, never double).
/// - [style]: optional text style (size, weight, color).
///
/// Used in: SummaryCard, CollectedCard, PersonShareCard, BillItemCard
/// and VacaTile.
class MoneyText extends StatelessWidget {
  const MoneyText(this.pesos, {super.key, this.style});

  final int pesos;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    // Tabular figures: every digit has the same width, so amounts line up.
    const tabular = TextStyle(fontFeatures: [FontFeature.tabularFigures()]);
    return Text(formatPesos(pesos), style: tabular.merge(style));
  }
}
