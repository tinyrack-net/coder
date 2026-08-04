import 'dart:convert';
import 'dart:io';

import 'package:coder_daemon/src/ports.dart';
import 'package:coder_daemon/src/project_settings.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('coder-project-settings-');
  });

  tearDown(() => root.delete(recursive: true));

  File settingsFile() => File(p.join(root.path, projectSettingsFileName));

  test('reports the workspace-root settings path', () {
    expect(
      const FileProjectSettingsStore().sourcePath(root.path),
      settingsFile().path,
    );
    expect(projectSettingsFileName, 'coder.json');
  });

  test('treats a missing or blank file as empty settings', () async {
    const store = FileProjectSettingsStore();

    expect(await store.load(root.path), const ProjectSettingsDto());

    await settingsFile().writeAsString('   \n');
    expect(await store.load(root.path), const ProjectSettingsDto());
  });

  test(
    'reads worktree hooks and drops blank commands',
    () async {
      await settingsFile().writeAsString(
        jsonEncode(<String, dynamic>{
          'worktree': <String, dynamic>{
            'setup': <String>['npm ci', '  ', ' npm run build '],
            'teardown': <String>['docker compose down'],
          },
        }),
      );

      expect(
        await const FileProjectSettingsStore().load(root.path),
        const ProjectSettingsDto(
          setup: <String>['npm ci', 'npm run build'],
          teardown: <String>['docker compose down'],
        ),
      );
    },
    tags: const <String>['feature_test__project_settings__unit'],
  );

  test('preserves unknown keys and drops empty hook lists on save', () async {
    await settingsFile().writeAsString(
      jsonEncode(<String, dynamic>{
        'scripts': <String, dynamic>{
          'typecheck': <String, dynamic>{'command': 'npm run typecheck'},
        },
        'worktree': <String, dynamic>{
          'setup': <String>['npm ci'],
          'teardown': <String>['docker compose down'],
          'futureHook': <String>['echo later'],
        },
      }),
    );
    const store = FileProjectSettingsStore();

    await store.save(
      root.path,
      const ProjectSettingsDto(setup: <String>['pnpm install']),
    );

    final document =
        jsonDecode(await settingsFile().readAsString()) as Map<String, dynamic>;
    expect(document['scripts'], <String, dynamic>{
      'typecheck': <String, dynamic>{'command': 'npm run typecheck'},
    });
    expect(document['worktree'], <String, dynamic>{
      'futureHook': <String>['echo later'],
      'setup': <String>['pnpm install'],
    });
    expect(
      await store.load(root.path),
      const ProjectSettingsDto(setup: <String>['pnpm install']),
    );
  });

  test('creates a formatted file when the project has no settings', () async {
    await const FileProjectSettingsStore().save(
      root.path,
      const ProjectSettingsDto(teardown: <String>['docker compose down']),
    );

    expect(
      await settingsFile().readAsString(),
      '{\n'
      '  "worktree": {\n'
      '    "teardown": [\n'
      '      "docker compose down"\n'
      '    ]\n'
      '  }\n'
      '}\n',
    );
  });

  test('removes the worktree section when every hook is cleared', () async {
    await settingsFile().writeAsString(
      jsonEncode(<String, dynamic>{
        'worktree': <String, dynamic>{
          'setup': <String>['npm ci'],
        },
      }),
    );

    await const FileProjectSettingsStore().save(
      root.path,
      const ProjectSettingsDto(),
    );

    expect(await settingsFile().readAsString(), '{}\n');
  });

  test('writes nothing when clearing hooks without a file', () async {
    await const FileProjectSettingsStore().save(
      root.path,
      const ProjectSettingsDto(),
    );

    expect(settingsFile().existsSync(), isFalse);
  });

  test('rejects malformed documents without overwriting them', () async {
    const store = FileProjectSettingsStore();

    await settingsFile().writeAsString('{ not json');
    await expectLater(
      store.load(root.path),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('invalid_project_settings'),
        ),
      ),
    );
    expect(await settingsFile().readAsString(), '{ not json');

    await settingsFile().writeAsString(jsonEncode(<String>['array']));
    await expectLater(store.load(root.path), throwsA(isA<FormatException>()));

    await settingsFile().writeAsString(
      jsonEncode(<String, dynamic>{'worktree': 'nope'}),
    );
    await expectLater(store.load(root.path), throwsA(isA<FormatException>()));

    await settingsFile().writeAsString(
      jsonEncode(<String, dynamic>{
        'worktree': <String, dynamic>{'setup': 'npm ci'},
      }),
    );
    await expectLater(store.load(root.path), throwsA(isA<FormatException>()));

    await settingsFile().writeAsString(
      jsonEncode(<String, dynamic>{
        'worktree': <String, dynamic>{
          'setup': <Object>[42],
        },
      }),
    );
    await expectLater(store.load(root.path), throwsA(isA<FormatException>()));
  });

  test('runs hook commands through the platform shell', () async {
    final result = await const ShellWorktreeHookRunner().run(
      r'printf "%s" "$CODER_WORKTREE_PATH" && printf error >&2 && exit 3',
      workingDirectory: root.path,
      environment: <String, String>{'CODER_WORKTREE_PATH': '/checkout'},
    );

    expect(result.exitCode, 3);
    expect(result.stdout, '/checkout');
    expect(result.stderr, 'error');
  }, testOn: '!windows');
}
