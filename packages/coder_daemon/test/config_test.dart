import 'dart:convert';

import 'package:coder_daemon/coder_daemon.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('config isolate serialization and copy preserve explicit values', () {
    const config = DaemonConfig(
      homeDirectory: '/state',
      configDirectory: '/config',
      userHomeDirectory: '/user',
      host: '0.0.0.0',
      port: 8123,
      apiKey: 'api-key',
      bearerToken: 'token',
      version: '2.0.0',
      useEnvironmentCredentials: false,
    );
    final decoded = DaemonConfig.fromIsolateMessage(config.toIsolateMessage());
    expect(decoded.homeDirectory, '/state');
    expect(decoded.configDirectory, '/config');
    expect(decoded.userHomeDirectory, '/user');
    expect(decoded.host, '0.0.0.0');
    expect(decoded.port, 8123);
    expect(decoded.apiKey, 'api-key');
    expect(decoded.bearerToken, 'token');
    expect(decoded.version, '2.0.0');
    expect(decoded.useEnvironmentCredentials, isFalse);

    final copy = config.copyWith(
      homeDirectory: '/other-state',
      configDirectory: '/other-config',
      userHomeDirectory: '/other-user',
      host: 'localhost',
      port: 9000,
      apiKey: 'other-key',
      bearerToken: 'other-token',
      useEnvironmentCredentials: true,
    );
    expect(copy.homeDirectory, '/other-state');
    expect(copy.configDirectory, '/other-config');
    expect(copy.userHomeDirectory, '/other-user');
    expect(copy.host, 'localhost');
    expect(copy.port, 9000);
    expect(copy.apiKey, 'other-key');
    expect(copy.bearerToken, 'other-token');
    expect(copy.version, config.version);
    expect(copy.useEnvironmentCredentials, isTrue);
  });

  test('environment config supports Linux defaults and explicit override', () {
    final defaults = DaemonConfig.fromEnvironment(
      environment: const _Environment(
        values: <String, String>{
          'HOME': '/home/test',
          'XDG_CONFIG_HOME': '/xdg/config',
          'XDG_STATE_HOME': '/xdg/state',
        },
        linux: true,
      ),
    );
    // The daemon joins with the host separator, which is what a daemon
    // running on that host should do, so the expectations join too rather
    // than pinning a slash.
    expect(defaults.configDirectory, p.join('/xdg/config', 'tinyrack-coder'));
    expect(defaults.homeDirectory, p.join('/xdg/state', 'tinyrack-coder'));
    expect(defaults.userHomeDirectory, '/home/test');
    expect(defaults.host, '127.0.0.1');
    expect(defaults.port, 7337);

    final override = DaemonConfig.fromEnvironment(
      apiKey: 'key',
      environment: const _Environment(
        values: <String, String>{
          'TINYRACK_CODER_HOME': '/override',
          'TINYRACK_CODER_LISTEN': '0.0.0.0:9001',
          'TINYRACK_CODER_TOKEN': 'token',
          'HOME': '/unused',
        },
        linux: true,
      ),
    );
    expect(override.homeDirectory, '/override');
    expect(override.configDirectory, '/override');
    // TINYRACK_CODER_HOME relocates daemon-owned state only. The shared
    // `~/.agents` tree still belongs to the real user home.
    expect(override.userHomeDirectory, '/unused');
    expect(override.host, '0.0.0.0');
    expect(override.port, 9001);
    expect(override.apiKey, 'key');
    expect(override.bearerToken, 'token');
  });

  test('agents home override wins over the platform user home', () {
    final overridden = DaemonConfig.fromEnvironment(
      environment: const _Environment(
        values: <String, String>{
          'HOME': '/home/test',
          'TINYRACK_CODER_AGENTS_HOME': '/tmp/agents-home',
        },
        linux: true,
      ),
    );
    expect(overridden.userHomeDirectory, '/tmp/agents-home');

    final windows = DaemonConfig.fromEnvironment(
      environment: const _Environment(
        values: <String, String>{
          'USERPROFILE': r'C:\Users\test',
          'APPDATA': r'C:\Roaming',
          'LOCALAPPDATA': r'C:\Local',
        },
        windows: true,
      ),
    );
    expect(windows.userHomeDirectory, r'C:\Users\test');
  });

  test('platform-specific defaults cover macOS, Windows, and fallback', () {
    final macOS = DaemonConfig.fromEnvironment(
      environment: const _Environment(
        values: <String, String>{'HOME': '/Users/test'},
        macOS: true,
      ),
    );
    expect(
      macOS.homeDirectory,
      p.join('/Users/test', 'Library', 'Application Support', 'Tinyrack Coder'),
    );
    expect(macOS.configDirectory, macOS.homeDirectory);

    final windows = DaemonConfig.fromEnvironment(
      environment: const _Environment(
        values: <String, String>{
          'USERPROFILE': r'C:\Users\test',
          'APPDATA': r'C:\Roaming',
          'LOCALAPPDATA': r'C:\Local',
        },
        windows: true,
      ),
    );
    expect(windows.configDirectory, contains('Roaming'));
    expect(windows.homeDirectory, contains('Local'));

    final fallback = DaemonConfig.fromEnvironment(
      environment: const _Environment(
        values: <String, String>{'HOME': '/home/test'},
      ),
    );
    expect(
      fallback.configDirectory,
      p.join('/home/test', '.config', 'tinyrack-coder'),
    );
    expect(
      fallback.homeDirectory,
      p.join('/home/test', '.local', 'state', 'tinyrack-coder'),
    );
  });

  test('invalid listen address is rejected and bearer tokens are 256-bit', () {
    expect(
      () => DaemonConfig.fromEnvironment(
        environment: const _Environment(
          values: <String, String>{'TINYRACK_CODER_LISTEN': 'invalid'},
          linux: true,
        ),
      ),
      throwsA(isA<FormatException>()),
    );
    final token = generateBearerToken();
    expect(base64Url.decode(base64Url.normalize(token)), hasLength(32));
    expect(token, isNot(contains('=')));
  });

  test('IO environment adapter reflects the running process', () {
    const environment = IoDaemonEnvironment();
    expect(environment.values, isNotNull);
    expect(
      <bool>[
        environment.isLinux,
        environment.isMacOS,
        environment.isWindows,
      ].where((value) => value),
      hasLength(1),
    );
  });
}

final class _Environment implements DaemonEnvironment {
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
