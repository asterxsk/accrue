import 'package:flutter/material.dart';

import '../app_nav.dart';
import '../state/habit_store.dart';
import '../theme/app_colors.dart';
import '../theme/metrics.dart';
import '../widgets/nav_pill.dart';
import 'insights_screen.dart';
import 'profile_screen.dart';
import 'routines_screen.dart';
import 'today_screen.dart';

/// The four tabbed screens plus the floating pill.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.store});

  final HabitStore store;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final nav = AppNavScope.of(context);
    return Scaffold(
      backgroundColor: colors.bg,
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(
              index: nav.index,
              children: [
                TodayScreen(store: store),
                InsightsScreen(store: store),
                RoutinesScreen(store: store),
                ProfileScreen(store: store),
              ],
            ),
          ),
          Positioned(
            left: Metrics.pillSide,
            right: Metrics.pillSide,
            bottom: Metrics.pillBottomInset(context),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: Metrics.maxAppWidth - Metrics.pillSide * 2,
                ),
                child: NavPill(index: nav.index, onSelect: nav.select),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
