import 'package:flutter/cupertino.dart';

import '../utils/constants.dart';
import '../utils/design_tokens.dart';
import 'grouped_section.dart';

/// TipSelector: [CupertinoSwitch] to include the tip, a
/// [CupertinoSlidingSegmentedControl] with the usual percentages and a
/// [CupertinoSlider] for a custom value (0 to 30 %).
///
/// Parameters:
/// - [enabled]: whether a tip is included.
/// - [percent]: selected percentage.
/// - [presets]: segment values (e.g. 10, 15, 20).
/// - [maxPercent]: right end of the slider.
/// - [onEnabledChanged] / [onPercentChanged]: report changes to the screen.
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
    // -1 = "Otra" (custom value from the slider).
    final segment = presets.contains(percent) ? percent : -1;
    return GroupedSection(
      header: 'Propina',
      footer: enabled ? 'Se reparte según lo que consumió cada uno.' : 'Sin propina.',
      children: [
        GroupedRow(
          title: 'Incluir propina',
          trailing: Semantics(
            label: 'Incluir propina',
            child: CupertinoSwitch(
              value: enabled,
              activeTrackColor: AppColors.primary,
              onChanged: onEnabledChanged,
            ),
          ),
        ),
        if (enabled)
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.l, Space.m, Space.l, Space.s),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: CupertinoSlidingSegmentedControl<int>(
                    groupValue: segment,
                    onValueChanged: (value) {
                      if (value != null && value >= 0) onPercentChanged(value);
                    },
                    children: {
                      for (final value in presets) value: _Segment('$value%'),
                      -1: _Segment(segment == -1 ? '$percent%' : 'Otra'),
                    },
                  ),
                ),
                const SizedBox(height: Space.m),
                Row(
                  children: [
                    const Text('0%', style: AppText.caption),
                    Expanded(
                      child: CupertinoSlider(
                        min: 0,
                        max: maxPercent.toDouble(),
                        divisions: maxPercent, // one step per whole percent
                        value: percent.toDouble(),
                        activeColor: AppColors.primary,
                        onChanged: (value) => onPercentChanged(value.round()),
                      ),
                    ),
                    Text('$maxPercent%', style: AppText.caption),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: Space.s),
    child: Text(text, style: AppText.subheadline.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600)),
  );
}
