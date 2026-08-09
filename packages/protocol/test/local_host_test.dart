import 'package:protocol/local_host.dart';
import 'package:test/test.dart';

void main() {
  test('resolves Linux XDG directories and explicit agent home', () {
    final directories = resolveLocalDaemonDirectories(
      environment: const _Environment(
        values: <String, String>{
          'HOME': '/home/coder',
          'XDG_CONFIG_HOME': '/config',
          'XDG_STATE_HOME': '/state',
          'TINYRACK_CODER_AGENTS_HOME': '/agents',
        },
        linux: true,
      ),
    );

    expect(directories.configDirectory, '/config/tinyrack-coder');
    expect(directories.stateDirectory, '/state/tinyrack-coder');
    expect(directories.userHomeDirectory, '/agents');
    expect(directories.osHomeDirectory, '/home/coder');
  });

  test('one Coder home override owns config and state', () {
    final directories = resolveLocalDaemonDirectories(
      environment: const _Environment(
        values: <String, String>{
          'HOME': '/home/coder',
          'TINYRACK_CODER_HOME': '/coder',
        },
        linux: true,
      ),
    );

    expect(directories.configDirectory, '/coder');
    expect(directories.stateDirectory, '/coder');
    expect(directories.userHomeDirectory, '/home/coder');
  });

  test('resolves macOS, Windows, and fallback conventions', () {
    final macOS = resolveLocalDaemonDirectories(
      environment: const _Environment(
        values: <String, String>{'HOME': '/Users/coder'},
        macOS: true,
      ),
    );
    expect(
      macOS.configDirectory,
      '/Users/coder/Library/Application Support/Tinyrack Coder',
    );
    expect(macOS.stateDirectory, macOS.configDirectory);

    final windows = resolveLocalDaemonDirectories(
      environment: const _Environment(
        values: <String, String>{
          'USERPROFILE': r'C:\Users\coder',
          'APPDATA': r'C:\Roaming',
          'LOCALAPPDATA': r'C:\Local',
        },
        windows: true,
      ),
    );
    expect(windows.configDirectory, r'C:\Roaming\Tinyrack Coder');
    expect(windows.stateDirectory, r'C:\Local\Tinyrack Coder');

    final fallback = resolveLocalDaemonDirectories(
      environment: const _Environment(values: <String, String>{}),
    );
    expect(fallback.configDirectory, './.config/tinyrack-coder');
    expect(fallback.stateDirectory, './.local/state/tinyrack-coder');
  });

  test('uses platform fallbacks when optional variables are absent', () {
    final linux = resolveLocalDaemonDirectories(
      environment: const _Environment(
        values: <String, String>{'HOME': '/home/coder'},
        linux: true,
      ),
    );
    expect(linux.configDirectory, '/home/coder/.config/tinyrack-coder');
    expect(linux.stateDirectory, '/home/coder/.local/state/tinyrack-coder');

    final windows = resolveLocalDaemonDirectories(
      environment: const _Environment(
        values: <String, String>{'USERPROFILE': r'C:\Users\coder'},
        windows: true,
      ),
    );
    expect(windows.configDirectory, r'C:\Users\coder\Tinyrack Coder');
    expect(windows.stateDirectory, windows.configDirectory);
  });

  test('parses listen addresses and rejects missing or invalid ports', () {
    expect(parseLocalDaemonListen(defaultLocalDaemonListen), (
      '127.0.0.1',
      7337,
    ));
    expect(parseLocalDaemonListen('::1:7444'), ('::1', 7444));
    expect(() => parseLocalDaemonListen('localhost'), throwsFormatException);
    expect(
      () => parseLocalDaemonListen('localhost:http'),
      throwsFormatException,
    );
  });
}

final class _Environment implements LocalDaemonEnvironment {
  const _Environment({
    required this.values,
    this.linux = false,
    this.macOS = false,
    this.windows = false,
  });

  @override
  final Map<String, String> values;

  final bool linux;
  final bool macOS;
  final bool windows;

  @override
  bool get isLinux => linux;

  @override
  bool get isMacOS => macOS;

  @override
  bool get isWindows => windows;
}
