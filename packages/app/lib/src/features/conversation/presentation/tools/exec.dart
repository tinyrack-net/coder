import 'package:app/l10n/gen/app_localizations.dart';
import 'package:app/src/features/conversation/application/chat_timeline_model.dart';
import 'package:app/src/features/conversation/presentation/tools/presenter.dart';

/// How the shell tools appear in the chat timeline.
final Map<String, ChatToolPresenter>
execPresenters = <String, ChatToolPresenter>{
  'exec_command': ChatToolPresenter(
    glyph: ChatToolGlyph.run,
    title: (l10n, activity) {
      final command = stringToolArg(activity, 'command') ?? '';
      return 'Bash(${truncateToolText(firstToolLine(command), 60)})';
    },
    result: _execResult,
    body: _execBody,
    argumentBody: (activity) {
      final command = stringToolArg(activity, 'command');
      if (command == null || command.isEmpty) return const ChatToolEmptyBody();
      // The directory changes what the command does, so it is shown whenever
      // it is not simply the workspace root.
      final workdir = stringToolArg(activity, 'workdir');
      return ChatToolTextBody(
        workdir == null || workdir.isEmpty
            ? '\$ $command'
            : '$workdir\n\$ $command',
      );
    },
    isFailure: _execIsFailure,
  ),
  'write_stdin': ChatToolPresenter(
    glyph: ChatToolGlyph.run,
    title: (l10n, activity) {
      final chars = stringToolArg(activity, 'chars') ?? '';
      final session = stringToolArg(activity, 'session_id') ?? '?';
      return chars.isEmpty
          ? 'Stdin($session)'
          : 'Stdin($session ← ${truncateToolText(firstToolLine(chars), 40)})';
    },
    result: _execResult,
    body: _execBody,
    argumentBody: (activity) {
      final chars = stringToolArg(activity, 'chars');
      return chars == null || chars.isEmpty
          ? const ChatToolEmptyBody()
          : ChatToolTextBody(chars);
    },
    isFailure: _execIsFailure,
  ),
};

/// Summarizes a pseudo-terminal chunk from `exec_command` or `write_stdin`.
String _execResult(
  AppLocalizations l10n,
  ChatToolActivity activity,
  ChatToolOutput output,
) {
  if (output is! ChatToolJsonObject) return genericToolResult(l10n, output);
  final error = output.value['error'];
  if (error is String) return error;
  final text = output.value['output'];
  final lines = text is String && text.isNotEmpty ? countToolLines(text) : 0;
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
  return plainToolBody(activity, output);
}

bool _execIsFailure(ChatToolOutput output) =>
    output is ChatToolJsonObject &&
    (output.value['error'] != null ||
        (output.value['exitCode'] is int && output.value['exitCode'] != 0));
