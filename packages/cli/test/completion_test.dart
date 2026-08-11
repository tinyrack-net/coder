import 'package:cli/cli.dart';
import 'package:client/local_daemon.dart';
import 'package:test/test.dart';

import 'helpers/capture_stream.dart';

void main() {
  late CaptureStream out;

  setUp(() => out = CaptureStream());

  const directories = LocalDaemonDirectories(
    configDirectory: '/config',
    stateDirectory: '/state',
    userHomeDirectory: '/home/test',
    osHomeDirectory: '/home/test',
  );

  Future<String> complete(List<String> words) async {
    await runCli(
      <String>['__complete', ...words],
      stdout: out,
      stderr: CaptureStream(),
      environment: const <String, String>{},
      directories: directories,
      connectClient:
          ({
            required host,
            required port,
            required bearerToken,
            required clientId,
          }) async => fail('completion must never connect to a daemon'),
      readSecret: () async => fail('completion must never prompt'),
      readFile: (_) async => fail('completion must never read files'),
    );
    return out.text;
  }

  test('an empty line proposes every top-level route', () async {
    final proposals = await complete(<String>['tinest-cli', '']);

    expect(proposals, contains('daemon'));
    expect(proposals, contains('provider'));
    expect(proposals, contains('agent'));
    expect(proposals, contains('completion'));
  });

  test('a partial route narrows the proposals', () async {
    final proposals = await complete(<String>['tinest-cli', 'prov']);

    expect(proposals, contains('provider'));
    expect(proposals, isNot(contains('agent')));
  });

  test('a route map proposes its subcommands', () async {
    final proposals = await complete(<String>['tinest-cli', 'provider', '']);

    expect(proposals, contains('list'));
    expect(proposals, contains('connect'));
    expect(proposals, contains('disconnect'));
    expect(proposals, contains('catalog-refresh'));
  });

  test('a command proposes its own flags', () async {
    final proposals = await complete(<String>[
      'tinest-cli',
      'provider',
      'list',
      '--',
    ]);

    expect(proposals, contains('--home'));
    expect(proposals, contains('--listen'));
    expect(proposals, contains('--token'));
  });

  test('the hidden --api-key flag is never proposed', () async {
    final proposals = await complete(<String>[
      'tinest-cli',
      'provider',
      'connect',
      '--',
    ]);

    expect(proposals, contains('--method'));
    // Passing a secret on the command line leaks it into shell history, so
    // completion must not offer it either.
    expect(proposals, isNot(contains('--api-key')));
  });

  test('the hidden --api-key flag stays out of help', () async {
    final help = CaptureStream();
    await runCli(
      <String>['provider', 'connect', '--help'],
      stdout: help,
      stderr: CaptureStream(),
      environment: const <String, String>{},
      directories: directories,
    );

    expect(help.text, contains('--method'));
    expect(help.text, isNot(contains('--api-key')));
  });

  test('daemon start proposes its own options', () async {
    final proposals = await complete(<String>[
      'tinest-cli',
      'daemon',
      'start',
      '--',
    ]);

    expect(proposals, contains('--allowed-origin'));
    expect(proposals, contains('--listen'));
  });

  test('every shell script calls the sanitized completion function', () {
    final scripts = <String>[
      completionScripts.bash,
      completionScripts.zsh,
      completionScripts.fish,
      completionScripts.powershell,
    ];

    for (final script in scripts) {
      expect(script, contains('tinest-cli'));
      expect(script, contains('__complete'));
      // A shell function name cannot contain a hyphen, so the executable name
      // is sanitized rather than interpolated verbatim.
      expect(script, isNot(contains('__tinest-cli_complete')));
    }
    expect(completionScripts.bash, contains('__tinest_cli_complete'));
  });

  test('each shell gets its own script through a command', () async {
    for (final shell in <String>['bash', 'zsh', 'fish', 'powershell']) {
      final stdout = CaptureStream();
      final code = await runCli(
        <String>['completion', shell],
        stdout: stdout,
        stderr: CaptureStream(),
        environment: const <String, String>{},
        directories: directories,
      );

      expect(code, 0, reason: 'completion $shell');
      expect(stdout.text, isNotEmpty, reason: 'completion $shell');
    }
  });
}
