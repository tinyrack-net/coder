/// Product names and identifiers that move together when the app is renamed.
///
/// Native build systems cannot import Dart constants. The identity contract
/// test keeps their platform-local declarations synchronized with this source.
abstract final class AppIdentity {
  /// Organization shown with the product name.
  static const String vendorName = 'Tinyrack';

  /// Short product name used by launchers and compact UI.
  static const String name = 'Coder';

  /// Fully qualified product name used in explanatory UI.
  static const String displayName = '$vendorName $name';

  /// Lowercase product name used by files and release targets.
  static const String slug = 'coder';

  /// Native application identifier.
  static const String applicationId = 'net.tinyrack.$slug';

  /// Installed GUI executable name.
  static const String executableName = slug;

  /// Display name of the companion command-line application.
  static const String cliDisplayName = '$name CLI';

  /// Installed command-line executable name.
  static const String cliExecutableName = '$slug-cli';

  /// Namespace used by the daemon WebSocket protocol.
  static const String protocolNamespace = 'tinyrack.$slug';

  /// Prefix of environment variables owned by the product.
  static const String environmentPrefix = 'TINYRACK_CODER';

  /// Native user configuration directory name.
  static const String configDirectoryName = 'tinyrack-$slug';

  /// Prefix used by device-local persisted application settings.
  static const String storagePrefix = 'tinyrack_coder';

  /// Repository-local configuration directory name.
  static const String projectConfigDirectoryName = '.$slug';
}
