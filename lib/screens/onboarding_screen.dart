import 'package:flutter/material.dart';

import '../models/habit.dart';
import '../state/habit_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_type.dart';
import '../theme/metrics.dart';
import '../widgets/dialogs.dart';
import '../widgets/ui.dart';
import 'new_habit_screen.dart';

/// Three-step setup: name, starter habits, starter routines.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.store});

  final HabitStore store;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final TextEditingController _name = TextEditingController();
  final Set<String> _habits = {for (final idea in starterHabits) idea.key};
  final Set<String> _routines = {...starterRoutines.keys};
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _name.addListener(_rebuild);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _next() {
    if (_step == 0 && _name.text.trim().isEmpty) return;
    setState(() => _step = (_step + 1).clamp(0, 2));
  }

  void _back() {
    if (_step > 0) setState(() => _step -= 1);
  }

  void _finish() {
    widget.store.completeOnboarding(
      name: _name.text,
      habitKeys: _habits,
      routineKeys: _routines,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final gutter = Metrics.gutter;

    return Scaffold(
      backgroundColor: colors.bg,
      body: Padding(
        padding: EdgeInsets.fromLTRB(
          gutter,
          Metrics.topInset(context) + 8,
          gutter,
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Eyebrow('Accrue'),
                const Spacer(),
                Row(
                  children: [
                    for (var i = 0; i < 3; i++) ...[
                      if (i > 0) const SizedBox(width: 6),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        curve: Curves.easeOut,
                        width: i == _step ? 18 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: i == _step ? colors.accent : colors.line,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_step == 0)
                      _welcome(colors)
                    else if (_step == 1)
                      _pickHabits(colors)
                    else
                      _pickRoutines(colors),
                    const SizedBox(height: 22),
                    _footer(),
                    SizedBox(height: Metrics.bottomInset(context) + 14),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _welcome(AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Eyebrow('Welcome'),
        const SizedBox(height: 8),
        Text(
          'Let’s make this yours.',
          style: AppType.title.copyWith(color: colors.text),
        ),
        const SizedBox(height: 10),
        Text(
          'A name makes this app personal.',
          style: AppType.body.copyWith(color: colors.muted),
        ),
        const SizedBox(height: 22),
        Center(child: Avatar(name: _name.text, size: 72)),
        const SizedBox(height: 22),
        Text(
          'Your name',
          style: AppType.meta.copyWith(
            fontWeight: FontWeight.w500,
            color: colors.muted,
          ),
        ),
        const SizedBox(height: 6),
        AppTextField(
          controller: _name,
          hint: 'Alex',
          maxLength: 40,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _next(),
        ),
      ],
    );
  }

  Widget _pickHabits(AppColors colors) {
    final own = widget.store.habits;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Eyebrow('Habits · 1 of 2'),
        const SizedBox(height: 8),
        Text(
          'Start with a few',
          style: AppType.title.copyWith(color: colors.text),
        ),
        const SizedBox(height: 10),
        Text(
          'Common habits to begin with. Pick what you want now — you can '
          'change everything later.',
          style: AppType.body.copyWith(color: colors.muted),
        ),
        const SizedBox(height: 22),
        for (final idea in starterHabits)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: RecCard(
              icon: idea.icon,
              name: idea.name,
              meta: idea.meta ?? '',
              selected: _habits.contains(idea.key),
              onTap: () => setState(() {
                if (!_habits.add(idea.key)) _habits.remove(idea.key);
              }),
            ),
          ),
        for (final habit in own)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: RecCard(
              icon: habit.icon,
              name: habit.name,
              meta: 'Added by you',
              selected: true,
              disabled: true,
              onTap: null,
            ),
          ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: () async {
            await openHabitForm(context, widget.store);
            setState(() {});
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 8),
            minimumSize: const Size(44, 44),
            alignment: Alignment.centerLeft,
          ),
          child: Text(
            '+ Add your own habit',
            style: AppType.metaStrong.copyWith(
              fontSize: 14,
              color: colors.accentInk,
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () async {
              await ideasDialog(context, widget.store);
              setState(() {});
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
              minimumSize: const Size(44, 44),
            ),
            child: Text(
              'Browse habit ideas',
              style: AppType.metaStrong.copyWith(
                fontSize: 14,
                color: colors.accentInk,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _pickRoutines(AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Eyebrow('Routines · 2 of 2'),
        const SizedBox(height: 8),
        Text(
          'Then a routine',
          style: AppType.title.copyWith(color: colors.text),
        ),
        const SizedBox(height: 10),
        Text(
          'A routine is a set of habits you run together, one after another. '
          'Skip these to build your own later.',
          style: AppType.body.copyWith(color: colors.muted),
        ),
        const SizedBox(height: 22),
        for (final entry in starterRoutines.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: RecCard(
              icon: 'layers',
              name: entry.key[0].toUpperCase() + entry.key.substring(1),
              meta: entry.value
                  .map(
                    (key) => starterHabits.firstWhere(
                      (idea) => idea.key == key,
                    ).name,
                  )
                  .join(' · '),
              selected: _routines.contains(entry.key),
              onTap: () => setState(() {
                if (!_routines.add(entry.key)) _routines.remove(entry.key);
              }),
            ),
          ),
      ],
    );
  }

  Widget _footer() {
    if (_step == 0) {
      return SizedBox(
        width: double.infinity,
        child: AppButton(
          label: 'Continue',
          expand: true,
          onPressed: _name.text.trim().isEmpty ? null : _next,
        ),
      );
    }
    return Row(
      children: [
        AppButton(
          label: 'Back',
          tone: AppButtonTone.secondary,
          onPressed: _back,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: AppButton(
            label: _step == 1 ? 'Continue' : 'Finish setup',
            expand: true,
            onPressed: _step == 1 ? _next : _finish,
          ),
        ),
      ],
    );
  }
}
