import 'package:flutter/material.dart';

import '../state/habit_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_type.dart';
import '../theme/metrics.dart';
import '../util/share.dart';
import '../widgets/dialogs.dart';
import '../widgets/popup_menu.dart';
import '../widgets/ui.dart';
import 'about_screen.dart';
import 'data_export_screen.dart';
import 'distracting_apps_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.store});

  final HabitStore store;

  Future<void> _share(BuildContext context) async {
    final outcome = await shareDialog(context, store);
    if (outcome != ShareOutcome.copied || !context.mounted) return;
    // Only reached where no native share target exists.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Caption copied')));
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final name = store.profileName.isEmpty ? 'You' : store.profileName;
        final bio = store.profileBio.isEmpty
            ? 'Local profile · nothing syncs, nothing leaves.'
            : store.profileBio;

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
                    Avatar(name: name, size: 52, photo: store.profilePhoto),
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
                            bio,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.meta.copyWith(color: colors.muted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _EditPill(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => EditProfileScreen(store: store),
                        ),
                      ),
                    ),
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
              Builder(
                builder: (rowContext) => SettingsRow(
                  label: 'Appearance',
                  value: store.themeLabel,
                  onTap: () => showActionMenu(context, rowContext, [
                    for (final (label, icon, mode) in const [
                      ('System', 'monitor', ThemeMode.system),
                      ('Light', 'sun', ThemeMode.light),
                      ('Dark', 'moon', ThemeMode.dark),
                    ])
                      AppMenuItem(
                        label: label,
                        icon: icon,
                        selected: store.themeLabel == label,
                        onSelected: () => store.setThemeMode(mode),
                      ),
                  ]),
                ),
              ),
              Builder(
                builder: (rowContext) => SettingsRow(
                  label: 'Start week on',
                  value: store.weekStartsMonday ? 'Monday' : 'Sunday',
                  onTap: () => showActionMenu(context, rowContext, [
                    for (final (label, monday) in const [
                      ('Monday', true),
                      ('Sunday', false),
                    ])
                      AppMenuItem(
                        label: label,
                        icon: 'calendar',
                        selected: store.weekStartsMonday == monday,
                        onSelected: () => store.setWeekStartsMonday(monday),
                      ),
                  ]),
                ),
              ),
              Builder(
                builder: (rowContext) => SettingsRow(
                  label: 'Time format',
                  value: store.clockLabel,
                  onTap: () => showActionMenu(context, rowContext, [
                    for (final (label, as24) in const [
                      ('24-hour', true),
                      ('12-hour', false),
                    ])
                      AppMenuItem(
                        label: label,
                        icon: 'clock',
                        selected: store.clock24 == as24,
                        onSelected: () => store.setClock24(as24),
                      ),
                  ]),
                ),
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
                onTap: () => openDataExport(context, store),
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

/// Small filled pill on the profile card, so editing lives with the profile.
class _EditPill extends StatelessWidget {
  const _EditPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Semantics(
      button: true,
      label: 'Edit profile',
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
