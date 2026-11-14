import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_nav.dart';
import 'screens/home_shell.dart';
import 'screens/onboarding_screen.dart';
import 'state/habit_store.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'theme/metrics.dart';

/// Owns the store, the tab selection, the theme mode and the timer tick.
class HabitApp extends StatefulWidget {
  const HabitApp({super.key, required this.store});

  final HabitStore store;

  @override
  State<HabitApp> createState() => _HabitAppState();
}

class _HabitAppState extends State<HabitApp> with WidgetsBindingObserver {
  final AppNav _nav = AppNav();
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.store.addListener(_syncTicker);
    _syncTicker();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        widget.store.ensureToday();
      case AppLifecycleState.paused:
        // No ticks run in the background; put the logged seconds on disk.
        widget.store.persistNow();
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  /// A running timer needs one tick a second anywhere in the app. The ticker
  /// only exists while a timer runs.
  void _syncTicker() {
    final running = widget.store.runningHabitId != null;
    if (running && _ticker == null) {
      _ticker = Timer.periodic(
        const Duration(seconds: 1),
        (_) => widget.store.tickTimer(),
      );
    } else if (!running && _ticker != null) {
      _ticker!.cancel();
      _ticker = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.store.removeListener(_syncTicker);
    _ticker?.cancel();
    _nav.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final dark = switch (widget.store.themeMode) {
          ThemeMode.dark => true,
          ThemeMode.light => false,
          ThemeMode.system =>
            WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark,
        };
        final colors = dark ? AppColors.dark : AppColors.light;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
            statusBarBrightness: dark ? Brightness.dark : Brightness.light,
            systemNavigationBarColor: colors.bg,
            systemNavigationBarIconBrightness: dark
                ? Brightness.light
                : Brightness.dark,
          ),
          child: MaterialApp(
            title: 'Accrue',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: widget.store.themeMode,
            home: widget.store.onboarded
                ? HomeShell(store: widget.store)
                : OnboardingScreen(store: widget.store),
            builder: (context, child) {
              return ColoredBox(
                color: AppColors.of(context).bg,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: Metrics.maxAppWidth,
                    ),
                    child: AppNavScope(
                      nav: _nav,
                      child: child ?? const SizedBox.shrink(),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
