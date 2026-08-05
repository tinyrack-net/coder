import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:coder_app/src/app.dart';
import 'package:coder_app/src/coder_icons.dart';
import 'package:coder_app/src/coder_list_row.dart';
import 'package:coder_app/src/coder_page_shell.dart';
import 'package:coder_app/src/controller.dart';
import 'package:coder_app/src/desktop_shell.dart';
import 'package:coder_app/src/host_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// Developer maintenance actions that are not tied to any single daemon.
class AdvancedSettingsPage extends ConsumerWidget {
  /// Creates the advanced settings page.
  const AdvancedSettingsPage({this.embedded = false, super.key});

  /// Whether the unified settings shell supplies navigation chrome.
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final body = ListView(
      padding: const EdgeInsets.all(24),
      children: const <Widget>[_ResetCard()],
    );
    if (embedded) return body;
    return CoderPageShell(
      appBar: CoderPageHeader(title: Text(l10n.settingsCategoryAdvanced)),
      body: body,
    );
  }
}

class _ResetCard extends ConsumerStatefulWidget {
  const _ResetCard();

  @override
  ConsumerState<_ResetCard> createState() => _ResetCardState();
}

class _ResetCardState extends ConsumerState<_ResetCard> {
  bool _busy = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final erasesDaemonData = ref
        .watch(appServicesProvider)
        .erasesEmbeddedDaemonData;
    final error = _error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          l10n.advancedResetSection,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        if (error != null) ...<Widget>[
          TRAlert(
            key: const ValueKey<String>('advanced-settings-reset-error'),
            title: Text(l10n.advancedResetFailedTitle),
            description: Text(error),
            icon: const Icon(CoderIcons.error),
            variant: TRStatusVariant.danger,
          ),
          const SizedBox(height: TRSpacing.medium),
        ],
        TRCard(
          padding: TRCardPadding.none,
          child: CoderListRow(
            title: Text(l10n.advancedResetTitle),
            subtitle: Text(
              erasesDaemonData
                  ? l10n.advancedResetDescription
                  : l10n.advancedResetDescriptionAppOnly,
            ),
            isThreeLine: true,
            trailing: TRButton(
              key: const ValueKey<String>('advanced-settings-reset-button'),
              appearance: TRAppearance.outline,
              uiSize: TRUiSize.sm,
              onPressed: _busy ? null : _confirmAndReset,
              child: Text(
                _busy ? l10n.advancedResetRunning : l10n.advancedResetAction,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmAndReset() async {
    final confirmed = await showTRDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return TRAlertDialog(
          key: const ValueKey<String>('advanced-reset-confirm-dialog'),
          title: Text(l10n.advancedResetConfirmTitle),
          content: Text(l10n.advancedResetConfirmBody),
          actions: <TRButton>[
            TRButton(
              key: const ValueKey<String>('advanced-reset-confirm-cancel'),
              appearance: TRAppearance.ghost,
              uiSize: TRUiSize.sm,
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.commonCancel),
            ),
            TRButton(
              key: const ValueKey<String>('advanced-reset-confirm-accept'),
              intent: TRIntent.primary,
              uiSize: TRUiSize.sm,
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.advancedResetConfirmAccept),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    final autostart = ref.read(autostartProvider);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(hostRegistryControllerProvider.notifier)
          .resetToFactoryDefaults();
      if (!mounted) return;
      // The registry survives a reset; only the caches keyed off erased daemon
      // state are stale. Invalidating the registry itself would close the
      // daemon that was just started.
      ref
        ..invalidate(selectionRestoreControllerProvider)
        ..invalidate(workspaceCatalogControllerProvider)
        ..invalidate(sessionComposerDraftControllerProvider)
        ..invalidate(providerSettingsControllerProvider);
      // Restored defaults re-enable the login item, so the operating system
      // registration has to follow rather than silently disagree.
      final settings = ref
          .read(hostRegistryControllerProvider)
          .asData
          ?.value
          .settings;
      if (settings != null) {
        await autostart?.apply(
          enabled: settings.startAtBoot,
          minimized: settings.startMinimizedAtBoot,
        );
      }
      if (!mounted) return;
      const WorkspaceHomeRoute().go(context);
    } on FactoryResetFailure catch (failure) {
      if (!mounted) return;
      // Read after the await: a reset clears the language override, so the
      // localizations in scope before it may no longer be the active ones.
      final l10n = AppLocalizations.of(context);
      setState(() {
        _error = switch (failure.reason) {
          FactoryResetFailureReason.daemonStillRunning =>
            l10n.advancedResetFailedDaemonRunning,
          FactoryResetFailureReason.filesystem =>
            l10n.advancedResetFailedFilesystem(failure.message),
          FactoryResetFailureReason.incomplete =>
            l10n.advancedResetFailedIncomplete,
        };
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
