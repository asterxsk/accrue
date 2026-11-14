import 'package:flutter/material.dart';

import '../models/habit.dart';
import 'app_icon.dart';

/// Parses "#RRGGBB". Anything unreadable falls back to [fallback].
Color hexColor(String value, Color fallback) {
  final hex = value.replaceFirst('#', '');
  if (hex.length != 6) return fallback;
  final parsed = int.tryParse(hex, radix: 16);
  if (parsed == null) return fallback;
  return Color(0xFF000000 | parsed);
}

/// The accent a habit's progress should use: the theme's clay, unless the
/// habit carries a badge — then its gradient start colour, so the ring around
/// a blue "WA" badge is blue too.
Color markAccent(Habit habit, Color fallback) =>
    habit.badge ? hexColor(habit.badgeStart, fallback) : fallback;

/// The habit's mark: either an icon from the library or a short text badge on
/// a gradient. Shared by rows, the detail disc, routine steps and the picker.
///
/// Pass [habit] to render a stored habit, or the parts directly for a preview.
class HabitMark extends StatelessWidget {
  const HabitMark({
    super.key,
    this.habit,
    this.badge = false,
    this.icon = 'check',
    this.badgeText = '',
    this.badgeFg = '#FAF9F5',
    this.badgeStart = '#C96442',
    this.badgeEnd = '#A94E2E',
    this.size = 40,
    this.iconSize = 18,
    this.iconColor,
  });

  final Habit? habit;
  final bool badge;
  final String icon;
  final String badgeText;
  final String badgeFg;
  final String badgeStart;
  final String badgeEnd;
  final double size;
  final double iconSize;
  final Color? iconColor;

  bool get _isBadge => habit?.badge ?? badge;
  String get _text => (habit?.badgeText ?? badgeText).toUpperCase();
  String get _fg => habit?.badgeFg ?? badgeFg;
  String get _start => habit?.badgeStart ?? badgeStart;
  String get _end => habit?.badgeEnd ?? badgeEnd;

  @override
  Widget build(BuildContext context) {
    if (!_isBadge) {
      return AppIcon(
        habit?.icon ?? icon,
        size: iconSize,
        color: iconColor,
      );
    }
    final letters = _text.length > 2 ? _text.substring(0, 2) : _text;
    final start = hexColor(_start, const Color(0xFFC96442));
    final end = hexColor(_end, start);
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [start, end],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Text(
            letters.isEmpty ? '·' : letters,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: size * 0.36,
              height: 1,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              color: hexColor(_fg, Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
