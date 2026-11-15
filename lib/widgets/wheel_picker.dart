import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_type.dart';
import '../util/sfx.dart';

/// A snapping column of values you flick through: the clock face used for
/// reminder times, where the hour is scrolled to instead of stepped to.
///
/// The band in the middle marks the selected row; rows either side fade out so
/// the column reads as a wheel rather than a list.
class WheelPicker extends StatefulWidget {
  const WheelPicker({
    super.key,
    required this.values,
    required this.selected,
    required this.onChanged,
    required this.semanticLabel,
    this.width = 68,
    this.itemExtent = 40,
    this.visibleRows = 5,
  });

  final List<String> values;
  final int selected;
  final ValueChanged<int> onChanged;
  final String semanticLabel;
  final double width;
  final double itemExtent;
  final int visibleRows;

  @override
  State<WheelPicker> createState() => _WheelPickerState();
}

class _WheelPickerState extends State<WheelPicker> {
  /// The value list is laid out this many times end to end so a flick in
  /// either direction never reaches an edge; the selected value is the item
  /// index modulo the list length, which is what makes the wheel wrap.
  static const int _repeats = 401;

  late final FixedExtentScrollController _controller;
  late int _index = widget.selected.clamp(0, widget.values.length - 1);

  int get _base => widget.values.length * (_repeats ~/ 2);

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(initialItem: _base + _index);
  }

  @override
  void didUpdateWidget(covariant WheelPicker old) {
    super.didUpdateWidget(old);
    if (widget.selected != _index) {
      _index = widget.selected.clamp(0, widget.values.length - 1);
      if (_controller.hasClients) _controller.jumpToItem(_base + _index);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final extent = widget.itemExtent;
    return Semantics(
      slider: true,
      label: widget.semanticLabel,
      value: widget.values[_index],
      child: SizedBox(
        width: widget.width,
        height: extent * widget.visibleRows,
        child: Stack(
          children: [
            Center(
              child: Container(
                height: extent,
                decoration: BoxDecoration(
                  color: colors.surface2,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.line),
                ),
              ),
            ),
            ListWheelScrollView.useDelegate(
              controller: _controller,
              itemExtent: extent,
              diameterRatio: 1.7,
              perspective: 0.003,
              // Clamping, not stretching: Android's stretch overscroll paints a
              // half row past the edge and reads as a glitch on a wheel.
              physics: const FixedExtentScrollPhysics(
                parent: ClampingScrollPhysics(),
              ),
              onSelectedItemChanged: (index) {
                final value = index % widget.values.length;
                if (value == _index) return;
                setState(() => _index = value);
                Sfx.playTick();
                widget.onChanged(value);
              },
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: widget.values.length * _repeats,
                builder: (context, index) {
                  final value = index % widget.values.length;
                  return Center(
                    child: Text(
                      widget.values[value],
                      style: AppType.count.copyWith(
                        fontSize: 20,
                        color: value == _index ? colors.text : colors.faint,
                      ),
                    ),
                  );
                },
              ),
            ),
            // Fade the top and bottom rows into the panel so the curved
            // slivers at the edge never read as clipped text.
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        colors.surface,
                        colors.surface.withValues(alpha: 0),
                        colors.surface.withValues(alpha: 0),
                        colors.surface,
                      ],
                      stops: const [0, 0.24, 0.76, 1],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Two thin pills stacked over a wheel column: the AM/PM half of a 12-hour
/// clock, sized to match [WheelPicker]'s height.
class MeridiemToggle extends StatelessWidget {
  const MeridiemToggle({
    super.key,
    required this.pm,
    required this.onChanged,
    this.height = 200,
  });

  final bool pm;
  final ValueChanged<bool> onChanged;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return SizedBox(
      height: height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final (label, isPm) in const [('AM', false), ('PM', true)]) ...[
            if (isPm) const SizedBox(height: 8),
            Semantics(
              button: true,
              selected: pm == isPm,
              child: Material(
                color: pm == isPm ? colors.accentSoft : colors.surface2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: pm == isPm ? colors.accentInk.withValues(alpha: 0.45) : colors.line,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => onChanged(isPm),
                  child: SizedBox(
                    width: 52,
                    height: 52,
                    child: Center(
                      child: Text(
                        label,
                        style: AppType.count.copyWith(
                          fontSize: 14,
                          fontWeight: pm == isPm
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: pm == isPm ? colors.accentInk : colors.muted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
