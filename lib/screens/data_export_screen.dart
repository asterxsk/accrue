import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../app_nav.dart';
import '../state/habit_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_type.dart';
import '../theme/metrics.dart';
import '../util/format.dart';
import '../widgets/dialogs.dart';
import '../widgets/ui.dart';

Future<void> openDataExport(BuildContext context, HabitStore store) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => DataExportScreen(store: store)),
  );
}

/// Full-page backup and clearing controls: export a JSON file, import one
/// back, or start over.
class DataExportScreen extends StatelessWidget {
  const DataExportScreen({super.key, required this.store});

  final HabitStore store;

  Future<void> _export(BuildContext context) async {
    final json = store.exportJson();
    final fileName = 'accrue-backup-${Fmt.dateKey(DateTime.now())}.json';
    try {
      final saved = await FilePicker.saveFile(
        fileName: fileName,
        bytes: Uint8List.fromList(utf8.encode(json)),
        mimeType: 'application/json',
        dialogTitle: 'Save backup',
      );
      if (!context.mounted || saved == null) return;
      await infoDialog(
        context,
        title: 'Exported',
        body: 'Backup exported. The file is where you saved it.',
      );
    } catch (_) {
      if (!context.mounted) return;
      await infoDialog(
        context,
        title: 'Could not export',
        body: 'The backup could not be saved.',
      );
    }
  }

  Future<void> _import(BuildContext context) async {
    final confirmed = await confirmDialog(
      context,
      title: 'Replace this device\'s data?',
      body:
          'The backup replaces every habit, routine, day of history, your '
          'profile and settings. Current data cannot be recovered. This '
          'cannot be undone.',
      confirmLabel: 'Choose file',
      danger: true,
    );
    if (!confirmed || !context.mounted) return;
    try {
      // Any file: Android's storage picker reports a saved .json as an unknown
      // type and then refuses to hand it over, so the picker stays unfiltered
      // and importJson validates what comes back.
      final file = await FilePicker.pickFile(
        type: FileType.any,
        dialogTitle: 'Choose a backup',
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final result = store.importJson(utf8.decode(bytes));
      if (!context.mounted) return;
      await infoDialog(
        context,
        title: result.ok ? 'Imported' : 'Could not import',
        body: result.message,
      );
    } catch (_) {
      if (!context.mounted) return;
      await infoDialog(
        context,
        title: 'Could not import',
        body: 'That backup could not be read.',
      );
    }
  }

  Future<void> _clearAll(BuildContext context) async {
    final confirmed = await confirmDialog(
      context,
      title: 'Clear habits & history?',
      body:
          'Habits, routines and their records are removed from this device. '
          'Your profile and settings stay. This cannot be undone.',
      confirmLabel: 'Clear all',
      danger: true,
    );
    if (!confirmed || !context.mounted) return;
    final nav = AppNavScope.of(context);
    store.clearAll();
    Navigator.of(context).pop();
    nav.select(0);
  }

  Future<void> _resetApp(BuildContext context) async {
    final confirmed = await confirmDialog(
      context,
      title: 'Reset the app?',
      body:
          'Habits, routines, history and your profile are removed, and setup '
          'starts again from the beginning. This cannot be undone.',
      confirmLabel: 'Reset app',
      danger: true,
    );
    if (!confirmed || !context.mounted) return;
    final nav = AppNavScope.of(context);
    store.resetApp();
    Navigator.of(context).pop();
    nav.select(0);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final empty = store.habits.isEmpty;
    return Scaffold(
      backgroundColor: colors.bg,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          Metrics.gutter,
          Metrics.topInset(context),
          Metrics.gutter,
          Metrics.bottomInset(context) + 30,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HeadBar(
              onBack: () => Navigator.of(context).maybePop(),
              center: 'Data & export',
            ),
            const SizedBox(height: 22),
            Text(
              'A backup is a single JSON file. Importing one replaces the '
              'current data here, so keep the file somewhere you can find it '
              'again.',
              style: AppType.meta.copyWith(color: colors.muted),
            ),
            const SizedBox(height: 26),
            _Section(
              title: 'Export data',
              body:
                  'Habits, routines, every day of history, your profile and '
                  'settings — all of it in one file you choose where to save.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppButton(
                    label: 'Export backup',
                    tone: AppButtonTone.secondary,
                    expand: true,
                    onPressed: empty ? null : () => _export(context),
                  ),
                  if (empty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Nothing to export yet. Add a habit first.',
                      style: AppType.micro.copyWith(color: colors.faint),
                    ),
                  ],
                ],
              ),
            ),
            _Section(
              title: 'Import from a file',
              body:
                  'Pick a backup made by Accrue. Importing replaces everything '
                  'on this device with what the file holds.',
              child: AppButton(
                label: 'Choose a backup',
                tone: AppButtonTone.secondary,
                expand: true,
                onPressed: () => _import(context),
              ),
            ),
            _Section(
              title: 'Clear',
              body:
                  'Clear removes your habits, routines and history but keeps '
                  'your profile and settings. Reset app wipes everything and '
                  'starts setup again. Neither can be undone.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppButton(
                    label: 'Clear habits & history',
                    tone: AppButtonTone.danger,
                    expand: true,
                    onPressed: () => _clearAll(context),
                  ),
                  const SizedBox(height: 10),
                  AppButton(
                    label: 'Reset app & profile',
                    tone: AppButtonTone.danger,
                    expand: true,
                    onPressed: () => _resetApp(context),
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

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.body,
    required this.child,
  });

  final String title;
  final String body;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(title),
          const SizedBox(height: 6),
          Text(
            body,
            style: AppType.meta.copyWith(color: colors.muted, height: 1.5),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
