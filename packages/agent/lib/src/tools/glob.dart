import 'dart:async';
import 'dart:convert';

import 'package:agent/src/contracts.dart';
import 'package:agent/src/gitignore.dart';
import 'package:agent/src/model.dart';
import 'package:agent/src/tools/tool_registry.dart';
import 'package:agent/src/tools/tool_support.dart';
import 'package:agent/src/workspace_walk.dart';
import 'package:file/file.dart' as file_api;
import 'package:file/local.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;
import 'package:platform/platform.dart';

/// GlobTool defines a public contract.
class GlobTool extends AgentTool {
  /// Creates a [GlobTool].
  GlobTool({
    this._fileSystem = const LocalFileSystem(),
    this._platform = const LocalPlatform(),
    this._gitignoreEnvironment = const GitignoreEnvironment.none(),
  });

  final file_api.FileSystem _fileSystem;
  final Platform _platform;

  /// Where user-level git configuration lives.
  final GitignoreEnvironment _gitignoreEnvironment;

  @override
  String get name => 'glob';
  @override
  String get description =>
      'Find workspace files by name using a glob pattern such as '
      '`**/*_test.dart`. Files git ignores are skipped unless include_ignored '
      'is set. Use search_text to search file contents instead.';
  @override
  AgentToolRisk get risk => AgentToolRisk.read;
  @override
  Map<String, dynamic> get strictJsonSchema => strictToolObject(
    <String, Map<String, dynamic>>{
      'pattern': <String, dynamic>{
        'type': 'string',
        'description':
            'Glob matched against paths relative to the searched directory, '
            'for example `**/*.dart` or `lib/**/model_*.dart`.',
      },
      'path': <String, dynamic>{
        'type': <String>['string', 'null'],
        'description':
            'Directory to search, relative to the workspace root. Null '
            'searches the whole workspace.',
      },
      'include_ignored': <String, dynamic>{
        'type': <String>['boolean', 'null'],
        'description':
            'Whether to include files git ignores. Null and false skip them.',
      },
      'max_results': <String, dynamic>{
        'type': <String>['integer', 'null'],
        'description': 'Most paths to return. Null uses $defaultSearchResults.',
      },
    },
  );

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async {
    final rawPattern = arguments['pattern'] as String;
    if (rawPattern.isEmpty) {
      throw const FormatException('pattern must not be empty.');
    }
    final List<Glob> globs;
    try {
      // Walked paths are always `/`-separated, so the pattern is compiled in
      // that same context rather than the host's.
      globs = <Glob>[
        Glob(rawPattern, context: p.posix),
        // `**/` means "one or more directories" to package:glob, so a plain
        // `**/*.dart` would silently miss every top-level file. Everyone who
        // writes that pattern means "at any depth, including here", so the
        // prefix-free form is matched as well.
        if (rawPattern.startsWith('**/'))
          Glob(rawPattern.substring(3), context: p.posix),
      ];
    } on FormatException catch (error) {
      return ToolResult(
        value: jsonEncode(<String, dynamic>{
          'error': 'pattern is not a valid glob.',
          'detail': error.message,
        }),
        isError: true,
      );
    }

    final root = WorkspacePathGuard(
      context.workspaceRoot,
      fileSystem: _fileSystem,
      platform: _platform,
    ).resolveExisting((arguments['path'] as String?) ?? '.');
    final maxResults =
        (arguments['max_results'] as int?) ?? defaultSearchResults;
    final walker = WorkspaceWalker(
      fileSystem: _fileSystem,
      workspaceRoot: context.workspaceRoot,
      respectGitignore: arguments['include_ignored'] != true,
      gitignoreEnvironment: _gitignoreEnvironment,
    );
    // Matching happens against the path the caller asked about, so a pattern
    // written for a subdirectory does not have to repeat that subdirectory.
    final scope = _scopeOf(root, context.workspaceRoot);

    final paths = <String>[];
    var truncated = false;
    await for (final walked in walker.walk(root, context.cancellation)) {
      final candidate = scope.isEmpty
          ? walked.relativePath
          : walked.relativePath.substring(scope.length + 1);
      // Glob.matches is used rather than Glob.list, which reaches for dart:io
      // directly and would bypass the injected filesystem.
      if (!globs.any((glob) => glob.matches(candidate))) continue;
      paths.add(walked.relativePath);
      if (paths.length >= maxResults) {
        truncated = true;
        break;
      }
    }

    return ToolResult(
      value: truncateToolOutput(
        jsonEncode(<String, dynamic>{
          'paths': paths,
          'truncated': truncated,
        }),
      ),
    );
  }

  String _scopeOf(String root, String workspaceRoot) {
    final relative = _fileSystem.path.relative(root, from: workspaceRoot);
    if (relative == '.') return '';
    return _fileSystem.path.split(relative).join('/');
  }
}

/// Registers the workspace file-name search.
final class GlobToolProvider extends SelectableToolProvider {
  /// Creates a [GlobToolProvider].
  const GlobToolProvider({required GitignoreEnvironment gitignoreEnvironment})
    : _gitignore = gitignoreEnvironment;

  final GitignoreEnvironment _gitignore;

  @override
  String get id => 'glob';

  @override
  AgentToolDefinition get catalogEntry => AgentToolDefinition(
    id: id,
    name: id,
    description: GlobTool(gitignoreEnvironment: _gitignore).description,
    risk: AgentToolRisk.read,
    alwaysOn: true,
  );

  @override
  List<AgentTool> build(AgentToolScope scope) => <AgentTool>[
    GlobTool(gitignoreEnvironment: _gitignore),
  ];
}
