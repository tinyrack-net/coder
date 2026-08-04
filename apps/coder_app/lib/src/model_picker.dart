import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:coder_app/src/coder_icons.dart';
import 'package:coder_app/src/coder_list_row.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/material.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// Sentinel returned by [showModelPicker] when the inherit option is chosen.
const String inheritModelSentinel = '__inherit__';

/// Shows the searchable model list as a dialog or a mobile bottom sheet.
///
/// Returns the chosen model id, [inheritModelSentinel] when [inheritLabel] is
/// supplied and picked, or null when dismissed.
Future<String?> showModelPicker(
  BuildContext context, {
  required String connectionId,
  required List<ProviderModelDto> models,
  required String? currentModelId,
  String? title,
  String? inheritLabel,
}) {
  final picker = ModelPicker(
    connectionId: connectionId,
    models: models,
    currentModelId: currentModelId,
    title: title,
    inheritLabel: inheritLabel,
  );
  if (MediaQuery.sizeOf(context).width < 760) {
    return showTRDrawer<String>(
      context: context,
      builder: (context) => TRDrawer(
        semanticLabel: title,
        snapPoints: const <double>[0.8, 1],
        content: picker,
      ),
    );
  }
  return showTRDialog<String>(
    context: context,
    builder: (context) => TRDialog(
      semanticLabel: title,
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 640),
        child: picker,
      ),
    ),
  );
}

/// Searchable list of one connection's models.
class ModelPicker extends StatefulWidget {
  /// Creates a [ModelPicker].
  const ModelPicker({
    required this.connectionId,
    required this.models,
    required this.currentModelId,
    this.title,
    this.inheritLabel,
    super.key,
  });

  /// Provider connection whose models are listed.
  final String connectionId;

  /// Models offered by [connectionId].
  final List<ProviderModelDto> models;

  /// Currently selected model, marked with a check.
  final String? currentModelId;

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
    final ordered = <ProviderModelDto>[
      ...widget.models.where((model) => model.id == widget.currentModelId),
      ...widget.models.where((model) => model.id != widget.currentModelId),
    ];
    final filtered = query.isEmpty
        ? ordered
        : ordered
              .where(
                (model) =>
                    model.id.toLowerCase().contains(query) ||
                    model.label.toLowerCase().contains(query),
              )
              .toList(growable: false);
    final inheritLabel = widget.inheritLabel;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  widget.title ?? l10n.modelPickerTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              TRIconButton(
                appearance: TRAppearance.ghost,
                uiSize: TRUiSize.sm,
                label: l10n.commonClose,
                onPressed: () => Navigator.pop(context),
                icon: const Icon(CoderIcons.close),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TRTextField(
            uiSize: TRUiSize.sm,
            key: const ValueKey('model-search-field'),
            autofocus: true,
            label: l10n.modelPickerSearch,
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 12),
          if (inheritLabel != null && query.isEmpty)
            CoderListRow(
              key: const ValueKey('model-option-inherit'),
              title: Text(inheritLabel),
              trailing: widget.currentModelId == null
                  ? const Icon(CoderIcons.check)
                  : null,
              onTap: () => Navigator.pop(context, inheritModelSentinel),
            ),
          Expanded(
            child: filtered.isEmpty
                ? Center(child: Text(l10n.modelPickerNoResults))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final model = filtered[index];
                      return CoderListRow(
                        key: ValueKey(
                          'model-option-${widget.connectionId}-${model.id}',
                        ),
                        title: Text(
                          model.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: model.label == model.id
                            ? null
                            : Text(
                                model.id,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                        trailing: model.id == widget.currentModelId
                            ? const Icon(CoderIcons.check)
                            : null,
                        onTap: () => Navigator.pop(context, model.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
