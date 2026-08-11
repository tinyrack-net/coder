import 'package:app/src/features/hosts/domain/host_models.dart';

/// Argument the registered login item passes back to the app.
///
/// The operating system launcher is the only caller that supplies it, which
/// is what separates a login launch from one the user started.
const String startMinimizedFlag = '--start-minimized';

/// Whether this launch should go straight to the tray without a window.
///
/// Both the stored preference and the login-item argument are required, so
/// opening the app yourself always shows a window even while the preference
/// is on.
bool shouldStartHidden({
  required List<String> arguments,
  required AppSettings settings,
}) => settings.startMinimizedAtBoot && arguments.contains(startMinimizedFlag);

/// Returns the canonical pairing route supplied by a desktop protocol launch.
///
/// Only a fragment capability is accepted. Query-string capabilities are
/// rejected so operating-system and web-server request logs cannot retain the
/// one-time secret.
String? desktopPairingInitialLocation(List<String> arguments) {
  for (final argument in arguments) {
    final uri = Uri.tryParse(argument);
    if (uri == null ||
        uri.scheme != 'tinyrack-coder' ||
        uri.host != 'pair' ||
        uri.path.isNotEmpty ||
        uri.query.isNotEmpty ||
        !uri.fragment.startsWith('offer=')) {
      continue;
    }
    return Uri(
      scheme: 'https',
      host: 'coder.tinyrack.net',
      path: '/pair',
      fragment: uri.fragment,
    ).toString();
  }
  return null;
}
