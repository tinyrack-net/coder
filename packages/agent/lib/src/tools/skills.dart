import 'dart:convert';
import 'dart:io' show FileSystemException;

import 'package:agent/src/contracts.dart';
import 'package:agent/src/model.dart';
import 'package:agent/src/tools.dart';
import 'package:agent/src/tools/tool_registry.dart';
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

/// Name of the tool that pages through the available skills.
const String listSkillsToolName = 'list_skills';

/// How many skills one page of [ListSkillsTool] carries.
const int skillPageSize = 50;

/// Lists the available skills a page at a time.
///
/// The catalog used to be written into the system prompt in full, which cost
/// every turn a token for every skill whether or not any were used. Paging it
/// behind a tool makes that cost proportional to the turns that actually want
/// a skill, which is what lets a workspace carry many of them.
class ListSkillsTool extends AgentTool {
  /// Creates a [ListSkillsTool] bound to one turn's catalog.
  ListSkillsTool(this._catalog);

  final SkillCatalog _catalog;

  @override
  String get name => listSkillsToolName;

  @override
  String get description =>
      'List the skills available in this workspace, with a one-line '
      'description each. Load one with the `skill` tool before acting on it.';

  @override
  AgentToolRisk get risk => AgentToolRisk.read;

  @override
  Map<String, dynamic> get strictJsonSchema => <String, dynamic>{
    'type': 'object',
    'properties': <String, dynamic>{
      'cursor': <String, dynamic>{
        'type': <String>['string', 'null'],
        'description':
            'Continue from a previous call by passing its nextCursor. Null '
            'starts at the first page.',
      },
    },
    'required': <String>['cursor'],
    'additionalProperties': false,
  };

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async {
    final summaries = _catalog.summaries().toList(growable: false)
      ..sort((left, right) => left.name.compareTo(right.name));
    final raw = arguments['cursor'];
    final start = raw is String ? int.tryParse(raw) : 0;
    if (start == null || start < 0 || start > summaries.length) {
      // A bad cursor is correctable, so it comes back as tool output rather
      // than failing the turn.
      return ToolResult(
        isError: true,
        value: jsonEncode(<String, dynamic>{
          'error': 'cursor is not one this tool handed out.',
        }),
      );
    }
    final end = start + skillPageSize < summaries.length
        ? start + skillPageSize
        : summaries.length;
    return ToolResult(
      value: truncateToolOutput(
        jsonEncode(<String, dynamic>{
          'skills': summaries
              .sublist(start, end)
              .map(
                (summary) => <String, dynamic>{
                  'name': summary.name,
                  'description': summary.description,
                },
              )
              .toList(growable: false),
          'total': summaries.length,
          if (end < summaries.length) 'nextCursor': '$end',
        }),
      ),
    );
  }
}

/// Loads skill instructions on demand so the prompt only carries a pointer.
class SkillTool extends AgentTool {
  /// Creates a [SkillTool] bound to one turn's catalog.
  SkillTool(this._catalog);

  final SkillCatalog _catalog;

  @override
  String get name => skillToolName;

  @override
  String get description =>
      'Load the full instructions for one available skill, or read one of '
      'its bundled files.';

  @override
  AgentToolRisk get risk => AgentToolRisk.read;

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
              value: jsonEncode(<String, dynamic>{
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
      value: jsonEncode(<String, dynamic>{
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
    value: jsonEncode(<String, dynamic>{
      'error': error,
      'available': _catalog
          .summaries()
          .map((summary) => summary.name)
          .toList(growable: false),
    }),
  );
}

/// Name of the tool that loads one skill's full instructions.
const String skillToolName = 'skill';

/// Executor authority used by the local workspace skill catalog.
const String localSkillAuthorityId = 'local';

Map<String, dynamic> _skillAuthority() => <String, dynamic>{
  'kind': 'executor',
  'id': localSkillAuthorityId,
};

ModelNamespaceToolDefinition _skillsNamespace(
  String name,
  String description,
  Map<String, dynamic> parameters,
  Map<String, dynamic> outputSchema,
) => ModelNamespaceToolDefinition(
  name: 'skills',
  description: 'Tools for listing and reading authority-owned skills.',
  tools: <ModelFunctionToolDefinition>[
    ModelFunctionToolDefinition(
      name: name,
      description: description,
      parameters: parameters,
      outputSchema: outputSchema,
      strict: false,
    ),
  ],
);

/// Modern `skills.list` adapter over the local executor catalog.
final class SkillsListTool extends AgentTool {
  /// Creates a namespaced list tool.
  SkillsListTool(this._catalog);

  final SkillCatalog _catalog;

  @override
  String get name => 'skills__list';

  @override
  String get description =>
      'List skills owned by the requested authority. Returns the exact '
      'authority, package, and main_resource values required by skills.read. '
      'Pass next_cursor back as cursor to continue.';

  @override
  AgentToolRisk get risk => AgentToolRisk.read;

  @override
  Map<String, dynamic> get strictJsonSchema => <String, dynamic>{
    'type': 'object',
    'properties': <String, dynamic>{
      'authority': <String, dynamic>{
        'type': 'object',
        'properties': <String, dynamic>{
          'kind': <String, dynamic>{
            'type': 'string',
            'enum': <String>['executor'],
          },
        },
        'required': <String>['kind'],
        'additionalProperties': false,
      },
      'cursor': <String, dynamic>{'type': 'string'},
    },
    'required': <String>['authority'],
    'additionalProperties': false,
  };

  @override
  ModelToolDefinition get modelSpec => _skillsNamespace(
    'list',
    description,
    strictJsonSchema,
    const <String, dynamic>{
      'type': 'object',
      'properties': <String, dynamic>{
        'skills': <String, dynamic>{'type': 'array'},
        'warnings': <String, dynamic>{'type': 'array'},
        'next_cursor': <String, dynamic>{
          'type': <String>['string', 'null'],
        },
      },
      'required': <String>['skills', 'warnings', 'next_cursor'],
      'additionalProperties': false,
    },
  );

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async {
    final authority = arguments['authority'];
    if (authority is! Map || authority['kind'] != 'executor') {
      return const ToolResult(
        value: <String, dynamic>{'error': 'unsupported skill authority'},
        isError: true,
      );
    }
    final summaries = _catalog.summaries().toList(growable: false)
      ..sort((left, right) => left.name.compareTo(right.name));
    final cursor = arguments['cursor'];
    final start = cursor == null
        ? 0
        : cursor is String && cursor.startsWith('local:')
        ? int.tryParse(cursor.substring(6))
        : null;
    if (start == null || start < 0 || start > summaries.length) {
      return const ToolResult(
        value: <String, dynamic>{'error': 'skills.list cursor is invalid'},
        isError: true,
      );
    }
    final end = (start + 20).clamp(0, summaries.length);
    return ToolResult(
      value: <String, dynamic>{
        'skills': <Map<String, dynamic>>[
          for (final summary in summaries.sublist(start, end))
            <String, dynamic>{
              'authority': _skillAuthority(),
              'package': summary.name,
              'name': summary.name,
              'description': summary.description,
              'main_resource': 'SKILL.md',
            },
        ],
        'warnings': const <String>[],
        'next_cursor': end < summaries.length ? 'local:$end' : null,
      },
    );
  }
}

/// Modern `skills.read` adapter over the local executor catalog.
final class SkillsReadTool extends AgentTool {
  /// Creates a namespaced read tool.
  SkillsReadTool(this._catalog);

  final SkillCatalog _catalog;

  @override
  String get name => 'skills__read';

  @override
  String get description =>
      'Read one page from a skill resource. Pass the exact authority and '
      'package from skills.list, plus its main_resource or a referenced '
      'resource beneath that package.';

  @override
  AgentToolRisk get risk => AgentToolRisk.read;

  @override
  Map<String, dynamic> get strictJsonSchema => <String, dynamic>{
    'type': 'object',
    'properties': <String, dynamic>{
      'authority': <String, dynamic>{
        'type': 'object',
        'properties': <String, dynamic>{
          'kind': <String, dynamic>{
            'type': 'string',
            'enum': <String>['executor'],
          },
          'id': <String, dynamic>{'type': 'string'},
        },
        'required': <String>['kind', 'id'],
        'additionalProperties': false,
      },
      'package': <String, dynamic>{'type': 'string'},
      'resource': <String, dynamic>{'type': 'string'},
      'cursor': <String, dynamic>{'type': 'string'},
    },
    'required': <String>['authority', 'package', 'resource'],
    'additionalProperties': false,
  };

  @override
  ModelToolDefinition get modelSpec => _skillsNamespace(
    'read',
    description,
    strictJsonSchema,
    const <String, dynamic>{
      'type': 'object',
      'properties': <String, dynamic>{
        'resource': <String, dynamic>{'type': 'string'},
        'contents': <String, dynamic>{'type': 'string'},
        'next_cursor': <String, dynamic>{
          'type': <String>['string', 'null'],
        },
      },
      'required': <String>['resource', 'contents', 'next_cursor'],
      'additionalProperties': false,
    },
  );

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async {
    final authority = arguments['authority'];
    final package = arguments['package'];
    final resource = arguments['resource'];
    if (authority is! Map ||
        authority['kind'] != 'executor' ||
        authority['id'] != localSkillAuthorityId ||
        package is! String ||
        resource is! String) {
      return const ToolResult(
        value: <String, dynamic>{
          'error':
              'skill package is not available from the requested authority',
        },
        isError: true,
      );
    }
    try {
      final contents = resource == 'SKILL.md'
          ? (await _catalog.read(package)).instructions
          : await _catalog.readResource(package, resource);
      final cursor = arguments['cursor'];
      final start = cursor == null
          ? 0
          : cursor is String && cursor.startsWith('local:')
          ? int.tryParse(cursor.substring(6))
          : null;
      if (start == null || start < 0 || start > contents.length) {
        return const ToolResult(
          value: <String, dynamic>{'error': 'skills.read cursor is invalid'},
          isError: true,
        );
      }
      const pageCharacters = 256 * 1024;
      final end = (start + pageCharacters).clamp(0, contents.length);
      return ToolResult(
        value: <String, dynamic>{
          'resource': resource,
          'contents': contents.substring(start, end),
          'next_cursor': end < contents.length ? 'local:$end' : null,
        },
      );
    } on SkillLookupException catch (error) {
      return ToolResult(
        value: <String, dynamic>{'error': error.message},
        isError: true,
      );
    } on FileSystemException catch (error) {
      return ToolResult(
        value: <String, dynamic>{'error': error.message},
        isError: true,
      );
    }
  }
}

/// Registers the skill tools, in a worktree that publishes any.
///
/// Hidden rather than selectable: a skill is content the workspace carries, so
/// the tools appear because the worktree has skills rather than because an
/// agent asked for them.
final class SkillToolProvider extends AgentToolProvider {
  /// Creates a [SkillToolProvider].
  const SkillToolProvider();

  @override
  String get id => 'skills';

  @override
  AgentToolDefinition? get catalogEntry => null;

  @override
  List<AgentTool> create(AgentToolScope scope) =>
      scope.skills.summaries().isEmpty
      ? const <AgentTool>[]
      : <AgentTool>[
          ListSkillsTool(scope.skills),
          SkillTool(scope.skills),
          SkillsListTool(scope.skills),
          SkillsReadTool(scope.skills),
        ];

  /// Points at the skill tools instead of listing every skill.
  ///
  /// Naming each skill here charged every turn for the whole catalog, whether
  /// or not it used one. The count is kept because it is one number and it is
  /// what tells the agent whether looking is worth a call at all.
  @override
  String? promptFragment(AgentToolScope scope) {
    final skills = scope.skills.summaries();
    if (skills.isEmpty) return null;
    final plural = skills.length == 1 ? 'skill is' : 'skills are';
    return '''
## Available skills
${skills.length} $plural available in this workspace.
Call the `$listSkillsToolName` tool to see their names and descriptions, then the
`$skillToolName` tool with a name to load its full instructions before acting on it.
Treat a skill's bundled scripts as ordinary workspace code: read them before running them.''';
  }
}
