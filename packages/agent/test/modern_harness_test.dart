import 'package:agent/agent.dart';
import 'package:test/test.dart';

void main() {
  test('modern tool specs distinguish function and freeform tools', () {
    const function = ModelFunctionToolDefinition(
      name: 'read_file',
      description: 'Read a file.',
      parameters: <String, dynamic>{'type': 'object'},
      outputSchema: <String, dynamic>{'type': 'object'},
      supportsParallelToolCalls: true,
    );
    const freeform = ModelFreeformToolDefinition(
      name: 'apply_patch',
      description: 'Apply a patch.',
      format: ModelFreeformToolFormat(
        type: 'grammar',
        syntax: 'lark',
        definition: 'start: patch',
      ),
    );

    expect(function.kind, ModelToolKind.function);
    expect(function.outputSchema, <String, dynamic>{'type': 'object'});
    expect(function.supportsParallelToolCalls, isTrue);
    expect(freeform.kind, ModelToolKind.freeform);
    expect(freeform.format?.syntax, 'lark');

    const namespace = ModelNamespaceToolDefinition(
      name: 'clock',
      description: 'Clock tools.',
      tools: <ModelFunctionToolDefinition>[function],
    );
    const deferred = ModelDeferredSearchToolDefinition(
      description: 'Search deferred tools.',
      parameters: <String, dynamic>{'type': 'object'},
    );
    expect(namespace.kind, ModelToolKind.namespace);
    expect(namespace.tools.single.name, 'read_file');
    expect(deferred.kind, ModelToolKind.deferredSearch);
    expect(deferred.execution, 'client');
  });

  test('modern typed call inputs reject legacy and unknown shapes', () {
    final json = ToolCallInput.fromJson(<String, dynamic>{
      'type': 'json',
      'value': <String, dynamic>{'path': 'README.md'},
    });
    final freeform = ToolCallInput.fromJson(<String, dynamic>{
      'type': 'freeform',
      'value': 'return tools.read_file({path="README.md"})',
    });
    expect(json.toJson()['type'], 'json');
    expect(freeform.toJson()['type'], 'freeform');
    expect(
      () => ToolCallInput.fromJson(<String, dynamic>{'type': 'legacy'}),
      throwsFormatException,
    );

    const raw = ModelFreeformCall(
      callId: 'raw',
      name: 'exec',
      rawInput: 'text("ok")',
    );
    const search = ModelDeferredSearchCall(
      callId: 'search',
      arguments: <String, dynamic>{'query': 'clock'},
    );
    expect((raw.input as FreeformToolCallInput).value, 'text("ok")');
    expect((search.input as JsonToolCallInput).value['query'], 'clock');
  });

  test('tool calls preserve raw freeform input without a JSON adapter', () {
    const call = ConversationToolCall.freeform(
      callId: 'call-1',
      name: 'apply_patch',
      input: '*** Begin Patch\n*** End Patch',
    );

    expect(call.input, isA<FreeformToolCallInput>());
    expect(call.toJson(), <String, dynamic>{
      'callId': 'call-1',
      'name': 'apply_patch',
      'kind': 'freeform',
      'input': <String, dynamic>{
        'type': 'freeform',
        'value': '*** Begin Patch\n*** End Patch',
      },
    });
  });

  test('tool results retain structured values and media content', () {
    const result = ToolResult(
      value: <String, dynamic>{'detail': 'original'},
      content: <ToolContent>[
        ToolTextContent('loaded'),
        ToolImageContent(
          imageUrl: 'data:image/png;base64,AA==',
          detail: 'original',
        ),
      ],
      structuredContent: <String, dynamic>{'ok': true},
    );

    expect(result.output, '{"detail":"original"}');
    expect(result.content.last, isA<ToolImageContent>());
    expect(result.structuredContent, <String, dynamic>{'ok': true});
  });

  test('rich tool-result history round-trips without flattening', () {
    const item = ToolResultConversationItem(
      callId: 'mcp-call',
      output: '{"ok":true}',
      toolKind: ModelToolKind.function,
      content: <ToolContent>[
        ToolImageContent(imageUrl: 'data:image/png;base64,AA=='),
        ToolAudioContent(audioUrl: 'data:audio/wav;base64,AA=='),
        ToolEmbeddedResourceContent(
          uri: 'file:///blob',
          blob: 'AA==',
          meta: <String, dynamic>{'source': 'mcp'},
        ),
      ],
      structuredContent: <String, dynamic>{'ok': true},
      meta: <String, dynamic>{'trace': 'one'},
    );

    final restored =
        ConversationItem.fromJson(item.toJson()) as ToolResultConversationItem;
    expect(restored.content[0], isA<ToolImageContent>());
    expect(restored.content[1], isA<ToolAudioContent>());
    expect(
      (restored.content[2] as ToolEmbeddedResourceContent).blob,
      'AA==',
    );
    expect(restored.structuredContent, <String, dynamic>{'ok': true});
    expect(restored.meta, <String, dynamic>{'trace': 'one'});
  });

  test('every modern content block round-trips metadata without loss', () {
    final blocks = <Map<String, dynamic>>[
      <String, dynamic>{
        'type': 'text',
        'text': 'hello',
        'annotations': <String, dynamic>{'priority': 1},
        '_meta': <String, dynamic>{'source': 'mcp'},
      },
      <String, dynamic>{
        'type': 'image',
        'image_url': 'data:image/png;base64,AA==',
        'detail': 'original',
      },
      <String, dynamic>{
        'type': 'audio',
        'audio_url': 'data:audio/wav;base64,AA==',
      },
      <String, dynamic>{
        'type': 'resource',
        'uri': 'file:///schema',
        'mimeType': 'application/json',
        'text': '{}',
        '_meta': <String, dynamic>{'etag': 'one'},
      },
      <String, dynamic>{
        'type': 'resource_link',
        'name': 'schema',
        'uri': 'file:///schema',
        'title': 'Schema',
        'description': 'A schema.',
        'mimeType': 'application/json',
        'size': 2,
        '_meta': <String, dynamic>{'etag': 'one'},
        'annotations': <String, dynamic>{
          'audience': <String>['assistant'],
        },
      },
    ];

    final restored = blocks.map(ToolContent.fromJson).toList();
    expect(restored.map((block) => block.toJson()), blocks);
    expect(
      () => ToolContent.fromJson(<String, dynamic>{'type': 'legacy'}),
      throwsFormatException,
    );
  });

  test(
    'base tools reject unsupported freeform and absent nested invocation',
    () async {
      final context = ToolExecutionContext(
        workspaceRoot: '/workspace',
        cancellation: CancellationToken(),
      );
      final tool = _JsonOnlyTool();
      expect(await tool.preview(const <String, dynamic>{}, context), isNull);
      expect(await tool.previewFreeform('source', context), isNull);
      expect(
        () => tool.executeFreeform('source', context),
        throwsA(isA<StateError>()),
      );
      expect(
        () => context.invokeNestedTool('read_file', const <String, dynamic>{}),
        throwsA(isA<StateError>()),
      );
    },
  );
}

final class _JsonOnlyTool extends AgentTool {
  @override
  String get name => 'json_only';

  @override
  String get description => 'JSON only.';

  @override
  AgentToolRisk get risk => AgentToolRisk.read;

  @override
  Map<String, dynamic> get strictJsonSchema => const <String, dynamic>{
    'type': 'object',
  };

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async => const ToolResult(value: <String, dynamic>{});
}
