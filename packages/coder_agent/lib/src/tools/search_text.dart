import 'dart:async';
import 'dart:convert';
import 'dart:io' show FileSystemException;

import 'package:coder_agent/src/gitignore.dart';
import 'package:coder_agent/src/model.dart';
import 'package:coder_agent/src/tools/tool_support.dart';
import 'package:coder_agent/src/workspace_walk.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:file/file.dart' as file_api;
import 'package:file/local.dart';
import 'package:platform/platform.dart';

/// Longest match line reported before it is cut.
const int maxSearchLineLength = 500;

/// Most lines of surrounding context a match may carry on each side.
const int maxSearchContextLines = 5;

/// Largest file the search will read.
///
/// Reporting context lines means holding a whole file at once, so a file this
/// far past anything hand-written is skipped rather than paged into memory. It
/// is almost certainly data or a build artefact.
const int maxSearchFileBytes = 8 * 1024 * 1024;

/// SearchTextTool defines a public contract.
class SearchTextTool extends AgentTool {
  /// Creates a [SearchTextTool].
  SearchTextTool({
    this._fileSystem = const LocalFileSystem(),
    this._platform = const LocalPlatform(),
    this._gitignoreEnvironment = const GitignoreEnvironment.none(),
  });

  final file_api.FileSystem _fileSystem;
  final Platform _platform;

  /// Where user-level git configuration lives.
  ///
  /// Empty by default so nothing reads the running user's home unless a
  /// composition root deliberately says to.
  final GitignoreEnvironment _gitignoreEnvironment;

  @override
  String get name => 'search_text';
  @override
  String get description =>
      'Search workspace text file contents. Matches a literal string by '
      'default, or a regular expression when regex is true. Files git ignores '
      'are skipped unless include_ignored is set. Use glob to search by file '
      'name instead.';
  @override
  ToolRisk get risk => ToolRisk.read;
  @override
  Map<String, dynamic> get strictJsonSchema =>
      strictToolObject(<String, Map<String, dynamic>>{
        'query': <String, dynamic>{
          'type': 'string',
          'description': 'Text to find, or a regular expression when regex.',
        },
        'path': <String, dynamic>{
          'type': <String>['string', 'null'],
          'description':
              'Directory to search, relative to the workspace root. Null '
              'searches the whole workspace.',
        },
        'regex': <String, dynamic>{
          'type': <String>['boolean', 'null'],
          'description':
              'Whether query is a regular expression. Null and false treat it '
              'as a literal string.',
        },
        'case_sensitive': <String, dynamic>{
          'type': <String>['boolean', 'null'],
          'description':
              'Whether case matters. Null and true match case exactly.',
        },
        'context_lines': <String, dynamic>{
          'type': <String>['integer', 'null'],
          'description':
              'Lines of surrounding context on each side of a match. Null '
              'returns none; values are clamped to $maxSearchContextLines.',
        },
        'include_ignored': <String, dynamic>{
          'type': <String>['boolean', 'null'],
          'description':
              'Whether to search files git ignores, such as build output and '
              'generated code. Null and false skip them.',
        },
        'max_results': <String, dynamic>{
          'type': <String>['integer', 'null'],
          'description':
              'Most matches to return. Null uses $defaultSearchResults.',
        },
      });

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async {
    final query = arguments['query'] as String;
    if (query.isEmpty) throw const FormatException('query must not be empty.');
    final caseSensitive = arguments['case_sensitive'] != false;
    final RegExp? pattern;
    if (arguments['regex'] == true) {
      try {
        pattern = RegExp(query, caseSensitive: caseSensitive);
      } on FormatException catch (error) {
        // A bad expression is something the model can fix on the next call, so
        // it is reported as tool output rather than failing the turn.
        return ToolResult(
          output: jsonEncode(<String, dynamic>{
            'error': 'query is not a valid regular expression.',
            'detail': error.message,
          }),
          isError: true,
        );
      }
    } else {
      pattern = null;
    }

    final root = WorkspacePathGuard(
      context.workspaceRoot,
      fileSystem: _fileSystem,
      platform: _platform,
    ).resolveExisting((arguments['path'] as String?) ?? '.');
    final maxResults =
        (arguments['max_results'] as int?) ?? defaultSearchResults;
    final contextLines = ((arguments['context_lines'] as int?) ?? 0).clamp(
      0,
      maxSearchContextLines,
    );
    final needle = caseSensitive ? query : query.toLowerCase();

    final matches = <Map<String, dynamic>>[];
    var filesSearched = 0;
    var truncated = false;
    final walker = WorkspaceWalker(
      fileSystem: _fileSystem,
      workspaceRoot: context.workspaceRoot,
      respectGitignore: arguments['include_ignored'] != true,
      gitignoreEnvironment: _gitignoreEnvironment,
    );

    await for (final walked in walker.walk(root, context.cancellation)) {
      final List<String> lines;
      try {
        if (await walked.file.length() > maxSearchFileBytes) continue;
        lines = const LineSplitter().convert(await walked.file.readAsString());
      } on FormatException {
        // Binary and non-UTF-8 files are skipped, not reported.
        continue;
      } on FileSystemException {
        continue;
      }
      filesSearched += 1;
      for (var index = 0; index < lines.length; index += 1) {
        final line = lines[index];
        final hit = pattern != null
            ? pattern.hasMatch(line)
            : (caseSensitive ? line : line.toLowerCase()).contains(needle);
        if (!hit) continue;
        matches.add(<String, dynamic>{
          'path': walked.relativePath,
          'line': index + 1,
          'text': _clip(line),
          if (contextLines > 0) ...<String, dynamic>{
            'before': _slice(lines, index - contextLines, index),
            'after': _slice(lines, index + 1, index + 1 + contextLines),
          },
        });
        if (matches.length >= maxResults) {
          truncated = true;
          break;
        }
      }
      // The cap ends the whole walk, not just this file.
      if (truncated) break;
    }

    return ToolResult(
      output: truncateToolOutput(
        jsonEncode(<String, dynamic>{
          'matches': matches,
          'matchCount': matches.length,
          'filesSearched': filesSearched,
          // Without this the model cannot tell "no more matches" from "the cap
          // hid the rest", which are opposite conclusions.
          'truncated': truncated,
        }),
      ),
    );
  }

  static String _clip(String line) => line.length > maxSearchLineLength
      ? line.substring(0, maxSearchLineLength)
      : line;

  static List<String> _slice(List<String> lines, int start, int end) => lines
      .sublist(start.clamp(0, lines.length), end.clamp(0, lines.length))
      .map(_clip)
      .toList(growable: false);
}
