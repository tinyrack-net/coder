import 'package:app/l10n/gen/app_localizations.dart';
import 'package:app/src/features/conversation/application/subagent_track_model.dart';
import 'package:app/src/features/conversation/presentation/subagents/subagent_status_icon.dart';
import 'package:app/src/shared/presentation/coder_list_row.dart';
import 'package:flutter/material.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// The collapsible subagent drawer docked on top of the chat composer.
///
/// Collapsed by default, its header summarizes how many subagents exist and
/// how many are running; expanding it lists every descendant of the current
/// session, and tapping a row opens that subagent's read-only tab.
class SubagentTrack extends StatefulWidget {
  /// Creates a subagent track.
  const SubagentTrack({
    required this.rows,
    required this.maxListHeight,
    required this.onOpenSubagent,
    this.initiallyOpen = false,
    super.key,
  });

  /// Depth-first descendants of the current session.
  final List<SubagentTrackRow> rows;

  /// Viewport-derived bound for the expanded list.
  final double maxListHeight;

  /// Opens one subagent session as a tab.
  final ValueChanged<String> onOpenSubagent;

  /// Whether the drawer starts expanded; collapsed by default.
  final bool initiallyOpen;

  @override
  State<SubagentTrack> createState() => _SubagentTrackState();
}

class _SubagentTrackState extends State<SubagentTrack> {
  late bool _open = widget.initiallyOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final running = runningSubagentCount(widget.rows);
    return TRCollapsible(
      key: const ValueKey('subagent-track'),
      attachedEdge: TRCollapsibleAttachedEdge.bottom,
      open: _open,
      onOpenChange: (next) => setState(() => _open = next),
      trigger: Row(
        children: <Widget>[
          Expanded(
            child: TRText.inherit(
              l10n.subagentTrackHeader(widget.rows.length),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (running > 0) ...<Widget>[
            const SizedBox(width: TRSpacing.small),
            TRBadge(
              variant: TRStatusVariant.info,
              child: TRText.inherit(l10n.subagentTrackRunning(running)),
            ),
          ],
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: widget.maxListHeight),
        child: TRScrollArea(
          semanticLabel: l10n.subagentTrackHeader(widget.rows.length),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (final row in widget.rows)
                CoderListRow(
                  key: ValueKey('subagent-row-${row.session.id}'),
                  dense: true,
                  onTap: () => widget.onOpenSubagent(row.session.id),
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      // Nested subagents indent by one spacing step per
                      // tree level.
                      SizedBox(width: TRSpacing.medium * row.depth),
                      SubagentStatusIcon(
                        lifecycle: row.session.lifecycle,
                        status: row.session.status,
                      ),
                    ],
                  ),
                  title: TRText.inherit(
                    row.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: TRText.inherit(
                    row.session.agentPath ?? row.session.agentDefinitionId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
