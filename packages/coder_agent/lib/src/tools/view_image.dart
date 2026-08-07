import 'dart:async';
import 'dart:convert';

import 'package:coder_agent/coder_agent.dart' show AttachFileTool;
import 'package:coder_agent/src/model.dart';
import 'package:coder_agent/src/tools.dart' show AttachFileTool;
import 'package:coder_agent/src/tools/attach_file.dart' show AttachFileTool;
import 'package:coder_agent/src/tools/tool_registry.dart';
import 'package:coder_agent/src/tools/tool_support.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:file/file.dart' as file_api;
import 'package:file/local.dart';
import 'package:platform/platform.dart';

/// Media types every supported provider accepts as model-visible images.
const Set<String> supportedContextImageTypes = <String>{
  'image/png',
  'image/jpeg',
  'image/webp',
  'image/gif',
};

/// Fidelity levels a provider understands for a model-visible image.
const Set<String> contextImageDetails = <String>{'auto', 'low', 'high'};

/// Largest size of one image loaded into the model's context.
///
/// Base64 inflates the payload by four thirds, so 10 MiB of image is about
/// 13.3 MB of request body.
const int maxContextImageBytes = 10 * 1024 * 1024;

/// Largest number of images one turn may load into the model's context.
const int maxContextImagesPerTurn = 8;

/// Loads a workspace image into the model's conversation context.
///
/// Distinct from [AttachFileTool], which publishes a file for the user to see:
/// this one makes the model actually look at the image.
class ViewImageTool extends AgentTool {
  /// Creates a [ViewImageTool].
  factory ViewImageTool({
    required AttachmentPublisher publisher,
    file_api.FileSystem fileSystem = const LocalFileSystem(),
    Platform platform = const LocalPlatform(),
  }) => ViewImageTool._(publisher, fileSystem, platform);

  ViewImageTool._(this._publisher, this._fileSystem, this._platform);

  final AttachmentPublisher _publisher;
  final file_api.FileSystem _fileSystem;
  final Platform _platform;

  /// Images loaded so far; the tool instance is scoped to one turn.
  int _loaded = 0;

  @override
  String get name => 'view_image';

  @override
  String get description =>
      'Look at an image file in the workspace. Use it for screenshots, '
      'diagrams, and design mock-ups whose content you need to reason about. '
      'Accepts PNG, JPEG, WebP, and GIF up to '
      '${maxContextImageBytes ~/ (1024 * 1024)} MB, at most '
      '$maxContextImagesPerTurn per turn.';

  @override
  ToolRisk get risk => ToolRisk.read;

  @override
  Map<String, dynamic> get strictJsonSchema =>
      strictToolObject(<String, Map<String, dynamic>>{
        'path': <String, dynamic>{
          'type': 'string',
          'description': 'Workspace-relative path of the image.',
        },
        'detail': <String, dynamic>{
          'type': <String>['string', 'null'],
          'description':
              'How closely to read the image: auto, low, or high. Null uses '
              'the provider default.',
        },
      });

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async {
    final detail = arguments['detail'];
    if (detail != null &&
        (detail is! String || !contextImageDetails.contains(detail))) {
      return _reject(
        'detail must be one of ${contextImageDetails.join(', ')}, or null.',
      );
    }
    if (_loaded >= maxContextImagesPerTurn) {
      return _reject(
        'At most $maxContextImagesPerTurn images can be viewed in one turn.',
      );
    }
    final resolved = WorkspacePathGuard(
      context.workspaceRoot,
      fileSystem: _fileSystem,
      platform: _platform,
    ).resolveExisting(arguments['path'] as String);
    final source = _fileSystem.file(resolved);
    final stat = source.statSync();
    if (stat.type != file_api.FileSystemEntityType.file) {
      return _reject('An image must be a regular file.');
    }
    if (stat.size > maxContextImageBytes) {
      return _reject(
        'The image exceeds the '
        '${maxContextImageBytes ~/ (1024 * 1024)} MB limit.',
      );
    }
    // Sniffing the header keeps a mislabelled file from reaching the provider,
    // which would fail the whole turn rather than this one call.
    final mimeType = _sniffImageType(
      await source.openRead(0, 12).expand((chunk) => chunk).toList(),
    );
    if (mimeType == null) {
      return _reject(
        'Not a supported image. Use PNG, JPEG, WebP, or GIF.',
      );
    }
    context.cancellation.throwIfCancelled();
    final published = await _publisher.publish(resolved);
    _loaded += 1;
    // Hydrate here rather than relying on the publisher: the model has to see
    // the image on this very turn, and later turns refill bytes from the
    // attachment store when the history is replayed.
    final attachment = ConversationAttachment(
      id: published.id,
      fileName: published.fileName,
      mimeType: mimeType,
      byteSize: published.byteSize,
      path: published.path,
      bytes: published.bytes ?? await source.readAsBytes(),
      kind: published.kind,
      sha256: published.sha256,
      createdAt: published.createdAt,
      imageDetail: detail as String?,
    );
    return ToolResult(
      output: jsonEncode(<String, dynamic>{
        'attachmentId': attachment.id,
        'fileName': attachment.fileName,
        'mimeType': attachment.mimeType,
        'byteSize': attachment.byteSize,
        'detail': detail,
      }),
      attachments: <ConversationAttachment>[attachment],
      contextImages: <ConversationAttachment>[attachment],
    );
  }

  /// Returns the media type [header] actually starts with, or null.
  static String? _sniffImageType(List<int> header) {
    bool matches(int offset, List<int> magic) {
      if (header.length < offset + magic.length) return false;
      for (var index = 0; index < magic.length; index += 1) {
        if (header[offset + index] != magic[index]) return false;
      }
      return true;
    }

    if (matches(0, <int>[0x89, 0x50, 0x4E, 0x47])) return 'image/png';
    if (matches(0, <int>[0xFF, 0xD8, 0xFF])) return 'image/jpeg';
    if (matches(0, <int>[0x47, 0x49, 0x46, 0x38])) return 'image/gif';
    // WebP is a RIFF container whose form type sits after the 4-byte length.
    if (matches(0, <int>[0x52, 0x49, 0x46, 0x46]) &&
        matches(8, <int>[0x57, 0x45, 0x42, 0x50])) {
      return 'image/webp';
    }
    return null;
  }

  ToolResult _reject(String reason) => ToolResult(
    output: jsonEncode(<String, dynamic>{'error': reason}),
    isError: true,
  );
}

/// Registers putting a workspace image into the model context.
final class ViewImageToolProvider extends SelectableToolProvider {
  /// Creates a [ViewImageToolProvider].
  const ViewImageToolProvider();

  @override
  String get id => 'view_image';

  @override
  AgentToolDefinitionDto get catalogEntry => AgentToolDefinitionDto(
    id: id,
    name: id,
    description:
        'Look at an image file in the workspace, such as a screenshot '
        'or a design mock-up.',
    risk: ToolRisk.read,
    alwaysOn: true,
  );

  @override
  List<AgentTool> build(AgentToolScope scope) => <AgentTool>[
    ViewImageTool(publisher: scope.attachmentPublisher),
  ];
}
