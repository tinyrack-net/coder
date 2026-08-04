import 'dart:convert';
import 'dart:io' show FileSystemException;

import 'package:coder_agent/src/model.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:file/file.dart' as file_api;
import 'package:file/local.dart';
import 'package:platform/platform.dart';

/// Keeps one skill payload inside the same budget the file tools use.
const int _maxSkillOutputBytes = 1024 * 1024;

/// One catalog entry offered to the model in the system prompt.
final class SkillSummary {
  /// Creates a skill summary.
  const SkillSummary({required this.name, required this.description});

  /// Name the model passes back to the `skill` tool.
  final String name;

  /// One-line description used to decide whether to load the skill.
  final String description;
}

/// One file bundled next to a skill document.
final class SkillResourceRef {
  /// Creates a skill resource reference.
  const SkillResourceRef({required this.path, required this.sizeBytes});

  /// Path relative to the skill directory.
  final String path;

  /// Size on disk, so the model can judge before loading it.
  final int sizeBytes;
}

/// Full instructions and bundled file listing for one skill.
final class SkillContent {
  /// Creates skill content.
  const SkillContent({
    required this.name,
    required this.description,
    required this.instructions,
    this.directory,
    this.resources = const <SkillResourceRef>[],
  });

  /// Name the skill is loaded by.
  final String name;

  /// One-line description repeated from the catalog.
  final String description;

  /// Markdown body handed to the model.
  final String instructions;

  /// Absolute skill directory, or null for a skill with no files on disk.
  final String? directory;

  /// Files bundled next to the skill document.
  final List<SkillResourceRef> resources;
}

/// Raised when a turn asks for a skill it cannot load.
final class SkillLookupException implements Exception {
  /// Creates a lookup failure carrying a model-readable reason.
  const SkillLookupException(this.message);

  /// Reason handed back to the model.
  final String message;

  @override
  String toString() => 'SkillLookupException: $message';
}

/// Turn-scoped boundary over the skills one session may load.
abstract interface class SkillCatalog {
  /// Returns the enabled skills, sorted by name.
  List<SkillSummary> summaries();

  /// Loads one skill body.
  ///
  /// Throws [SkillLookupException] when the skill is unknown or disabled.
  Future<SkillContent> read(String name);

  /// Loads one file bundled next to a skill document.
  Future<String> readResource(String name, String relativePath);
}

/// Confines skill file access to one skill directory.
final class SkillPathGuard {
  /// Creates a guard rooted at one skill directory.
  SkillPathGuard(
    String skillRoot, {
    file_api.FileSystem fileSystem = const LocalFileSystem(),
    this._platform = const LocalPlatform(),
  }) : _fileSystem = fileSystem,
       _skillRoot = fileSystem.directory(skillRoot).resolveSymbolicLinksSync();

  final file_api.FileSystem _fileSystem;
  final Platform _platform;
  final String _skillRoot;

  /// Resolves one existing bundled file inside the skill directory.
  String resolveExisting(String candidate) {
    final path = _fileSystem.path;
    if (path.isAbsolute(candidate)) {
      throw FileSystemException('Skill paths must be relative.', candidate);
    }
    final resolved = _fileSystem
        .file(path.join(_skillRoot, candidate))
        .resolveSymbolicLinksSync();
    final root = _platform.isWindows ? _skillRoot.toLowerCase() : _skillRoot;
    final target = _platform.isWindows ? resolved.toLowerCase() : resolved;
    if (!path.isWithin(root, target)) {
      throw FileSystemException('Path escapes the skill.', resolved);
    }
    return resolved;
  }
}

/// Loads skill instructions on demand so the prompt only carries a catalog.
class SkillTool extends AgentTool {
  /// Creates a [SkillTool] bound to one turn's catalog.
  SkillTool(this._catalog);

  final SkillCatalog _catalog;

  @override
  String get name => 'skill';

  @override
  String get description =>
      'Load the full instructions for one available skill, or read one of '
      'its bundled files.';

  @override
  ToolRisk get risk => ToolRisk.read;

  @override
  Map<String, dynamic> get strictJsonSchema => <String, dynamic>{
    'type': 'object',
    'properties': <String, dynamic>{
      'name': <String, dynamic>{'type': 'string'},
      'resource': <String, dynamic>{
        'type': <String>['string', 'null'],
      },
    },
    'required': <String>['name', 'resource'],
    'additionalProperties': false,
  };

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async {
    final name = arguments['name'] as String;
    final resource = arguments['resource'] as String?;
    try {
      return resource == null
          ? _describe(await _catalog.read(name))
          : ToolResult(
              output: jsonEncode(<String, dynamic>{
                'name': name,
                'resource': resource,
                'content': await _catalog.readResource(name, resource),
              }),
            );
    } on SkillLookupException catch (error) {
      return _failure(error.message);
    } on FileSystemException catch (error) {
      return _failure(error.message);
    } on FormatException catch (error) {
      return _failure(error.message);
    }
  }

  ToolResult _describe(SkillContent content) {
    const budget = _maxSkillOutputBytes ~/ 2;
    final truncated = content.instructions.length > budget;
    return ToolResult(
      output: jsonEncode(<String, dynamic>{
        'name': content.name,
        'description': content.description,
        'directory': content.directory,
        'instructions': truncated
            ? content.instructions.substring(0, budget)
            : content.instructions,
        if (truncated) 'truncated': true,
        'resources': content.resources
            .map(
              (resource) => <String, dynamic>{
                'path': resource.path,
                'bytes': resource.sizeBytes,
              },
            )
            .toList(growable: false),
      }),
    );
  }

  ToolResult _failure(String error) => ToolResult(
    isError: true,
    output: jsonEncode(<String, dynamic>{
      'error': error,
      'available': _catalog
          .summaries()
          .map((summary) => summary.name)
          .toList(growable: false),
    }),
  );
}
