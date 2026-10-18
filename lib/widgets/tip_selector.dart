import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// TipSelector: [Switch] to include the tip, [ChoiceChip]s with the usual
/// percentages and a [Slider] for a custom value (0 to 30 %).
///
/// Parameters:
/// - [enabled]: whether a tip is included.
/// - [percent]: selected percentage.
/// - [presets]: chip values (e.g. 10, 15, 20).
/// - [maxPercent]: right end of the slider.
/// - [onEnabledChanged] / [onPercentChanged]: report changes to the screen.
///
/// Used in: RegisterScreen.
class TipSelector extends StatelessWidget {
  const TipSelector({
    super.key,
    required this.enabled,
    required this.percent,
    required this.presets,
    required this.maxPercent,
    required this.onEnabledChanged,
    required this.onPercentChanged,
  });

  final bool enabled;
  final int percent;
  final List<int> presets;
  final int maxPercent;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<int> onPercentChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text('Incluir propina', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(enabled ? 'Se reparte según lo que consumió cada uno' : 'Sin propina'),
              value: enabled,
              onChanged: onEnabledChanged,
            ),
            // AnimatedSize makes the chips and slider appear smoothly.
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: enabled ? _TipControls(this) : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipControls extends StatelessWidget {
  const _TipControls(this.parent);

  final TipSelector parent;

  @override
  Widget build(BuildContext context) {
    final isCustom = !parent.presets.contains(parent.percent);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (final value in parent.presets)
                ChoiceChip(
                  label: Text('$value%'),
                  selected: parent.percent == value,
                  onSelected: (_) => parent.onPercentChanged(value),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isCustom ? 'Personalizada: ${parent.percent}%' : 'O ajusta con la barra: ${parent.percent}%',
            style: const TextStyle(color: AppColors.muted),
          ),
          Slider(
            min: 0,
            max: parent.maxPercent.toDouble(),
            divisions: parent.maxPercent, // one step per whole percent
            value: parent.percent.toDouble(),
            label: '${parent.percent}%',
            onChanged: (value) => parent.onPercentChanged(value.round()),
          ),
        ],
      ),
    );
  }
}
