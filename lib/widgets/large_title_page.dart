import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../utils/constants.dart';
import '../utils/design_tokens.dart';

/// LargeTitlePage: the skeleton of every screen, iOS style. A large title
/// that shrinks into the bar when you scroll, optional pull-to-refresh
/// (CupertinoSliverRefreshControl) and the content below.
///
/// Parameters:
/// - [title]: large title; [previousPageTitle]: text of the back chevron.
/// - [trailing]: action at the right of the bar (e.g. "Editar").
/// - [onRefresh]: enables pull-to-refresh.
/// - [children]: the content. All of them are built at once (not lazily)
///   so a `Form` can validate every field.
/// - [bottomPadding]: extra room at the end (e.g. above the tab bar).
/// - [bottomBar]: widget pinned at the bottom (main button of a form).
class LargeTitlePage extends StatelessWidget {
  const LargeTitlePage({
    super.key,
    required this.title,
    required this.children,
    this.previousPageTitle,
    this.trailing,
    this.onRefresh,
    this.bottomPadding = Space.xxl,
    this.bottomBar,
  });

  final String title;
  final List<Widget> children;
  final String? previousPageTitle;
  final Widget? trailing;
  final Future<void> Function()? onRefresh;
  final double bottomPadding;
  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        // Bouncing + always scrollable: pull-to-refresh works even when the
        // list is short.
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(title),
            previousPageTitle: previousPageTitle,
            trailing: trailing,
            border: null,
            backgroundColor: AppColors.background.withValues(alpha: 0.94),
            // Tabs keep several bars alive at once; the hero animation
            // between bars would clash, so we keep the plain transition.
            transitionBetweenRoutes: false,
          ),
          if (onRefresh != null) CupertinoSliverRefreshControl(onRefresh: onRefresh),
          SliverToBoxAdapter(
            child: SafeArea(
              top: false,
              bottom: bottomBar == null,
              child: Padding(
                padding: EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, bottomPadding),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: bottomBar == null
          ? null
          : DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.97),
                border: const Border(top: BorderSide(color: AppColors.separator, width: 0.5)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(padding: const EdgeInsets.fromLTRB(Space.l, Space.m, Space.l, Space.m), child: bottomBar),
              ),
            ),
    );
  }
}

/// Vertical gap between grouped sections (iOS uses generous spacing).
class SectionGap extends StatelessWidget {
  const SectionGap({super.key, this.height = Space.xxl});

  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(height: height);
}
