import 'dart:async';

import 'package:app/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:protocol/protocol.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// One model offered by the combined provider model Select.
final class ModelPickerOption {
  /// Creates a provider-qualified model option.
  const ModelPickerOption({
    required this.providerName,
    required this.model,
  });

  /// User-facing name of the provider connection.
  final String providerName;

  /// Provider-local model metadata.
  final ProviderModelDto model;

  /// Selection persisted on the session.
  SessionModelSelectionDto get selection => SessionModelSelectionDto(
    modelId: model.id,
  );
}

/// Loads the provider-qualified models displayed by a Select.
typedef ModelPickerOptionsLoader = Future<List<ModelPickerOption>> Function();

/// A searchable model Select that owns its catalog loading state.
///
/// The loaded catalog is shared by the desktop dropdown and mobile sheet
/// because both surfaces belong to the same [TRSelect].
class AsyncModelSelect extends StatefulWidget {
  /// Creates a model Select backed by [loadOptions].
  const AsyncModelSelect({
    required this.loadOptions,
    required this.currentSelection,
    required this.onValueChange,
    required this.inheritLabel,
    this.loadKey,
    this.enabled = true,
    this.leading,
    this.appearance = TRFieldAppearance.solid,
    this.uiSize = TRUiSize.md,
    this.width,
    this.placeholder,
    super.key,
  });

  /// Loads all usable provider models through the typed application port.
  final ModelPickerOptionsLoader loadOptions;

  /// Stable identity that triggers a reload when the owning host changes.
  final Object? loadKey;

  /// Current explicit selection, or null when the fallback chain is used.
  final SessionModelSelectionDto? currentSelection;

  /// Receives the selected option, or null when inheritance is selected.
  final FutureOr<void> Function(ModelPickerOption? option) onValueChange;

  /// Label of the null/inherited option.
  final String? inheritLabel;

  /// Whether the Select accepts input once loaded.
  final bool enabled;

  /// Optional leading trigger content.
  final Widget? leading;

  /// Design-system field appearance.
  final TRFieldAppearance appearance;

  /// Design-system control density.
  final TRUiSize uiSize;

  /// Optional trigger width.
  final double? width;

  /// Trigger placeholder while no explicit option resolves.
  final String? placeholder;

  @override
  State<AsyncModelSelect> createState() => _AsyncModelSelectState();
}

class _AsyncModelSelectState extends State<AsyncModelSelect> {
  List<ModelPickerOption>? _options;
  Object? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant AsyncModelSelect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loadKey != widget.loadKey) unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _options = null;
      _error = null;
    });
    try {
      final options = await widget.loadOptions();
      if (mounted) setState(() => _options = options);
    } on Object catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final options = _options;
    if (options == null) {
      if (_error != null) {
        return TRButton(
          key: const ValueKey<String>('model-select-retry'),
          appearance: TRAppearance.ghost,
          uiSize: widget.uiSize,
          onPressed: widget.enabled ? () => unawaited(_load()) : null,
          child: TRText.inherit(l10n.commonRetry),
        );
      }
      return Semantics(
        label: l10n.settingsLoading,
        child: TRSkeleton(
          key: const ValueKey<String>('model-select-loading'),
          width: widget.width ?? TRMeasurements.measureXl,
        ),
      );
    }
    final current = options
        .where((option) => option.selection == widget.currentSelection)
        .firstOrNull;
    return TRSelect<ModelPickerOption?>.controlled(
      key: const ValueKey<String>('model-select'),
      value: current,
      enabled: widget.enabled,
      leading: widget.leading,
      appearance: widget.appearance,
      uiSize: widget.uiSize,
      width: widget.width,
      placeholder: widget.placeholder ?? widget.inheritLabel,
      searchable: true,
      searchPlaceholder: l10n.selectSearchPlaceholder,
      noResultsText: l10n.selectNoResults,
      // Explicit so the production Select policy can audit adaptation.
      // ignore: avoid_redundant_argument_values
      surface: TRSelectSurface.auto,
      items: <TRSelectItem<ModelPickerOption?>>[
        if (widget.inheritLabel case final inheritLabel?)
          TRSelectItem<ModelPickerOption?>(
            key: const ValueKey<String>('model-option-inherit'),
            value: null,
            label: inheritLabel,
          ),
        for (final option in options)
          TRSelectItem<ModelPickerOption?>(
            key: ValueKey<String>(_optionKey(option)),
            value: option,
            label: option.model.label,
            description: '${option.providerName} · ${option.model.id}',
          ),
      ],
      onValueChange: (option) => unawaited(
        Future<void>.sync(() async => widget.onValueChange(option)),
      ),
    );
  }

  String _optionKey(ModelPickerOption option) {
    final model = option.model;
    final providerModelId = model.providerModelId.isEmpty
        ? model.id
        : model.providerModelId;
    return 'model-option-${model.connectionId}-$providerModelId';
  }
}
