import 'package:audioplayers/audioplayers.dart';

/// The app's two sounds: the cannon pop when a habit lands, and the tick each
/// wheel row makes as it passes. Both are bundled assets, so nothing is
/// fetched and a failure to play never blocks anything.
class Sfx {
  Sfx._();

  static const String pop = 'sounds/pop.wav';
  static const String tick = 'sounds/tick.wav';

  static final Map<String, AudioPlayer> _players = {};

  /// A fast flick sends a tick every few milliseconds; past this the clicks
  /// blur into a rattle and the player cannot keep up.
  static const Duration _tickGap = Duration(milliseconds: 45);
  static DateTime _lastTick = DateTime.fromMillisecondsSinceEpoch(0);

  static Future<void> playPop() => _play(pop, volume: 0.9);

  static Future<void> playTick() {
    final now = DateTime.now();
    if (now.difference(_lastTick) < _tickGap) return Future<void>.value();
    _lastTick = now;
    return _play(tick, volume: 0.55);
  }

  static Future<void> _play(String asset, {required double volume}) async {
    try {
      final player = _players[asset] ??= AudioPlayer()
        ..setReleaseMode(ReleaseMode.stop)
        ..setPlayerMode(PlayerMode.lowLatency);
      await player.stop();
      await player.play(AssetSource(asset), volume: volume);
    } catch (_) {
      // No audio device, or tests without the plugin: stay quiet.
    }
  }
}
