import 'dart:async';

import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:coder_app/src/shared/presentation/coder_icons.dart';
import 'package:coder_app/src/shared/presentation/coder_layout_metrics.dart';
import 'package:coder_app/src/shared/presentation/coder_list_row.dart';
import 'package:coder_app/src/shared/presentation/settings_layout.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/material.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// One model offered by the combined provider model picker.
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
    providerConnectionId: model.connectionId,
    modelId: model.id,
  );
}

/// A typed result from the model picker.
sealed class ModelPickerChoice {
  const ModelPickerChoice();
}

/// Loads the provider-qualified models displayed by a picker.
typedef ModelPickerOptionsLoader = Future<List<ModelPickerOption>> Function();

/// An explicitly selected provider-qualified model.
final class SelectedModelPickerChoice extends ModelPickerChoice {
  /// Creates a selected model result.
  const SelectedModelPickerChoice(this.selection);

  /// Chosen model persisted on the session.
  final SessionModelSelectionDto selection;
}

/// A request to restore the selected agent's model default.
final class InheritModelPickerChoice extends ModelPickerChoice {
  /// Creates an inherit result.
  const InheritModelPickerChoice();
}

/// Shows the searchable model list as a dialog or a mobile bottom sheet.
///
/// Returns the chosen provider-qualified model, an explicit inherit choice,
/// or null when dismissed.
Future<ModelPickerChoice?> showModelPicker(
  BuildContext context, {
  required ModelPickerOptionsLoader loadOptions,
  required SessionModelSelectionDto? currentSelection,
  String? title,
  String? inheritLabel,
}) {
  final picker = _AsyncModelPicker(
    loadOptions: loadOptions,
    currentSelection: currentSelection,
    title: title,
    inheritLabel: inheritLabel,
  );
  if (MediaQuery.sizeOf(context).width < CoderLayoutMetrics.compactBreakpoint) {
    return showTRDrawer<ModelPickerChoice>(
      context: context,
      builder: (context) => TRDrawer(
        semanticLabel: title,
        snapPoints: const <double>[0.8, 1],
        content: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.8,
          child: picker,
        ),
      ),
    );
  }
  return showTRDialog<ModelPickerChoice>(
    context: context,
    builder: (context) => TRDialog(
      semanticLabel: title,
      content: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: TRMeasurements.overlayWidthMd,
          maxHeight: TRMeasurements.measureXl,
        ),
        child: picker,
      ),
    ),
  );
}

class _AsyncModelPicker extends StatefulWidget {
  const _AsyncModelPicker({
    required this.loadOptions,
    required this.currentSelection,
    this.title,
    this.inheritLabel,
  });

  final ModelPickerOptionsLoader loadOptions;
  final SessionModelSelectionDto? currentSelection;
  final String? title;
  final String? inheritLabel;

  @override
  State<_AsyncModelPicker> createState() => _AsyncModelPickerState();
}

class _AsyncModelPickerState extends State<_AsyncModelPicker> {
  List<ModelPickerOption>? _options;
  Object? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
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
    final options = _options;
    if (options != null) {
      return ModelPicker(
        options: options,
        currentSelection: widget.currentSelection,
        title: widget.title,
        inheritLabel: widget.inheritLabel,
      );
    }
    final l10n = AppLocalizations.of(context);
    final error = _error;
    if (error != null) {
      return SettingsDialogForm(
        children: <Widget>[
          TRAlert(
            key: const ValueKey<String>('model-picker-load-error'),
            variant: TRStatusVariant.danger,
            title: TRText.inherit(l10n.settingsRefreshFailed('$error')),
            actions: <Widget>[
              TRButton(
                intent: TRIntent.primary,
                onPressed: () => unawaited(_load()),
                child: TRText.inherit(l10n.commonRetry),
              ),
            ],
          ),
        ],
      );
    }
    return SettingsSkeletonLayout.overlay(
      semanticLabel: l10n.settingsLoading,
    );
  }
}

/// Searchable list of models across all usable provider connections.
class ModelPicker extends StatefulWidget {
  /// Creates a [ModelPicker].
  const ModelPicker({
    required this.options,
    required this.currentSelection,
    this.title,
    this.inheritLabel,
    super.key,
  });

  /// Provider-qualified models offered to the user.
  final List<ModelPickerOption> options;

  /// Currently selected model, marked with a check.
  final SessionModelSelectionDto? currentSelection;

  /// Heading shown above the search field, or null for the default.
  final String? title;

  /// When set, adds a leading option that clears an explicit selection.
  final String? inheritLabel;

  @override
  State<ModelPicker> createState() => _ModelPickerState();
}

class _ModelPickerState extends State<ModelPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final query = _query.trim().toLowerCase();
    final ordered = <ModelPickerOption>[
      ...widget.options.where(_isSelected),
      ...widget.options.where((option) => !_isSelected(option)),
    ];
    final filtered = query.isEmpty
        ? ordered
        : ordered
              .where(
                (option) =>
                    option.model.id.toLowerCase().contains(query) ||
                    option.model.label.toLowerCase().contains(query) ||
                    option.providerName.toLowerCase().contains(query),
              )
              .toList(growable: false);
    final inheritLabel = widget.inheritLabel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: TRText(
                widget.title ?? l10n.modelPickerTitle,
                variant: TRTextVariant.headingLg,
              ),
            ),
            TRIconButton(
              appearance: TRAppearance.ghost,
              label: l10n.commonClose,
              onPressed: () => Navigator.pop(context),
              icon: const Icon(CoderIcons.close),
            ),
          ],
        ),
        const SizedBox(height: TRSpacing.small),
        TRTextField(
          key: const ValueKey('model-search-field'),
          autofocus: true,
          label: l10n.modelPickerSearch,
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: TRSpacing.medium),
        if (inheritLabel != null && query.isEmpty)
          CoderListRow(
            key: const ValueKey('model-option-inherit'),
            title: TRText.inherit(inheritLabel),
            trailing: widget.currentSelection == null
                ? const Icon(CoderIcons.check)
                : null,
            onTap: () => Navigator.pop(
              context,
              const InheritModelPickerChoice(),
            ),
          ),
        Expanded(
          child: filtered.isEmpty
              ? Center(child: TRText.inherit(l10n.modelPickerNoResults))
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final option = filtered[index];
                    final model = option.model;
                    return CoderListRow(
                      key: ValueKey(
                        'model-option-${model.connectionId}-${model.id}',
                      ),
                      title: TRText.inherit(
                        model.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: TRText.inherit(
                        model.label == model.id
                            ? option.providerName
                            : '${option.providerName} · ${model.id}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: _isSelected(option)
                          ? const Icon(CoderIcons.check)
                          : null,
                      onTap: () => Navigator.pop(
                        context,
                        SelectedModelPickerChoice(option.selection),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  bool _isSelected(ModelPickerOption option) =>
      option.model.connectionId ==
          widget.currentSelection?.providerConnectionId &&
      option.model.id == widget.currentSelection?.modelId;
}
