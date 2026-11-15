import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_type.dart';
import '../theme/metrics.dart';
import '../util/format.dart';
import '../util/updates.dart';
import '../widgets/ui.dart';

/// The Updates page: what this build is, one manual check against GitHub, the
/// download it offers, and the releases before it.
Future<void> openUpdates(BuildContext context) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const UpdatesScreen()),
  );
}

class UpdatesScreen extends StatefulWidget {
  const UpdatesScreen({super.key});

  @override
  State<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen> {
  final UpdateController _updates = UpdateController.instance;

  @override
  void initState() {
    super.initState();
    _updates.loadInstalled();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.bg,
      body: ListenableBuilder(
        listenable: _updates,
        builder: (context, _) {
          final latest = _updates.latest;
          final selected = _updates.selected;
          // Offer the newer build when there is one; otherwise a release the
          // user explicitly picked from the list.
          final offer = _updates.hasUpdate
              ? latest
              : (selected != null && selected.version != _updates.installed
                  ? selected
                  : null);
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              Metrics.gutter,
              Metrics.topInset(context),
              Metrics.gutter,
              Metrics.bottomInset(context) + 30,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HeadBar(
                  onBack: () => Navigator.of(context).maybePop(),
                  center: 'Updates',
                ),
                const SizedBox(height: 22),
                Text(
                  'You are on ${_updates.installedLabel}. Updates are checked '
                  'here when you ask, never in the background.',
                  style: AppType.body.copyWith(color: colors.muted),
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: switch (_updates.phase) {
                    UpdatePhase.checking => 'Checking…',
                    _ => 'Check for updates',
                  },
                  tone: AppButtonTone.secondary,
                  expand: true,
                  onPressed: _updates.busy ? null : _updates.check,
                ),
                if (_updates.message != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _updates.message!,
                    style: AppType.meta.copyWith(color: colors.muted),
                  ),
                ],
                // The release on offer: the newer build when GitHub has one,
                // or whichever older build the user picked to download.
                if (offer != null) ...[
                  const SizedBox(height: 24),
                  SectionTitle('Version ${offer.version}'),
                  const SizedBox(height: 6),
                  Text(
                    _releaseSubtitle(offer),
                    style: AppType.meta.copyWith(color: colors.muted),
                  ),
                  const SizedBox(height: 12),
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (offer.notes.isNotEmpty) ...[
                          Text(
                            _shortNotes(offer.notes),
                            maxLines: 6,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.meta.copyWith(
                              color: colors.text,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        _DownloadArea(
                          release: offer,
                          file: _updates.downloaded,
                        ),
                      ],
                    ),
                  ),
                ],
                if (latest == null && _updates.releases.isEmpty) ...[
                  const SizedBox(height: 18),
                  Text(
                    _updates.phase == UpdatePhase.current
                        ? 'No newer release is published.'
                        : 'Tap check to ask GitHub for the latest release.',
                    style: AppType.meta.copyWith(color: colors.faint),
                  ),
                ],
                if (_updates.releases.isNotEmpty) ...[
                  const SizedBox(height: 26),
                  SectionTitle('Earlier versions'),
                  const SizedBox(height: 6),
                  Text(
                    'Installing an older build over this one is refused by '
                    'Android; it would need an uninstall first, which clears '
                    'your habits.',
                    style: AppType.micro.copyWith(color: colors.faint),
                  ),
                  const SizedBox(height: 8),
                  for (final release in _updates.releases)
                    _ReleaseRow(
                      release: release,
                      current: release.version == _updates.installed,
                      selected: selected?.version == release.version,
                      busy: _updates.busy,
                      onDownload: () => _updates.download(release),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  String _releaseSubtitle(AppRelease release) {
    final parts = <String>[];
    if (release.publishedAt != null) parts.add(Fmt.shortDate(release.publishedAt!));
    if (release.apkBytes > 0) {
      parts.add('${(release.apkBytes / (1024 * 1024)).toStringAsFixed(1)} MB');
    }
    return parts.isEmpty ? 'Published on GitHub' : parts.join(' · ');
  }

  /// Release bodies start with headings and paragraphs; keep the first lines.
  String _shortNotes(String notes) {
    final lines = notes
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty && !line.startsWith('#'))
        .take(5)
        .join('\n');
    return lines.replaceAll(RegExp(r'[*_`]'), '');
  }
}

/// Download → progress → install, for the release on offer.
class _DownloadArea extends StatelessWidget {
  const _DownloadArea({required this.release, required this.file});

  final AppRelease release;
  final dynamic file;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final updates = UpdateController.instance;
    if (updates.downloading) {
      final pct = (updates.progress * 100).round();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: updates.progress,
              minHeight: 6,
              backgroundColor: colors.surface2,
              valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Downloading… $pct%',
            style: AppType.meta.copyWith(color: colors.muted),
          ),
        ],
      );
    }
    if (file != null && updates.selected?.version == release.version) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppButton(
            label: 'Install ${release.version}',
            expand: true,
            onPressed: updates.install,
          ),
          const SizedBox(height: 8),
          Text(
            'Android asks you to allow installs from Accrue the first time, '
            'then shows its own install dialog.',
            style: AppType.micro.copyWith(color: colors.faint),
          ),
        ],
      );
    }
    return AppButton(
      label: 'Download ${release.version}',
      expand: true,
      onPressed: updates.busy ? null : () => updates.download(release),
    );
  }
}

class _ReleaseRow extends StatelessWidget {
  const _ReleaseRow({
    required this.release,
    required this.current,
    required this.selected,
    required this.busy,
    required this.onDownload,
  });

  final AppRelease release;
  final bool current;
  final bool selected;
  final bool busy;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final when = release.publishedAt == null
        ? ''
        : Fmt.shortDate(release.publishedAt!);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      release.version,
                      style: AppType.body.copyWith(
                        color: colors.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (current) ...[
                      const SizedBox(width: 8),
                      _Chip(label: 'installed', colors: colors),
                    ] else if (selected) ...[
                      const SizedBox(width: 8),
                      _Chip(label: 'selected', colors: colors),
                    ],
                  ],
                ),
                if (when.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    when,
                    style: AppType.micro.copyWith(color: colors.muted),
                  ),
                ],
              ],
            ),
          ),
          AppIconButton(
            icon: 'download',
            size: 38,
            iconSize: 16,
            filled: true,
            label: 'Download ${release.version}',
            onTap: release.hasApk && !busy ? onDownload : null,
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.colors});

  final String label;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: colors.surface2,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppType.micro.copyWith(fontSize: 10, color: colors.muted),
      ),
    );
  }
}
