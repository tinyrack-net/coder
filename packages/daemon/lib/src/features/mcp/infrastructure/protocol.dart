import 'dart:convert';

/// Protocol revisions this client speaks, newest first.
///
/// A server that answers `initialize` with anything outside this list fails the
/// connection: the client does not negotiate downwards through compatibility
/// shims.
const List<String> supportedMcpProtocolVersions = <String>[
  '2025-06-18',
  '2025-03-26',
];

/// The revision offered in the `initialize` request.
const String preferredMcpProtocolVersion = '2025-06-18';

/// The JSON-RPC method names this client sends or answers.
abstract final class McpMethod {
  /// Opens the session and negotiates the protocol revision.
  static const String initialize = 'initialize';

  /// Confirms that the client finished initializing.
  static const String initialized = 'notifications/initialized';

  /// Lists the tools a server publishes.
  static const String toolsList = 'tools/list';

  /// Invokes one published tool.
  static const String toolsCall = 'tools/call';

  /// Announces that a server's tool list changed.
  static const String toolsListChanged = 'notifications/tools/list_changed';

  /// Lists the resources a server publishes.
  static const String resourcesList = 'resources/list';

  /// Lists the parameterized resource templates a server publishes.
  static const String resourceTemplatesList = 'resources/templates/list';

  /// Reads one published resource.
  static const String resourcesRead = 'resources/read';

  /// Announces that a server's resource list changed.
  static const String resourcesListChanged =
      'notifications/resources/list_changed';

  /// Checks that the peer is still responsive.
  static const String ping = 'ping';

  /// Abandons an in-flight request.
  static const String cancelled = 'notifications/cancelled';
}

/// A malformed or unusable MCP payload.
class McpProtocolException implements Exception {
  /// Creates a [McpProtocolException].
  const McpProtocolException(this.message);

  /// Human-readable description of what could not be decoded.
  final String message;

  @override
  String toString() => 'McpProtocolException: $message';
}

/// A server that answered `initialize` with an unsupported revision.
class McpUnsupportedProtocolVersion implements Exception {
  /// Creates a [McpUnsupportedProtocolVersion].
  const McpUnsupportedProtocolVersion(this.version);

  /// The revision the server insisted on.
  final String version;

  @override
  String toString() =>
      'McpUnsupportedProtocolVersion: the server requires $version; '
      'this client speaks ${supportedMcpProtocolVersions.join(', ')}.';
}

/// A JSON-RPC error returned by an MCP server.
class McpServerException implements Exception {
  /// Creates a [McpServerException].
  const McpServerException({required this.code, required this.message});

  /// The JSON-RPC error code.
  final int code;

  /// The JSON-RPC error message.
  final String message;

  @override
  String toString() => 'McpServerException($code): $message';
}

/// Identity a server reports during `initialize`.
class McpServerIdentity {
  /// Creates a [McpServerIdentity].
  const McpServerIdentity({
    required this.protocolVersion,
    this.name,
    this.version,
    this.publishesTools = false,
    this.emitsToolListChanged = false,
    this.publishesResources = false,
    this.emitsResourceListChanged = false,
  });

  /// The negotiated protocol revision.
  final String protocolVersion;

  /// The server's self-reported name.
  final String? name;

  /// The server's self-reported version.
  final String? version;

  /// Whether the server advertised the `tools` capability.
  final bool publishesTools;

  /// Whether the server advertised `tools.listChanged`.
  final bool emitsToolListChanged;

  /// Whether the server advertised the `resources` capability.
  final bool publishesResources;

  /// Whether the server advertised `resources.listChanged`.
  final bool emitsResourceListChanged;
}

/// One resource a server publishes through `resources/list`.
class McpResourceDescriptor {
  /// Creates a [McpResourceDescriptor].
  const McpResourceDescriptor({
    required this.uri,
    this.name,
    this.title,
    this.description,
    this.mimeType,
    this.sizeBytes,
  });

  /// Decodes one entry of a `resources/list` result.
  factory McpResourceDescriptor.fromJson(Map<String, dynamic> json) {
    final uri = json['uri'];
    if (uri is! String || uri.isEmpty) {
      throw const McpProtocolException('A resource descriptor needs a uri.');
    }
    return McpResourceDescriptor(
      uri: uri,
      name: _optionalString(json['name']),
      title: _optionalString(json['title']),
      description: _optionalString(json['description']),
      mimeType: _optionalString(json['mimeType']),
      sizeBytes: json['size'] is int ? json['size'] as int : null,
    );
  }

  /// Where the resource lives; unique within its server.
  final String uri;

  /// A programmatic name, when the server supplies one.
  final String? name;

  /// A display title, when the server supplies one.
  final String? title;

  /// What the resource holds, when the server supplies it.
  final String? description;

  /// The declared media type, when present.
  final String? mimeType;

  /// The declared size in bytes, when present.
  final int? sizeBytes;
}

/// One parameterized resource template a server publishes.
class McpResourceTemplateDescriptor {
  /// Creates a [McpResourceTemplateDescriptor].
  const McpResourceTemplateDescriptor({
    required this.uriTemplate,
    this.name,
    this.title,
    this.description,
    this.mimeType,
  });

  /// Decodes one entry of a `resources/templates/list` result.
  factory McpResourceTemplateDescriptor.fromJson(Map<String, dynamic> json) {
    final uriTemplate = json['uriTemplate'];
    if (uriTemplate is! String || uriTemplate.isEmpty) {
      throw const McpProtocolException(
        'A resource template needs a uriTemplate.',
      );
    }
    return McpResourceTemplateDescriptor(
      uriTemplate: uriTemplate,
      name: _optionalString(json['name']),
      title: _optionalString(json['title']),
      description: _optionalString(json['description']),
      mimeType: _optionalString(json['mimeType']),
    );
  }

  /// The RFC 6570 template a client expands to reach a resource.
  final String uriTemplate;

  /// A programmatic name, when the server supplies one.
  final String? name;

  /// A display title, when the server supplies one.
  final String? title;

  /// What the template addresses, when the server supplies it.
  final String? description;

  /// The declared media type of expansions, when present.
  final String? mimeType;
}

/// One entry of a `resources/read` result.
sealed class McpResourceContents {
  const McpResourceContents();

  /// Where the content came from.
  String get uri;

  /// The declared media type.
  String get mimeType;
}

/// Textual resource content returned inline.
final class McpTextResourceContents extends McpResourceContents {
  /// Creates a [McpTextResourceContents].
  const McpTextResourceContents({
    required this.uri,
    required this.mimeType,
    required this.text,
  });

  @override
  final String uri;

  @override
  final String mimeType;

  /// The resource body.
  final String text;
}

/// Binary resource content returned inline as base64.
final class McpBlobResourceContents extends McpResourceContents {
  /// Creates a [McpBlobResourceContents].
  const McpBlobResourceContents({
    required this.uri,
    required this.mimeType,
    required this.byteLength,
  });

  @override
  final String uri;

  @override
  final String mimeType;

  /// Decoded size in bytes, or null when the payload would not decode.
  final int? byteLength;
}

/// The decoded result of one `resources/read` call.
class McpReadResourceResult {
  /// Creates a [McpReadResourceResult].
  const McpReadResourceResult({required this.contents});

  /// Decodes a `resources/read` result, dropping entries it cannot use.
  ///
  /// A server that returns an entry with neither `text` nor `blob` has told us
  /// nothing, so it contributes nothing rather than failing the whole read.
  factory McpReadResourceResult.fromJson(Map<String, dynamic> json) {
    final raw = json['contents'];
    if (raw is! List) {
      return const McpReadResourceResult(
        contents: <McpResourceContents>[],
      );
    }
    final contents = <McpResourceContents>[];
    for (final entry in raw.whereType<Map<dynamic, dynamic>>()) {
      final item = Map<String, dynamic>.from(entry);
      final uri = item['uri'];
      if (uri is! String || uri.isEmpty) continue;
      final text = item['text'];
      if (text is String) {
        contents.add(
          McpTextResourceContents(
            uri: uri,
            mimeType: _mimeType(item),
            text: text,
          ),
        );
        continue;
      }
      if (item['blob'] != null) {
        contents.add(
          McpBlobResourceContents(
            uri: uri,
            mimeType: _mimeType(item),
            byteLength: _base64Length(item['blob']),
          ),
        );
      }
    }
    return McpReadResourceResult(
      contents: List<McpResourceContents>.unmodifiable(contents),
    );
  }

  /// The decoded contents, in server order.
  final List<McpResourceContents> contents;
}

String? _optionalString(Object? value) =>
    value is String && value.isNotEmpty ? value : null;

/// One tool a server publishes through `tools/list`.
class McpToolDescriptor {
  /// Creates a [McpToolDescriptor].
  const McpToolDescriptor({
    required this.name,
    this.title,
    this.description,
    this.inputSchema,
    this.annotations = const McpToolAnnotations(),
  });

  /// Decodes one entry of a `tools/list` result.
  factory McpToolDescriptor.fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    if (name is! String || name.isEmpty) {
      throw const McpProtocolException('A tool descriptor needs a name.');
    }
    return McpToolDescriptor(
      name: name,
      title: json['title'] is String ? json['title'] as String : null,
      description: json['description'] is String
          ? json['description'] as String
          : null,
      inputSchema: json['inputSchema'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['inputSchema'] as Map)
          : null,
      annotations: json['annotations'] is Map<String, dynamic>
          ? McpToolAnnotations.fromJson(
              json['annotations'] as Map<String, dynamic>,
            )
          : const McpToolAnnotations(),
    );
  }

  /// The tool name, unique within its server.
  final String name;

  /// A display title, when the server supplies one.
  final String? title;

  /// What the tool does, as advertised to the model.
  final String? description;

  /// The JSON Schema describing the tool arguments.
  final Map<String, dynamic>? inputSchema;

  /// What the server claims about the tool's effects.
  final McpToolAnnotations annotations;
}

/// What a server claims about the effects of calling one of its tools.
///
/// Every field is a hint, not a guarantee: the server is the only one who
/// knows, and it is also the only one who can be wrong. They are used to
/// relax an approval prompt, never to grant something a policy withheld.
class McpToolAnnotations {
  /// Creates [McpToolAnnotations].
  const McpToolAnnotations({
    this.readOnlyHint = false,
    this.destructiveHint,
    this.idempotentHint,
    this.openWorldHint,
  });

  /// Decodes the `annotations` object of a tool descriptor.
  factory McpToolAnnotations.fromJson(Map<String, dynamic> json) {
    bool? flag(String key) => json[key] is bool ? json[key] as bool : null;
    return McpToolAnnotations(
      readOnlyHint: flag('readOnlyHint') ?? false,
      destructiveHint: flag('destructiveHint'),
      idempotentHint: flag('idempotentHint'),
      openWorldHint: flag('openWorldHint'),
    );
  }

  /// Whether the tool only reads, making no modification of any kind.
  final bool readOnlyHint;

  /// Whether the tool may perform destructive updates.
  ///
  /// The specification defaults this to true, but only for a tool that is not
  /// read-only; null means the server said nothing.
  final bool? destructiveHint;

  /// Whether repeating the call with the same arguments adds no further effect.
  final bool? idempotentHint;

  /// Whether the tool touches entities outside its own closed world.
  final bool? openWorldHint;
}

/// One block of a `tools/call` result.
sealed class McpContentBlock {
  /// Creates a [McpContentBlock].
  const McpContentBlock();
}

/// Plain text output.
final class McpTextContent extends McpContentBlock {
  /// Creates a [McpTextContent].
  const McpTextContent(this.text);

  /// The text the server returned.
  final String text;
}

/// An image, reduced to its media type and size.
final class McpImageContent extends McpContentBlock {
  /// Creates a [McpImageContent].
  const McpImageContent({required this.mimeType, required this.byteLength});

  /// The declared media type.
  final String mimeType;

  /// Decoded payload size, or null when the payload was not valid base64.
  final int? byteLength;
}

/// Audio, reduced to its media type and size.
final class McpAudioContent extends McpContentBlock {
  /// Creates a [McpAudioContent].
  const McpAudioContent({required this.mimeType, required this.byteLength});

  /// The declared media type.
  final String mimeType;

  /// Decoded payload size, or null when the payload was not valid base64.
  final int? byteLength;
}

/// A resource embedded directly in the result.
final class McpEmbeddedResource extends McpContentBlock {
  /// Creates a [McpEmbeddedResource].
  const McpEmbeddedResource({
    required this.uri,
    this.mimeType,
    this.text,
    this.blobByteLength,
  });

  /// Where the resource lives.
  final String uri;

  /// The declared media type, when present.
  final String? mimeType;

  /// Inline text, for textual resources.
  final String? text;

  /// Decoded blob size, for binary resources.
  final int? blobByteLength;
}

/// A pointer to a resource the client may fetch separately.
final class McpResourceLink extends McpContentBlock {
  /// Creates a [McpResourceLink].
  const McpResourceLink({required this.uri, this.name, this.mimeType});

  /// Where the resource lives.
  final String uri;

  /// A display name, when the server supplies one.
  final String? name;

  /// The declared media type, when present.
  final String? mimeType;
}

/// A content block of a type this client does not model.
final class McpUnknownContent extends McpContentBlock {
  /// Creates a [McpUnknownContent].
  const McpUnknownContent(this.type);

  /// The `type` discriminator the server sent.
  final String type;
}

/// The result of one `tools/call`.
class McpCallToolResult {
  /// Creates a [McpCallToolResult].
  const McpCallToolResult({
    required this.content,
    this.structuredContent,
    this.isError = false,
  });

  /// Decodes a `tools/call` result, dropping blocks it cannot parse.
  factory McpCallToolResult.fromJson(Map<String, dynamic> json) {
    final raw = json['content'];
    final blocks = <McpContentBlock>[];
    if (raw is List) {
      for (final entry in raw) {
        if (entry is! Map<String, dynamic>) continue;
        final block = _contentFromJson(entry);
        if (block != null) blocks.add(block);
      }
    }
    return McpCallToolResult(
      content: blocks,
      structuredContent: json['structuredContent'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['structuredContent'] as Map)
          : null,
      isError: json['isError'] == true,
    );
  }

  /// The ordered content blocks the server returned.
  final List<McpContentBlock> content;

  /// A machine-readable result, when the tool declares an output schema.
  final Map<String, dynamic>? structuredContent;

  /// Whether the tool itself reported a failure.
  final bool isError;
}

McpContentBlock? _contentFromJson(Map<String, dynamic> json) {
  final type = json['type'];
  if (type is! String) return null;
  switch (type) {
    case 'text':
      final text = json['text'];
      return text is String ? McpTextContent(text) : null;
    case 'image':
      return McpImageContent(
        mimeType: _mimeType(json),
        byteLength: _base64Length(json['data']),
      );
    case 'audio':
      return McpAudioContent(
        mimeType: _mimeType(json),
        byteLength: _base64Length(json['data']),
      );
    case 'resource':
      final resource = json['resource'];
      if (resource is! Map<String, dynamic>) return null;
      final uri = resource['uri'];
      if (uri is! String) return null;
      return McpEmbeddedResource(
        uri: uri,
        mimeType: resource['mimeType'] is String
            ? resource['mimeType'] as String
            : null,
        text: resource['text'] is String ? resource['text'] as String : null,
        blobByteLength: _base64Length(resource['blob']),
      );
    case 'resource_link':
      final uri = json['uri'];
      if (uri is! String) return null;
      return McpResourceLink(
        uri: uri,
        name: json['name'] is String ? json['name'] as String : null,
        mimeType: json['mimeType'] is String
            ? json['mimeType'] as String
            : null,
      );
    default:
      return McpUnknownContent(type);
  }
}

String _mimeType(Map<String, dynamic> json) =>
    json['mimeType'] is String && (json['mimeType'] as String).isNotEmpty
    ? json['mimeType'] as String
    : 'application/octet-stream';

int? _base64Length(Object? data) {
  if (data is! String) return null;
  try {
    return base64.decode(data).length;
  } on FormatException {
    return null;
  }
}
