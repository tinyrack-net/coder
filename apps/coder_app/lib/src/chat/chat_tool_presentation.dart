import 'dart:convert';

import 'package:coder_app/src/chat/chat_diff.dart';
import 'package:coder_app/src/chat/chat_timeline_model.dart';

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
ChatToolPresentation describeToolActivity(ChatToolActivity activity) {
  final spec = _specs[activity.toolName] ?? _genericSpec;
  final title = spec.title(activity);
  final argumentBody = spec.argumentBody(activity);
  switch (activity.status) {
    case ChatToolStatus.running:
      return ChatToolPresentation(
        glyph: spec.glyph,
        title: title,
        resultLine: '실행 중',
        body: const ChatToolEmptyBody(),
        argumentBody: argumentBody,
        isFailure: false,
      );
    case ChatToolStatus.denied:
      return ChatToolPresentation(
        glyph: spec.glyph,
        title: title,
        resultLine: '거부됨',
        body: const ChatToolEmptyBody(),
        argumentBody: argumentBody,
        isFailure: false,
      );
    case ChatToolStatus.failed:
      return ChatToolPresentation(
        glyph: spec.glyph,
        title: title,
        resultLine: _truncate(_firstLine(activity.error ?? '실패'), 120),
        body: ChatToolTextBody(activity.error ?? ''),
        argumentBody: argumentBody,
        isFailure: true,
      );
    case ChatToolStatus.succeeded:
      final output = decodeToolOutput(activity.output ?? '');
      return ChatToolPresentation(
        glyph: spec.glyph,
        title: title,
        resultLine: spec.result(activity, output),
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
  final String Function(ChatToolActivity activity) title;
  final String Function(ChatToolActivity activity, ChatToolOutput output)
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

final Map<String, _ToolSpec> _specs = <String, _ToolSpec>{
  'read_file': _ToolSpec(
    glyph: ChatToolGlyph.read,
    title: (activity) {
      final path = _stringArg(activity, 'path') ?? '?';
      final offset = activity.arguments['offset'];
      final limit = activity.arguments['limit'];
      if (offset == null && limit == null) return 'Read($path)';
      return 'Read($path @${offset ?? 0}+${limit ?? 0})';
    },
    result: (activity, output) {
      final text = _asText(output);
      if (text.isEmpty) return '빈 파일';
      return '${_countLines(text)}줄 읽음';
    },
  ),
  'list_directory': _ToolSpec(
    glyph: ChatToolGlyph.list,
    title: (activity) => 'List(${_stringArg(activity, 'path') ?? '.'})',
    result: (activity, output) {
      if (output is! ChatToolJsonArray) return _genericResult(output);
      final entries = output.value.whereType<Map<String, dynamic>>();
      if (entries.length != output.value.length) {
        return '항목 ${output.value.length}개';
      }
      final directories = entries
          .where((entry) => entry['type'] == 'directory')
          .length;
      return '디렉터리 $directories · 파일 ${entries.length - directories}';
    },
  ),
  'search_text': _ToolSpec(
    glyph: ChatToolGlyph.search,
    title: (activity) {
      final query = _truncate(_stringArg(activity, 'query') ?? '', 40);
      final path = _stringArg(activity, 'path');
      return path == null ? 'Search($query)' : 'Search($query in $path)';
    },
    result: (activity, output) {
      if (output is! ChatToolJsonArray) return _genericResult(output);
      if (output.value.isEmpty) return '일치 없음';
      final paths = output.value
          .whereType<Map<String, dynamic>>()
          .map((match) => match['path'])
          .whereType<String>()
          .toSet();
      return '${paths.length}개 파일에서 ${output.value.length}건';
    },
  ),
  'apply_patch': _ToolSpec(
    glyph: ChatToolGlyph.edit,
    title: (activity) {
      final files = parseChatDiff(_stringArg(activity, 'patch') ?? '');
      final named = files
          .where((file) => file.path.isNotEmpty)
          .toList(growable: false);
      if (named.isEmpty) return 'Edit';
      if (named.length == 1) return 'Edit(${named.single.path})';
      return 'Edit(${named.length}개 파일)';
    },
    result: (activity, output) {
      final files = parseChatDiff(_stringArg(activity, 'patch') ?? '');
      final added = files.fold<int>(0, (sum, file) => sum + file.added);
      final removed = files.fold<int>(0, (sum, file) => sum + file.removed);
      final changed = output is ChatToolJsonObject
          ? output.value['changedFiles']
          : null;
      final count = changed is int ? changed : files.length;
      return '+$added -$removed · $count개 파일';
    },
    argumentBody: (activity) =>
        ChatToolDiffBody(parseChatDiff(_stringArg(activity, 'patch') ?? '')),
    body: (activity, output) => const ChatToolEmptyBody(),
  ),
  'run_command': _ToolSpec(
    glyph: ChatToolGlyph.run,
    title: (activity) {
      final command = _stringArg(activity, 'command') ?? '';
      return 'Bash(${_truncate(_firstLine(command), 60)})';
    },
    result: (activity, output) {
      if (output is! ChatToolJsonObject) return _genericResult(output);
      final exitCode = output.value['exitCode'];
      final text = output.value['output'];
      if (exitCode is! int || text is! String) return _genericResult(output);
      return '종료 코드 $exitCode · ${text.isEmpty ? 0 : _countLines(text)}줄';
    },
    body: (activity, output) {
      if (output is ChatToolJsonObject && output.value['output'] is String) {
        final text = output.value['output']! as String;
        return text.isEmpty
            ? const ChatToolEmptyBody()
            : ChatToolTextBody(text);
      }
      return _plainBody(activity, output);
    },
    argumentBody: (activity) {
      final command = _stringArg(activity, 'command');
      return command == null || command.isEmpty
          ? const ChatToolEmptyBody()
          : ChatToolTextBody('\$ $command');
    },
    isFailure: (output) =>
        output is ChatToolJsonObject && output.value['exitCode'] != 0,
  ),
  'delegate_agent': _ToolSpec(
    glyph: ChatToolGlyph.delegate,
    title: (activity) =>
        'Task(${_stringArg(activity, 'agentDefinitionId') ?? '?'})',
    argumentBody: (activity) {
      final prompt = _stringArg(activity, 'prompt');
      return prompt == null || prompt.isEmpty
          ? const ChatToolEmptyBody()
          : ChatToolTextBody(prompt);
    },
    result: (activity, output) {
      if (output is! ChatToolJsonObject) return _genericResult(output);
      final status = output.value['status'];
      final finalText = output.value['finalText'];
      if (status is! String) return _genericResult(output);
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
  title: (activity) {
    final scalar = activity.arguments.values
        .where((value) => value is String || value is num || value is bool)
        .map((value) => '$value')
        .firstOrNull;
    if (scalar == null) return '${activity.toolName}()';
    return '${activity.toolName}(${_truncate(_firstLine(scalar), 40)})';
  },
  result: (activity, output) => _genericResult(output),
);

String _genericResult(ChatToolOutput output) {
  final text = _asText(output);
  final line = text
      .split('\n')
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .firstOrNull;
  if (line == null || line.isEmpty) return '완료';
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
