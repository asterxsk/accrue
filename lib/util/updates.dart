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

  /// v2.5.0 moved to the current signing key. Earlier builds cannot install
  /// over this one (and this one cannot install over them), so the Updates
  /// page only lists releases from here on.
  static const String minimumRelease = '2.5.0';
  static const MethodChannel _channel = MethodChannel('habit_tracker/updates');

  UpdatePhase phase = UpdatePhase.idle;
  String? message;

  /// True for two seconds after a check finds nothing newer, so the button can
  /// say "up to date" before settling back to its idle glyph.
  bool justChecked = false;
  Timer? _settle;

  /// When GitHub's hourly API quota is spent, the Atom feed is read instead
  /// until the quota refills at this time.
  DateTime? _apiBlockedUntil;
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
      final rows = await _releases();
      releases = [
        for (final release in rows)
          if (compareVersions(release.version, minimumRelease) >= 0) release,
      ];
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
    } on _HttpFailure catch (failure) {
      phase = UpdatePhase.failed;
      message = failure.rateLimited
          ? 'GitHub is limiting update checks${_until(failure.resetAt)}. '
                'The next check works after that.'
          : 'GitHub answered HTTP ${failure.status} while checking. Try again.';
    } on FormatException {
      phase = UpdatePhase.failed;
      message = 'The release list came back unreadable. Try again.';
    } catch (_) {
      phase = UpdatePhase.failed;
      message = 'Could not reach GitHub. Check the connection and try again.';
    }
    notifyListeners();
  }

  /// The API first — it carries each asset's digest — and the public Atom feed
  /// when GitHub's hourly quota for this IP is spent. The feed has no digest,
  /// so a download from it is guarded by its ZIP structure instead.
  Future<List<AppRelease>> _releases() async {
    final blocked = _apiBlockedUntil;
    if (blocked != null && DateTime.now().isBefore(blocked)) {
      return _atomReleases();
    }
    try {
      return await _apiReleases();
    } on _HttpFailure catch (failure) {
      if (!failure.rateLimited) rethrow;
      _apiBlockedUntil =
          failure.resetAt ?? DateTime.now().add(const Duration(minutes: 5));
      return _atomReleases();
    }
  }

  Future<List<AppRelease>> _apiReleases() async {
    final body = await _get(
      Uri.parse('https://api.github.com/repos/$repo/releases?per_page=20'),
      headers: const {'Accept': 'application/vnd.github+json'},
    );
    return (jsonDecode(body) as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .where((row) => row['draft'] != true && row['prerelease'] != true)
        .map(_parse)
        .where((release) => release != null)
        .cast<AppRelease>()
        .toList()
      ..sort((a, b) => compareVersions(b.version, a.version));
  }

  Future<List<AppRelease>> _atomReleases() async {
    final body = await _get(Uri.parse('https://github.com/$repo/releases.atom'));
    final rows = parseAtomReleases(body, repo: repo)
      ..sort((a, b) => compareVersions(b.version, a.version));
    if (rows.isEmpty) throw const FormatException('no releases in the feed');
    return rows;
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
      // Without a digest (the Atom feed carries none) the ZIP itself is the
      // proof: a truncated file has no end-of-central-directory record.
      if (expected == null && !await _looksLikeApk(file)) {
        await _discard(file);
        file = null;
        downloaded = null;
        progress = 0;
        message = 'The download came through damaged. Try again.';
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

Future<String> _get(Uri url, {Map<String, String>? headers}) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
  try {
    final request = await client.getUrl(url);
    request.headers.set('User-Agent', 'Accrue-updater');
    headers?.forEach(request.headers.set);
    final response = await request.close();
    if (response.statusCode != 200) {
      final reset = int.tryParse(
        response.headers.value('x-ratelimit-reset') ?? '',
      );
      final retryAfter = int.tryParse(response.headers.value('retry-after') ?? '');
      throw _HttpFailure(
        response.statusCode,
        reset != null
            ? DateTime.fromMillisecondsSinceEpoch(reset * 1000)
            : retryAfter != null
            ? DateTime.now().add(Duration(seconds: retryAfter))
            : null,
      );
    }
    return await response.transform(utf8.decoder).join();
  } finally {
    client.close(force: true);
  }
}

/// A status GitHub returned instead of a body. [resetAt] is when the hourly
/// quota refills, when GitHub said so.
class _HttpFailure implements Exception {
  const _HttpFailure(this.status, this.resetAt);

  final int status;
  final DateTime? resetAt;

  bool get rateLimited => status == 403 || status == 429;

  @override
  String toString() => 'HTTP $status';
}

/// " until 16:40" when the quota reset time is known, otherwise empty.
String _until(DateTime? resetAt) {
  if (resetAt == null) return '';
  final local = resetAt.toLocal();
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  return ' until $hh:$mm';
}

/// Reads the release Atom feed, which needs no API quota. The feed carries the
/// tag, the published time and the notes, but not the asset, so the APK URL is
/// built from the name the release workflow publishes.
List<AppRelease> parseAtomReleases(String xml, {required String repo}) {
  final rows = <AppRelease>[];
  for (final entry in RegExp(r'<entry>([\s\S]*?)</entry>').allMatches(xml)) {
    final body = entry.group(1) ?? '';
    final href =
        RegExp(r'<link rel="alternate"[^>]*href="([^"]+)"').firstMatch(body)?.group(1) ??
        '';
    if (!href.contains('/tag/')) continue;
    final tag = href.split('/tag/').last.replaceAll(RegExp(r'[/"]'), '').trim();
    final version = tag.replaceFirst('v', '');
    if (version.isEmpty) continue;
    final updated = RegExp(r'<updated>([^<]+)</updated>').firstMatch(body)?.group(1);
    final content =
        RegExp(r'<content type="html">([\s\S]*?)</content>').firstMatch(body)?.group(1) ??
        '';
    rows.add(
      AppRelease(
        version: version,
        tag: tag,
        publishedAt: DateTime.tryParse(updated ?? '')?.toLocal(),
        notes: _plainText(content),
        apkUrl: 'https://github.com/$repo/releases/download/$tag/accrue-$version.apk',
        apkBytes: 0,
      ),
    );
  }
  return rows;
}

/// HTML-escaped release notes as plain text lines. The feed escapes its HTML,
/// so unescape first and strip the markup that appears.
String _plainText(String html) {
  final decoded = html
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&amp;', '&')
      .replaceAll('<br>', '\n')
      .replaceAll('<br/>', '\n')
      .replaceAll('<br />', '\n')
      .replaceAll('</p>', '\n')
      .replaceAll(RegExp(r'<[^>]*>'), '');
  return decoded
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .join('\n');
}

/// Cheap sanity check on a downloaded APK: a ZIP starts with a local header and
/// ends with an end-of-central-directory record. A truncated transfer fails one
/// of the two, which Android would report as "problem parsing the package".
Future<bool> _looksLikeApk(File file) async {
  try {
    final length = await file.length();
    if (length < 64) return false;
    final head = await file.openRead(0, 4).first;
    if (head.length < 4 || head[0] != 0x50 || head[1] != 0x4B) return false;
    final tailStart = length > 65558 ? length - 65558 : 0;
    final tail = await file.openRead(tailStart).fold<List<int>>(
      <int>[],
      (all, chunk) => all..addAll(chunk),
    );
    for (var i = tail.length - 22; i >= 0; i--) {
      if (tail[i] == 0x50 &&
          tail[i + 1] == 0x4B &&
          tail[i + 2] == 0x05 &&
          tail[i + 3] == 0x06) {
        return true;
      }
    }
    return false;
  } catch (_) {
    return false;
  }
}
