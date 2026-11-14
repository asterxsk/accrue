import 'package:flutter/material.dart';

import '../app_nav.dart';
import '../state/habit_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_type.dart';
import '../theme/metrics.dart';
import '../util/format.dart';
import '../util/share.dart';
import '../widgets/dialogs.dart';
import '../widgets/ui.dart';
import 'about_screen.dart';
import 'distracting_apps_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.store});

  final HabitStore store;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  /// Which inline select is open: 'appearance', 'week' or null.
  String? _open;

  HabitStore get store => widget.store;

  String get _themeLabel => store.themeLabel;

  String get _weekLabel => store.weekStartsMonday ? 'Monday' : 'Sunday';

  void _toggle(String key) {
    setState(() => _open = _open == key ? null : key);
  }

  Future<void> _share(BuildContext context) async {
    final outcome = await shareDialog(context, store);
    if (outcome != ShareOutcome.copied || !context.mounted) return;
    // Only reached where no native share target exists.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Caption copied')));
  }

  Future<void> _editName(BuildContext context) async {
    final picked = await editProfileDialog(
      context,
      name: store.profileName,
    );
    if (picked != null) store.setProfileName(picked);
  }

  Future<void> _data(BuildContext context) async {
    final choice = await dataDialog(context);
    if (choice == null || !context.mounted) return;
    switch (choice) {
      case DataChoice.clearAll:
        final confirmed = await confirmDialog(
          context,
          title: 'Clear habits & history?',
          body:
              'Habits, routines and their records are removed from this '
              'device. Your profile and settings stay. This cannot be undone.',
          confirmLabel: 'Clear all',
          danger: true,
        );
        if (!confirmed) return;
        store.clearAll();
        if (context.mounted) AppNavScope.of(context).select(0);
      case DataChoice.resetApp:
        final confirmed = await confirmDialog(
          context,
          title: 'Reset the app?',
          body:
              'Habits, routines, history and your profile are removed, and '
              'setup starts again from the beginning. This cannot be undone.',
          confirmLabel: 'Reset app',
          danger: true,
        );
        if (!confirmed) return;
        store.resetApp();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final name = store.profileName.isEmpty ? 'You' : store.profileName;

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: screenPadding(context, topLevel: true),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HeaderBlock(eyebrow: 'Local profile', title: 'Profile'),
              const SizedBox(height: 20),
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Avatar(name: name, size: 52),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.headTitle.copyWith(
                              color: colors.text,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Local profile · nothing syncs, nothing leaves.',
                            style: AppType.meta.copyWith(
                              color: colors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _EditPill(onTap: () => _editName(context)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              AppButton(
                label: 'Share stats',
                tone: AppButtonTone.secondary,
                expand: true,
                onPressed: () => _share(context),
              ),
              const SizedBox(height: 4),
              _GroupLabel('Appearance', colors: colors),
              SettingsSelect(
                label: 'Appearance',
                options: const ['System', 'Light', 'Dark'],
                selected: _themeLabel,
                expanded: _open == 'appearance',
                onToggle: () => _toggle('appearance'),
                onSelected: (picked) {
                  store.setThemeMode(switch (picked) {
                    'Light' => ThemeMode.light,
                    'Dark' => ThemeMode.dark,
                    _ => ThemeMode.system,
                  });
                  _toggle('appearance');
                },
              ),
              _GroupLabel('Reminders', colors: colors),
              SettingsRow(
                label: 'Reminders',
                showChevron: false,
                trailing: AppSwitch(
                  value: store.remindersOn,
                  onChanged: store.setReminders,
                ),
              ),
              SettingsRow(
                label: 'Reminder time',
                value: Fmt.time(store.reminderHour, store.reminderMinute),
                onTap: () async {
                  final picked = await timeDialog(
                    context,
                    hour: store.reminderHour,
                    minute: store.reminderMinute,
                  );
                  if (picked != null) {
                    store.setReminderTime(picked.hour, picked.minute);
                  }
                },
              ),
              SettingsSelect(
                label: 'Start week on',
                options: const ['Monday', 'Sunday'],
                selected: _weekLabel,
                expanded: _open == 'week',
                onToggle: () => _toggle('week'),
                onSelected: (picked) {
                  store.setWeekStartsMonday(picked == 'Monday');
                  _toggle('week');
                },
              ),
              _GroupLabel('Focus', colors: colors),
              SettingsRow(
                label: 'Distracting apps',
                value: store.blockedApps.isEmpty
                    ? 'Off'
                    : '${store.blockedApps.length}',
                onTap: () => openDistractingApps(context, store),
              ),
              _GroupLabel('Data', colors: colors),
              SettingsRow(
                label: 'Data & export',
                onTap: () => _data(context),
              ),
              _GroupLabel('About', colors: colors),
              SettingsRow(
                label: 'About',
                value: 'v$appVersion',
                onTap: () => openAbout(context),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text, {required this.colors});

  final String text;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 26, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: AppType.eyebrow.copyWith(color: colors.muted),
      ),
    );
  }
}

/// Small filled pill on the profile card, so renaming lives with the name.
class _EditPill extends StatelessWidget {
  const _EditPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Semantics(
      button: true,
      label: 'Edit name',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: Metrics.touch),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.accentSoft,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'Edit',
            style: AppType.metaStrong.copyWith(
              fontSize: 13,
              color: colors.accentInk,
            ),
          ),
        ),
      ),
    );
  }
}
