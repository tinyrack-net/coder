import 'dart:async';
import 'dart:convert';
import 'dart:io' show FileSystemException;

import 'package:coder_agent/src/model.dart';
import 'package:coder_agent/src/tools/tool_registry.dart';
import 'package:coder_agent/src/tools/tool_support.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:file/file.dart' as file_api;
import 'package:file/local.dart';
import 'package:platform/platform.dart';

/// Publishes one regular workspace file to the user as an attachment.
class AttachFileTool extends AgentTool {
  /// Creates an attachment publication tool.
  factory AttachFileTool({
    required AttachmentPublisher publisher,
    file_api.FileSystem fileSystem = const LocalFileSystem(),
    Platform platform = const LocalPlatform(),
  }) => AttachFileTool._(publisher, fileSystem, platform);

  AttachFileTool._(this._publisher, this._fileSystem, this._platform);

  final AttachmentPublisher _publisher;
  final file_api.FileSystem _fileSystem;
  final Platform _platform;

  @override
  String get name => 'attach_file';

  @override
  String get description =>
      'Attach a regular file from the workspace to the conversation.';

  @override
  ToolRisk get risk => ToolRisk.read;

  @override
  Map<String, dynamic> get strictJsonSchema =>
      strictToolObject(<String, Map<String, dynamic>>{
        'path': <String, dynamic>{'type': 'string'},
      });

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async {
    final resolved = WorkspacePathGuard(
      context.workspaceRoot,
      fileSystem: _fileSystem,
      platform: _platform,
    ).resolveExisting(arguments['path'] as String);
    final source = _fileSystem.file(resolved);
    final stat = source.statSync();
    if (stat.type != file_api.FileSystemEntityType.file) {
      throw FileSystemException('Attachment must be a regular file.', resolved);
    }
    if (stat.size > maxAttachmentBytes) {
      throw FileSystemException(
        'Attachment exceeds the 50 MB limit.',
        resolved,
      );
    }
    context.cancellation.throwIfCancelled();
    final attachment = await _publisher.publish(resolved);
    return ToolResult(
      output: jsonEncode(<String, dynamic>{
        'attachmentId': attachment.id,
        'fileName': attachment.fileName,
        'mimeType': attachment.mimeType,
        'byteSize': attachment.byteSize,
      }),
      attachments: <ConversationAttachment>[attachment],
    );
  }
}

/// Registers publishing a workspace file to the conversation.
final class AttachFileToolProvider extends SelectableToolProvider {
  /// Creates a [AttachFileToolProvider].
  const AttachFileToolProvider();

  @override
  String get id => 'attach_file';

  @override
  AgentToolDefinitionDto get catalogEntry => AgentToolDefinitionDto(
    id: id,
    name: id,
    description:
        'Attach a regular file from the workspace to the conversation.',
    risk: ToolRisk.read,
    alwaysOn: true,
  );

  @override
  List<AgentTool> build(AgentToolScope scope) => <AgentTool>[
    AttachFileTool(publisher: scope.attachmentPublisher),
  ];
}
