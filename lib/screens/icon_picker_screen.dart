import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_type.dart';
import '../theme/metrics.dart';
import '../widgets/app_icon.dart';
import '../widgets/habit_mark.dart';
import '../widgets/icon_library.dart';
import '../widgets/ui.dart';

/// What the picker returns to the habit form.
class MarkChoice {
  const MarkChoice({
    required this.badge,
    required this.icon,
    required this.text,
    required this.fg,
    required this.start,
    required this.end,
  });

  final bool badge;
  final String icon;
  final String text;
  final String fg;
  final String start;
  final String end;
}

const List<(String, Color)> _textColors = [
  ('Bone', Color(0xFFFAF9F5)),
  ('Ink', Color(0xFF141413)),
  ('Blush', Color(0xFFF4D8CE)),
  ('Rust', Color(0xFF7B2D1C)),
  ('Slate', Color(0xFF1F2937)),
  ('Moss', Color(0xFF0F5132)),
  ('Amber', Color(0xFF713F12)),
  ('Violet', Color(0xFF5B21B6)),
  ('Brick', Color(0xFF9E3B31)),
  ('Teal', Color(0xFF0E7490)),
];

const List<(String, Color, Color)> _gradients = [
  ('Clay', Color(0xFFC96442), Color(0xFFA94E2E)),
  ('Sunset', Color(0xFFF97316), Color(0xFFDB2777)),
  ('Ocean', Color(0xFF0EA5E9), Color(0xFF2563EB)),
  ('Forest', Color(0xFF22C55E), Color(0xFF15803D)),
  ('Plum', Color(0xFFA855F7), Color(0xFF6D28D9)),
  ('Ink', Color(0xFF30302E), Color(0xFF141413)),
  ('Sand', Color(0xFFE8E6DC), Color(0xFFC9C4B4)),
  ('Rose', Color(0xFFFB7185), Color(0xFFBE123C)),
  ('Teal', Color(0xFF14B8A6), Color(0xFF0F766E)),
  ('Amber', Color(0xFFF59E0B), Color(0xFFB45309)),
];

String _hex(Color color) =>
    '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';

Future<MarkChoice?> openMarkPicker(
  BuildContext context, {
  required MarkChoice initial,
}) {
  return Navigator.of(context).push<MarkChoice>(
    MaterialPageRoute<MarkChoice>(
      builder: (_) => MarkPickerScreen(initial: initial),
    ),
  );
}

/// Full-screen mark picker: search the whole icon library, or build a one or
/// two character badge with its own text colour and gradient.
class MarkPickerScreen extends StatefulWidget {
  const MarkPickerScreen({super.key, required this.initial});

  final MarkChoice initial;

  @override
  State<MarkPickerScreen> createState() => _MarkPickerScreenState();
}

class _MarkPickerScreenState extends State<MarkPickerScreen> {
  late bool _badge = widget.initial.badge;
  late String _icon = widget.initial.icon;
  late String _text = widget.initial.text;
  late Color _fg = hexColor(widget.initial.fg, Colors.white);
  late Color _start = hexColor(widget.initial.start, const Color(0xFFC96442));
  late Color _end = hexColor(widget.initial.end, const Color(0xFFA94E2E));
  final _search = TextEditingController();
  late final TextEditingController _badgeField = TextEditingController(
    text: widget.initial.text,
  );
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    _badgeField.dispose();
    super.dispose();
  }

  List<String> get _results {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return lucideIconNames;
    return lucideIconNames.where((name) => name.contains(q)).toList();
  }

  void _apply() {
    Navigator.of(context).pop(
      MarkChoice(
        badge: _badge,
        icon: _icon,
        text: _text,
        fg: _hex(_fg),
        start: _hex(_start),
        end: _hex(_end),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final gutters = EdgeInsets.symmetric(horizontal: Metrics.gutter);
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
                center: 'Habit mark',
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
                          _StyleSwitch(
                            badge: _badge,
                            onChanged: (value) => setState(() => _badge = value),
                          ),
                          const SizedBox(height: 18),
                          if (_badge) _badgeControls(colors) else _iconControls(),
                        ],
                      ),
                    ),
                  ),
                  if (!_badge)
                    SliverPadding(
                      padding: gutters.copyWith(top: 14),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          _results.isEmpty
                              ? 'No icons match “${_query.trim()}”. Try run, book or moon.'
                              : '${_results.length} '
                                    '${_results.length == 1 ? 'icon' : 'icons'}',
                          style: AppType.micro.copyWith(color: colors.faint),
                        ),
                      ),
                    ),
                  if (!_badge)
                    SliverPadding(
                      padding: gutters.copyWith(top: 10, bottom: 20),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 6,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                            ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final name = _results[index];
                          return _IconTile(
                            name: name,
                            selected: name == _icon,
                            onTap: () => setState(() => _icon = name),
                          );
                        }, childCount: _results.length),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                Metrics.gutter,
                10,
                Metrics.gutter,
                Metrics.bottomInset(context),
              ),
              child: AppButton(
                label: _badge ? 'Use this badge' : 'Use this icon',
                expand: true,
                onPressed: _apply,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconControls() {
    return LabeledField(
      label: 'Search icons',
      controller: _search,
      hint: 'water, run, book, moon…',
      onChanged: (value) => setState(() => _query = value),
    );
  }

  Widget _badgeControls(AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: HabitMark(
            badge: true,
            badgeText: _text,
            badgeFg: _hex(_fg),
            badgeStart: _hex(_start),
            badgeEnd: _hex(_end),
            size: 96,
          ),
        ),
        const SizedBox(height: 22),
        LabeledField(
          label: 'Badge text',
          controller: _badgeField,
          hint: 'WA',
          maxLength: 2,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
            LengthLimitingTextInputFormatter(2),
            TextInputFormatter.withFunction(
              (oldValue, newValue) => newValue.copyWith(
                text: newValue.text.toUpperCase(),
              ),
            ),
          ],
          onChanged: (value) => setState(() => _text = value.toUpperCase()),
        ),
        const SizedBox(height: 8),
        SectionTitle('Text colour'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final (name, color) in _textColors)
              Semantics(
                label: '$name text',
                selected: color.toARGB32() == _fg.toARGB32(),
                button: true,
                child: _Swatch(
                  selected: color.toARGB32() == _fg.toARGB32(),
                  onTap: () => setState(() => _fg = color),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.line),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        SectionTitle('Background'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final (name, a, b) in _gradients)
              Semantics(
                label: '$name gradient',
                selected: a.toARGB32() == _start.toARGB32(),
                button: true,
                child: _Swatch(
                  selected: a.toARGB32() == _start.toARGB32(),
                  onTap: () => setState(() {
                    _start = a;
                    _end = b;
                  }),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [a, b],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Two letters read best: WA for water, RD for read.',
          style: AppType.micro.copyWith(color: colors.faint),
        ),
      ],
    );
  }
}

class _StyleSwitch extends StatelessWidget {
  const _StyleSwitch({required this.badge, required this.onChanged});

  final bool badge;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Row(
      children: [
        Expanded(
          child: _SwitchItem(
            label: 'Icon',
            selected: !badge,
            onTap: () => onChanged(false),
            colors: colors,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SwitchItem(
            label: 'Text badge',
            selected: badge,
            onTap: () => onChanged(true),
            colors: colors,
          ),
        ),
      ],
    );
  }
}

class _SwitchItem extends StatelessWidget {
  const _SwitchItem({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.colors,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: Metrics.touch,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? colors.accentSoft : colors.surface,
            borderRadius: BorderRadius.circular(Metrics.rSm),
            border: Border.all(
              color: selected ? colors.accent : colors.line,
            ),
          ),
          child: Text(
            label,
            style: AppType.bodyStrong.copyWith(
              color: selected ? colors.accentInk : colors.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: name.replaceAll('-', ' '),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: selected ? colors.accentSoft : colors.surface,
            borderRadius: BorderRadius.circular(Metrics.rSm),
            border: Border.all(
              color: selected ? colors.accent : colors.line,
            ),
          ),
          child: Center(
            child: AppIcon(
              name,
              size: 22,
              color: selected ? colors.accentInk : colors.text,
            ),
          ),
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.child,
    required this.selected,
    required this.onTap,
  });

  final Widget child;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? colors.accent : Colors.transparent,
            width: 2,
          ),
        ),
        child: child,
      ),
    );
  }
}
