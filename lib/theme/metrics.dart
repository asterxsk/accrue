import 'package:flutter/material.dart';

/// Layout constants from the Habit Tracker prototype.
///
/// The prototype is a 412 x 915 handset; the app caps its content at 430 and
/// centres it on wider surfaces.
class Metrics {
  const Metrics._();

  /// Side gutter on every screen.
  static const double gutter = 20;

  /// Narrower gutter under 340 logical pixels.
  static const double narrowGutter = 16;

  /// Phone content is capped at this width.
  static const double maxAppWidth = 430;

  /// Radii: controls, cards, sheets.
  static const double rSm = 8;
  static const double rMd = 12;
  static const double rLg = 16;

  /// Minimum hit target.
  static const double touch = 44;

  /// Habit row box.
  static const double habitRow = 68;

  /// Floating tab pill: nearly edge to edge, with a small side margin.
  static const double pillHeight = 78;
  static const double pillButtonHeight = 64;
  static const double pillSide = 12;

  /// Space a scrolling top-level screen keeps clear for the pill.
  static const double pillClearance = 124;

  /// Screen header padding above the eyebrow.
  static const double headerTop = 6;

  /// Pushed-screen head bar.
  static const double headBar = 52;

  /// Primary/secondary button height.
  static const double button = 48;

  /// The status bar area never collapses: on hosts without one (web, desktop)
  /// the same inset keeps every screen's rhythm.
  static const double minTopInset = 44;

  /// Resolved top inset.
  static double topInset(BuildContext context) {
    final padding = MediaQuery.paddingOf(context).top;
    return padding > minTopInset ? padding : minTopInset;
  }

  /// Bottom safe inset with a floor, so the pill keeps its lift on hosts
  /// without a home indicator.
  static double bottomInset(BuildContext context) =>
      MediaQuery.paddingOf(context).bottom + 16;

  /// The pill sits closer to the edge than screen footers do: the safe-area
  /// inset carries the clearance, so only a sliver is added on top of it.
  static double pillBottomInset(BuildContext context) =>
      MediaQuery.paddingOf(context).bottom + 6;

  /// Side gutter for the current width.
  static double gutterFor(double width) =>
      width < 340 ? narrowGutter : gutter;
}
