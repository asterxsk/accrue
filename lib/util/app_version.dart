import 'package:package_info_plus/package_info_plus.dart';

/// The installed version, read from the platform once at startup so every
/// screen shows the build that is actually running.
class AppVersion {
  static String version = '';

  static Future<void> load() async {
    try {
      version = (await PackageInfo.fromPlatform()).version;
    } catch (_) {
      // Tests and unsupported platforms have no package info.
      version = '';
    }
  }
}
