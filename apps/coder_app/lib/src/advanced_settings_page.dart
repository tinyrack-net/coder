import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:coder_app/src/app.dart';
import 'package:coder_app/src/coder_icons.dart';
import 'package:coder_app/src/coder_page_shell.dart';
import 'package:coder_app/src/controller.dart';
import 'package:coder_app/src/desktop_shell.dart';
import 'package:coder_app/src/host_models.dart';
import 'package:coder_app/src/settings/settings_layout.dart';
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
    const body = SettingsScaffold(children: <Widget>[_ResetSection()]);
    if (embedded) return body;
    return CoderPageShell(
      appBar: CoderPageHeader(
        title: TRText.inherit(l10n.settingsCategoryAdvanced),
      ),
      body: body,
    );
  }
}

class _ResetSection extends ConsumerStatefulWidget {
  const _ResetSection();

  @override
  ConsumerState<_ResetSection> createState() => _ResetSectionState();
}

class _ResetSectionState extends ConsumerState<_ResetSection> {
  bool _busy = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final erasesDaemonData = ref
        .watch(appServicesProvider)
        .erasesEmbeddedDaemonData;
    final error = _error;
    return SettingsSection(
      title: l10n.advancedResetSection,
      banner: error == null
          ? null
          : TRAlert(
              key: const ValueKey<String>('advanced-settings-reset-error'),
              title: TRText.inherit(l10n.advancedResetFailedTitle),
              description: TRText.inherit(error),
              icon: const Icon(CoderIcons.error),
              variant: TRStatusVariant.danger,
            ),
      children: <Widget>[
        SettingsRow(
          title: TRText.inherit(l10n.advancedResetTitle),
          description: TRText.inherit(
            erasesDaemonData
                ? l10n.advancedResetDescription
                : l10n.advancedResetDescriptionAppOnly,
          ),
          unboundedDescription: true,
          control: TRButton(
            key: const ValueKey<String>('advanced-settings-reset-button'),
            appearance: TRAppearance.outline,
            onPressed: _busy ? null : _confirmAndReset,
            child: TRText.inherit(
              _busy ? l10n.advancedResetRunning : l10n.advancedResetAction,
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
          title: TRText.inherit(l10n.advancedResetConfirmTitle),
          content: TRText.inherit(l10n.advancedResetConfirmBody),
          actions: <TRButton>[
            TRButton(
              key: const ValueKey<String>('advanced-reset-confirm-cancel'),
              appearance: TRAppearance.ghost,
              onPressed: () => Navigator.pop(context, false),
              child: TRText.inherit(l10n.commonCancel),
            ),
            TRButton(
              key: const ValueKey<String>('advanced-reset-confirm-accept'),
              intent: TRIntent.primary,
              onPressed: () => Navigator.pop(context, true),
              child: TRText.inherit(l10n.advancedResetConfirmAccept),
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
