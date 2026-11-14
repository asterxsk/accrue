import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_type.dart';
import '../theme/metrics.dart';
import '../widgets/brand_mark.dart';
import '../widgets/ui.dart';

/// Shown in the profile and on the About page.
const String appVersion = '2.2';

/// The app's display name.
const String appName = 'Accrue';

/// The name the app is signed with.
const String studioName = 'Wrong Turn';

Future<void> openAbout(BuildContext context) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const AboutScreen()),
  );
}

/// Full-page About: the version, what the app does and does not do, and the
/// licences that ship inside it.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.bg,
      body: SingleChildScrollView(
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
              center: 'About',
            ),
            const SizedBox(height: 18),
            Center(
              child: Semantics(
                label: appName,
                image: true,
                child: const BrandMark(size: 68),
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: Text(
                appName,
                style: AppType.displayName.copyWith(color: colors.text),
              ),
            ),
            const SizedBox(height: 2),
            Center(
              child: Text(
                'Version $appVersion',
                style: AppType.meta.copyWith(color: colors.muted),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'by $studioName',
                style: AppType.meta.copyWith(color: colors.faint),
              ),
            ),
            const SizedBox(height: 26),
            _Section(
              title: 'What Accrue means',
              body:
                  'To accrue is to build up over time. Every check, glass and '
                  'minute adds to a record that only grows — kept on this '
                  'device, never sent anywhere.',
            ),
            _Section(
              title: 'Local only',
              body:
                  'There is no account, no sync and no network. Your habits, '
                  'history and profile stay in this device\'s storage, and '
                  'clearing the app\'s data removes them.',
            ),
            _Section(
              title: 'What is inside',
              body:
                  'Check-off, counted and timed habits with icons or a text '
                  'badge, half-unit counts, ordered routines, week insights, a '
                  'month heat map, per-habit reminders, a share card, and focus '
                  'blocking for timed habits on Android.',
            ),
            _Section(
              title: 'Focus blocking',
              body:
                  'While a timed habit runs, Android accessibility access is '
                  'used to draw a blocked screen over the apps you pick. The '
                  'service is declared without window-content access: it reads '
                  'the package name of the front app and nothing else. It is '
                  'off until you switch it on in system settings.',
            ),
            _Section(
              title: 'Reminders',
              body:
                  'Each habit can carry one daily reminder. Accrue asks Android '
                  'for notification permission the first time one is set; the '
                  'time is kept on device even when notifications are denied. '
                  'Backups exported from Data & export contain every habit, '
                  'routine, day of history, setting and the profile.',
            ),
            _Section(
              title: 'Licences',
              body:
                  'Icons: Lucide (ISC). Type: Source Serif 4 and Inter '
                  '(SIL Open Font License). Built with Flutter under the '
                  'BSD-3-Clause licence.',
            ),
            const SizedBox(height: 22),
            Text(
              'Made by $studioName · on this device, nothing leaves it',
              style: AppType.micro.copyWith(color: colors.faint),
            ),
            const SizedBox(height: 6),
            Text(
              '© 2026 $studioName',
              style: AppType.micro.copyWith(color: colors.faint),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: AppType.eyebrow.copyWith(color: colors.muted),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: AppType.body.copyWith(color: colors.text, height: 1.5),
          ),
        ],
      ),
    );
  }
}
