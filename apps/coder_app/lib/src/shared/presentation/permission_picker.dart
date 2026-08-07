import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:coder_app/src/shared/presentation/coder_icons.dart';
import 'package:coder_app/src/shared/presentation/coder_list_row.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/material.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// A permission choice, including inheritance when [mode] is null.
final class PermissionPickerChoice {
  /// Creates a permission choice.
  const PermissionPickerChoice(this.mode);

  /// Explicit mode, or null to inherit the next default in the hierarchy.
  final PermissionMode? mode;
}

/// Opens the shared, descriptive permission picker.
Future<PermissionPickerChoice?> showPermissionPicker(
  BuildContext context, {
  required PermissionMode? currentMode,
  String? inheritLabel,
  PermissionMode? inheritedMode,
}) => showTRDrawer<PermissionPickerChoice>(
  context: context,
  builder: (context) => PermissionPickerDrawer(
    currentMode: currentMode,
    inheritLabel: inheritLabel,
    inheritedMode: inheritedMode,
  ),
);

/// Descriptive permission choices presented in the shared drawer surface.
class PermissionPickerDrawer extends StatelessWidget {
  /// Creates a permission picker drawer.
  const PermissionPickerDrawer({
    required this.currentMode,
    this.inheritLabel,
    this.inheritedMode,
    super.key,
  });

  /// The selected explicit mode, or null when inheritance is selected.
  final PermissionMode? currentMode;

  /// Optional label for an inherited-mode choice.
  final String? inheritLabel;

  /// Effective inherited mode shown under [inheritLabel].
  final PermissionMode? inheritedMode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final inheritLabel = this.inheritLabel;
    final inheritedMode = this.inheritedMode;
    return TRDrawer(
      title: TRText.inherit(l10n.composerSelectPermissionMode),
      description: TRText.inherit(l10n.permissionPickerDescription),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (inheritLabel != null)
            CoderListRow(
              key: const ValueKey<String>('permission-option-inherit'),
              selected: currentMode == null,
              title: TRText.inherit(inheritLabel),
              subtitle: inheritedMode == null
                  ? null
                  : TRText.inherit(permissionModeLabel(l10n, inheritedMode)),
              trailing: currentMode == null
                  ? const Icon(CoderIcons.check)
                  : null,
              onTap: () => Navigator.pop(
                context,
                const PermissionPickerChoice(null),
              ),
            ),
          for (final mode in PermissionMode.values)
            CoderListRow(
              key: ValueKey<String>('permission-option-${mode.name}'),
              selected: currentMode == mode,
              title: TRText.inherit(permissionModeLabel(l10n, mode)),
              subtitle: TRText.inherit(permissionModeDescription(l10n, mode)),
              unboundedSubtitle: true,
              trailing: currentMode == mode
                  ? const Icon(CoderIcons.check)
                  : null,
              onTap: () => Navigator.pop(
                context,
                PermissionPickerChoice(mode),
              ),
            ),
        ],
      ),
    );
  }
}

/// Localized short label for one permission mode.
String permissionModeLabel(AppLocalizations l10n, PermissionMode mode) =>
    switch (mode) {
      PermissionMode.readOnly => l10n.composerPermissionReadOnly,
      PermissionMode.ask => l10n.composerPermissionAsk,
      PermissionMode.workspaceWrite => l10n.composerPermissionWorkspaceWrite,
      PermissionMode.fullAccess => l10n.composerPermissionFullAccess,
    };

/// Localized explanation of the effective behavior of one mode.
String permissionModeDescription(
  AppLocalizations l10n,
  PermissionMode mode,
) => switch (mode) {
  PermissionMode.readOnly => l10n.permissionDescriptionReadOnly,
  PermissionMode.ask => l10n.permissionDescriptionAsk,
  PermissionMode.workspaceWrite => l10n.permissionDescriptionWorkspaceWrite,
  PermissionMode.fullAccess => l10n.permissionDescriptionFullAccess,
};
