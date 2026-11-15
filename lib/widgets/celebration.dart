import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// One short chime per completed habit. The clip is a bundled asset, so nothing
/// is fetched and a failure to play never blocks the celebration.
class CompletionSound {
  CompletionSound._();

  static AudioPlayer? _player;

  static Future<void> play() async {
    try {
      final player = _player ??= AudioPlayer()
        ..setReleaseMode(ReleaseMode.stop)
        ..setPlayerMode(PlayerMode.lowLatency);
      await player.stop();
      await player.play(AssetSource('sounds/complete.wav'));
    } catch (_) {
      // No audio device, or tests without the plugin: stay quiet.
    }
  }
}

/// Throws confetti from the bottom of the screen once, above every route.
void celebrate(BuildContext context) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  final colors = AppColors.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _ConfettiBurst(
      colors: colors,
      onDone: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
  CompletionSound.play();
}

class _ConfettiBurst extends StatefulWidget {
  const _ConfettiBurst({required this.colors, required this.onDone});

  final AppColors colors;
  final VoidCallback onDone;

  @override
  State<_ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<_ConfettiBurst>
    with SingleTickerProviderStateMixin {
  static const Duration _life = Duration(milliseconds: 1500);

  late final AnimationController _controller;
  late final List<_Piece> _pieces;

  @override
  void initState() {
    super.initState();
    _pieces = _buildPieces();
    _controller = AnimationController(vsync: this, duration: _life)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onDone();
      })
      ..forward();
  }

  List<_Piece> _buildPieces() {
    final random = math.Random();
    final palette = [
      widget.colors.accent,
      widget.colors.accentInk,
      widget.colors.accentSoft,
      widget.colors.text,
    ];
    return [
      for (var i = 0; i < 70; i++)
        _Piece(
          // Fired from the lower middle, fanned upward.
          originX: 0.5 + (random.nextDouble() - 0.5) * 0.18,
          velocityX: (random.nextDouble() - 0.5) * 1.5,
          velocityY: -(0.7 + random.nextDouble() * 0.75),
          spin: (random.nextDouble() - 0.5) * 14,
          size: 3.5 + random.nextDouble() * 5,
          delay: random.nextDouble() * 0.18,
          color: palette[random.nextInt(palette.length)],
          round: random.nextBool(),
        ),
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          size: MediaQuery.sizeOf(context),
          painter: _ConfettiPainter(
            pieces: _pieces,
            progress: _controller.value,
          ),
        ),
      ),
    );
  }
}

class _Piece {
  const _Piece({
    required this.originX,
    required this.velocityX,
    required this.velocityY,
    required this.spin,
    required this.size,
    required this.delay,
    required this.color,
    required this.round,
  });

  final double originX;
  final double velocityX;
  final double velocityY;
  final double spin;
  final double size;
  final double delay;
  final Color color;
  final bool round;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.pieces, required this.progress});

  final List<_Piece> pieces;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final paint = Paint();
    for (final piece in pieces) {
      final t = ((progress - piece.delay) / (1 - piece.delay)).clamp(0.0, 1.0);
      if (t == 0) continue;
      // Position in fractions of the height, so it reads the same anywhere.
      final x = (piece.originX + piece.velocityX * t) * size.width;
      final y =
          (1.0 + (piece.velocityY + 1.1 * t) * t) * size.height;
      final fade = (1 - t).clamp(0.0, 1.0);
      paint.color = piece.color.withValues(alpha: fade * 0.9);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(piece.spin * t);
      if (piece.round) {
        canvas.drawCircle(Offset.zero, piece.size / 2.2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: piece.size,
            height: piece.size * 0.45,
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.progress != progress || old.pieces != pieces;
}
