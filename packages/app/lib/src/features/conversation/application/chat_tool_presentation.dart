import 'package:app/l10n/gen/app_localizations.dart';
import 'package:app/src/features/conversation/application/chat_timeline_model.dart';
import 'package:app/src/features/conversation/presentation/tools/apply_patch.dart';
import 'package:app/src/features/conversation/presentation/tools/ask_user.dart';
import 'package:app/src/features/conversation/presentation/tools/attach_file.dart';
import 'package:app/src/features/conversation/presentation/tools/clock.dart';
import 'package:app/src/features/conversation/presentation/tools/collaboration.dart';
import 'package:app/src/features/conversation/presentation/tools/context_window.dart';
import 'package:app/src/features/conversation/presentation/tools/exec.dart';
import 'package:app/src/features/conversation/presentation/tools/glob.dart';
import 'package:app/src/features/conversation/presentation/tools/list_directory.dart';
import 'package:app/src/features/conversation/presentation/tools/mcp_resources.dart';
import 'package:app/src/features/conversation/presentation/tools/presenter.dart';
import 'package:app/src/features/conversation/presentation/tools/read_attachment.dart';
import 'package:app/src/features/conversation/presentation/tools/read_file.dart';
import 'package:app/src/features/conversation/presentation/tools/search_text.dart';
import 'package:app/src/features/conversation/presentation/tools/skills.dart';
import 'package:app/src/features/conversation/presentation/tools/tool_search.dart';
import 'package:app/src/features/conversation/presentation/tools/update_plan.dart';
import 'package:app/src/features/conversation/presentation/tools/view_image.dart';

export 'package:app/src/features/conversation/presentation/tools/presenter.dart';

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

/// Every tool this app knows how to draw, keyed by the name the model calls.
///
/// Assembled from one file per capability rather than written out here, so a
/// new tool is a new file and one entry in this list.
final Map<String, ChatToolPresenter> chatToolPresenters =
    <String, ChatToolPresenter>{
      ...applyPatchPresenters,
      ...askUserPresenters,
      ...attachFilePresenters,
      ...clockPresenters,
      ...collaborationPresenters,
      ...contextWindowPresenters,
      ...execPresenters,
      ...globPresenters,
      ...listDirectoryPresenters,
      ...mcpResourcesPresenters,
      ...readAttachmentPresenters,
      ...readFilePresenters,
      ...searchTextPresenters,
      ...skillsPresenters,
      ...toolSearchPresenters,
      ...updatePlanPresenters,
      ...viewImagePresenters,
    };

/// The presenter for [toolName], falling back when nothing claims it.
ChatToolPresenter presenterFor(String toolName) =>
    chatToolPresenters[toolName] ??
    // MCP tool names are `mcp__server__tool`, made up at runtime, so they
    // cannot sit in a fixed map the way the built-ins do.
    (toolName.startsWith('mcp__') ? mcpToolPresenter : genericToolPresenter);

/// Describes one tool activity for the chat timeline.
ChatToolPresentation describeToolActivity(
  AppLocalizations l10n,
  ChatToolActivity activity,
) {
  final spec = presenterFor(activity.toolName);
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
        resultLine: truncateToolText(
          firstToolLine(activity.error ?? l10n.toolFailed),
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
