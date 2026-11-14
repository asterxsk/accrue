import 'package:flutter/material.dart';

import '../models/habit.dart';
import '../state/habit_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_type.dart';
import '../widgets/dialogs.dart';
import '../widgets/popup_menu.dart';
import '../widgets/routine_cards.dart';
import '../widgets/ui.dart';
import 'routine_run_screen.dart';

class RoutinesScreen extends StatelessWidget {
  const RoutinesScreen({super.key, required this.store});

  final HabitStore store;

  Future<void> _newRoutine(BuildContext context) async {
    final edit = await routineEditorDialog(context, store);
    if (edit == null) return;
    store.addRoutine(edit.name, edit.habitIds);
  }

  Future<void> _routineMenu(
    BuildContext context,
    Routine routine,
    BuildContext anchor,
  ) {
    return showActionMenu(context, anchor, [
      AppMenuItem(
        label: 'Open routine',
        icon: 'layers',
        onSelected: () => openRoutineRun(context, store, routine),
      ),
      AppMenuItem(
        label: 'Edit habits',
        icon: 'pencil',
        onSelected: () async {
          final edit = await routineEditorDialog(
            context,
            store,
            routine: routine,
          );
          if (edit != null) {
            store.updateRoutine(routine, edit.name, edit.habitIds);
          }
        },
      ),
      AppMenuItem(
        label: 'Delete routine',
        icon: 'trash',
        danger: true,
        onSelected: () async {
          final confirmed = await confirmDialog(
            context,
            title: 'Delete ${routine.name}?',
            body:
                "The routine, its steps and today's progress are removed from "
                'this device. This cannot be undone.',
            confirmLabel: 'Delete routine',
            danger: true,
          );
          if (confirmed) store.deleteRoutine(routine);
        },
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: screenPadding(context, topLevel: true),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HeaderBlock(
                eyebrow: 'Step by step',
                title: 'Routines',
                trailing: AppIconButton(
                  icon: 'plus',
                  size: 44,
                  iconSize: 20,
                  filled: true,
                  label: 'New routine',
                  onTap: () => _newRoutine(context),
                ),
              ),
              const SizedBox(height: 26),
              if (store.routines.isEmpty)
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle(
                        'No routines yet',
                        margin: EdgeInsets.only(bottom: 6),
                      ),
                      Text(
                        'A routine is a set of your habits that you run '
                        'together — morning, evening — one after another.',
                        style: AppType.micro.copyWith(color: colors.muted),
                      ),
                    ],
                  ),
                )
              else
                for (final routine in store.routines)
                  RoutineLargeCard(
                    store: store,
                    routine: routine,
                    onOpen: () => openRoutineRun(context, store, routine),
                    onMenu: (anchor) =>
                        _routineMenu(context, routine, anchor),
                  ),
              DashedNewRow(
                label: 'New routine',
                onTap: () => _newRoutine(context),
              ),
            ],
          ),
        );
      },
    );
  }
}
