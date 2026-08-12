import 'package:test/test.dart';

import '../../tool/src/desktop_e2e_cli.dart';

void main() {
  test('typed flags resolve defaults and explicit overrides', () async {
    DesktopE2eCliOptions? captured;

    expect(
      await runDesktopE2eCli(
        const <String>[],
        detectedJobs: 6,
        defaultSeed: 7,
        execute: (options) async {
          captured = options;
          return 0;
        },
      ),
      0,
    );
    expect(captured?.jobs, 6);
    expect(captured?.seed, 7);

    expect(
      await runDesktopE2eCli(
        const <String>[
          '--jobs=2',
          '--seed',
          '0',
          '--scenario=relay',
          '--report=report.json',
        ],
        detectedJobs: 6,
        defaultSeed: 7,
        execute: (options) async {
          captured = options;
          return 23;
        },
      ),
      23,
    );
    expect(captured?.jobs, 2);
    expect(captured?.seed, 0);
    expect(captured?.scenario, 'relay');
    expect(captured?.reportPath, 'report.json');
  });

  test('invalid options fail before executing the runner', () async {
    var executions = 0;
    for (final arguments in <List<String>>[
      <String>['--jobs=0'],
      <String>['--scenario=missing'],
      <String>['--unknown'],
      <String>['--report='],
    ]) {
      expect(
        await runDesktopE2eCli(
          arguments,
          detectedJobs: 4,
          defaultSeed: 1,
          execute: (_) async {
            executions += 1;
            return 0;
          },
        ),
        64,
      );
    }
    expect(executions, 0);
  });

  test('help exits without executing the runner', () async {
    var executions = 0;
    expect(
      await runDesktopE2eCli(
        const <String>['--help'],
        detectedJobs: 4,
        defaultSeed: 1,
        execute: (_) async {
          executions += 1;
          return 0;
        },
      ),
      0,
    );
    expect(executions, 0);
  });
}
