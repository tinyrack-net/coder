import 'package:coder_mcp/coder_mcp.dart';
import 'package:test/test.dart';

void main() {
  test('the negotiated protocol versions are ordered newest first', () {
    expect(supportedMcpProtocolVersions.first, preferredMcpProtocolVersion);
    expect(supportedMcpProtocolVersions, contains('2025-06-18'));
    expect(supportedMcpProtocolVersions, contains('2025-03-26'));
  });

  test('tool descriptors decode names, titles, and input schemas', () {
    final descriptor = McpToolDescriptor.fromJson(<String, dynamic>{
      'name': 'create_issue',
      'title': 'Create issue',
      'description': 'Opens a GitHub issue.',
      'inputSchema': <String, dynamic>{
        'type': 'object',
        'properties': <String, dynamic>{
          'title': <String, dynamic>{'type': 'string'},
        },
        'required': <String>['title'],
      },
    });

    expect(descriptor.name, 'create_issue');
    expect(descriptor.title, 'Create issue');
    expect(descriptor.description, 'Opens a GitHub issue.');
    expect(descriptor.inputSchema!['type'], 'object');
  });

  test('tool descriptors tolerate a server that omits optional fields', () {
    final descriptor = McpToolDescriptor.fromJson(<String, dynamic>{
      'name': 'ping',
    });

    expect(descriptor.name, 'ping');
    expect(descriptor.title, isNull);
    expect(descriptor.description, isNull);
    expect(descriptor.inputSchema, isNull);
  });

  test('a tool descriptor without a usable name is rejected', () {
    expect(
      () => McpToolDescriptor.fromJson(<String, dynamic>{'title': 'No name'}),
      throwsA(isA<McpProtocolException>()),
    );
    expect(
      () => McpToolDescriptor.fromJson(<String, dynamic>{'name': ''}),
      throwsA(isA<McpProtocolException>()),
    );
  });

  test('call results decode every content block the spec defines', () {
    final result = McpCallToolResult.fromJson(<String, dynamic>{
      'content': <dynamic>[
        <String, dynamic>{'type': 'text', 'text': 'hello'},
        <String, dynamic>{
          'type': 'image',
          'mimeType': 'image/png',
          'data': 'AAAA',
        },
        <String, dynamic>{
          'type': 'audio',
          'mimeType': 'audio/wav',
          'data': 'AAAAAAAA',
        },
        <String, dynamic>{
          'type': 'resource',
          'resource': <String, dynamic>{
            'uri': 'file:///a.txt',
            'mimeType': 'text/plain',
            'text': 'body',
          },
        },
        <String, dynamic>{
          'type': 'resource',
          'resource': <String, dynamic>{
            'uri': 'file:///a.bin',
            'blob': 'AAAA',
          },
        },
        <String, dynamic>{
          'type': 'resource_link',
          'uri': 'https://example.test/doc',
          'name': 'doc',
        },
        <String, dynamic>{'type': 'future_block'},
      ],
    });

    expect(result.isError, isFalse);
    expect(result.structuredContent, isNull);
    expect(result.content, hasLength(7));

    final text = result.content[0] as McpTextContent;
    expect(text.text, 'hello');

    final image = result.content[1] as McpImageContent;
    expect(image.mimeType, 'image/png');
    expect(image.byteLength, 3);

    final audio = result.content[2] as McpAudioContent;
    expect(audio.mimeType, 'audio/wav');
    expect(audio.byteLength, 6);

    final textResource = result.content[3] as McpEmbeddedResource;
    expect(textResource.uri, 'file:///a.txt');
    expect(textResource.mimeType, 'text/plain');
    expect(textResource.text, 'body');
    expect(textResource.blobByteLength, isNull);

    final blobResource = result.content[4] as McpEmbeddedResource;
    expect(blobResource.text, isNull);
    expect(blobResource.blobByteLength, 3);

    final link = result.content[5] as McpResourceLink;
    expect(link.uri, 'https://example.test/doc');
    expect(link.name, 'doc');

    final unknown = result.content[6] as McpUnknownContent;
    expect(unknown.type, 'future_block');
  });

  test('call results carry structured content and the error flag', () {
    final result = McpCallToolResult.fromJson(<String, dynamic>{
      'content': <dynamic>[
        <String, dynamic>{'type': 'text', 'text': 'failed'},
      ],
      'structuredContent': <String, dynamic>{'code': 42},
      'isError': true,
    });

    expect(result.isError, isTrue);
    expect(result.structuredContent, <String, dynamic>{'code': 42});
  });

  test('call results tolerate missing and malformed content', () {
    expect(McpCallToolResult.fromJson(<String, dynamic>{}).content, isEmpty);
    expect(
      McpCallToolResult.fromJson(<String, dynamic>{
        'content': <dynamic>['not-an-object', 42],
      }).content,
      isEmpty,
    );
    expect(
      McpCallToolResult.fromJson(<String, dynamic>{
        'content': 'not-a-list',
      }).content,
      isEmpty,
    );
    expect(
      McpCallToolResult.fromJson(<String, dynamic>{
        'structuredContent': 'not-an-object',
      }).structuredContent,
      isNull,
    );
  });

  test('undecodable base64 payloads report an unknown byte length', () {
    final result = McpCallToolResult.fromJson(<String, dynamic>{
      'content': <dynamic>[
        <String, dynamic>{'type': 'image', 'data': '!!not base64!!'},
        <String, dynamic>{'type': 'text'},
      ],
    });

    final image = result.content.single as McpImageContent;
    expect(image.mimeType, 'application/octet-stream');
    expect(image.byteLength, isNull);
  });

  test('protocol exceptions expose a stable diagnostic message', () {
    expect(
      const McpProtocolException('bad tool').toString(),
      contains('bad tool'),
    );
    expect(
      const McpUnsupportedProtocolVersion('1999-01-01').toString(),
      contains('1999-01-01'),
    );
    expect(
      const McpServerException(code: -32601, message: 'nope').toString(),
      allOf(contains('-32601'), contains('nope')),
    );
  });
}
