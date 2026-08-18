import 'package:agent/agent.dart';
import 'package:test/test.dart';

void main() {
  test('cancellation is idempotent and late listeners run immediately', () {
    final cancellation = CancellationToken();
    var notifications = 0;
    cancellation
      ..onCancel(() => notifications += 1)
      ..onCancel(() => notifications += 1)
      ..cancel()
      ..cancel()
      ..onCancel(() => notifications += 1);

    expect(cancellation.isCancelled, isTrue);
    expect(notifications, 3);
    expect(
      cancellation.throwIfCancelled,
      throwsA(isA<AgentCancelledException>()),
    );
    expect(
      const ModelContextOverflowException('too large').toString(),
      'ModelContextOverflowException: too large',
    );
  });

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
      name: 'discover_tools',
      description: 'Search deferred tools.',
      parameters: <String, dynamic>{'type': 'object'},
    );
    expect(namespace.kind, ModelToolKind.namespace);
    expect(namespace.tools.single.name, 'read_file');
    expect(deferred.kind, ModelToolKind.deferredSearch);
    expect(deferred.name, 'discover_tools');
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
      name: 'discover_tools',
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

  test('all model call kinds round-trip their typed inputs', () {
    final marker = DateTime.now().microsecondsSinceEpoch.toString();
    final calls = <ConversationToolCall>[
      ConversationToolCall.function(
        callId: 'function-$marker',
        name: 'clock',
        namespace: 'time',
        arguments: <String, dynamic>{'zone': marker},
      ),
      ConversationToolCall.deferredSearch(
        callId: 'search-$marker',
        name: 'discover_tools',
        arguments: <String, dynamic>{'query': marker},
      ),
      ConversationToolCall.freeform(
        callId: 'freeform-$marker',
        name: 'exec',
        input: marker,
      ),
    ];

    final restored = calls
        .map((call) => ConversationToolCall.fromJson(call.toJson()))
        .toList(growable: false);
    expect(restored[0].namespace, 'time');
    expect((restored[0].input as JsonToolCallInput).value['zone'], marker);
    expect(restored[1].kind, ModelToolKind.deferredSearch);
    expect((restored[2].input as FreeformToolCallInput).value, marker);
  });

  test(
    'conversation variants round-trip defaults and reject unknown input',
    () {
      final marker = DateTime.now().microsecondsSinceEpoch.toString();
      final user = ConversationItem.fromJson(<String, dynamic>{
        'type': 'user',
        'text': 'inspect',
        'attachments': <Object?>[
          <String, dynamic>{
            'id': 'attachment',
            'fileName': 'image.png',
            'mimeType': 'image/png',
            'byteSize': 2,
            'path': '/attachments/image.png',
          },
          'ignored',
        ],
      }) as UserConversationItem;
      final assistant = ConversationItem.fromJson(<String, dynamic>{
        'type': 'assistant',
        'toolCalls': <Object?>[
          ConversationToolCall.function(
            callId: marker,
            name: 'read',
            arguments: <String, dynamic>{},
          ).toJson(),
          'ignored',
        ],
        'opaqueItems': <Object?>[
          <String, dynamic>{'type': 'provider_state'},
          'ignored',
        ],
      }) as AssistantConversationItem;
      final result = ConversationItem.fromJson(<String, dynamic>{
        'type': 'toolResult',
        'callId': 'call',
        'output': 'done',
        'toolKind': 'function',
        'meta': 'invalid',
      }) as ToolResultConversationItem;

      expect(user.attachments.single.fileName, 'image.png');
      expect(assistant.text, isEmpty);
      expect(assistant.toolCalls.single.name, 'read');
      expect(assistant.opaqueItems.single['type'], 'provider_state');
      expect(assistant.toJson()['text'], isEmpty);
      expect(result.meta, isEmpty);
      expect(
        () => ConversationItem.fromJson(<String, dynamic>{'type': 'legacy'}),
        throwsFormatException,
      );
    },
  );

  test('model requests and stream events retain driver-owned data', () async {
    final marker = DateTime.now().microsecondsSinceEpoch.toString();
    final block = ModelRoleBlock(role: 'developer', content: marker);
    final request = ModelRequest(
      model: 'test-model',
      blocks: <ModelRoleBlock>[block],
      history: <ConversationItem>[
        AssistantConversationItem(text: marker),
      ],
      tools: const <ModelToolDefinition>[],
      safetyIdentifier: 'session',
      forceToolName: 'clock',
    );
    final events = <ModelEvent>[
      ModelTextDelta(marker),
      ModelReasoningDelta(marker),
      ModelFunctionCall(
        callId: marker,
        name: 'clock',
        arguments: <String, dynamic>{'zone': marker},
      ),
      ModelResponseCompleted(
        assistant: AssistantConversationItem(text: marker),
        usage: ModelUsage.fromJson(<String, dynamic>{'totalTokens': 3}),
      ),
    ];

    expect(block.toJson(), <String, dynamic>{
      'role': 'developer',
      'content': marker,
    });
    expect(request.blocks.single, same(block));
    expect(request.forceToolName, 'clock');
    expect((events[0] as ModelTextDelta).delta, marker);
    expect((events[1] as ModelReasoningDelta).delta, marker);
    expect(
      ((events[2] as ModelFunctionCall).input as JsonToolCallInput)
          .value['zone'],
      marker,
    );
    expect((events[3] as ModelResponseCompleted).usage.totalTokens, 3);
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
}
