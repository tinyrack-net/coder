/// Desktop operating systems supported by workspace verification.
enum DesktopHost {
  /// Linux desktop host.
  linux,

  /// macOS desktop host.
  macos,

  /// Windows desktop host.
  windows;

  /// Resolves Dart's operating-system name to a supported desktop host.
  static DesktopHost? fromOperatingSystem(String value) => switch (value) {
    'linux' => linux,
    'macos' => macos,
    'windows' => windows,
    _ => null,
  };
}
