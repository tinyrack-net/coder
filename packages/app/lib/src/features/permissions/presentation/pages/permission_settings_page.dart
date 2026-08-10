import 'dart:async';

import 'package:app/l10n/gen/app_localizations.dart';
import 'package:app/src/features/permissions/application/permission_settings_controller.dart';
import 'package:app/src/shared/presentation/permission_picker.dart';
import 'package:app/src/shared/presentation/settings_layout.dart';
import 'package:app/src/shared/presentation/toast_messenger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:protocol/protocol.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// Daemon-global default permission settings.
class PermissionSettingsPage extends ConsumerStatefulWidget {
  /// Creates permission settings for [hostId].
  const PermissionSettingsPage({required this.hostId, super.key});

  /// Selected daemon host.
  final String hostId;

  @override
  ConsumerState<PermissionSettingsPage> createState() =>
      _PermissionSettingsPageState();
}

class _PermissionSettingsPageState
    extends ConsumerState<PermissionSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      permissionSettingsControllerProvider(widget.hostId),
    );
    return SettingsAsyncContent<PermissionSettingsDto>(
      state: state,
      loading: SettingsSkeletonLayout.form(
        semanticLabel: AppLocalizations.of(context).settingsLoading,
      ),
      error: (error, stackTrace) => Center(child: TRText.inherit('$error')),
      data: (settings) {
        final l10n = AppLocalizations.of(context);
        return SettingsScaffold(
          children: <Widget>[
            SettingsSection(
              title: l10n.permissionSettingsSection,
              description: l10n.permissionSettingsSectionDescription,
              children: <Widget>[
                SettingsRow(
                  title: TRText.inherit(
                    permissionModeLabel(l10n, settings.defaultMode),
                  ),
                  description: TRText.inherit(
                    permissionModeDescription(l10n, settings.defaultMode),
                  ),
                  unboundedDescription: true,
                  control: TRButton(
                    key: const ValueKey<String>(
                      'permission-settings-change',
                    ),
                    appearance: TRAppearance.outline,
                    onPressed: () => unawaited(
                      _choose(context, settings.defaultMode),
                    ),
                    child: TRText.inherit(l10n.permissionSettingsChange),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _choose(
    BuildContext context,
    PermissionMode currentMode,
  ) async {
    final choice = await showPermissionPicker(
      context,
      currentMode: currentMode,
    );
    if (choice?.mode case final mode?) {
      if (!context.mounted) return;
      // Resolved before the write: the messenger keeps no context of its own,
      // which is what lets its report outlive this screen.
      final l10n = AppLocalizations.of(context);
      await ref
          .read(toastMessengerProvider)
          .run(
            () => ref
                .read(
                  permissionSettingsControllerProvider(widget.hostId).notifier,
                )
                .setDefaultMode(mode),
            failure: l10n.permissionSettingsSaveFailed,
            success: l10n.commonSaved,
            id: 'permission-settings-default-mode',
          );
    }
  }
}
