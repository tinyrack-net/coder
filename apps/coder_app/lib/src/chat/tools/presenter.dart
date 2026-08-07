import 'dart:convert';

import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:coder_app/src/chat/chat_diff.dart';
import 'package:coder_app/src/chat/chat_timeline_model.dart';
import 'package:flutter/widgets.dart';

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

/// Everything the UI needs to draw one tool activity, from data only.
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

/// How one tool's activity appears in the timeline.
enum ChatToolTimeline {
  /// A collapsed tool row, like most tools.
  row,

  /// Nothing: the activity already renders as its own item, so a row beside
  /// it would only repeat what the reader can already see.
  suppressed,

  /// A card of its own, built by the timeline from this tool's arguments.
  card,
}

/// Everything the UI knows about how to draw one tool.
///
/// A tool's glyph, title, result line, expanded bodies, timeline placement,
/// and approval preview all live here, so adding a tool to the UI is adding
/// one file rather than editing a shared table in six places.
final class ChatToolPresenter {
  /// Creates a presenter for one tool.
  const ChatToolPresenter({
    required this.glyph,
    required this.title,
    required this.result,
    this.body = plainToolBody,
    this.argumentBody = noToolArgumentBody,
    this.isFailure = toolNeverFails,
    this.timeline = ChatToolTimeline.row,
    this.approvalBody,
  });

  /// Icon family for the collapsed row.
  final ChatToolGlyph glyph;

  /// Builds the CLI-style title line.
  final String Function(AppLocalizations l10n, ChatToolActivity activity) title;

  /// Builds the short result summary.
  final String Function(
    AppLocalizations l10n,
    ChatToolActivity activity,
    ChatToolOutput output,
  )
  result;

  /// Builds the expanded result content.
  final ChatToolBody Function(ChatToolActivity activity, ChatToolOutput output)
  body;

  /// Builds the expanded request content shown above the result.
  final ChatToolBody Function(ChatToolActivity activity) argumentBody;

  /// Reads a tool-specific failure out of an otherwise successful result.
  final bool Function(ChatToolOutput output) isFailure;

  /// Where this tool's activity belongs in the timeline.
  final ChatToolTimeline timeline;

  /// Builds the preview shown while the user decides on an approval.
  ///
  /// Null leaves the approval card with its plain argument summary, which is
  /// what a tool without a richer preview than its own arguments wants.
  final Widget Function(BuildContext context, String argumentsJson)?
  approvalBody;
}

/// Renders whatever a tool returned, pretty-printing structured output.
ChatToolBody plainToolBody(ChatToolActivity activity, ChatToolOutput output) =>
    switch (output) {
      ChatToolPlainText(:final value) =>
        value.isEmpty ? const ChatToolEmptyBody() : ChatToolTextBody(value),
      ChatToolJsonObject(:final value) => ChatToolTextBody(prettyJson(value)),
      ChatToolJsonArray(:final value) => ChatToolTextBody(prettyJson(value)),
    };

/// Built-in tools already carry their arguments in the title, so the expanded
/// view stays free of an argument dump.
ChatToolBody noToolArgumentBody(ChatToolActivity activity) =>
    const ChatToolEmptyBody();

/// Dumps a tool call's arguments, for tools whose title omits them.
ChatToolBody prettyToolArgumentBody(ChatToolActivity activity) =>
    activity.arguments.isEmpty
    ? const ChatToolEmptyBody()
    : ChatToolTextBody(prettyJson(activity.arguments));

/// For a tool whose success is never hidden inside a successful result.
bool toolNeverFails(ChatToolOutput output) => false;

/// Reads the `error` key tools use to report a recoverable failure.
bool toolHasErrorKey(ChatToolOutput output) =>
    output is ChatToolJsonObject && output.value['error'] != null;

/// Summarizes any result as its first non-empty line.
String genericToolResult(AppLocalizations l10n, ChatToolOutput output) {
  final text = toolOutputText(output);
  final line = text
      .split('\n')
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .firstOrNull;
  if (line == null || line.isEmpty) return l10n.commonDone;
  return truncateToolText(line, 80);
}

/// Flattens decoded output back to text.
String toolOutputText(ChatToolOutput output) => switch (output) {
  ChatToolPlainText(:final value) => value,
  ChatToolJsonObject(:final value) => prettyJson(value),
  ChatToolJsonArray(:final value) => prettyJson(value),
};

/// Indents a decoded JSON value for the expanded view.
String prettyJson(Object value) =>
    const JsonEncoder.withIndent('  ').convert(value);

/// Reads one string argument, or null when it is absent or another type.
String? stringToolArg(ChatToolActivity activity, String key) {
  final value = activity.arguments[key];
  return value is String ? value : null;
}

/// Counts lines, ignoring a single trailing newline.
int countToolLines(String text) {
  final normalized = text.endsWith('\n')
      ? text.substring(0, text.length - 1)
      : text;
  if (normalized.isEmpty) return 0;
  return normalized.split('\n').length;
}

/// The first line of [text], trimmed.
String firstToolLine(String text) {
  final line = text.split('\n').firstOrNull ?? '';
  return line.trim();
}

/// Shortens [text] to [max] characters with an ellipsis.
String truncateToolText(String text, int max) =>
    text.length <= max ? text : '${text.substring(0, max - 1)}…';

/// How a tool an MCP server published appears.
///
/// Its name is `mcp__server__tool`, made up at runtime, so it cannot sit in
/// a fixed map the way the built-ins do.
final ChatToolPresenter mcpToolPresenter = ChatToolPresenter(
  glyph: ChatToolGlyph.generic,
  argumentBody: prettyToolArgumentBody,
  title: (l10n, activity) {
    final parts = activity.toolName.split('__');
    return parts.length >= 3
        ? '${parts[1]}.${parts.sublist(2).join('__')}'
        : activity.toolName;
  },
  result: (l10n, activity, output) {
    // A server may answer with structured data or with plain text, and the
    // error key is the one shape this side knows how to read.
    if (output is ChatToolJsonObject && output.value['error'] is String) {
      return output.value['error']! as String;
    }
    return genericToolResult(l10n, output);
  },
  isFailure: toolHasErrorKey,
);

/// How a tool nothing else claims appears.
final ChatToolPresenter genericToolPresenter = ChatToolPresenter(
  glyph: ChatToolGlyph.generic,
  argumentBody: prettyToolArgumentBody,
  title: (l10n, activity) {
    final scalar = activity.arguments.values
        .where((value) => value is String || value is num || value is bool)
        .map((value) => '$value')
        .firstOrNull;
    if (scalar == null) return '${activity.toolName}()';
    final summary = truncateToolText(firstToolLine(scalar), 40);
    return '${activity.toolName}($summary)';
  },
  result: (l10n, activity, output) => genericToolResult(l10n, output),
);
