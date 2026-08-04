import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:coder_app/src/chat/chat_markdown.dart';
import 'package:coder_app/src/chat/chat_theme.dart';
import 'package:coder_app/src/chat/chat_timeline_model.dart';
import 'package:coder_app/src/coder_icons.dart';
import 'package:coder_app/src/external_url_opener.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Renders a plan the agent proposed in plan mode.
class ChatPlanCard extends ConsumerWidget {
  /// Creates a plan card.
  const ChatPlanCard({required this.proposal, super.key});

  /// The proposed plan.
  final ChatPlanProposal proposal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(color: theme.colorScheme.primary, width: 3),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    CoderIcons.plan,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context).chatPlanTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              MarkdownBody(
                data: proposal.markdown,
                selectable: true,
                styleSheet: chatMarkdownStyleSheet(context),
                onTapLink: (text, href, title) =>
                    openChatLink(ref.read(externalUrlOpenerProvider), href),
              ),
              if (!proposal.isComplete)
                Text(
                  '▌',
                  style: chatMonospaceStyle(
                    context,
                    color: theme.colorScheme.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
