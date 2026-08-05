import 'dart:async';
import 'dart:convert';

import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:coder_app/src/chat/chat_code_block.dart';
import 'package:coder_app/src/chat/chat_diff.dart';
import 'package:coder_app/src/chat/chat_diff_view.dart';
import 'package:coder_app/src/controller.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// Renders an actionable tool approval request.
class ApprovalCard extends ConsumerWidget {
  /// Creates an [ApprovalCard].
  const ApprovalCard({required this.hostId, required this.approval, super.key});

  /// Stable host profile containing the approval's agent.
  final String hostId;

  /// The pending approval rendered by this card.
  final ApprovalRequestDto approval;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: TRCard(
        padding: TRCardPadding.none,
        variant: TRCardVariant.elevated,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                l10n.chatApprovalRequired(approval.toolName),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              _preview(),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  TRButton(
                    appearance: TRAppearance.ghost,
                    onPressed: () => _resolve(ref, approved: false),
                    child: Text(l10n.chatApprovalDeny),
                  ),
                  const SizedBox(width: 8),
                  TRButton(
                    intent: TRIntent.primary,
                    onPressed: () => _resolve(ref, approved: true),
                    child: Text(l10n.chatApprovalAllow),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _preview() {
    final preview = approval.preview;
    if (preview == null || preview.isEmpty) {
      return ChatCodeBlock(
        text: const JsonEncoder.withIndent('  ').convert(approval.arguments),
        maxLines: 12,
      );
    }
    if (approval.toolName == 'apply_patch') {
      return ChatDiffView(files: parseChatDiff(preview), maxLines: 24);
    }
    return ChatCodeBlock(text: preview, maxLines: 12);
  }

  void _resolve(WidgetRef ref, {required bool approved}) => unawaited(
    ref
        .read(
          conversationControllerProvider(hostId, approval.sessionId).notifier,
        )
        .resolveApproval(approval.id, approved: approved),
  );
}
