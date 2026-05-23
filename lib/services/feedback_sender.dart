import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';

// Opens the system mail composer pre-addressed to Vanessa with a body that
// includes app + device context, so triaging feedback doesn't need an extra
// back-and-forth on "which version are you on?".
class FeedbackSender {
  static const _recipient = 'hi.nourishme@gmail.com';

  static Future<void> openFeedbackMail(AppLocalizations l10n) async {
    final pkg = await PackageInfo.fromPlatform();
    String deviceLine = '';
    try {
      final info = DeviceInfoPlugin();
      if (Platform.isIOS) {
        final ios = await info.iosInfo;
        deviceLine =
            '${l10n.feedbackMailDeviceLabel}: ${ios.utsname.machine} · iOS ${ios.systemVersion}';
      } else if (Platform.isAndroid) {
        final android = await info.androidInfo;
        deviceLine =
            '${l10n.feedbackMailDeviceLabel}: ${android.model} · Android ${android.version.release}';
      }
    } catch (_) {
      // Device info is a nice-to-have; not a blocker.
    }

    final body = '''


--
${l10n.feedbackMailTriageHint}
App: NourishMe ${pkg.version}+${pkg.buildNumber}
$deviceLine
''';

    final uri = Uri(
      scheme: 'mailto',
      path: _recipient,
      query: _encode({
        'subject': l10n.feedbackMailSubject,
        'body': body,
      }),
    );

    await launchUrl(uri);
  }

  // Manual query string encoder. Uri's queryParameters helpfully replaces
  // spaces with '+' which most mail apps don't decode back, so we encode
  // explicitly with %20.
  static String _encode(Map<String, String> params) => params.entries
      .map((e) =>
          '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeComponent(e.value)}')
      .join('&');
}
