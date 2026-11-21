import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/constants.dart';
import '../utils/design_tokens.dart';
import 'muuvelo_icon.dart';

/// One button of the [GlassTabBar].
class GlassTab {
  const GlassTab({required this.label, required this.asset, required this.fallback, required this.color});

  final String label;

  /// PNG name in assets/icons (e.g. 'tab_home'); [fallback] until it exists.
  final String asset;
  final IconData fallback;
  final Color color;
}

/// GlassTabBar: floating "liquid glass" navigation, detached from the
/// screen edges. A frosted pill with the tabs (the selected one sits in a
/// "puck" that slides between tabs) plus a separate round glass button
/// with the Muuvelo mark that opens the profile.
///
/// Parameters:
/// - [tabs]: the buttons, in order.
/// - [selectedIndex]: which tab is highlighted (null = none).
/// - [onTap]: called with the tapped index.
/// - [onProfile]: tap on the round logo button.
class GlassTabBar extends StatelessWidget {
  const GlassTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTap,
    required this.onProfile,
  });

  final List<GlassTab> tabs;
  final int? selectedIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onProfile;

  static const height = 64.0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: Space.s),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.l),
        child: Row(
          children: [
            Expanded(
              child: _Glass(
                shape: const StadiumBorder(),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth = (constraints.maxWidth - Space.s) / tabs.length;
                    return Stack(
                      children: [
                        if (selectedIndex != null)
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 320),
                            curve: Curves.easeOutCubic,
                            left: Space.xs + itemWidth * selectedIndex!,
                            top: Space.xs,
                            bottom: Space.xs,
                            width: itemWidth,
                            child: const DecoratedBox(
                              decoration: ShapeDecoration(color: Color(0x14000000), shape: StadiumBorder()),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: Space.xs),
                          child: Row(
                            children: [
                              for (var i = 0; i < tabs.length; i++)
                                Expanded(
                                  child: _TabButton(
                                    tab: tabs[i],
                                    selected: i == selectedIndex,
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      onTap(i);
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: Space.s),
            Semantics(
              button: true,
              label: 'Perfil y cerrar sesión',
              child: GestureDetector(
                onTap: onProfile,
                child: _Glass(
                  shape: const CircleBorder(),
                  width: height,
                  child: Padding(
                    padding: const EdgeInsets.all(Space.s),
                    child: ClipOval(child: Image.asset('assets/images/logo.png', fit: BoxFit.cover)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Frosted glass surface: blur of what is behind + translucent white +
/// a thin light border + a soft shadow.
class _Glass extends StatelessWidget {
  const _Glass({required this.shape, required this.child, this.width});

  final ShapeBorder shape;
  final Widget child;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: GlassTabBar.height,
      decoration: ShapeDecoration(
        shape: shape,
        shadows: const [BoxShadow(color: Color(0x1F000000), blurRadius: 24, offset: Offset(0, 8))],
      ),
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: Colors.white.withValues(alpha: 0.72),
              shape: shape is CircleBorder
                  ? const CircleBorder(side: BorderSide(color: Color(0x99FFFFFF)))
                  : const StadiumBorder(side: BorderSide(color: Color(0x99FFFFFF))),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.tab, required this.selected, required this.onTap});

  final GlassTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: tab.label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 32,
        child: SizedBox(
          height: GlassTabBar.height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: selected ? 1 : 0.88,
                duration: const Duration(milliseconds: 220),
                child: AnimatedOpacity(
                  opacity: selected ? 1 : 0.6,
                  duration: const Duration(milliseconds: 220),
                  child: MuuveloIcon(tab.asset, size: 26, fallback: tab.fallback, color: tab.color),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                tab.label,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: AppText.caption.copyWith(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.ink : AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
