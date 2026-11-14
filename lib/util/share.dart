import 'dart:async';

import 'package:flutter/services.dart';

/// Result of a share attempt, so the caller can say what actually happened.
enum ShareOutcome { shared, copied }

/// The Android side of sharing. A plain method channel is enough for one
/// intent, and it avoids adding a plugin this build cannot compile on Windows.
class NativeShare {
  const NativeShare._();

  static const MethodChannel _channel = MethodChannel('habit_tracker/share');

  /// Opens the system share sheet with [text]. Returns false when there is no
  /// native share target (web, desktop), so the caller can fall back to the
  /// clipboard instead of pretending.
  static Future<bool> text(String text, {String? subject}) async {
    try {
      final opened = await _channel
          .invokeMethod<bool>('shareText', {
            'text': text,
            'subject': subject ?? 'Accrue',
          })
          // A host that never answers must not trap the dialog open.
          .timeout(const Duration(seconds: 4));
      return opened ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    } on TimeoutException {
      return false;
    }
  }
}
