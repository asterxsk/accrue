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

/// The four tabbed screens, swipeable left and right, plus the floating pill.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.store});

  final HabitStore store;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final PageController _pages = PageController();
  AppNav? _nav;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nav = AppNavScope.of(context);
    if (identical(_nav, nav)) return;
    _nav?.removeListener(_onNavChanged);
    _nav = nav;
    nav.addListener(_onNavChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pages.hasClients) return;
      _pages.jumpToPage(nav.index.clamp(0, 3));
    });
  }

  /// The pill and a push route both select through [AppNav]; the page view
  /// follows it with the same animation a swipe uses.
  void _onNavChanged() {
    final nav = _nav;
    if (nav == null || !_pages.hasClients) return;
    final current = (_pages.page ?? _pages.initialPage.toDouble()).round();
    if (current == nav.index) return;
    _pages.animateToPage(
      nav.index.clamp(0, 3),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _nav?.removeListener(_onNavChanged);
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final nav = AppNavScope.of(context);
    return Scaffold(
      backgroundColor: colors.bg,
      body: Stack(
        children: [
          Positioned.fill(
            child: PageView(
              controller: _pages,
              onPageChanged: nav.select,
              physics: const PageScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              children: [
                _KeepAlivePage(child: TodayScreen(store: widget.store)),
                _KeepAlivePage(child: InsightsScreen(store: widget.store)),
                _KeepAlivePage(child: RoutinesScreen(store: widget.store)),
                _KeepAlivePage(child: ProfileScreen(store: widget.store)),
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

/// Keeps a tab's scroll position and local state while another tab is shown.
class _KeepAlivePage extends StatefulWidget {
  const _KeepAlivePage({required this.child});

  final Widget child;

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
