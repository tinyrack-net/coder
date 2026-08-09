import 'package:app/src/features/conversation/application/chat_diff.dart';
import 'package:app/src/features/conversation/presentation/chat_diff_view.dart';
import 'package:app/src/features/conversation/presentation/tools/presenter.dart';
import 'package:flutter/widgets.dart';

/// How `apply_patch` appears in the chat timeline.
final Map<String, ChatToolPresenter> applyPatchPresenters =
    <String, ChatToolPresenter>{
      'apply_patch': ChatToolPresenter(
        approvalBody: _patchApprovalBody,
        glyph: ChatToolGlyph.edit,
        title: (l10n, activity) {
          final files = parseChatDiff(stringToolArg(activity, 'patch') ?? '');
          final named = files
              .where((file) => file.path.isNotEmpty)
              .toList(growable: false);
          if (named.isEmpty) return 'Edit';
          if (named.length == 1) return 'Edit(${named.single.path})';
          return l10n.toolEditFiles(named.length);
        },
        result: (l10n, activity, output) {
          final files = parseChatDiff(stringToolArg(activity, 'patch') ?? '');
          final added = files.fold<int>(0, (sum, file) => sum + file.added);
          final removed = files.fold<int>(0, (sum, file) => sum + file.removed);
          final changed = output is ChatToolJsonObject
              ? output.value['changedFiles']
              : null;
          final count = changed is int ? changed : files.length;
          return l10n.toolPatchSummary(added, removed, count);
        },
        argumentBody: (activity) => ChatToolDiffBody(
          parseChatDiff(stringToolArg(activity, 'patch') ?? ''),
        ),
        body: (activity, output) => const ChatToolEmptyBody(),
      ),
    };

/// Shows the patch as a colored diff while the user decides on it.
Widget _patchApprovalBody(BuildContext context, String preview) =>
    ChatDiffView(files: parseChatDiff(preview), maxLines: 24);
