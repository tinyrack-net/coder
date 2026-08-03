import 'package:coder_daemon/src/agent_cli.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:test/test.dart';

void main() {
  test('agent CLI lists, validates, applies, archives, and resets', () async {
    final backend = _AgentBackend();
    final output = StringBuffer();

    expect(
      await runAgentCommand(<String>['list'], backend: backend, output: output),
      0,
    );
    expect(output.toString(), contains('coder'));

    expect(
      await runAgentCommand(
        <String>['validate', '/tmp/reviewer.md'],
        backend: backend,
        output: output,
        readFile: (_) async => 'markdown',
      ),
      0,
    );
    expect(
      await runAgentCommand(
        <String>['apply', 'reviewer', '--file', '/tmp/reviewer.md'],
        backend: backend,
        output: output,
        readFile: (_) async => 'markdown',
      ),
      0,
    );
    expect(backend.applied, contains('reviewer'));
    expect(
      await runAgentCommand(
        <String>['archive', 'reviewer'],
        backend: backend,
        output: output,
      ),
      0,
    );
    expect(
      await runAgentCommand(
        <String>['reset', 'coder'],
        backend: backend,
        output: output,
      ),
      0,
    );
  });

  test(
    'agent CLI reports help, stale state, and invalid command shapes',
    () async {
      final backend = _AgentBackend(includeStale: true);
      final output = StringBuffer();
      expect(
        await runAgentCommand(
          const <String>[],
          backend: backend,
          output: output,
        ),
        0,
      );
      expect(
        await runAgentCommand(
          const <String>['help'],
          backend: backend,
          output: output,
        ),
        0,
      );
      await runAgentCommand(
        const <String>['list'],
        backend: backend,
        output: output,
      );
      expect(output.toString(), contains('stale'));

      final invalidCommands = <List<String>>[
        <String>['validate'],
        <String>['apply', '--file', '/tmp/reviewer.md'],
        <String>['archive'],
        <String>['reset', 'reviewer'],
        <String>['unknown'],
      ];
      for (final command in invalidCommands) {
        await expectLater(
          runAgentCommand(command, backend: backend, output: output),
          throwsA(isA<FormatException>()),
        );
      }
      await expectLater(
        runAgentCommand(
          const <String>['validate', '/tmp/reviewer.md'],
          backend: backend,
          output: output,
        ),
        throwsA(isA<StateError>()),
      );
    },
  );
}

final class _AgentBackend implements AgentCliBackend {
  _AgentBackend({this.includeStale = false});

  final bool includeStale;
  final List<String> applied = <String>[];

  AgentDefinitionDto definition(String id) => AgentDefinitionDto(
    id: id,
    name: id,
    description: '',
    mode: id == 'coder' ? AgentMode.primary : AgentMode.subagent,
    promptEnabled: true,
    systemPrompt: 'prompt',
    model: const AgentModelSelectionDto(
      source: AgentModelSource.daemonDefault,
    ),
    reasoningEffort: 'medium',
    permissionMode: PermissionMode.ask,
    toolIds: const <String>[],
    callableAgentIds: const <String>[],
    contentHash: 'hash',
    sourcePath: '/config/agents/$id.md',
    isBuiltIn: id == 'coder',
  );

  @override
  Future<void> archive(String id) async {}

  @override
  Future<AgentDefinitionDto> apply(
    String id,
    AgentDefinitionDto definition,
  ) async {
    applied.add(id);
    return definition;
  }

  @override
  Future<List<AgentDefinitionDto>> list() async => <AgentDefinitionDto>[
    definition('coder'),
    if (includeStale)
      definition('stale').copyWith(
        isStale: true,
        diagnostics: const <AgentDefinitionDiagnosticDto>[
          AgentDefinitionDiagnosticDto(
            code: 'invalid_agent_markdown',
            message: 'broken',
          ),
        ],
      ),
  ];

  @override
  Future<AgentDefinitionDto> reset(String id) async => definition(id);

  @override
  Future<AgentDefinitionDto> validate(String id, String markdown) async =>
      definition(id);
}
