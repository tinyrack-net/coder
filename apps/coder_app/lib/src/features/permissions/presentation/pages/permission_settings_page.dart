import 'dart:async';

import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:coder_app/src/features/permissions/application/permission_settings_controller.dart';
import 'package:coder_app/src/shared/presentation/coder_icons.dart';
import 'package:coder_app/src/shared/presentation/permission_picker.dart';
import 'package:coder_app/src/shared/presentation/settings_layout.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  String? _saveError;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      permissionSettingsControllerProvider(widget.hostId),
    );
    return state.when(
      loading: () => const Center(child: TRSpinner()),
      error: (error, stackTrace) => Center(child: TRText.inherit('$error')),
      data: (settings) {
        final l10n = AppLocalizations.of(context);
        return SettingsScaffold(
          children: <Widget>[
            SettingsSection(
              title: l10n.permissionSettingsSection,
              description: l10n.permissionSettingsSectionDescription,
              banner: _saveError == null
                  ? null
                  : TRAlert(
                      key: const ValueKey<String>(
                        'permission-settings-error',
                      ),
                      title: TRText.inherit(
                        l10n.permissionSettingsSaveFailed,
                      ),
                      description: TRText.inherit(_saveError!),
                      icon: const Icon(CoderIcons.error),
                      variant: TRStatusVariant.danger,
                    ),
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
      if (mounted) setState(() => _saveError = null);
      try {
        await ref
            .read(
              permissionSettingsControllerProvider(widget.hostId).notifier,
            )
            .setDefaultMode(mode);
      } on Object catch (error) {
        if (mounted) setState(() => _saveError = '$error');
      }
    }
  }
}
