import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../utils/constants.dart';
import '../utils/design_tokens.dart';

/// GroupedSection: iOS "inset grouped" list. A white rounded block on the
/// gray background, with an optional uppercase header above, a footnote
/// below and hairline separators between rows (inset from the left).
///
/// Parameters:
/// - [header] / [footer]: small gray texts outside the block.
/// - [trailingHeader]: widget at the right of the header (counter, button).
/// - [children]: the rows. Separators are added automatically.
/// - [separatorInset]: where the hairline starts (aligned with row text).
///
/// Used in: every screen.
class GroupedSection extends StatelessWidget {
  const GroupedSection({
    super.key,
    this.header,
    this.footer,
    this.trailingHeader,
    required this.children,
    this.separatorInset = Space.l,
    this.padding = EdgeInsets.zero,
  });

  final String? header;
  final String? footer;
  final Widget? trailingHeader;
  final List<Widget> children;
  final double separatorInset;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (header != null || trailingHeader != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.s),
            child: Row(
              children: [
                Expanded(child: Text((header ?? '').toUpperCase(), style: AppText.sectionHeader)),
                ?trailingHeader,
              ],
            ),
          ),
        DecoratedBox(
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: Radii.largeAll),
          child: ClipRRect(
            borderRadius: Radii.largeAll,
            child: Padding(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < children.length; i++) ...[
                    if (i > 0) Hairline(indent: separatorInset),
                    children[i],
                  ],
                ],
              ),
            ),
          ),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, 0),
            child: Text(footer!, style: AppText.footnote),
          ),
      ],
    );
  }
}

/// 0.5 px iOS separator line.
class Hairline extends StatelessWidget {
  const Hairline({super.key, this.indent = 0});

  final double indent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: indent),
      child: Container(height: 0.5, color: AppColors.separator),
    );
  }
}

/// GroupedRow: one row inside a [GroupedSection], like a UITableViewCell.
///
/// Parameters:
/// - [leading]: icon tile or avatar at the left.
/// - [title] / [subtitle]: texts.
/// - [trailing]: amount, switch, chip...
/// - [onTap]: makes the row tappable and adds a chevron (unless
///   [showChevron] is false).
class GroupedRow extends StatelessWidget {
  const GroupedRow({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showChevron = true,
    this.titleStyle,
  });

  final Widget? leading;
  final String title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    final content = ConstrainedBox(
      // 48dp minimum tap target (iOS uses 44pt).
      constraints: const BoxConstraints(minHeight: 52),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.m),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: Space.m)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: titleStyle ?? AppText.body, maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    DefaultTextStyle(style: AppText.footnote, child: subtitle!),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: Space.s), trailing!],
            if (onTap != null && showChevron) ...[
              const SizedBox(width: Space.s),
              const Icon(CupertinoIcons.chevron_forward, size: 16, color: Color(0xFFC4C4C7)),
            ],
          ],
        ),
      ),
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, child: content),
    );
  }
}

/// IconTile: rounded colored square with a white icon, like iOS Settings.
class IconTile extends StatelessWidget {
  const IconTile({super.key, required this.icon, required this.color, this.size = 30});

  final Widget icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, borderRadius: Radii.smallAll),
      child: IconTheme(
        data: IconThemeData(color: Colors.white, size: size * 0.6),
        child: icon,
      ),
    );
  }
}
