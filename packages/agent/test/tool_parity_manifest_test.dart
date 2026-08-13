@Tags(<String>['feature_test__tool_harness_parity__unit'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:agent/agent.dart';
import 'package:test/test.dart';

void main() {
  test(
    'pinned Codex v2 manifest separates core, exclusions, and extensions',
    () {
      final manifest = jsonDecode(
        _fixture().readAsStringSync(),
      ) as Map<String, dynamic>;
      final source = manifest['source']! as Map<String, dynamic>;
      expect(
        source['commit'],
        '646f7c0a91b8e327d263335da68ae8ef212895ce',
      );
      expect(source['protocol'], 'modern-v2');

      final core = (manifest['core']! as List)
          .cast<Map<String, dynamic>>()
          .map((entry) => entry['name']! as String)
          .toSet();
      final excluded = (manifest['excluded']! as List).cast<String>().toSet();
      final extensions = (manifest['extensions']! as List)
          .cast<String>()
          .toSet();
      expect(core.intersection(excluded), isEmpty);
      expect(core.intersection(extensions), isEmpty);
      expect(excluded.intersection(extensions), isEmpty);
      expect(
        core,
        containsAll(<String>{'apply_patch', 'exec', 'skills__read'}),
      );
      expect(excluded, contains('javascript_code_mode'));
    },
  );

  test('representative runtime declarations match the pinned wire kinds', () {
    final definitions = <ModelToolDefinition>[
      ApplyPatchTool().modelSpec,
      GetContextRemainingTool().modelSpec,
      CurrentTimeTool(clock: const _Clock()).modelSpec,
    ];
    expect(definitions.map((definition) => definition.kind), <ModelToolKind>[
      ModelToolKind.freeform,
      ModelToolKind.function,
      ModelToolKind.namespace,
    ]);
    expect(definitions.map((definition) => definition.name), <String>[
      'apply_patch',
      'get_context_remaining',
      'clock',
    ]);
  });
}

File _fixture() {
  final candidates = <File>[
    File('test/fixtures/codex_v2_tool_manifest.json'),
    File('packages/agent/test/fixtures/codex_v2_tool_manifest.json'),
  ];
  return candidates.firstWhere((file) => file.existsSync());
}

final class _Clock implements AgentClock {
  const _Clock();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('$invocation');
}
