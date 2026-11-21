import 'package:flutter/cupertino.dart';

import '../utils/constants.dart';
import '../utils/design_tokens.dart';
import 'muuvelo_icon.dart';
import 'primary_button.dart';

/// EmptyState: illustration + title + message + optional action, for
/// lists with nothing to show.
///
/// Used in: Listado (no vacas / no results), Inicio, Cobros.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.illustration,
    required this.fallback,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String illustration;
  final IconData fallback;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.xl, vertical: Space.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MuuveloIcon(illustration, size: 96, fallback: fallback, color: AppColors.muted.withValues(alpha: 0.6)),
          const SizedBox(height: Space.l),
          Text(title, style: AppText.title2, textAlign: TextAlign.center),
          const SizedBox(height: Space.s),
          Text(message, style: AppText.subheadline, textAlign: TextAlign.center),
          if (actionLabel != null) ...[
            const SizedBox(height: Space.xl),
            PrimaryButton(label: actionLabel!, onPressed: onAction),
          ],
        ],
      ),
    );
  }
}

/// ErrorView: explains what failed (already in Spanish, from
/// friendlyError) and offers "Reintentar".
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.xl, vertical: Space.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(CupertinoIcons.wifi_exclamationmark, size: 56, color: AppColors.muted),
          const SizedBox(height: Space.l),
          const Text('No pudimos cargar tus vacas', style: AppText.title2, textAlign: TextAlign.center),
          const SizedBox(height: Space.s),
          Text(message, style: AppText.subheadline, textAlign: TextAlign.center),
          const SizedBox(height: Space.xl),
          PrimaryButton(label: 'Reintentar', icon: CupertinoIcons.arrow_clockwise, onPressed: onRetry),
        ],
      ),
    );
  }
}

/// SkeletonRows: gray placeholder rows that pulse while the first load
/// is running (feels faster than a lone spinner).
class SkeletonRows extends StatefulWidget {
  const SkeletonRows({super.key, this.count = 4});

  final int count;

  @override
  State<SkeletonRows> createState() => _SkeletonRowsState();
}

class _SkeletonRowsState extends State<SkeletonRows> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: 0.45,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Widget _bar(double width, double height) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(color: AppColors.fill, borderRadius: Radii.smallAll),
  );

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Cargando',
      child: FadeTransition(
        opacity: _pulse,
        child: Container(
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: Radii.largeAll),
          child: Column(
            children: [
              for (var i = 0; i < widget.count; i++)
                Padding(
                  padding: const EdgeInsets.all(Space.l),
                  child: Row(
                    children: [
                      _bar(40, 40),
                      const SizedBox(width: Space.m),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [_bar(140, 14), const SizedBox(height: Space.s), _bar(90, 10)],
                        ),
                      ),
                      _bar(64, 16),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
