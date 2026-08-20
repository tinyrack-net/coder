@Tags(<String>['feature_test__plugin_runtime__unit'])
library;

import 'package:daemon/src/features/plugins/runtime/plugin_registration.dart';
import 'package:protocol/protocol.dart';
import 'package:test/test.dart';

void main() {
  test('tool registration rejects unsupported shapes before publication', () {
    final cases = <String, Map<String, Object?>>{
      'unsupported kind': _spec(
        tools: <Object?>[_tool('bad-kind', kind: 'streaming')],
      ),
      'non-object function input': _spec(
        tools: <Object?>[
          _tool('bad-input', inputSchema: <String, Object?>{'type': 'string'}),
        ],
      ),
      'non-array tools': <String, Object?>{'tools': 'not-an-array'},
      'empty tool id': _spec(
        tools: <Object?>[_tool('', bindingId: 'placeholder')],
      ),
      'duplicate tool id': _spec(
        tools: <Object?>[_tool('same'), _tool('same')],
      ),
      'undeclared capability': _spec(
        tools: <Object?>[
          _tool(
            'capability',
            requiredCapabilities: <Object?>['network.request'],
          ),
        ],
      ),
      'invalid operation': _spec(
        tools: <Object?>[
          _tool('operation', operations: <Object?>['NOT AN OPERATION']),
        ],
      ),
      'duplicate operation': _spec(
        tools: <Object?>[
          _tool(
            'operation',
            operations: <Object?>[
              'host.workspace.read_text',
              'host.workspace.read_text',
            ],
          ),
        ],
      ),
    };

    for (final entry in cases.entries) {
      expect(
        () => _parse(entry.value),
        throwsA(isA<PluginRegistrationException>()),
        reason: entry.key,
      );
    }
  });

  test('opaque bindings reject wrong identity and author fields', () {
    final cases = <String, Map<String, Object?>>{
      'wrong kind': _spec(
        tools: <Object?>[
          _tool(
            'read',
            binding: <String, Object?>{
              'kind': 'driver',
              'id': 'read',
              'key': '__tinest.tool.read',
            },
          ),
        ],
      ),
      'wrong local ID': _spec(
        tools: <Object?>[
          _tool(
            'read',
            binding: <String, Object?>{
              'kind': 'tool',
              'id': 'other',
              'key': '__tinest.tool.read',
            },
          ),
        ],
      ),
      'extra binding field': _spec(
        tools: <Object?>[
          _tool(
            'read',
            binding: <String, Object?>{
              'kind': 'tool',
              'id': 'read',
              'key': '__tinest.tool.read',
              'handler': 'forged',
            },
          ),
        ],
      ),
    };

    for (final entry in cases.entries) {
      expect(
        () => _parse(entry.value),
        throwsA(isA<PluginRegistrationException>()),
        reason: entry.key,
      );
    }
  });

  test('schemas, metadata references, hooks, and UI slots fail closed', () {
    final cases = <String, Map<String, Object?>>{
      'unknown lifecycle': <String, Object?>{
        'hooks': <String, Object?>{'before_forever': <String, Object?>{}},
      },
      'missing control default': <String, Object?>{
        'session_controls': <Object?>[
          <String, Object?>{
            'id': 'mode',
            'schema': <String, Object?>{'type': 'boolean'},
          },
        ],
      },
      'unsupported UI slot': <String, Object?>{
        'ui': <Object?>[
          <String, Object?>{'id': 'card', 'slot': 'browser-overlay'},
        ],
      },
      // The host can only invalidate state it knows how to watch. Accepting a
      // name it does not know would read as a working declaration and then
      // silently never fire.
      'unsupported UI dependency': <String, Object?>{
        'ui': <Object?>[
          <String, Object?>{
            'id': 'card',
            'slot': 'timeline',
            'depends_on': <Object?>['the_weather'],
          },
        ],
      },
      'non-array UI dependencies': <String, Object?>{
        'ui': <Object?>[
          <String, Object?>{
            'id': 'card',
            'slot': 'timeline',
            'depends_on': 'session_tree',
          },
        ],
      },
      'duplicate UI dependency': <String, Object?>{
        'ui': <Object?>[
          <String, Object?>{
            'id': 'card',
            'slot': 'timeline',
            'depends_on': <Object?>['session_tree', 'session_tree'],
          },
        ],
      },
      'schema type is not scalar or array': _spec(
        tools: <Object?>[
          _tool('schema', inputSchema: <String, Object?>{'type': 42}),
        ],
      ),
      'schema number is non-finite': _spec(
        tools: <Object?>[
          _tool(
            'schema',
            inputSchema: <String, Object?>{
              'type': 'object',
              'maximum': double.infinity,
            },
          ),
        ],
      ),
      'schema contains non-JSON value': _spec(
        tools: <Object?>[
          _tool(
            'schema',
            inputSchema: <String, Object?>{
              'type': 'object',
              'default': DateTime.utc(2026),
            },
          ),
        ],
      ),
      'unsupported metadata reference': _spec(
        tools: <Object?>[
          _tool(
            'metadata',
            presentation: <String, Object?>{
              'target': <String, Object?>{
                '__tinest_ref': 'driver',
                'id': 'main',
              },
            },
          ),
        ],
      ),
      'metadata reference has extra field': _spec(
        tools: <Object?>[
          _tool(
            'metadata',
            presentation: <String, Object?>{
              'target': <String, Object?>{
                '__tinest_ref': 'ui',
                'id': 'card',
                'plugin': 'foreign',
              },
            },
          ),
        ],
      ),
      'metadata reference has invalid local ID': _spec(
        tools: <Object?>[
          _tool(
            'metadata',
            presentation: <String, Object?>{
              'target': <String, Object?>{
                '__tinest_ref': 'ui',
                'id': 'Not-Local',
              },
            },
          ),
        ],
      ),
    };

    for (final entry in cases.entries) {
      expect(
        () => _parse(entry.value),
        throwsA(isA<PluginRegistrationException>()),
        reason: entry.key,
      );
    }
  });

  test('effect classes map to host-enforced model tool risks', () {
    final registration = _parse(
      _spec(
        tools: <Object?>[
          _tool('read'),
          _tool('write', effects: <Object?>['workspace.write']),
          _tool('command', effects: <Object?>['process.command']),
          _tool('dangerous', effects: <Object?>['network.request']),
        ],
      ),
    );

    expect(
      registration.descriptor.contributions
          .map((contribution) => contribution.tool?.risk)
          .whereType<ToolRisk>(),
      <ToolRisk>[
        ToolRisk.read,
        ToolRisk.write,
        ToolRisk.command,
        ToolRisk.dangerous,
      ],
    );
    expect(registration.tools.first.binding.toString(), '__tinest.tool.read');
  });
}

PluginRegistration _parse(Map<String, Object?> spec) =>
    PluginRegistrationParser.parse(
      descriptor: const PluginDescriptorDto(
        apiMajor: 5,
        id: 'acme.validation',
        version: '1.0.0',
        name: 'Validation',
        entrypoint: 'main.lua',
        source: PluginSource.user,
        sourcePath: 'plugins/acme.validation',
        requestedCapabilities: <String>['state.read'],
      ),
      revisionHash: 'execution-revision',
      value: <String, Object?>{'api': 5, 'spec': spec},
    );

Map<String, Object?> _spec({List<Object?>? tools}) => <String, Object?>{
  'tools': ?tools,
};

Map<String, Object?> _tool(
  String id, {
  String? bindingId,
  String kind = 'function',
  Map<String, Object?> inputSchema = const <String, Object?>{'type': 'object'},
  Map<String, Object?>? binding,
  List<Object?>? requiredCapabilities,
  List<Object?>? operations,
  List<Object?>? effects,
  Map<String, Object?>? presentation,
}) => <String, Object?>{
  'id': id,
  'kind': kind,
  'input_schema': inputSchema,
  'binding':
      binding ??
      <String, Object?>{
        'kind': 'tool',
        'id': bindingId ?? id,
        'key': '__tinest.tool.${bindingId ?? id}',
      },
  'required_capabilities': ?requiredCapabilities,
  'declared_operations': ?operations,
  'effects': ?effects,
  'presentation': ?presentation,
};
