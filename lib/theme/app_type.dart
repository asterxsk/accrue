import 'package:flutter/material.dart';

/// Type scale for Accrue, from the Claude design prototype.
///
/// Source Serif 4 at 500 for display lines, Inter for the interface. Numbers
/// that change (counts, timers, percentages) use tabular figures.
class AppType {
  const AppType._();

  static const String ui = 'Inter';
  static const String serifFamily = 'Source Serif 4';

  static const List<FontVariation> _serif500 = [FontVariation('wght', 500)];
  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  // ------------------------------------------------------------- interface

  /// 11/1.4 uppercase label above a title or inside a card.
  static const TextStyle eyebrow = TextStyle(
    fontFamily: ui,
    fontSize: 11,
    height: 1.4,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.1,
    color: Colors.black87,
  );

  /// 13/1.4 uppercase section title.
  static const TextStyle sectionTitle = TextStyle(
    fontFamily: ui,
    fontSize: 13,
    height: 1.35,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.78,
  );

  static const TextStyle body = TextStyle(
    fontFamily: ui,
    fontSize: 15,
    height: 1.45,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle bodyStrong = TextStyle(
    fontFamily: ui,
    fontSize: 15,
    height: 1.45,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle meta = TextStyle(
    fontFamily: ui,
    fontSize: 13,
    height: 1.35,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle metaStrong = TextStyle(
    fontFamily: ui,
    fontSize: 13,
    height: 1.35,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle micro = TextStyle(
    fontFamily: ui,
    fontSize: 12,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: ui,
    fontSize: 11,
    height: 1.18,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.11,
  );

  static const TextStyle field = TextStyle(
    fontFamily: ui,
    fontSize: 16,
    height: 1.4,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle button = TextStyle(
    fontFamily: ui,
    fontSize: 15,
    height: 1.2,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle habitName = TextStyle(
    fontFamily: ui,
    fontSize: 16,
    height: 1.3,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle habitSub = TextStyle(
    fontFamily: ui,
    fontSize: 13,
    height: 1.35,
    fontWeight: FontWeight.w400,
    fontFeatures: _tabular,
  );

  static const TextStyle count = TextStyle(
    fontFamily: ui,
    fontSize: 16,
    height: 1.2,
    fontWeight: FontWeight.w600,
    fontFeatures: _tabular,
  );

  static const TextStyle axis = TextStyle(
    fontFamily: ui,
    fontSize: 10,
    height: 1.2,
    fontWeight: FontWeight.w400,
    fontFeatures: _tabular,
  );

  // ---------------------------------------------------------------- display

  /// 30/1.14 screen title.
  static const TextStyle title = TextStyle(
    fontFamily: serifFamily,
    fontSize: 30,
    height: 1.14,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.3,
    fontVariations: _serif500,
  );

  /// 32/1.14 empty-state headline.
  static const TextStyle emptyTitle = TextStyle(
    fontFamily: serifFamily,
    fontSize: 32,
    height: 1.14,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.32,
    fontVariations: _serif500,
  );

  /// 28/1.2 detail name.
  static const TextStyle displayName = TextStyle(
    fontFamily: serifFamily,
    fontSize: 28,
    height: 1.2,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.28,
    fontVariations: _serif500,
  );

  /// 24/1.25 step name.
  static const TextStyle stepName = TextStyle(
    fontFamily: serifFamily,
    fontSize: 24,
    height: 1.25,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.24,
    fontVariations: _serif500,
  );

  /// 22/1.27 dialog and sheet title.
  static const TextStyle dialogTitle = TextStyle(
    fontFamily: serifFamily,
    fontSize: 22,
    height: 1.27,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.22,
    fontVariations: _serif500,
  );

  /// 19/1.3 centred page title and profile name.
  static const TextStyle headTitle = TextStyle(
    fontFamily: serifFamily,
    fontSize: 19,
    height: 1.3,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.1,
    fontVariations: _serif500,
  );

  /// 17/1.3 muted timer name.
  static const TextStyle timerName = TextStyle(
    fontFamily: serifFamily,
    fontSize: 17,
    height: 1.3,
    fontWeight: FontWeight.w500,
    fontVariations: _serif500,
  );

  /// 56/1 count on the counter screen.
  static const TextStyle bigCount = TextStyle(
    fontFamily: ui,
    fontSize: 56,
    height: 1,
    fontWeight: FontWeight.w500,
    letterSpacing: -1.68,
    fontFeatures: _tabular,
  );

  /// 22/1.1 counter denominator.
  static const TextStyle bigCountDenom = TextStyle(
    fontFamily: ui,
    fontSize: 22,
    height: 1.1,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.22,
  );

  /// 52/1 insights hero percentage.
  static const TextStyle bigStat = TextStyle(
    fontFamily: ui,
    fontSize: 52,
    height: 1,
    fontWeight: FontWeight.w500,
    letterSpacing: -1.56,
    fontFeatures: _tabular,
  );

  /// 24/1.1 the "%" after the hero percentage.
  static const TextStyle bigStatSuffix = TextStyle(
    fontFamily: ui,
    fontSize: 24,
    height: 1.1,
    fontWeight: FontWeight.w500,
  );

  /// 34/1.15 timer clock.
  static const TextStyle timerClock = TextStyle(
    fontFamily: ui,
    fontSize: 34,
    height: 1.15,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.68,
    fontFeatures: _tabular,
  );

  /// 30/1.15 today's stat line.
  static const TextStyle statLine = TextStyle(
    fontFamily: ui,
    fontSize: 30,
    height: 1.15,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.6,
    fontFeatures: _tabular,
  );

  /// 20/1.2 today's percentage.
  static const TextStyle statPct = TextStyle(
    fontFamily: ui,
    fontSize: 20,
    height: 1.2,
    fontWeight: FontWeight.w600,
    fontFeatures: _tabular,
  );

  /// 22/1.2 streak number.
  static const TextStyle streakNumber = TextStyle(
    fontFamily: ui,
    fontSize: 22,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.22,
    fontFeatures: _tabular,
  );
}
