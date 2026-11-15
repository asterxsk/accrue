import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// A GitHub release of Accrue, as the updater reads it.
class AppRelease {
  const AppRelease({
    required this.version,
    required this.tag,
    required this.publishedAt,
    required this.notes,
    required this.apkUrl,
    required this.apkBytes,
    this.sha256,
  });

  final String version;
  final String tag;
  final DateTime? publishedAt;
  final String notes;
  final String apkUrl;
  final int apkBytes;

  /// Hex SHA-256 of the APK, from GitHub's asset digest when present.
  final String? sha256;

  bool get hasApk => apkUrl.isNotEmpty;
}

enum UpdatePhase { idle, checking, current, available, failed }

/// Manual updater: one tap checks GitHub, downloads the release APK and hands
/// it to the system installer. Nothing runs in the background.
///
/// A single instance so the profile's corner button and the Updates page share
/// the same result and the same in-flight download.
class UpdateController extends ChangeNotifier {
  UpdateController._();

  static final UpdateController instance = UpdateController._();

  static const String repo = 'asterxsk/accrue';
  static const MethodChannel _channel = MethodChannel('habit_tracker/updates');

  UpdatePhase phase = UpdatePhase.idle;
  String? message;

  /// True for two seconds after a check finds nothing newer, so the button can
  /// say "up to date" before settling back to its idle glyph.
  bool justChecked = false;
  Timer? _settle;
  String installed = '';
  List<AppRelease> releases = const [];
  AppRelease? latest;
  AppRelease? selected;
  File? downloaded;
  double progress = 0;
  bool downloading = false;

  bool get hasUpdate =>
      latest != null && installed.isNotEmpty && isNewer(latest!.version, installed);

  bool get busy => phase == UpdatePhase.checking || downloading;

  Future<void> loadInstalled() async {
    if (installed.isNotEmpty) return;
    try {
      final info = await PackageInfo.fromPlatform();
      installed = info.version;
    } catch (_) {
      // No platform plugin (tests): the check still runs, comparisons wait.
      installed = '';
    }
    notifyListeners();
  }

  /// Reads the release list. Fails quietly into [phase] so the UI can say why.
  Future<void> check() async {
    if (phase == UpdatePhase.checking) return;
    phase = UpdatePhase.checking;
    message = null;
    justChecked = false;
    _settle?.cancel();
    notifyListeners();
    await loadInstalled();
    try {
      final body = await _get(
        'https://api.github.com/repos/$repo/releases?per_page=20',
      );
      final rows = (jsonDecode(body) as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .where((row) => row['draft'] != true && row['prerelease'] != true)
          .map(_parse)
          .where((release) => release != null)
          .cast<AppRelease>()
          .toList()
        ..sort((a, b) => compareVersions(b.version, a.version));
      releases = rows;
      latest = rows.isEmpty ? null : rows.first;
      selected = latest;
      phase = hasUpdate ? UpdatePhase.available : UpdatePhase.current;
      if (!hasUpdate) {
        justChecked = true;
        message = 'No updates. You are on the latest build.';
        _settle = Timer(const Duration(seconds: 2), () {
          justChecked = false;
          if (phase == UpdatePhase.current) message = null;
          notifyListeners();
        });
      }
      if (installed.isEmpty && latest != null) {
        // Unknown installed version: say nothing definitive.
        phase = UpdatePhase.current;
        message = 'Latest build is ${latest!.version}.';
      }
    } catch (_) {
      phase = UpdatePhase.failed;
      message = 'Could not reach GitHub. Check the connection and try again.';
    }
    notifyListeners();
  }

  /// Streams [release]'s APK into the app cache, reporting progress 0..1.
  Future<void> download(AppRelease release) async {
    if (downloading) return;
    selected = release;
    downloaded = null;
    progress = 0;
    downloading = true;
    message = null;
    notifyListeners();

    HttpClient? client;
    File? file;
    try {
      final dir = await _channel.invokeMethod<String>('downloadDir');
      if (dir == null) throw const FileSystemException('no cache dir');
      client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
      final request = await client.getUrl(Uri.parse(release.apkUrl));
      request.headers.set('User-Agent', 'Accrue/$installed');
      final response = await request.close();
      if (response.statusCode != 200) {
        throw HttpException('HTTP ${response.statusCode}');
      }
      final total = response.contentLength > 0
          ? response.contentLength
          : release.apkBytes;
      final target = File('$dir/accrue-${release.version}.apk');
      for (final stale in Directory(dir).listSync()) {
        if (stale is File && stale.path.endsWith('.apk') && stale.path != target.path) {
          try {
            await stale.delete();
          } catch (_) {}
        }
      }
      file = target;
      final sink = target.openWrite();
      var received = 0;
      var shown = 0.0;
      try {
        await for (final chunk in response) {
          sink.add(chunk);
          received += chunk.length;
          if (total > 0) {
            final next = (received / total).clamp(0.0, 1.0);
            if (next - shown >= 0.01 || next == 1.0) {
              shown = next;
              progress = next;
              notifyListeners();
            }
          }
        }
        await sink.flush();
      } finally {
        await sink.close();
      }
      downloaded = file;
      // GitHub publishes the asset's SHA-256; a truncated transfer otherwise
      // only surfaces as Android's "problem parsing the package".
      final expected = release.sha256;
      if (expected != null) {
        final actual = await _sha256Of(file);
        if (actual != expected) {
          await _discard(file);
          file = null;
          downloaded = null;
          progress = 0;
          message = 'The download came through damaged. Try again.';
          return;
        }
      }
      if (release.apkBytes > 0 && await file.length() != release.apkBytes) {
        await _discard(file);
        file = null;
        downloaded = null;
        progress = 0;
        message = 'The download is incomplete. Try again.';
        return;
      }
      progress = 1;
    } catch (_) {
      progress = 0;
      message = 'The download did not finish. Try again.';
      if (file != null) {
        try {
          await file.delete();
        } catch (_) {}
      }
    } finally {
      client?.close(force: true);
      downloading = false;
      notifyListeners();
    }
  }

  /// Hands the downloaded file to Android's installer. Android shows its own
  /// confirmation; the first time it also needs "install unknown apps", which
  /// the channel opens in settings and reports back as an error.
  Future<void> install() async {
    final file = downloaded;
    if (file == null) return;
    message = null;
    try {
      await _channel.invokeMethod<bool>('installApk', {'path': file.path});
    } on PlatformException catch (error) {
      message = error.message ?? 'Android refused the installer.';
    } catch (_) {
      message = 'This build cannot install an app by itself.';
    }
    notifyListeners();
  }

  String get installedLabel => installed.isEmpty ? 'this build' : installed;
}

AppRelease? _parse(Map<String, dynamic> row) {
  final tag = (row['tag_name'] as String? ?? '').replaceFirst('v', '');
  if (tag.isEmpty) return null;
  final assets = (row['assets'] as List<dynamic>? ?? const [])
      .cast<Map<String, dynamic>>();
  final apk = assets.cast<Map<String, dynamic>?>().firstWhere(
    (asset) => (asset?['name'] as String? ?? '').endsWith('.apk'),
    orElse: () => null,
  );
  final digest = ((apk?['digest'] as String?) ?? '')
      .replaceFirst('sha256:', '')
      .trim();
  return AppRelease(
    version: tag,
    tag: row['tag_name'] as String? ?? 'v$tag',
    publishedAt: DateTime.tryParse(row['published_at'] as String? ?? '')
        ?.toLocal(),
    notes: (row['body'] as String? ?? '').trim(),
    apkUrl: apk?['browser_download_url'] as String? ?? '',
    apkBytes: (apk?['size'] as num?)?.toInt() ?? 0,
    sha256: digest.isEmpty ? null : digest,
  );
}

Future<String> _sha256Of(File file) async {
  final digest = await sha256.bind(file.openRead()).first;
  return digest.toString();
}

Future<void> _discard(File file) async {
  try {
    await file.delete();
  } catch (_) {}
}

/// "1.10.0" beats "1.9.2"; anything unparsable sorts below a real version.
int compareVersions(String a, String b) {
  final left = _parts(a);
  final right = _parts(b);
  if (left == null && right == null) return 0;
  if (left == null) return -1;
  if (right == null) return 1;
  for (var i = 0; i < 3; i++) {
    final diff = left[i] - right[i];
    if (diff != 0) return diff;
  }
  return 0;
}

bool isNewer(String candidate, String current) =>
    compareVersions(candidate, current) > 0;

List<int>? _parts(String version) {
  final match = RegExp(r'^(\d+)\.(\d+)\.(\d+)').firstMatch(version.trim());
  if (match == null) return null;
  return [
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
  ];
}

Future<String> _get(String url) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
  try {
    final request = await client.getUrl(Uri.parse(url));
    request.headers
      ..set('Accept', 'application/vnd.github+json')
      ..set('User-Agent', 'Accrue-updater');
    final response = await request.close();
    if (response.statusCode != 200) {
      throw HttpException('HTTP ${response.statusCode}');
    }
    return await response.transform(utf8.decoder).join();
  } finally {
    client.close(force: true);
  }
}
