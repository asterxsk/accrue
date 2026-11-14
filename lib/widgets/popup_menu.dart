import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_type.dart';
import '../theme/metrics.dart';
import 'app_icon.dart';

class AppMenuItem {
  const AppMenuItem({
    required this.label,
    required this.icon,
    required this.onSelected,
    this.danger = false,
    this.selected = false,
  });

  final String label;
  final String icon;
  final VoidCallback onSelected;
  final bool danger;

  /// Shows a check on the option the setting currently holds.
  final bool selected;
}

/// An anchored options panel (the prototype's popup menu).
Future<void> showActionMenu(
  BuildContext context,
  BuildContext anchorContext,
  List<AppMenuItem> items,
) {
  final renderObject = anchorContext.findRenderObject();
  final anchor = renderObject is RenderBox && renderObject.hasSize
      ? renderObject.localToGlobal(Offset.zero) & renderObject.size
      : Rect.zero;
  final width = _menuWidth(context, items);
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close menu',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 140),
    pageBuilder: (dialogContext, _, _) {
      return CustomSingleChildLayout(
        delegate: _MenuLayout(anchor: anchor, width: width),
        child: _MenuPanel(items: items),
      );
    },
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          alignment: Alignment.topRight,
          scale: Tween(begin: 0.94, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Width that fits the longest item on one line: panel padding, row padding,
/// icon and gap, plus the label.
double _menuWidth(BuildContext context, List<AppMenuItem> items) {
  final direction = Directionality.of(context);
  var widest = 0.0;
  for (final item in items) {
    final painter = TextPainter(
      text: TextSpan(
        text: item.label,
        style: AppType.button.copyWith(
          color: item.danger
              ? AppColors.of(context).danger
              : AppColors.of(context).text,
        ),
      ),
      maxLines: 1,
      textDirection: direction,
    )..layout();
    if (painter.width > widest) widest = painter.width;
  }
  return (widest + 18 + 10 + 24 + 12 + 22).clamp(180.0, 320.0);
}

class _MenuLayout extends SingleChildLayoutDelegate {
  _MenuLayout({required this.anchor, required this.width});

  final Rect anchor;
  final double width;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints(
        minWidth: width,
        maxWidth: width,
        maxHeight: constraints.maxHeight - 70,
      );

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    const pad = 8.0;
    const topSafe = 54.0;
    final bottomLimit = 96.0;
    var left = anchor.right - childSize.width;
    left = left.clamp(pad, size.width - childSize.width - pad);
    final below = anchor.bottom + 6;
    final above = anchor.top - childSize.height - 6;
    var top = below;
    if (below + childSize.height > size.height - bottomLimit && above > topSafe) {
      top = above;
    }
    top = top.clamp(topSafe, size.height - childSize.height - bottomLimit);
    return Offset(left, top);
  }

  @override
  bool shouldRelayout(_MenuLayout oldDelegate) =>
      oldDelegate.anchor != anchor || oldDelegate.width != width;
}

class _MenuPanel extends StatelessWidget {
  const _MenuPanel({required this.items});

  final List<AppMenuItem> items;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Material(
      color: colors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Metrics.rMd),
        side: BorderSide(color: colors.line),
      ),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final item in items)
              Semantics(
                button: true,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    item.onSelected();
                  },
                  borderRadius: BorderRadius.circular(Metrics.rSm),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          AppIcon(
                            item.icon,
                            size: 18,
                            color: item.danger ? colors.danger : colors.muted,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppType.button.copyWith(
                                color: item.danger
                                    ? colors.danger
                                    : item.selected
                                    ? colors.accentInk
                                    : colors.text,
                              ),
                            ),
                          ),
                          if (item.selected) ...[
                            const SizedBox(width: 10),
                            AppIcon('check', size: 16, color: colors.accent),
                          ],
                        ],
                      ),
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
