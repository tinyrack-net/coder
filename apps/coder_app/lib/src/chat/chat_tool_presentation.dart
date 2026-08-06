import 'dart:convert';

import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:coder_app/src/chat/chat_diff.dart';
import 'package:coder_app/src/chat/chat_timeline_model.dart';

/// Renders normalized token counters as one muted summary line.
///
/// The counters arrive under the stable names `ModelUsage` writes, so this is a
/// fixed set rather than a walk over whatever keys a provider happened to send.
/// Cached input and hidden reasoning are subsets of their parents, so they read
/// as parenthesised qualifiers. Returns null when there is nothing to report.
String? describeTokenUsage(AppLocalizations l10n, Map<String, num> tokens) {
  int count(String key) {
    final value = tokens[key];
    return value is num ? value.round() : 0;
  }

  final input = count('inputTokens');
  final cached = count('cachedInputTokens');
  final output = count('outputTokens');
  final reasoning = count('reasoningTokens');
  final total = count('totalTokens');
  if (input == 0 && output == 0 && total == 0) return null;

  final parts = <String>[
    if (input > 0)
      cached > 0
          ? l10n.usageInputCached(input, cached)
          : l10n.usageInput(input),
    if (output > 0)
      reasoning > 0
          ? l10n.usageOutputReasoning(output, reasoning)
          : l10n.usageOutput(output),
    if (total > 0) l10n.usageTotal(total),
  ];
  return parts.join(' · ');
}

/// Decoded shape of `tool.completed.output`, which some tools double-encode.
sealed class ChatToolOutput {
  const ChatToolOutput();
}

/// Output that decoded into a JSON object.
final class ChatToolJsonObject extends ChatToolOutput {
  /// Creates a decoded JSON object output.
  const ChatToolJsonObject(this.value);

  /// The decoded object.
  final Map<String, dynamic> value;
}

/// Output that decoded into a JSON array.
final class ChatToolJsonArray extends ChatToolOutput {
  /// Creates a decoded JSON array output.
  const ChatToolJsonArray(this.value);

  /// The decoded array.
  final List<dynamic> value;
}

/// Output that is plain text, or JSON that failed to decode.
final class ChatToolPlainText extends ChatToolOutput {
  /// Creates a plain-text output.
  const ChatToolPlainText(this.value);

  /// The raw text.
  final String value;
}

/// Decodes tool output without ever throwing.
ChatToolOutput decodeToolOutput(String raw) {
  final trimmed = raw.trim();
  if (!trimmed.startsWith('{') && !trimmed.startsWith('[')) {
    return ChatToolPlainText(raw);
  }
  try {
    final decoded = json.decode(trimmed);
    if (decoded is Map<String, dynamic>) return ChatToolJsonObject(decoded);
    if (decoded is List<dynamic>) return ChatToolJsonArray(decoded);
    return ChatToolPlainText(raw);
  } on FormatException {
    return ChatToolPlainText(raw);
  }
}

/// Expanded body of one tool activity.
sealed class ChatToolBody {
  const ChatToolBody();
}

/// Nothing to show beyond the summary.
final class ChatToolEmptyBody extends ChatToolBody {
  /// Creates an empty body.
  const ChatToolEmptyBody();
}

/// Monospace text such as command output or a file slice.
final class ChatToolTextBody extends ChatToolBody {
  /// Creates a text body.
  const ChatToolTextBody(this.text);

  /// The text to render.
  final String text;
}

/// A colored unified diff.
final class ChatToolDiffBody extends ChatToolBody {
  /// Creates a diff body.
  const ChatToolDiffBody(this.files);

  /// Parsed diff files.
  final List<ChatDiffFile> files;
}

/// Icon family used by the collapsed tool row.
enum ChatToolGlyph {
  /// File reads.
  read,

  /// Directory listings.
  list,

  /// Text searches.
  search,

  /// File edits.
  edit,

  /// Shell commands.
  run,

  /// Subagent delegation.
  delegate,

  /// Plan updates.
  plan,

  /// Questions put to the user.
  ask,

  /// MCP resource discovery and reads.
  resource,

  /// Tool discovery.
  tools,

  /// Time and waiting.
  clock,

  /// The model's own context window.
  context,

  /// Images loaded into the model context.
  image,

  /// Anything this build does not know.
  generic,
}

/// Everything the UI needs to draw one tool activity, computed from data only.
final class ChatToolPresentation {
  /// Creates a tool presentation.
  const ChatToolPresentation({
    required this.glyph,
    required this.title,
    required this.resultLine,
    required this.body,
    required this.isFailure,
    this.argumentBody = const ChatToolEmptyBody(),
  });

  /// Icon family for the collapsed row.
  final ChatToolGlyph glyph;

  /// CLI-style one-line title such as `Read(lib/main.dart)`.
  final String title;

  /// Short Korean result summary, or null while nothing is known.
  final String? resultLine;

  /// Expanded result content.
  final ChatToolBody body;

  /// Expanded request content, shown above [body].
  final ChatToolBody argumentBody;

  /// Whether the result should be styled as an error.
  final bool isFailure;
}

/// Describes one tool activity for the chat timeline.
ChatToolPresentation describeToolActivity(
  AppLocalizations l10n,
  ChatToolActivity activity,
) {
  final spec = _specs[activity.toolName] ?? _genericSpec;
  final title = spec.title(l10n, activity);
  final argumentBody = spec.argumentBody(activity);
  switch (activity.status) {
    case ChatToolStatus.running:
      return ChatToolPresentation(
        glyph: spec.glyph,
        title: title,
        resultLine: l10n.commonRunning,
        body: const ChatToolEmptyBody(),
        argumentBody: argumentBody,
        isFailure: false,
      );
    case ChatToolStatus.denied:
      return ChatToolPresentation(
        glyph: spec.glyph,
        title: title,
        resultLine: l10n.toolRejected,
        body: const ChatToolEmptyBody(),
        argumentBody: argumentBody,
        isFailure: false,
      );
    case ChatToolStatus.failed:
      return ChatToolPresentation(
        glyph: spec.glyph,
        title: title,
        resultLine: _truncate(
          _firstLine(activity.error ?? l10n.toolFailed),
          120,
        ),
        body: ChatToolTextBody(activity.error ?? ''),
        argumentBody: argumentBody,
        isFailure: true,
      );
    case ChatToolStatus.succeeded:
      final output = decodeToolOutput(activity.output ?? '');
      return ChatToolPresentation(
        glyph: spec.glyph,
        title: title,
        resultLine: spec.result(l10n, activity, output),
        body: spec.body(activity, output),
        argumentBody: argumentBody,
        isFailure: activity.isError || spec.isFailure(output),
      );
  }
}

final class _ToolSpec {
  const _ToolSpec({
    required this.glyph,
    required this.title,
    required this.result,
    this.body = _plainBody,
    this.argumentBody = _noArgumentBody,
    this.isFailure = _neverFails,
  });

  final ChatToolGlyph glyph;
  final String Function(AppLocalizations l10n, ChatToolActivity activity) title;
  final String Function(
    AppLocalizations l10n,
    ChatToolActivity activity,
    ChatToolOutput output,
  )
  result;
  final ChatToolBody Function(ChatToolActivity activity, ChatToolOutput output)
  body;
  final ChatToolBody Function(ChatToolActivity activity) argumentBody;
  final bool Function(ChatToolOutput output) isFailure;
}

ChatToolBody _plainBody(ChatToolActivity activity, ChatToolOutput output) =>
    switch (output) {
      ChatToolPlainText(:final value) =>
        value.isEmpty ? const ChatToolEmptyBody() : ChatToolTextBody(value),
      ChatToolJsonObject(:final value) => ChatToolTextBody(_pretty(value)),
      ChatToolJsonArray(:final value) => ChatToolTextBody(_pretty(value)),
    };

/// Built-in tools already carry their arguments in the title, so the expanded
/// view stays free of an argument dump.
ChatToolBody _noArgumentBody(ChatToolActivity activity) =>
    const ChatToolEmptyBody();

ChatToolBody _prettyArgumentBody(ChatToolActivity activity) =>
    activity.arguments.isEmpty
    ? const ChatToolEmptyBody()
    : ChatToolTextBody(_pretty(activity.arguments));

bool _neverFails(ChatToolOutput output) => false;

bool _hasErrorKey(ChatToolOutput output) =>
    output is ChatToolJsonObject && output.value['error'] != null;

/// Summarizes an MCP listing, noting when a page was truncated.
String _mcpListResult(
  AppLocalizations l10n,
  ChatToolOutput output,
  String key,
  String Function(int count) label,
) {
  if (output is! ChatToolJsonObject) return _genericResult(l10n, output);
  final error = output.value['error'];
  if (error is String) return error;
  final entries = output.value[key];
  final count = entries is List ? entries.length : 0;
  final summary = label(count);
  return output.value['truncated'] == true ? '$summary…' : summary;
}

/// Summarizes a pseudo-terminal chunk from `exec_command` or `write_stdin`.
String _execResult(
  AppLocalizations l10n,
  ChatToolActivity activity,
  ChatToolOutput output,
) {
  if (output is! ChatToolJsonObject) return _genericResult(l10n, output);
  final error = output.value['error'];
  if (error is String) return error;
  final text = output.value['output'];
  final lines = text is String && text.isNotEmpty ? _countLines(text) : 0;
  final exitCode = output.value['exitCode'];
  // A session that is still running has no exit code to report yet.
  return exitCode is int
      ? l10n.toolCommandResult(exitCode, lines)
      : l10n.toolExecRunning(lines);
}

ChatToolBody _execBody(ChatToolActivity activity, ChatToolOutput output) {
  if (output is ChatToolJsonObject && output.value['output'] is String) {
    final text = output.value['output']! as String;
    return text.isEmpty ? const ChatToolEmptyBody() : ChatToolTextBody(text);
  }
  return _plainBody(activity, output);
}

bool _execIsFailure(ChatToolOutput output) =>
    output is ChatToolJsonObject &&
    (output.value['error'] != null ||
        (output.value['exitCode'] is int && output.value['exitCode'] != 0));

final Map<String, _ToolSpec> _specs = <String, _ToolSpec>{
  'read_file': _ToolSpec(
    glyph: ChatToolGlyph.read,
    title: (l10n, activity) {
      final path = _stringArg(activity, 'path') ?? '?';
      final offset = activity.arguments['offset'];
      final limit = activity.arguments['limit'];
      if (offset == null && limit == null) return 'Read($path)';
      return 'Read($path @${offset ?? 0}+${limit ?? 0})';
    },
    result: (l10n, activity, output) {
      final text = _asText(output);
      if (text.isEmpty) return l10n.toolEmptyFile;
      return l10n.toolReadLines(_countLines(text));
    },
  ),
  'list_directory': _ToolSpec(
    glyph: ChatToolGlyph.list,
    title: (l10n, activity) => 'List(${_stringArg(activity, 'path') ?? '.'})',
    result: (l10n, activity, output) {
      if (output is! ChatToolJsonArray) return _genericResult(l10n, output);
      final entries = output.value.whereType<Map<String, dynamic>>();
      if (entries.length != output.value.length) {
        return l10n.toolListItems(output.value.length);
      }
      final directories = entries
          .where((entry) => entry['type'] == 'directory')
          .length;
      return l10n.toolListEntries(directories, entries.length - directories);
    },
  ),
  'search_text': _ToolSpec(
    glyph: ChatToolGlyph.search,
    title: (l10n, activity) {
      final query = _truncate(_stringArg(activity, 'query') ?? '', 40);
      final path = _stringArg(activity, 'path');
      return path == null ? 'Search($query)' : 'Search($query in $path)';
    },
    result: (l10n, activity, output) {
      if (output is! ChatToolJsonObject) return _genericResult(l10n, output);
      final error = output.value['error'];
      if (error is String) return error;
      final matches = output.value['matches'];
      if (matches is! List || matches.isEmpty) return l10n.toolNoMatches;
      final paths = matches
          .whereType<Map<String, dynamic>>()
          .map((match) => match['path'])
          .whereType<String>()
          .toSet();
      // The cap changes what the count means: a truncated run says "at least",
      // not "exactly".
      return output.value['truncated'] == true
          ? l10n.toolMatchesTruncated(matches.length, paths.length)
          : l10n.toolMatches(matches.length, paths.length);
    },
    isFailure: (output) =>
        output is ChatToolJsonObject && output.value['error'] != null,
  ),
  'glob': _ToolSpec(
    glyph: ChatToolGlyph.search,
    title: (l10n, activity) {
      final pattern = _truncate(_stringArg(activity, 'pattern') ?? '', 40);
      final path = _stringArg(activity, 'path');
      return path == null ? 'Glob($pattern)' : 'Glob($pattern in $path)';
    },
    result: (l10n, activity, output) {
      if (output is! ChatToolJsonObject) return _genericResult(l10n, output);
      final error = output.value['error'];
      if (error is String) return error;
      final paths = output.value['paths'];
      if (paths is! List || paths.isEmpty) return l10n.toolNoPaths;
      return output.value['truncated'] == true
          ? l10n.toolPathsTruncated(paths.length)
          : l10n.toolPaths(paths.length);
    },
    isFailure: (output) =>
        output is ChatToolJsonObject && output.value['error'] != null,
  ),
  'list_skills': _ToolSpec(
    glyph: ChatToolGlyph.list,
    title: (l10n, activity) => 'Skills()',
    result: (l10n, activity, output) {
      if (output is! ChatToolJsonObject) return _genericResult(l10n, output);
      final skills = output.value['skills'];
      if (skills is! List || skills.isEmpty) return l10n.toolNoMatches;
      return output.value['nextCursor'] != null
          ? l10n.toolSkillsTruncated(skills.length)
          : l10n.toolSkills(skills.length);
    },
    isFailure: _hasErrorKey,
  ),
  'skill': _ToolSpec(
    glyph: ChatToolGlyph.read,
    title: (l10n, activity) {
      final name = _stringArg(activity, 'name') ?? '?';
      final resource = _stringArg(activity, 'resource');
      // The bundled file matters as much as the skill when one is named.
      return resource == null || resource.isEmpty
          ? 'Skill($name)'
          : 'Skill($name:${_truncate(resource, 40)})';
    },
    result: (l10n, activity, output) {
      if (output is! ChatToolJsonObject) return _genericResult(l10n, output);
      final error = output.value['error'];
      if (error is String) return error;
      final name = output.value['name'];
      return name is String
          ? l10n.toolSkillLoaded(name)
          : _genericResult(l10n, output);
    },
    body: (activity, output) {
      if (output is! ChatToolJsonObject) return _plainBody(activity, output);
      final text = output.value['instructions'] ?? output.value['content'];
      return text is String && text.isNotEmpty
          ? ChatToolTextBody(text)
          : const ChatToolEmptyBody();
    },
    isFailure: _hasErrorKey,
  ),
  'apply_patch': _ToolSpec(
    glyph: ChatToolGlyph.edit,
    title: (l10n, activity) {
      final files = parseChatDiff(_stringArg(activity, 'patch') ?? '');
      final named = files
          .where((file) => file.path.isNotEmpty)
          .toList(growable: false);
      if (named.isEmpty) return 'Edit';
      if (named.length == 1) return 'Edit(${named.single.path})';
      return l10n.toolEditFiles(named.length);
    },
    result: (l10n, activity, output) {
      final files = parseChatDiff(_stringArg(activity, 'patch') ?? '');
      final added = files.fold<int>(0, (sum, file) => sum + file.added);
      final removed = files.fold<int>(0, (sum, file) => sum + file.removed);
      final changed = output is ChatToolJsonObject
          ? output.value['changedFiles']
          : null;
      final count = changed is int ? changed : files.length;
      return l10n.toolPatchSummary(added, removed, count);
    },
    argumentBody: (activity) =>
        ChatToolDiffBody(parseChatDiff(_stringArg(activity, 'patch') ?? '')),
    body: (activity, output) => const ChatToolEmptyBody(),
  ),
  'ask_user': _ToolSpec(
    glyph: ChatToolGlyph.ask,
    title: (l10n, activity) {
      final questions = activity.arguments['questions'];
      final headers = questions is List
          ? questions
                .whereType<Map<dynamic, dynamic>>()
                .map((question) => question['header'])
                .whereType<String>()
          : const <String>[];
      return 'Ask(${headers.isEmpty ? '?' : headers.join(', ')})';
    },
    result: (l10n, activity, output) {
      if (output is! ChatToolJsonArray) return _genericResult(l10n, output);
      final answers = output.value
          .whereType<Map<dynamic, dynamic>>()
          .map((answer) => answer['answer'])
          .whereType<String>();
      return answers.isEmpty
          ? _genericResult(l10n, output)
          : answers.join(', ');
    },
  ),
  'current_time': _ToolSpec(
    glyph: ChatToolGlyph.clock,
    title: (l10n, activity) => 'Now()',
    result: (l10n, activity, output) =>
        output is ChatToolJsonObject && output.value['utc'] is String
        ? output.value['utc']! as String
        : _genericResult(l10n, output),
  ),
  // A running sleep renders as its own countdown card; this only draws one
  // that failed or was denied.
  'sleep': _ToolSpec(
    glyph: ChatToolGlyph.clock,
    title: (l10n, activity) {
      final milliseconds = activity.arguments['duration_ms'];
      return milliseconds is int ? 'Sleep(${milliseconds}ms)' : 'Sleep()';
    },
    result: (l10n, activity, output) {
      if (output is! ChatToolJsonObject) return _genericResult(l10n, output);
      final error = output.value['error'];
      if (error is String) return error;
      final slept = output.value['sleptMs'];
      return slept is int
          ? l10n.chatSleepDone((slept / 1000).ceil())
          : _genericResult(l10n, output);
    },
    isFailure: _hasErrorKey,
  ),
  'get_context_remaining': _ToolSpec(
    glyph: ChatToolGlyph.context,
    title: (l10n, activity) => 'Context()',
    result: (l10n, activity, output) {
      if (output is! ChatToolJsonObject) return _genericResult(l10n, output);
      final remaining = output.value['remainingTokens'];
      final window = output.value['contextWindowTokens'];
      final used = output.value['usedTokens'];
      // A provider that never advertised a window has no denominator, so the
      // row reports what was spent instead of inventing a percentage.
      if (remaining is! int || window is! int) {
        return l10n.toolContextRemainingUnknown(used is int ? used : 0);
      }
      return l10n.toolContextRemaining(remaining, window);
    },
  ),
  // A successful reset renders as its own divider; this only draws one that
  // failed or was denied.
  'new_context': _ToolSpec(
    glyph: ChatToolGlyph.context,
    title: (l10n, activity) => 'NewContext()',
    result: (l10n, activity, output) =>
        output is ChatToolJsonObject && output.value['error'] is String
        ? output.value['error']! as String
        : l10n.chatContextReset,
    isFailure: _hasErrorKey,
  ),
  'tool_search': _ToolSpec(
    glyph: ChatToolGlyph.tools,
    title: (l10n, activity) =>
        'Tools(${_truncate(_stringArg(activity, 'query') ?? '', 40)})',
    result: (l10n, activity, output) {
      if (output is! ChatToolJsonObject) return _genericResult(l10n, output);
      final error = output.value['error'];
      if (error is String) return error;
      final found = output.value['tools'];
      final remaining = output.value['remaining'];
      return l10n.toolSearchFound(
        found is List ? found.length : 0,
        remaining is int ? remaining : 0,
      );
    },
    body: (activity, output) {
      // The names are the useful part; the schemas are for the model.
      if (output is! ChatToolJsonObject) return _plainBody(activity, output);
      final found = output.value['tools'];
      if (found is! List) return _plainBody(activity, output);
      final names = found
          .whereType<Map<dynamic, dynamic>>()
          .map((tool) => tool['name'])
          .whereType<String>()
          .join('\n');
      return names.isEmpty
          ? const ChatToolEmptyBody()
          : ChatToolTextBody(names);
    },
    isFailure: _hasErrorKey,
  ),
  'list_mcp_resources': _ToolSpec(
    glyph: ChatToolGlyph.resource,
    title: (l10n, activity) =>
        'Resources(${_stringArg(activity, 'server') ?? 'all'})',
    result: (l10n, activity, output) => _mcpListResult(
      l10n,
      output,
      'resources',
      l10n.toolMcpResources,
    ),
    isFailure: _hasErrorKey,
  ),
  'list_mcp_resource_templates': _ToolSpec(
    glyph: ChatToolGlyph.resource,
    title: (l10n, activity) =>
        'ResourceTemplates(${_stringArg(activity, 'server') ?? 'all'})',
    result: (l10n, activity, output) => _mcpListResult(
      l10n,
      output,
      'resourceTemplates',
      l10n.toolMcpResourceTemplates,
    ),
    isFailure: _hasErrorKey,
  ),
  'read_mcp_resource': _ToolSpec(
    glyph: ChatToolGlyph.resource,
    title: (l10n, activity) {
      final server = _stringArg(activity, 'server') ?? '?';
      final uri = _truncate(_stringArg(activity, 'uri') ?? '?', 48);
      return 'Resource($server: $uri)';
    },
    result: (l10n, activity, output) {
      if (output is! ChatToolJsonObject) return _genericResult(l10n, output);
      final error = output.value['error'];
      if (error is String) return error;
      final contents = output.value['contents'];
      final blocks = contents is List ? contents.length : 0;
      return l10n.toolMcpResourceRead(blocks);
    },
    body: (activity, output) {
      // Text contents are what the user actually wants to inspect.
      if (output is! ChatToolJsonObject) return _plainBody(activity, output);
      final contents = output.value['contents'];
      if (contents is! List) return _plainBody(activity, output);
      final text = contents
          .whereType<Map<dynamic, dynamic>>()
          .map((block) => block['text'])
          .whereType<String>()
          .join('\n');
      return text.isEmpty
          ? _plainBody(activity, output)
          : ChatToolTextBody(text);
    },
    isFailure: _hasErrorKey,
  ),
  'view_image': _ToolSpec(
    glyph: ChatToolGlyph.image,
    title: (l10n, activity) => 'View(${_stringArg(activity, 'path') ?? '?'})',
    result: (l10n, activity, output) {
      if (output is! ChatToolJsonObject) return _genericResult(l10n, output);
      final error = output.value['error'];
      if (error is String) return error;
      final bytes = output.value['byteSize'];
      return bytes is int
          ? l10n.toolImageLoaded(bytes)
          : _genericResult(l10n, output);
    },
    isFailure: (output) =>
        output is ChatToolJsonObject && output.value['error'] != null,
  ),
  // An accepted plan renders as its own card, so this spec only ever draws a
  // plan the daemon rejected.
  'update_plan': _ToolSpec(
    glyph: ChatToolGlyph.plan,
    title: (l10n, activity) {
      final plan = activity.arguments['plan'];
      return 'Plan(${plan is List ? plan.length : 0})';
    },
    result: (l10n, activity, output) {
      final error = output is ChatToolJsonObject ? output.value['error'] : null;
      return error is String ? error : _genericResult(l10n, output);
    },
    isFailure: (output) =>
        output is ChatToolJsonObject && output.value['error'] != null,
  ),
  'exec_command': _ToolSpec(
    glyph: ChatToolGlyph.run,
    title: (l10n, activity) {
      final command = _stringArg(activity, 'command') ?? '';
      return 'Bash(${_truncate(_firstLine(command), 60)})';
    },
    result: _execResult,
    body: _execBody,
    argumentBody: (activity) {
      final command = _stringArg(activity, 'command');
      if (command == null || command.isEmpty) return const ChatToolEmptyBody();
      // The directory changes what the command does, so it is shown whenever
      // it is not simply the workspace root.
      final workdir = _stringArg(activity, 'workdir');
      return ChatToolTextBody(
        workdir == null || workdir.isEmpty
            ? '\$ $command'
            : '$workdir\n\$ $command',
      );
    },
    isFailure: _execIsFailure,
  ),
  'write_stdin': _ToolSpec(
    glyph: ChatToolGlyph.run,
    title: (l10n, activity) {
      final chars = _stringArg(activity, 'chars') ?? '';
      final session = _stringArg(activity, 'session_id') ?? '?';
      return chars.isEmpty
          ? 'Stdin($session)'
          : 'Stdin($session ← ${_truncate(_firstLine(chars), 40)})';
    },
    result: _execResult,
    body: _execBody,
    argumentBody: (activity) {
      final chars = _stringArg(activity, 'chars');
      return chars == null || chars.isEmpty
          ? const ChatToolEmptyBody()
          : ChatToolTextBody(chars);
    },
    isFailure: _execIsFailure,
  ),
  'delegate_agent': _ToolSpec(
    glyph: ChatToolGlyph.delegate,
    title: (l10n, activity) =>
        'Task(${_stringArg(activity, 'agentDefinitionId') ?? '?'})',
    argumentBody: (activity) {
      final prompt = _stringArg(activity, 'prompt');
      return prompt == null || prompt.isEmpty
          ? const ChatToolEmptyBody()
          : ChatToolTextBody(prompt);
    },
    result: (l10n, activity, output) {
      if (output is! ChatToolJsonObject) return _genericResult(l10n, output);
      final status = output.value['status'];
      final finalText = output.value['finalText'];
      if (status is! String) return _genericResult(l10n, output);
      if (finalText is! String || finalText.isEmpty) return status;
      return '$status · ${_truncate(_firstLine(finalText), 80)}';
    },
    body: (activity, output) {
      if (output is ChatToolJsonObject && output.value['finalText'] is String) {
        return ChatToolTextBody(output.value['finalText']! as String);
      }
      return _plainBody(activity, output);
    },
  ),
};

final _ToolSpec _genericSpec = _ToolSpec(
  glyph: ChatToolGlyph.generic,
  argumentBody: _prettyArgumentBody,
  title: (l10n, activity) {
    final scalar = activity.arguments.values
        .where((value) => value is String || value is num || value is bool)
        .map((value) => '$value')
        .firstOrNull;
    if (scalar == null) return '${activity.toolName}()';
    return '${activity.toolName}(${_truncate(_firstLine(scalar), 40)})';
  },
  result: (l10n, activity, output) => _genericResult(l10n, output),
);

String _genericResult(AppLocalizations l10n, ChatToolOutput output) {
  final text = _asText(output);
  final line = text
      .split('\n')
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .firstOrNull;
  if (line == null || line.isEmpty) return l10n.commonDone;
  return _truncate(line, 80);
}

String _asText(ChatToolOutput output) => switch (output) {
  ChatToolPlainText(:final value) => value,
  ChatToolJsonObject(:final value) => _pretty(value),
  ChatToolJsonArray(:final value) => _pretty(value),
};

String _pretty(Object value) =>
    const JsonEncoder.withIndent('  ').convert(value);

String? _stringArg(ChatToolActivity activity, String key) {
  final value = activity.arguments[key];
  return value is String ? value : null;
}

int _countLines(String text) {
  final normalized = text.endsWith('\n')
      ? text.substring(0, text.length - 1)
      : text;
  if (normalized.isEmpty) return 0;
  return normalized.split('\n').length;
}

String _firstLine(String text) {
  final line = text.split('\n').firstOrNull ?? '';
  return line.trim();
}

String _truncate(String text, int max) =>
    text.length <= max ? text : '${text.substring(0, max - 1)}…';
