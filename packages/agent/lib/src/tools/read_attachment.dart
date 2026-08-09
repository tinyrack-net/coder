import 'dart:async';
import 'dart:convert';

import 'package:agent/src/contracts.dart';
import 'package:agent/src/model.dart';
import 'package:agent/src/tools/tool_registry.dart';
import 'package:agent/src/tools/tool_support.dart';

/// Resolves attachment metadata and its safe daemon-local fallback path.
class ReadAttachmentTool extends AgentTool {
  /// Creates an ID-based attachment reader.
  factory ReadAttachmentTool({required AttachmentReader reader}) =>
      ReadAttachmentTool._(reader);

  ReadAttachmentTool._(this._reader);

  final AttachmentReader _reader;

  @override
  String get name => 'read_attachment';

  @override
  String get description =>
      'Resolve an attachment ID to validated metadata and a readable path.';

  @override
  AgentToolRisk get risk => AgentToolRisk.read;

  @override
  Map<String, dynamic> get strictJsonSchema =>
      strictToolObject(<String, Map<String, dynamic>>{
        'id': <String, dynamic>{'type': 'string'},
      });

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async {
    context.cancellation.throwIfCancelled();
    final attachment = await _reader.read(arguments['id'] as String);
    return ToolResult(value: jsonEncode(attachment.toJson()));
  }
}

/// Registers resolving an attachment id the session already owns.
final class ReadAttachmentToolProvider extends SelectableToolProvider {
  /// Creates a [ReadAttachmentToolProvider].
  const ReadAttachmentToolProvider();

  @override
  String get id => 'read_attachment';

  @override
  AgentToolDefinition get catalogEntry => AgentToolDefinition(
    id: id,
    name: id,
    description:
        'Resolve an attachment ID to validated metadata and a '
        'readable path.',
    risk: AgentToolRisk.read,
    alwaysOn: true,
  );

  @override
  List<AgentTool> build(AgentToolScope scope) => <AgentTool>[
    ReadAttachmentTool(reader: scope.attachmentReader),
  ];
}
