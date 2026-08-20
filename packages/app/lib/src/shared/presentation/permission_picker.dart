import 'package:app/l10n/gen/app_localizations.dart';
import 'package:app/src/shared/presentation/tinest_select_presentation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:protocol/protocol.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// A descriptive permission Select shared by composer and settings surfaces.
class PermissionSelect extends StatelessWidget {
  /// Creates a permission Select, including an optional inherited value.
  const PermissionSelect({
    required this.currentMode,
    required this.onValueChange,
    this.inheritLabel,
    this.inheritedMode,
    this.enabled = true,
    this.leading,
    this.appearance = TRFieldAppearance.solid,
    this.padding = TRFieldPadding.standard,
    this.uiSize,
    this.width,
    super.key,
  });

  /// Selected explicit mode, or null when inheritance is selected.
  final PermissionMode? currentMode;

  /// Optional inherited option label.
  final String? inheritLabel;

  /// Effective inherited mode shown as supporting option text.
  final PermissionMode? inheritedMode;

  /// Called with the explicit mode or null for inheritance.
  final ValueChanged<PermissionMode?>? onValueChange;

  /// Whether the Select accepts input.
  final bool enabled;

  /// Optional leading trigger content.
  final Widget? leading;

  /// Design-system field appearance.
  final TRFieldAppearance appearance;

  /// Whether the trigger adds the inline inset its size scale defines.
  ///
  /// A picker standing in for a value in a settings row passes
  /// [TRFieldPadding.none], because the row supplies that inset already.
  final TRFieldPadding padding;

  /// Design-system control density.
  final TRUiSize? uiSize;

  /// Optional trigger width.
  final double? width;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final inheritLabel = this.inheritLabel;
    return TRSelect<PermissionMode?>.controlled(
      value: currentMode,
      enabled: enabled,
      leading: leading,
      appearance: appearance,
      padding: padding,
      uiSize: uiSize,
      width: width,
      searchable: true,
      searchPlaceholder: l10n.selectSearchPlaceholder,
      noResultsText: l10n.selectNoResults,
      presentation: TinestSelectPresentation.resolve(context),
      items: <TRSelectItem<PermissionMode?>>[
        if (inheritLabel != null)
          TRSelectItem<PermissionMode?>(
            key: const ValueKey<String>('permission-option-inherit'),
            value: null,
            label: inheritLabel,
            description: inheritedMode == null
                ? null
                : permissionModeLabel(l10n, inheritedMode!),
          ),
        for (final mode in PermissionMode.values)
          TRSelectItem<PermissionMode?>(
            key: ValueKey<String>('permission-option-${mode.name}'),
            value: mode,
            label: permissionModeLabel(l10n, mode),
            description: permissionModeDescription(l10n, mode),
          ),
      ],
      onValueChange: onValueChange,
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
