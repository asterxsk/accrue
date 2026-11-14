import 'package:flutter/cupertino.dart' as cupertino;
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_type.dart';

/// Theme built from the prototype's two token sets. Light is the default.
class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(AppColors.light, Brightness.light);

  static ThemeData dark() => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors colors, Brightness brightness) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: colors.bg,
      canvasColor: colors.bg,
      splashFactory: InkSparkle.splashFactory,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.accent,
        brightness: brightness,
        surface: colors.surface,
        primary: colors.accent,
        onPrimary: colors.accentOn,
        error: colors.danger,
      ),
      fontFamily: AppType.ui,
    );

    final textTheme = base.textTheme.copyWith(
      displayLarge: AppType.title.copyWith(color: colors.text),
      headlineLarge: AppType.title.copyWith(color: colors.text),
      headlineMedium: AppType.displayName.copyWith(color: colors.text),
      titleMedium: AppType.habitName.copyWith(color: colors.text),
      bodyLarge: AppType.body.copyWith(color: colors.text),
      bodyMedium: AppType.meta.copyWith(color: colors.muted),
      bodySmall: AppType.micro.copyWith(color: colors.muted),
      labelLarge: AppType.button.copyWith(color: colors.text),
      labelMedium: AppType.meta.copyWith(color: colors.muted),
      labelSmall: AppType.labelSmall.copyWith(color: colors.muted),
    );

    return base.copyWith(
      extensions: [colors],
      textTheme: textTheme,
      dividerTheme: DividerThemeData(color: colors.line, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: colors.muted),
      // The prototype has no grey Material hover/press wash: interaction is
      // shown with a faint clay tint instead.
      hoverColor: Colors.transparent,
      highlightColor: colors.accentSoft,
      splashColor: colors.accentSoft,
      focusColor: colors.accentSoft,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colors.accent,
        selectionColor: colors.accent.withValues(alpha: 0.22),
        selectionHandleColor: colors.accent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.line),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.actionBg,
        contentTextStyle: AppType.body.copyWith(color: colors.actionFg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _FadeSlideTransitionBuilder(),
          TargetPlatform.iOS: cupertino.CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: cupertino.CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: _FadeSlideTransitionBuilder(),
          TargetPlatform.linux: _FadeSlideTransitionBuilder(),
          TargetPlatform.fuchsia: _FadeSlideTransitionBuilder(),
        },
      ),
    );
  }
}

/// A short fade with a 12pt rise: pushed screens are the same surface with a
/// back button, so the move reads as a page swap, not an effect.
class _FadeSlideTransitionBuilder extends PageTransitionsBuilder {
  const _FadeSlideTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.015),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
