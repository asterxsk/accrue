import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import 'icon_library.dart';

/// The prototype's inline icon set, drawn from the same 24pt stroke paths.
///
/// Icons inherit colour from the widget's [IconTheme] unless one is given.
class AppIcon extends StatelessWidget {
  const AppIcon(this.name, {super.key, this.size = 20, this.color});

  final String name;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolved =
        color ??
        IconTheme.of(context).color ??
        AppColors.of(context).muted;
    return SvgPicture.string(
      iconSvg(name),
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(resolved, BlendMode.srcIn),
    );
  }
}

/// Shared wrapper so every library icon inherits the same stroke treatment.
const String _lucideRoot =
    '<svg viewBox="0 0 24 24" fill="none" stroke="#000" stroke-width="1.7" '
    'stroke-linecap="round" stroke-linejoin="round">';

/// Resolves an icon name: the prototype's hand-tuned set first (it carries a
/// lighter stroke), then the full Lucide library, then a check mark.
String iconSvg(String name) {
  final custom = _icons[name];
  if (custom != null) return custom;
  final lucide = lucideIcons[name];
  if (lucide != null) return '$_lucideRoot$lucide</svg>';
  return _icons['check']!;
}

const Map<String, String> _icons = {
  'walk':
      '<svg viewBox="0 0 24 24" fill="none" stroke="#000" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M4 18h5M4 13h9M4 8h13"/><circle cx="17.5" cy="18" r="1.6"/></svg>',
  'book':
      '<svg viewBox="0 0 24 24" fill="none" stroke="#000" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M5 5.5A2.5 2.5 0 0 1 7.5 3H19v15.5H7.5A2.5 2.5 0 0 0 5 21Z"/><path d="M9 7.5h6"/></svg>',
  'water':
      '<svg viewBox="0 0 24 24" fill="none" stroke="#000" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M12 3.4c3.2 3.5 5.5 6.4 5.5 9.1a5.5 5.5 0 1 1-11 0c0-2.7 2.3-5.6 5.5-9.1Z"/></svg>',
  'timer':
      '<svg viewBox="0 0 24 24" fill="none" stroke="#000" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="8"/><path d="M12 8v4.3l2.6 1.6"/></svg>',
  'check':
      '<svg viewBox="0 0 24 24" fill="none" stroke="#000" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12.6l4.4 4.3L19 6.9"/></svg>',
  'plus':
      '<svg viewBox="0 0 24 24" fill="none" stroke="#000" stroke-width="1.8" stroke-linecap="round"><path d="M12 5v14M5 12h14"/></svg>',
  'minus':
      '<svg viewBox="0 0 24 24" fill="none" stroke="#000" stroke-width="1.8" stroke-linecap="round"><path d="M5 12h14"/></svg>',
  'back':
      '<svg viewBox="0 0 24 24" fill="none" stroke="#000" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M15 5l-7 7 7 7"/></svg>',
  'chevron':
      '<svg viewBox="0 0 24 24" fill="none" stroke="#000" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M9 5l7 7-7 7"/></svg>',
  'person':
      '<svg viewBox="0 0 24 24" fill="none" stroke="#000" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="8.4" r="3.6"/><path d="M4.8 20.2a7.2 7.2 0 0 1 14.4 0"/></svg>',
  'home':
      '<svg viewBox="0 0 24 24" fill="none" stroke="#000" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M4 10.6 12 4l8 6.6V20a1 1 0 0 1-1 1h-4.6v-6h-4.8v6H5a1 1 0 0 1-1-1Z"/></svg>',
  'chart':
      '<svg viewBox="0 0 24 24" fill="none" stroke="#000" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M4 20V4M4 20h16"/><path d="M8.5 16v-4.5M13 16V8M17.5 16v-6.5"/></svg>',
  'layers':
      '<svg viewBox="0 0 24 24" fill="none" stroke="#000" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="m12 3 8.5 4.6L12 12 3.5 7.6Z"/><path d="m4 12.4 8 4.3 8-4.3"/><path d="m4 16.9 8 4.3 8-4.3"/></svg>',
  'play':
      '<svg viewBox="0 0 24 24" fill="#000"><path d="M8.4 5.6a1 1 0 0 1 1.5-.86l8 6.4a1 1 0 0 1 0 1.72l-8 6.4a1 1 0 0 1-1.5-.86Z"/></svg>',
  'pause':
      '<svg viewBox="0 0 24 24" fill="#000"><rect x="7" y="5" width="3.6" height="14" rx="1.3"/><rect x="13.4" y="5" width="3.6" height="14" rx="1.3"/></svg>',
  'up':
      '<svg viewBox="0 0 24 24" fill="none" stroke="#000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 19V6M6.5 11.5 12 6l5.5 5.5"/></svg>',
  'down':
      '<svg viewBox="0 0 24 24" fill="none" stroke="#000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 5v13M6.5 12.5 12 18l5.5-5.5"/></svg>',
  'flat':
      '<svg viewBox="0 0 24 24" fill="none" stroke="#000" stroke-width="2" stroke-linecap="round"><path d="M6 12h12"/></svg>',
  'more':
      '<svg viewBox="0 0 24 24" fill="#000"><circle cx="12" cy="5.2" r="1.7"/><circle cx="12" cy="12" r="1.7"/><circle cx="12" cy="18.8" r="1.7"/></svg>',
  'pencil':
      '<svg viewBox="0 0 24 24" fill="none" stroke="#000" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M4.5 19.5h3.2L19 8.2a1.7 1.7 0 0 0 0-2.4l-.8-.8a1.7 1.7 0 0 0-2.4 0L4.5 16.3Z"/><path d="m14.8 6.9 2.3 2.3"/></svg>',
  'trash':
      '<svg viewBox="0 0 24 24" fill="none" stroke="#000" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M4.5 6.5h15M9.5 6.5V4.8a1 1 0 0 1 1-1h3a1 1 0 0 1 1 1v1.7M6.5 6.5l.8 12.2a1.6 1.6 0 0 0 1.6 1.5h6.2a1.6 1.6 0 0 0 1.6-1.5l.8-12.2"/></svg>',
  // Not in the prototype's table (it fell back to a check); a moon belongs on
  // "Sleep by 11", so it is drawn here in the same grid.
  'moon':
      '<svg viewBox="0 0 24 24" fill="none" stroke="#000" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M12 3a9 9 0 1 0 9 9 7 7 0 0 1-9-9Z"/></svg>',
};
