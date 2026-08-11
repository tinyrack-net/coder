import 'package:app/src/features/conversation/application/chat_timeline_model.dart';
import 'package:app/src/features/conversation/presentation/tools/presenter.dart';

/// How the collaboration tools appear in the chat timeline.
final Map<String, ChatToolPresenter>
collaborationPresenters = <String, ChatToolPresenter>{
  'spawn_agent': ChatToolPresenter(
    glyph: ChatToolGlyph.delegate,
    title: (l10n, activity) =>
        l10n.toolTitleSpawn(stringToolArg(activity, 'task_name') ?? '?'),
    argumentBody: _messageArgumentBody,
    result: (l10n, activity, output) {
      if (output is! ChatToolJsonObject) return genericToolResult(l10n, output);
      final error = output.value['error'];
      if (error is String) return error;
      final path = output.value['task_name'];
      return path is String ? path : genericToolResult(l10n, output);
    },
  ),
  'send_message': ChatToolPresenter(
    glyph: ChatToolGlyph.delegate,
    title: (l10n, activity) =>
        l10n.toolTitleSend(stringToolArg(activity, 'target') ?? '?'),
    argumentBody: _messageArgumentBody,
    result: (l10n, activity, output) => l10n.chatToolSubagentQueued,
  ),
  'followup_task': ChatToolPresenter(
    glyph: ChatToolGlyph.delegate,
    title: (l10n, activity) =>
        l10n.toolTitleFollowup(stringToolArg(activity, 'target') ?? '?'),
    argumentBody: _messageArgumentBody,
    result: (l10n, activity, output) {
      if (output is! ChatToolJsonObject) return genericToolResult(l10n, output);
      final error = output.value['error'];
      if (error is String) return error;
      final delivery = output.value['delivery'];
      return delivery is String ? delivery : genericToolResult(l10n, output);
    },
  ),
  'wait_agent': ChatToolPresenter(
    glyph: ChatToolGlyph.delegate,
    title: (l10n, activity) => l10n.toolTitleWait,
    result: (l10n, activity, output) {
      if (output is! ChatToolJsonObject) return genericToolResult(l10n, output);
      final error = output.value['error'];
      if (error is String) return error;
      final message = output.value['message'];
      return message is String ? message : genericToolResult(l10n, output);
    },
  ),
  'interrupt_agent': ChatToolPresenter(
    glyph: ChatToolGlyph.delegate,
    title: (l10n, activity) =>
        l10n.toolTitleInterrupt(stringToolArg(activity, 'target') ?? '?'),
    result: (l10n, activity, output) {
      if (output is! ChatToolJsonObject) return genericToolResult(l10n, output);
      final error = output.value['error'];
      if (error is String) return error;
      final previous = output.value['previous_status'];
      return previous is String ? previous : genericToolResult(l10n, output);
    },
  ),
  'list_agents': ChatToolPresenter(
    glyph: ChatToolGlyph.delegate,
    title: (l10n, activity) => l10n.toolTitleAgents,
    result: (l10n, activity, output) {
      if (output is! ChatToolJsonObject) return genericToolResult(l10n, output);
      final error = output.value['error'];
      if (error is String) return error;
      final agents = output.value['agents'];
      if (agents is! List) return genericToolResult(l10n, output);
      return l10n.chatToolSubagentCount(agents.length);
    },
  ),
};

/// Shows a `message` argument as the expanded request body.
ChatToolBody _messageArgumentBody(ChatToolActivity activity) {
  final message = stringToolArg(activity, 'message');
  return message == null || message.isEmpty
      ? const ChatToolEmptyBody()
      : ChatToolTextBody(message);
}
