import 'package:flutter/material.dart';

import '../state/habit_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_type.dart';
import '../theme/metrics.dart';
import '../util/focus.dart';
import '../widgets/dialogs.dart';
import '../widgets/ui.dart';

Future<void> openDistractingApps(
  BuildContext context,
  HabitStore store,
) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => DistractingAppsScreen(store: store),
    ),
  );
}

/// Choose the apps that a running focus timer covers. The first choice asks
/// for Android's accessibility access, which is what draws the overlay.
class DistractingAppsScreen extends StatefulWidget {
  const DistractingAppsScreen({super.key, required this.store});

  final HabitStore store;

  @override
  State<DistractingAppsScreen> createState() => _DistractingAppsScreenState();
}

class _DistractingAppsScreenState extends State<DistractingAppsScreen>
    with WidgetsBindingObserver {
  final _search = TextEditingController();
  InstalledApp? _pending;
  String _query = '';
  bool _supported = true;
  bool _enabled = false;
  bool _loading = true;
  List<InstalledApp> _apps = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _search.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshPermission();
  }

  /// Coming back from Android's accessibility settings: adopt the grant and
  /// apply the switch the user was reaching for.
  Future<void> _refreshPermission() async {
    final enabled = await FocusBlocking.enabled;
    if (!mounted) return;
    final pending = _pending;
    setState(() {
      _enabled = enabled;
      _pending = null;
    });
    if (enabled && pending != null) {
      widget.store.toggleBlockedApp(pending.package);
    }
  }

  Future<void> _load() async {
    final supported = await FocusBlocking.supported;
    final enabled = supported && await FocusBlocking.enabled;
    final List<InstalledApp> apps = supported
        ? await FocusBlocking.installedApps()
        : const [];
    apps.sort(
      (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
    );
    if (!mounted) return;
    setState(() {
      _supported = supported;
      _enabled = enabled;
      _apps = apps;
      _loading = false;
    });
  }

  Future<void> _enableAccess() async {
    final granted = await confirmDialog(
      context,
      title: 'Allow focus blocking?',
      body:
          'Accrue uses Android accessibility access for one thing: '
          'drawing a blocked screen over the apps you pick while a focus '
          'timer runs.\n\n'
          'It cannot read screen content, keystrokes or text — the service is '
          'declared without window-content access. Turn it off at any time in '
          'Android Settings → Accessibility.',
      confirmLabel: 'Open settings',
    );
    if (!granted) return;
    await FocusBlocking.openSettings();
  }

  Future<void> _toggle(InstalledApp app) async {
    if (!_enabled) {
      _pending = app;
      await _enableAccess();
      return;
    }
    widget.store.toggleBlockedApp(app.package);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final gutters = EdgeInsets.symmetric(horizontal: Metrics.gutter);
    final query = _query.trim().toLowerCase();
    final visible = query.isEmpty
        ? _apps
        : _apps
              .where(
                (app) =>
                    app.label.toLowerCase().contains(query) ||
                    app.package.toLowerCase().contains(query),
              )
              .toList();
    final blocked = widget.store.blockedApps;

    return Scaffold(
      backgroundColor: colors.bg,
      body: Padding(
        padding: EdgeInsets.only(top: Metrics.topInset(context)),
        child: Column(
          children: [
            Padding(
              padding: gutters,
              child: HeadBar(
                onBack: () => Navigator.of(context).maybePop(),
                center: 'Distracting apps',
              ),
            ),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: gutters.copyWith(top: 6),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _AccessCard(
                            supported: _supported,
                            enabled: _enabled,
                            blockedCount: blocked.length,
                            onEnable: _enableAccess,
                          ),
                          const SizedBox(height: 18),
                          if (_supported && _apps.isNotEmpty)
                            LabeledField(
                              label: 'Apps',
                              controller: _search,
                              hint: 'Instagram, YouTube, games…',
                              onChanged: (value) =>
                                  setState(() => _query = value),
                            ),
                          const SizedBox(height: 6),
                          Text(
                            'While a timed habit is running, these apps show '
                            'the blocked screen instead. Opening Accrue '
                            'lifts it; the timer keeps counting.',
                            style: AppType.micro.copyWith(color: colors.faint),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: gutters.copyWith(top: 8, bottom: 30),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (_loading) return const SizedBox.shrink();
                          if (!_supported) return const SizedBox.shrink();
                          if (visible.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Text(
                                _apps.isEmpty
                                    ? 'No launchable apps found.'
                                    : 'No apps match “${_query.trim()}”.',
                                style: AppType.meta.copyWith(
                                  color: colors.muted,
                                ),
                              ),
                            );
                          }
                          final app = visible[index];
                          return SettingsRow(
                            label: app.label,
                            showChevron: false,
                            onTap: () => _toggle(app),
                            trailing: AppSwitch(
                              value: blocked.contains(app.package),
                              onChanged: (_) => _toggle(app),
                            ),
                          );
                        },
                        childCount: _loading || !_supported
                            ? 0
                            : (visible.isEmpty ? 1 : visible.length),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccessCard extends StatelessWidget {
  const _AccessCard({
    required this.supported,
    required this.enabled,
    required this.blockedCount,
    required this.onEnable,
  });

  final bool supported;
  final bool enabled;
  final int blockedCount;
  final VoidCallback onEnable;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final String title;
    final String body;
    if (!supported) {
      title = 'Android only';
      body =
          'Focus blocking draws an Android system overlay, so it is available '
          'in the phone build only.';
    } else if (enabled) {
      title = 'Focus access is on';
      body = blockedCount == 0
          ? 'Pick the apps below. Each one shows the blocked screen while a '
                'timer runs.'
          : '$blockedCount ${blockedCount == 1 ? 'app is' : 'apps are'} covered '
                'while a focus timer runs.';
    } else {
      title = 'Focus access is off';
      body =
          'Blocking needs Android accessibility access. It is used only to '
          'draw the blocked screen over the apps you pick — never to read '
          'what is on screen.';
    }
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppType.bodyStrong.copyWith(color: colors.text),
          ),
          const SizedBox(height: 4),
          Text(body, style: AppType.meta.copyWith(color: colors.muted)),
          if (supported && !enabled) ...[
            const SizedBox(height: 12),
            AppButton(
              label: 'Enable focus access',
              tone: AppButtonTone.secondary,
              height: 44,
              onPressed: onEnable,
            ),
          ],
        ],
      ),
    );
  }
}
