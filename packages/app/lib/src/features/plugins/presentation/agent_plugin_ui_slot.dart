import 'dart:async';

import 'package:app/l10n/gen/app_localizations.dart';
import 'package:app/src/app/app_identity.dart';
import 'package:app/src/features/plugins/application/plugin_settings_controller.dart';
import 'package:app/src/features/plugins/presentation/plugin_ui_document_view.dart';
import 'package:app/src/shared/presentation/client_error_alert.dart';
import 'package:client/client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:protocol/protocol.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// Renders every declarative UI contribution owned by an Agent in one slot.
///
/// Contribution order follows the Agent harness: driver, ordered extensions,
/// tools, and finally plugins referenced only by settings. The host owns the
/// loading/error boundary and all native widgets; plugins only provide data.
class AgentPluginUiSlot extends ConsumerWidget {
  /// Creates an Agent-scoped plugin surface.
  const AgentPluginUiSlot({
    required this.hostId,
    required this.agent,
    required this.slot,
    this.context = const <String, dynamic>{},
    super.key,
  });

  /// Daemon that owns the Agent and plugin catalog.
  final String hostId;

  /// Agent harness whose explicit references activate plugins.
  final AgentDefinitionDto agent;

  /// Host-owned native surface being rendered.
  final PluginUiSlot slot;

  /// Immutable session/workspace data offered to render handlers.
  final Map<String, dynamic> context;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(pluginSettingsControllerProvider(hostId));
    return state.when(
      skipLoadingOnRefresh: true,
      data: (catalog) {
        final pluginsById = <String, PluginDescriptorDto>{
          for (final plugin in catalog.plugins) plugin.id: plugin,
        };
        final contributions =
            <
              ({
                PluginDescriptorDto plugin,
                PluginContributionDto contribution,
              })
            >[];
        for (final pluginId in _orderedPluginIds(agent)) {
          final plugin = pluginsById[pluginId];
          if (plugin == null) continue;
          for (final contribution in plugin.contributions) {
            if (contribution.kind == PluginContributionKind.ui &&
                _slots(contribution).contains(slot.name)) {
              contributions.add((plugin: plugin, contribution: contribution));
            }
          }
        }
        if (contributions.isEmpty) return const SizedBox.shrink();
        return Column(
          key: ValueKey<String>('agent-plugin-ui-${slot.name}'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (final (index, entry) in contributions.indexed) ...<Widget>[
              if (index > 0) const SizedBox(height: TRSpacing.small),
              PluginUiContributionSurface(
                key: ValueKey<String>(
                  'agent-plugin-ui-${slot.name}-${entry.contribution.id}',
                ),
                hostId: hostId,
                agentId: agent.id,
                plugin: entry.plugin,
                contribution: entry.contribution,
                slot: slot,
                context: this.context,
              ),
            ],
          ],
        );
      },
      loading: () => TRProgress(label: l10n.pluginUiLoading),
      error: (error, _) => ClientErrorAlert(
        error: _clientError(error),
        title: l10n.pluginUiLoadFailed,
      ),
    );
  }
}

/// Presents any slot failure as the daemon failure the alert knows how to read.
///
/// A daemon failure already carries the code and trace id [ClientErrorAlert]
/// translates. Anything else came from this app, so it is wrapped without a
/// code, which makes the alert fall back to the original text rather than
/// claiming a daemon fault the daemon never reported.
TinestClientException _clientError(Object error) =>
    error is TinestClientException
    ? error
    : TinestClientException(error is Error ? '$error' : error.toString());

/// Loads and renders one declared UI contribution through the public RPC.
class PluginUiContributionSurface extends ConsumerStatefulWidget {
  /// Creates one pinned plugin UI contribution surface.
  const PluginUiContributionSurface({
    required this.hostId,
    required this.agentId,
    required this.plugin,
    required this.contribution,
    required this.slot,
    this.context = const <String, dynamic>{},
    super.key,
  });

  /// Daemon profile owning the plugin runtime.
  final String hostId;

  /// Agent whose grants and harness scope the contribution.
  final String agentId;

  /// Plugin descriptor containing [contribution].
  final PluginDescriptorDto plugin;

  /// Exact UI contribution to invoke.
  final PluginContributionDto contribution;

  /// Host-owned surface requested from the contribution.
  final PluginUiSlot slot;

  /// Immutable render context supplied by the host.
  final Map<String, dynamic> context;

  @override
  ConsumerState<PluginUiContributionSurface> createState() =>
      _PluginUiContributionSurfaceState();
}

class _PluginUiContributionSurfaceState
    extends ConsumerState<PluginUiContributionSurface> {
  PluginUiDocumentDto? _document;
  Object? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(PluginUiContributionSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hostId != widget.hostId ||
        oldWidget.agentId != widget.agentId ||
        oldWidget.plugin.revision?.contentHash !=
            widget.plugin.revision?.contentHash ||
        oldWidget.contribution != widget.contribution ||
        oldWidget.slot != widget.slot ||
        !mapEquals(oldWidget.context, widget.context)) {
      unawaited(_load());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final document = _document;
    if (_error case final error?) {
      return ClientErrorAlert(
        error: _clientError(error),
        title: l10n.pluginUiLoadFailed,
        onRetry: () => unawaited(_load()),
      );
    }
    if (document == null) return TRProgress(label: l10n.pluginUiLoading);
    return PluginUiDocumentView(
      document: document,
      semanticLabel: l10n.pluginUiSemanticLabel(widget.plugin.name),
      invalidDocumentLabel: l10n.pluginUiInvalidTitle,
      invalidDocumentDescription: l10n.pluginUiInvalidDescription(
        AppIdentity.displayName,
      ),
      onAction: _dispatch,
    );
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _document = null;
        _error = null;
      });
    }
    try {
      final document = await ref
          .read(pluginSettingsControllerProvider(widget.hostId).notifier)
          .renderUi(
            agentId: widget.agentId,
            pluginId: widget.plugin.id,
            contributionId: widget.contribution.id,
            slot: widget.slot,
            context: widget.context,
          );
      if (mounted) setState(() => _document = document);
    } on Object catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  Future<PluginUiDocumentDto> _dispatch(PluginUiActionDto action) async {
    try {
      final document = await ref
          .read(pluginSettingsControllerProvider(widget.hostId).notifier)
          .dispatchUi(
            agentId: widget.agentId,
            pluginId: widget.plugin.id,
            action: action,
          );
      if (mounted) setState(() => _document = document);
      return document;
    } on Object catch (error) {
      if (mounted) setState(() => _error = error);
      return _document!;
    }
  }
}

List<String> _orderedPluginIds(AgentDefinitionDto agent) {
  final ordered = <String>[];
  final seen = <String>{};
  void add(String contributionId) {
    final id = pluginIdForContribution(contributionId);
    if (id.isNotEmpty && seen.add(id)) ordered.add(id);
  }

  add(agent.driverId);
  agent.extensionIds.forEach(add);
  agent.toolIds.forEach(add);
  agent.pluginSettings.keys.forEach(add);
  return ordered;
}

Set<String> _slots(PluginContributionDto contribution) {
  final value = contribution.metadata['slots'];
  return value is List<Object?>
      ? value.whereType<String>().toSet()
      : const <String>{};
}
