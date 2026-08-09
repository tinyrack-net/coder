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
