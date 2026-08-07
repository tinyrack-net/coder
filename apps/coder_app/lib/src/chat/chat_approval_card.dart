import 'dart:async';
import 'dart:convert';

import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:coder_app/src/chat/chat_code_block.dart';
import 'package:coder_app/src/chat/chat_tool_presentation.dart';
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
      padding: const EdgeInsets.fromLTRB(
        TRSpacing.large,
        TRSpacing.small,
        TRSpacing.large,
        0,
      ),
      child: TRCard(
        padding: TRCardPadding.none,
        variant: TRCardVariant.elevated,
        child: Padding(
          padding: const EdgeInsets.all(TRSpacing.medium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TRText(
                l10n.chatApprovalRequired(approval.toolName),
                variant: TRTextVariant.headingSm,
              ),
              const SizedBox(height: TRSpacing.small),
              _preview(context),
              const SizedBox(height: TRSpacing.small),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  TRButton(
                    appearance: TRAppearance.ghost,
                    onPressed: () => _resolve(ref, approved: false),
                    child: TRText.inherit(l10n.chatApprovalDeny),
                  ),
                  const SizedBox(width: TRSpacing.small),
                  TRButton(
                    intent: TRIntent.primary,
                    onPressed: () => _resolve(ref, approved: true),
                    child: TRText.inherit(l10n.chatApprovalAllow),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _preview(BuildContext context) {
    final preview = approval.preview;
    if (preview == null || preview.isEmpty) {
      return ChatCodeBlock(
        text: const JsonEncoder.withIndent('  ').convert(approval.arguments),
        maxLines: 12,
      );
    }
    // A tool that has a richer preview than its own arguments supplies it;
    // everything else reads as the text the daemon sent.
    final body = presenterFor(approval.toolName).approvalBody;
    return body == null
        ? ChatCodeBlock(text: preview, maxLines: 12)
        : body(context, preview);
  }

  void _resolve(WidgetRef ref, {required bool approved}) => unawaited(
    ref
        .read(
          conversationControllerProvider(hostId, approval.sessionId).notifier,
        )
        .resolveApproval(approval.id, approved: approved),
  );
}
