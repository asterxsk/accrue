import 'package:flutter/material.dart';

/// Colour tokens from the Habit Tracker prototype (Claude design system).
///
/// Light parchment is the default; dark is a separately tuned set. Widgets
/// read these through [AppColors.of] and never hard-code a colour.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.line,
    required this.hairline,
    required this.text,
    required this.muted,
    required this.faint,
    required this.accent,
    required this.accentInk,
    required this.accentOn,
    required this.accentSoft,
    required this.warn,
    required this.warnInk,
    required this.danger,
    required this.dangerOn,
    required this.actionBg,
    required this.actionFg,
    required this.actionHover,
    required this.track,
    required this.scrim,
    required this.focus,
    required this.shadow,
    required this.isDark,
  });

  /// App ground.
  final Color bg;

  /// Cards, rows, sheets, the nav pill.
  final Color surface;

  /// Raised controls, inactive dots, choice rows.
  final Color surface2;

  /// Hairlines and control outlines.
  final Color line;

  /// The softer edge used by cards.
  final Color hairline;

  /// Primary text.
  final Color text;

  /// Secondary text.
  final Color muted;

  /// Tertiary text and inactive glyphs.
  final Color faint;

  /// Clay fill: progress, checked rings, active accents.
  final Color accent;

  /// Clay used as text or icon on a surface.
  final Color accentInk;

  /// Text and glyphs on an accent fill.
  final Color accentOn;

  /// Tinted accent wash behind discs and selected rows.
  final Color accentSoft;

  /// Missed-streak warning text.
  final Color warn;

  /// Stronger warning text.
  final Color warnInk;

  /// Destructive actions.
  final Color danger;

  /// Text on a destructive fill.
  final Color dangerOn;

  /// Primary action fill (ink in light, paper in dark).
  final Color actionBg;

  /// Primary action label.
  final Color actionFg;

  final Color actionHover;

  /// Progress tracks and empty chart bars.
  final Color track;

  /// Dialog and sheet scrim.
  final Color scrim;

  /// Keyboard focus ring.
  final Color focus;

  /// Card lift; a hairline ring in dark mode.
  final BoxShadow shadow;

  final bool isDark;

  static const AppColors light = AppColors(
    bg: Color(0xFFF5F4ED),
    surface: Color(0xFFFAF9F5),
    surface2: Color(0xFFE8E6DC),
    line: Color(0xFFE8E6DC),
    hairline: Color(0xFFF0EEE6),
    text: Color(0xFF141413),
    muted: Color(0xFF5E5D59),
    faint: Color(0xFF87867F),
    accent: Color(0xFFC96442),
    accentInk: Color(0xFFA94E2E),
    accentOn: Color(0xFFFAF9F5),
    accentSoft: Color(0x1FC96442),
    warn: Color(0xFF9C6B23),
    warnInk: Color(0xFF8A5D1C),
    danger: Color(0xFF9E3B31),
    dangerOn: Color(0xFFFBF6F2),
    actionBg: Color(0xFF141413),
    actionFg: Color(0xFFFAF9F5),
    actionHover: Color(0xFF2B2B28),
    track: Color(0xFFE8E6DC),
    scrim: Color(0x4D141413),
    focus: Color(0xFF3898EC),
    shadow: BoxShadow(color: Color(0x0D000000), blurRadius: 24, offset: Offset(0, 4)),
    isDark: false,
  );

  static const AppColors dark = AppColors(
    bg: Color(0xFF141413),
    surface: Color(0xFF30302E),
    surface2: Color(0xFF3D3D3A),
    line: Color(0xFF3D3D3A),
    hairline: Color(0xFF30302E),
    text: Color(0xFFFAF9F5),
    muted: Color(0xFFB0AEA5),
    faint: Color(0xFFA5A49C),
    accent: Color(0xFFD97757),
    accentInk: Color(0xFFE89A7E),
    accentOn: Color(0xFF141413),
    accentSoft: Color(0x29D97757),
    warn: Color(0xFFE0A458),
    warnInk: Color(0xFFE6B271),
    danger: Color(0xFFE58A7A),
    dangerOn: Color(0xFF141413),
    actionBg: Color(0xFFFAF9F5),
    actionFg: Color(0xFF141413),
    actionHover: Color(0xFFE8E6DC),
    track: Color(0xFF3D3D3A),
    scrim: Color(0x99000000),
    focus: Color(0xFF8AB4D8),
    shadow: BoxShadow(color: Color(0xFF3D3D3A), spreadRadius: 1, blurRadius: 0),
    isDark: true,
  );

  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>() ?? light;

  @override
  AppColors copyWith({
    Color? bg,
    Color? surface,
    Color? surface2,
    Color? line,
    Color? hairline,
    Color? text,
    Color? muted,
    Color? faint,
    Color? accent,
    Color? accentInk,
    Color? accentOn,
    Color? accentSoft,
    Color? warn,
    Color? warnInk,
    Color? danger,
    Color? dangerOn,
    Color? actionBg,
    Color? actionFg,
    Color? actionHover,
    Color? track,
    Color? scrim,
    Color? focus,
    BoxShadow? shadow,
    bool? isDark,
  }) {
    return AppColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      line: line ?? this.line,
      hairline: hairline ?? this.hairline,
      text: text ?? this.text,
      muted: muted ?? this.muted,
      faint: faint ?? this.faint,
      accent: accent ?? this.accent,
      accentInk: accentInk ?? this.accentInk,
      accentOn: accentOn ?? this.accentOn,
      accentSoft: accentSoft ?? this.accentSoft,
      warn: warn ?? this.warn,
      warnInk: warnInk ?? this.warnInk,
      danger: danger ?? this.danger,
      dangerOn: dangerOn ?? this.dangerOn,
      actionBg: actionBg ?? this.actionBg,
      actionFg: actionFg ?? this.actionFg,
      actionHover: actionHover ?? this.actionHover,
      track: track ?? this.track,
      scrim: scrim ?? this.scrim,
      focus: focus ?? this.focus,
      shadow: shadow ?? this.shadow,
      isDark: isDark ?? this.isDark,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      line: Color.lerp(line, other.line, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      text: Color.lerp(text, other.text, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      faint: Color.lerp(faint, other.faint, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentInk: Color.lerp(accentInk, other.accentInk, t)!,
      accentOn: Color.lerp(accentOn, other.accentOn, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      warn: Color.lerp(warn, other.warn, t)!,
      warnInk: Color.lerp(warnInk, other.warnInk, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerOn: Color.lerp(dangerOn, other.dangerOn, t)!,
      actionBg: Color.lerp(actionBg, other.actionBg, t)!,
      actionFg: Color.lerp(actionFg, other.actionFg, t)!,
      actionHover: Color.lerp(actionHover, other.actionHover, t)!,
      track: Color.lerp(track, other.track, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      focus: Color.lerp(focus, other.focus, t)!,
      shadow: BoxShadow.lerp(shadow, other.shadow, t)!,
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}
