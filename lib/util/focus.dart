import 'dart:async';

import 'package:flutter/services.dart';

/// One launchable app on the device.
class InstalledApp {
  const InstalledApp({required this.package, required this.label});

  final String package;
  final String label;
}

/// Focus blocking: while a timed habit is running, Android draws a full-screen
/// overlay over the app packages the user chose.
///
/// It is implemented by an `AccessibilityService` (no overlay plugin exists
/// without symlink-enabling Developer Mode on this machine, and an
/// accessibility overlay needs no `SYSTEM_ALERT_WINDOW` grant). The service is
/// declared with `canRetrieveWindowContent="false"`: it only reads the package
/// name of the foreground window and never its content.
///
/// On web and desktop every call is a no-op that reports "not supported".
class FocusBlocking {
  static const MethodChannel _channel = MethodChannel('habit_tracker/focus');
  static const Duration _timeout = Duration(seconds: 4);

  /// False on platforms without the native side.
  static Future<bool> get supported async {
    try {
      return await _channel.invokeMethod<bool>('supported').timeout(_timeout) ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    } on TimeoutException {
      return false;
    }
  }

  /// Whether the user has switched the service on in system settings.
  static Future<bool> get enabled async {
    try {
      return await _channel.invokeMethod<bool>('isEnabled').timeout(_timeout) ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    } on TimeoutException {
      return false;
    }
  }

  /// Opens Android's accessibility settings, where the service is switched on.
  static Future<void> openSettings() async {
    try {
      await _channel.invokeMethod<void>('openSettings').timeout(_timeout);
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    } on TimeoutException {
      return;
    }
  }

  /// Launchable apps, excluding this one. Empty where unsupported.
  static Future<List<InstalledApp>> installedApps() async {
    try {
      final rows = await _channel
          .invokeListMethod<Map<Object?, Object?>>('installedApps')
          .timeout(_timeout);
      if (rows == null) return const [];
      return [
        for (final row in rows)
          if (row['package'] is String)
            InstalledApp(
              package: row['package']! as String,
              label: (row['label'] as String?) ?? row['package']! as String,
            ),
      ];
    } on MissingPluginException {
      return const [];
    } on PlatformException {
      return const [];
    } on TimeoutException {
      return const [];
    }
  }

  /// Starts blocking [packages] until [endsAt], showing [habitName].
  static Future<void> start({
    required String habitName,
    required DateTime endsAt,
    required Set<String> packages,
  }) async {
    if (packages.isEmpty) return stop();
    try {
      await _channel
          .invokeMethod<void>('startFocus', {
            'habit': habitName,
            'endsAt': endsAt.millisecondsSinceEpoch,
            'packages': packages.toList(),
          })
          .timeout(_timeout);
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    } on TimeoutException {
      return;
    }
  }

  static Future<void> stop() async {
    try {
      await _channel.invokeMethod<void>('stopFocus').timeout(_timeout);
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    } on TimeoutException {
      return;
    }
  }
}
