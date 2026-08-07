import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:coder_app/src/features/agents/application/agent_definitions_controller.dart';
import 'package:coder_app/src/features/conversation/application/attachment_ports.dart';
import 'package:coder_app/src/features/conversation/application/composer_controller.dart';
import 'package:coder_app/src/features/conversation/application/composer_suggestions.dart';
import 'package:coder_app/src/features/conversation/application/conversation_controller.dart';
import 'package:coder_app/src/features/conversation/domain/composer_commands.dart';
import 'package:coder_app/src/features/conversation/presentation/chat_plan_actions.dart';
import 'package:coder_app/src/features/conversation/presentation/composer_client_commands.dart';
import 'package:coder_app/src/features/conversation/presentation/composer_trigger.dart';
import 'package:coder_app/src/features/conversation/presentation/widgets/composer_completion_scope.dart';
import 'package:coder_app/src/features/conversation/presentation/widgets/composer_suggestions_overlay.dart';
import 'package:coder_app/src/features/hosts/domain/host_models.dart';
import 'package:coder_app/src/features/permissions/application/permission_settings_controller.dart';
import 'package:coder_app/src/features/providers/application/model_picker_options.dart';
import 'package:coder_app/src/features/providers/application/provider_settings_controller.dart';
import 'package:coder_app/src/features/providers/application/session_model_options.dart';
import 'package:coder_app/src/features/sessions/domain/session_title.dart';
import 'package:coder_app/src/shared/presentation/coder_icons.dart';
import 'package:coder_app/src/shared/presentation/model_picker.dart';
import 'package:coder_app/src/shared/presentation/permission_picker.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:dropwell/dropwell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// Turn settings shown in the composer toolbar row.
class SessionComposerBar extends ConsumerStatefulWidget {
  /// Creates a [SessionComposerBar].
  const SessionComposerBar({
    required this.hostId,
    required this.definitions,
    required this.agentDefinitionId,
    required this.selection,
    required this.onAgentChanged,
    required this.onModelChanged,
    required this.mode,
    required this.onModeChanged,
    this.modelControls = const <String, ModelControlValueDto>{},
    this.onModelControlsChanged,
    this.permissionMode,
    this.onPermissionModeChanged,
    this.agentEnabled = true,
    this.enabled = true,
    this.leading,
    super.key,
  });

  /// Control pinned before the chips, which never collapses.
  final Widget? leading;

  /// Returns this bar with [leading] pinned before its chips.
  ///
  /// The composer owns the attach action but the bar owns the width the chips
  /// have to fit, so the two are measured together.
  SessionComposerBar withLeading(Widget leading) => SessionComposerBar(
    hostId: hostId,
    definitions: definitions,
    agentDefinitionId: agentDefinitionId,
    selection: selection,
    onAgentChanged: onAgentChanged,
    onModelChanged: onModelChanged,
    mode: mode,
    onModeChanged: onModeChanged,
    modelControls: modelControls,
    onModelControlsChanged: onModelControlsChanged,
    permissionMode: permissionMode,
    onPermissionModeChanged: onPermissionModeChanged,
    agentEnabled: agentEnabled,
    enabled: enabled,
    leading: leading,
    key: key,
  );

  /// Daemon profile owning the provider connections.
  final String hostId;

  /// Agent definitions the user may choose from.
  final List<AgentDefinitionDto> definitions;

  /// Agent definition currently in effect.
  final String? agentDefinitionId;

  /// Provider-qualified model currently in effect, if any resolves.
  final SessionModelSelectionDto? selection;

  /// Called with the newly chosen agent definition id.
  final ValueChanged<String> onAgentChanged;

  /// Called with the chosen override, or null to inherit the agent definition.
  final FutureOr<void> Function(
    SessionModelSelectionDto? selection,
    Map<String, ModelControlValueDto> controls,
  )
  onModelChanged;

  /// Collaboration mode currently in effect.
  final SessionMode mode;

  /// Called with the mode to switch to.
  final ValueChanged<SessionMode> onModeChanged;

  /// Explicit values for the selected provider model.
  final Map<String, ModelControlValueDto> modelControls;

  /// Called whenever a model-specific value changes.
  final FutureOr<void> Function(Map<String, ModelControlValueDto>)?
  onModelControlsChanged;

  /// Permission mode in effect, or null to inherit the agent definition.
  final PermissionMode? permissionMode;

  /// Called with the chosen mode, or null to inherit the agent definition.
  final FutureOr<void> Function(PermissionMode?)? onPermissionModeChanged;

  /// Whether the agent can still be changed; false once a session exists.
  final bool agentEnabled;

  /// Whether any selector accepts input.
  final bool enabled;

  @override
  ConsumerState<SessionComposerBar> createState() => _SessionComposerBarState();
}

class _SessionComposerBarState extends ConsumerState<SessionComposerBar> {
  final Set<String> _loading = <String>{};
  String? _permissionError;

  /// Loads the catalog naming the chosen model, after this frame.
  ///
  /// Whether the catalog is needed is only known once the connection has been
  /// resolved in build, but mutating a provider from build is not allowed, so
  /// the load is handed to the next frame instead.
  void _scheduleModelLoad(String connectionId) {
    if (_loadedModels(connectionId) != null || !_loading.add(connectionId)) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        await _ensureModelsLoaded(connectionId);
      } finally {
        _loading.remove(connectionId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hostId = widget.hostId;
    final definitions = widget.definitions;
    final selection = widget.selection;
    final agentEnabled = widget.agentEnabled;
    final enabled = widget.enabled;
    final planning = widget.mode == SessionMode.plan;
    // Keep the loaded connections while the provider refreshes.
    final providers = ref
        .watch(providerSettingsControllerProvider(hostId))
        .value;
    final l10n = AppLocalizations.of(context);
    final connections = usableConnections(
      providers?.connections ?? const <ProviderConnectionDto>[],
    );
    final agent = definitions
        .where((definition) => definition.id == widget.agentDefinitionId)
        .firstOrNull;
    final daemonDefault = ref
        .watch(permissionSettingsControllerProvider(hostId))
        .value
        ?.defaultMode;
    final inheritedPermission =
        agent?.permissionMode ?? daemonDefault ?? PermissionMode.ask;
    final connection = connections
        .where((item) => item.id == selection?.providerConnectionId)
        .firstOrNull;
    final models =
        providers?.models[connection?.id] ?? const <ProviderModelDto>[];
    final model = models
        .where((item) => item.id == selection?.modelId)
        .firstOrNull;
    final modelLabel = model?.label;
    // The catalog decides which turn settings the chosen model can honour, so
    // an unsupported control is hidden rather than shown and ignored.
    final capabilities = model?.capabilities ?? const ModelCapabilitiesDto();
    // Labels come from the model catalog, so load it once per connection
    // instead of showing a raw model id.
    if (connection != null) _scheduleModelLoad(connection.id);
    final bar = ComposerChipBar(
      overflowLabel: l10n.composerMoreSettings,
      leading: widget.leading,
      // These are settings under the prompt, not the prompt itself, so the row
      // takes the dense size the design system keeps for application chrome.
      uiSize: TRUiSize.sm,
      chips: <ComposerChipSpec>[
        ComposerChipSpec(
          valueKey: const ValueKey('session-composer-agent'),
          icon: CoderIcons.agent,
          label: agent?.name ?? 'Agent',
          tooltip: agentEnabled
              ? l10n.composerSelectAgent
              : l10n.composerAgentLocked,
          menuChildren: enabled && agentEnabled && definitions.isNotEmpty
              ? <Widget>[
                  for (final definition in definitions)
                    TRMenuItem(
                      key: ValueKey('session-composer-agent-${definition.id}'),
                      onPressed: () => widget.onAgentChanged(definition.id),
                      child: TRText.inherit(definition.name),
                    ),
                ]
              : null,
        ),
        ComposerChipSpec(
          valueKey: const ValueKey('session-composer-model'),
          icon: CoderIcons.memory,
          label: modelLabel ?? selection?.modelId ?? l10n.composerModel,
          tooltip: l10n.composerSelectModel,
          onPressed: enabled && connections.isNotEmpty ? _chooseModel : null,
        ),
        for (final control in capabilities.controls)
          _controlChip(control, enabled),
        ComposerChipSpec(
          valueKey: const ValueKey('session-composer-permission'),
          icon: CoderIcons.permission,
          label: permissionModeLabel(
            l10n,
            widget.permissionMode ?? inheritedPermission,
          ),
          tooltip: l10n.composerSelectPermissionMode,
          onPressed: enabled && widget.onPermissionModeChanged != null
              ? (_) => unawaited(
                  _choosePermission(context, inheritedPermission),
                )
              : null,
        ),
        ComposerChipSpec(
          valueKey: const ValueKey('session-composer-mode'),
          icon: CoderIcons.checklist,
          label: planning ? l10n.composerPlan : l10n.composerRun,
          tooltip: planning
              ? l10n.composerPlanTooltip
              : l10n.composerRunTooltip,
          selected: planning,
          onPressed: enabled
              ? (_) => widget.onModeChanged(
                  planning ? SessionMode.normal : SessionMode.plan,
                )
              : null,
        ),
      ],
    );
    final permissionError = _permissionError;
    if (permissionError == null) return bar;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TRAlert(
          key: const ValueKey<String>('session-composer-permission-error'),
          title: TRText.inherit(l10n.permissionChangeFailed),
          description: TRText.inherit(permissionError),
          icon: const Icon(CoderIcons.error),
          variant: TRStatusVariant.danger,
        ),
        bar,
      ],
    );
  }

  ComposerChipSpec _controlChip(
    ModelControlDescriptorDto descriptor,
    bool enabled,
  ) {
    final value = widget.modelControls[descriptor.id];
    final canChange = enabled && widget.onModelControlsChanged != null;
    return switch (descriptor.kind) {
      ModelControlKind.choice => ComposerChipSpec(
        valueKey: ValueKey('session-composer-control-${descriptor.id}'),
        icon: _controlIcon(descriptor.id),
        label: switch (value) {
          ModelControlStringValueDto(:final value) =>
            descriptor.choices
                    .where((choice) => choice.id == value)
                    .firstOrNull
                    ?.label ??
                value,
          _ => descriptor.label,
        },
        tooltip: descriptor.description ?? descriptor.label,
        menuChildren: canChange
            ? <Widget>[
                TRMenuItem(
                  key: ValueKey(
                    'session-composer-control-${descriptor.id}-default',
                  ),
                  onPressed: () => _setControl(descriptor, null),
                  child: TRText.inherit(
                    AppLocalizations.of(
                      context,
                    ).providerSettingsDefaultModelAutomatic,
                  ),
                ),
                for (final choice in descriptor.choices)
                  TRMenuItem(
                    key: ValueKey(
                      'session-composer-control-${descriptor.id}-${choice.id}',
                    ),
                    onPressed: () => _setControl(
                      descriptor,
                      ModelControlValueDto.stringValue(value: choice.id),
                    ),
                    child: TRText.inherit(choice.label),
                  ),
              ]
            : null,
      ),
      ModelControlKind.toggle => ComposerChipSpec(
        valueKey: ValueKey('session-composer-control-${descriptor.id}'),
        icon: _controlIcon(descriptor.id),
        label: descriptor.label,
        tooltip: descriptor.description ?? descriptor.label,
        selected: value is ModelControlBoolValueDto && value.value,
        onPressed: canChange
            ? (_) => _setControl(
                descriptor,
                value is ModelControlBoolValueDto && value.value
                    ? null
                    : const ModelControlValueDto.boolValue(value: true),
              )
            : null,
      ),
      ModelControlKind.integer => ComposerChipSpec(
        valueKey: ValueKey('session-composer-control-${descriptor.id}'),
        icon: _controlIcon(descriptor.id),
        label: switch (value) {
          ModelControlIntValueDto(:final value) =>
            '${descriptor.label}: $value',
          _ => descriptor.label,
        },
        tooltip: descriptor.description ?? descriptor.label,
        onPressed: canChange
            ? (chipContext) => unawaited(
                _chooseInteger(chipContext, descriptor, value),
              )
            : null,
      ),
    };
  }

  IconData _controlIcon(String id) => switch (id) {
    'fast_mode' => CoderIcons.fast,
    'reasoning_effort' ||
    'reasoning_mode' ||
    'thinking_budget' => CoderIcons.reasoning,
    _ => CoderIcons.settings,
  };

  void _setControl(
    ModelControlDescriptorDto descriptor,
    ModelControlValueDto? value,
  ) {
    final updated = <String, ModelControlValueDto>{...widget.modelControls}
      ..remove(descriptor.id);
    descriptor.conflictsWith.forEach(updated.remove);
    if (value != null) updated[descriptor.id] = value;
    final callback = widget.onModelControlsChanged;
    if (callback != null) {
      unawaited(Future<void>.sync(() async => callback(updated)));
    }
  }

  Future<void> _chooseInteger(
    BuildContext context,
    ModelControlDescriptorDto descriptor,
    ModelControlValueDto? current,
  ) async {
    final value = await showTRDialog<int>(
      context: context,
      builder: (context) => _IntegerControlDialog(
        descriptor: descriptor,
        initialValue: current is ModelControlIntValueDto ? current.value : null,
      ),
    );
    if (value == null || !mounted) return;
    _setControl(descriptor, ModelControlValueDto.intValue(value: value));
  }

  Future<void> _choosePermission(
    BuildContext context,
    PermissionMode inheritedMode,
  ) async {
    final choice = await showPermissionPicker(
      context,
      currentMode: widget.permissionMode,
      inheritLabel: AppLocalizations.of(context).composerInheritPermissionMode,
      inheritedMode: inheritedMode,
    );
    if (choice == null) return;
    if (mounted) setState(() => _permissionError = null);
    try {
      await widget.onPermissionModeChanged?.call(choice.mode);
    } on Object catch (error) {
      if (mounted) setState(() => _permissionError = '$error');
    }
  }

  List<ProviderModelDto>? _loadedModels(String connectionId) => ref
      .read(providerSettingsControllerProvider(widget.hostId))
      .value
      ?.models[connectionId];

  Future<void> _ensureModelsLoaded(String connectionId) async {
    if (_loadedModels(connectionId) != null) return;
    await ref
        .read(providerSettingsControllerProvider(widget.hostId).notifier)
        .loadModels(connectionId);
  }

  Future<void> _chooseModel(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final options = await loadModelPickerOptions(ref, widget.hostId);
    if (!context.mounted) return;
    // Clearing the override always means "follow the fallback chain"; only the
    // first step of that chain differs per agent.
    final chosen = await showModelPicker(
      context,
      options: options,
      currentSelection: widget.selection,
      title: l10n.composerSelectModel,
      inheritLabel: _selectedAgent?.model.source == AgentModelSource.fixed
          ? l10n.composerInheritModel
          : l10n.composerInheritDefaultModel,
    );
    if (chosen == null) return;
    switch (chosen) {
      case SelectedModelPickerChoice(:final selection):
        final target = options
            .where((option) => option.selection == selection)
            .firstOrNull;
        final allowed =
            target?.model.capabilities.controls
                .map((control) => control.id)
                .toSet() ??
            const <String>{};
        final retained = <String, ModelControlValueDto>{
          for (final entry in widget.modelControls.entries)
            if (allowed.contains(entry.key)) entry.key: entry.value,
        };
        await widget.onModelChanged(selection, retained);
      case InheritModelPickerChoice():
        await widget.onModelChanged(
          null,
          const <String, ModelControlValueDto>{},
        );
    }
  }

  AgentDefinitionDto? get _selectedAgent => widget.definitions
      .where((definition) => definition.id == widget.agentDefinitionId)
      .firstOrNull;
}

class _IntegerControlDialog extends StatefulWidget {
  const _IntegerControlDialog({
    required this.descriptor,
    required this.initialValue,
  });

  final ModelControlDescriptorDto descriptor;
  final int? initialValue;

  @override
  State<_IntegerControlDialog> createState() => _IntegerControlDialogState();
}

class _IntegerControlDialogState extends State<_IntegerControlDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue?.toString() ?? '',
  );

  int? get _value => int.tryParse(_controller.text.trim());

  bool get _valid {
    final value = _value;
    if (value == null) return false;
    final descriptor = widget.descriptor;
    return (descriptor.minimum == null || value >= descriptor.minimum!) &&
        (descriptor.maximum == null || value <= descriptor.maximum!) &&
        (descriptor.step == null ||
            descriptor.minimum == null ||
            (value - descriptor.minimum!) % descriptor.step! == 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TRAlertDialog(
    title: TRText.inherit(widget.descriptor.label),
    description: widget.descriptor.description == null
        ? null
        : TRText.inherit(widget.descriptor.description!),
    content: TRTextField(
      controller: _controller,
      autofocus: true,
      keyboardType: TextInputType.number,
      onChanged: (_) => setState(() {}),
      label: widget.descriptor.label,
      errorText: _controller.text.isEmpty || _valid
          ? null
          : '${widget.descriptor.minimum ?? ''}'
                '–${widget.descriptor.maximum ?? ''}',
    ),
    actions: <TRButton>[
      TRButton(
        appearance: TRAppearance.ghost,
        onPressed: () => Navigator.pop(context),
        child: TRText.inherit(AppLocalizations.of(context).commonCancel),
      ),
      TRButton(
        intent: TRIntent.primary,
        onPressed: _valid ? () => Navigator.pop(context, _value) : null,
        child: TRText.inherit(AppLocalizations.of(context).commonSave),
      ),
    ],
  );
}

/// One turn setting the composer toolbar offers.
///
/// The toolbar decides how much of a chip fits, so a setting describes itself
/// once and is rendered as a labelled chip, an icon, or a menu entry.
@immutable
class ComposerChipSpec {
  /// Creates a [ComposerChipSpec].
  const ComposerChipSpec({
    required this.valueKey,
    required this.icon,
    required this.label,
    required this.tooltip,
    this.onPressed,
    this.menuChildren,
    this.selected = false,
  });

  /// Stable key used by tests and by the enclosing row.
  final ValueKey<String> valueKey;

  /// Leading glyph.
  final IconData icon;

  /// Chip label.
  final String label;

  /// Hover and long-press description.
  final String tooltip;

  /// Tap handler receiving the chip's own context.
  final void Function(BuildContext chipContext)? onPressed;

  /// Anchored menu entries. When supplied, the chip opens a menu.
  final List<Widget>? menuChildren;

  /// Whether the chip renders as active.
  final bool selected;

  /// Renders the setting as a chip.
  Widget toChip({
    TRUiSize uiSize = TRUiSize.md,
    bool compact = false,
    double? maxWidth,
  }) => ComposerChip(
    valueKey: valueKey,
    icon: icon,
    label: label,
    tooltip: tooltip,
    onPressed: onPressed,
    menuChildren: menuChildren,
    selected: selected,
    uiSize: uiSize,
    compact: compact,
    maxWidth: maxWidth,
  );
}

/// Toolbar that trades label width, then whole labels, then chips, for width.
///
/// Chip widths are computed from the published control geometry rather than
/// measured after the fact, so exactly one arrangement is ever built: the
/// widest one that fits.
class ComposerChipBar extends StatelessWidget {
  /// Creates a [ComposerChipBar].
  const ComposerChipBar({
    required this.chips,
    required this.overflowLabel,
    this.leading,
    this.uiSize = TRUiSize.md,
    super.key,
  });

  /// Control geometry every chip in the row is built and measured with.
  final TRUiSize uiSize;

  /// Settings to show. The trailing ones give up their labels and room first.
  final List<ComposerChipSpec> chips;

  /// Label and tooltip of the menu holding whatever did not fit.
  final String overflowLabel;

  /// Control pinned before the chips at every width.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    const gap = TRSpacing.extraSmall;
    // A chip is a control holding one icon; a labelled one adds its text, and
    // a menu chip its disclosure glyph.
    final icon = TRControlMetrics.iconSizeOf(uiSize);
    final compact =
        2 *
            (TRControlMetrics.inlinePaddingOf(uiSize) +
                TRControlMetrics.borderWidth) +
        icon;
    // A chip renders its label in the control style, not the ambient one, and
    // measuring it any other way under-reports the width.
    final style = TRControlMetrics.labelStyleOf(uiSize);
    final scaler = MediaQuery.textScalerOf(context);
    double width(int index, double label) =>
        compact +
        gap +
        label +
        (chips[index].menuChildren == null ? 0 : gap + icon);
    final natural = <double>[
      for (var index = 0; index < chips.length; index += 1)
        width(index, _textWidth(chips[index].label, style, scaler)),
    ];
    // A label narrower than the glyph beside it is a character and an ellipsis,
    // which reads as noise next to an icon that already names the setting. Such
    // a chip gives its label up instead of showing a stub.
    final legible = <double>[
      for (var index = 0; index < chips.length; index += 1) width(index, icon),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // The pinned control is a square icon button and keeps its slot at
        // every width, so the chips only ever compete for what it leaves.
        final pinned = leading == null
            ? 0.0
            : TRControlMetrics.heightOf(uiSize) + gap;
        final available = constraints.maxWidth - pinned;
        final gaps = chips.isEmpty ? 0.0 : gap * (chips.length - 1);
        final room = available - gaps;
        // Labels are dropped from the trailing end, one at a time. A row where
        // only the last chip is wordy keeps every label before it, and the one
        // long value is ellipsized rather than costing the whole row its text.
        for (var labelled = chips.length; labelled >= 1; labelled -= 1) {
          final widths = _share(
            natural.take(labelled).toList(growable: false),
            room - compact * (chips.length - labelled),
          );
          final fits = <bool>[
            for (var index = 0; index < labelled; index += 1)
              widths[index] >= math.min(natural[index], legible[index]),
          ];
          if (fits.contains(false)) continue;
          return _row(<Widget>[
            for (var index = 0; index < labelled; index += 1)
              chips[index].toChip(
                uiSize: uiSize,
                maxWidth: widths[index] < natural[index] ? widths[index] : null,
              ),
            for (final chip in chips.skip(labelled))
              chip.toChip(uiSize: uiSize, compact: true),
          ]);
        }
        if (compact * chips.length <= room) {
          return _row(
            chips
                .map((chip) => chip.toChip(uiSize: uiSize, compact: true))
                .toList(),
          );
        }
        // Every chip that still fits keeps its place; the rest move into one
        // menu, which needs a slot of its own.
        final shared = available - compact - gap;
        final visible = shared <= 0
            ? 0
            : ((shared + gap) / (compact + gap)).floor().clamp(0, chips.length);
        return _row(<Widget>[
          for (final chip in chips.take(visible))
            chip.toChip(uiSize: uiSize, compact: true),
          _overflow(chips.skip(visible).toList(growable: false)),
        ]);
      },
    );
  }

  /// Divides [room] between chips wanting [natural] widths, fairest first.
  ///
  /// A chip that wants less than an equal share takes only what it wants and
  /// leaves the rest to be shared again, so a row of short labels and one long
  /// one spends the width on the long one instead of clipping all of them.
  List<double> _share(List<double> natural, double room) {
    final widths = List<double>.filled(natural.length, 0);
    final pending = <int>{
      for (var index = 0; index < natural.length; index += 1) index,
    };
    var remaining = room;
    while (pending.isNotEmpty) {
      final equal = remaining / pending.length;
      final content = pending
          .where((index) => natural[index] <= equal)
          .toList(
            growable: false,
          );
      if (content.isEmpty) {
        for (final index in pending) {
          widths[index] = equal;
        }
        break;
      }
      for (final index in content) {
        widths[index] = natural[index];
        remaining -= natural[index];
        pending.remove(index);
      }
    }
    return widths;
  }

  double _textWidth(String label, TextStyle style, TextScaler scaler) {
    final painter = TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }

  Widget _row(List<Widget> children) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: TRSpacing.extraSmall,
    children: <Widget>[
      ?leading,
      ...children,
    ],
  );

  Widget _overflow(List<ComposerChipSpec> hidden) => TRTooltip(
    message: overflowLabel,
    child: TRMenu.icon(
      key: const ValueKey('session-composer-overflow'),
      uiSize: uiSize,
      icon: const Icon(CoderIcons.more),
      label: overflowLabel,
      menuChildren: <Widget>[
        for (final chip in hidden)
          if (chip.menuChildren case final children?)
            TRMenuSubmenu(
              key: ValueKey('${chip.valueKey.value}-overflow'),
              menuChildren: children,
              leadingIcon: Icon(chip.icon),
              child: Text(chip.label),
            )
          else
            // The entry supplies its own context so an action that anchors a
            // picker opens it against the menu it was chosen from.
            Builder(
              builder: (itemContext) => TRMenuItem(
                key: ValueKey('${chip.valueKey.value}-overflow'),
                leadingIcon: Icon(chip.icon),
                onPressed: chip.onPressed == null
                    ? null
                    : () => chip.onPressed!(itemContext),
                child: Text(chip.label),
              ),
            ),
      ],
    ),
  );
}

/// Compact selector chip shared by the composers.
class ComposerChip extends StatelessWidget {
  /// Creates a composer chip.
  const ComposerChip({
    required this.valueKey,
    required this.icon,
    required this.label,
    required this.tooltip,
    this.menuChildren,
    this.onPressed,
    this.selected = false,
    this.uiSize = TRUiSize.md,
    this.compact = false,
    this.maxWidth,
    super.key,
  });

  /// Stable key used by tests and by the enclosing row.
  final ValueKey<String> valueKey;

  /// Leading glyph.
  final IconData icon;

  /// Chip label.
  final String label;

  /// Hover and long-press description.
  final String tooltip;

  /// Tap handler receiving the chip's own context.
  final void Function(BuildContext chipContext)? onPressed;

  /// Anchored menu entries. When supplied, the chip is a [TRMenu] trigger.
  final List<Widget>? menuChildren;

  /// Whether the chip renders as active.
  final bool selected;

  /// Control geometry the chip and the row around it share.
  final TRUiSize uiSize;

  /// Whether the chip drops its label and shows the icon alone.
  ///
  /// The tooltip already names the control, so a narrow toolbar loses width
  /// rather than meaning.
  final bool compact;

  /// Outer width the chip may not exceed, ellipsizing its label to fit.
  ///
  /// A chip whose value is long enough to crowd out its neighbours is capped
  /// here instead, so one wordy model name costs its own label rather than
  /// every label in the row.
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    // The glyph never appears or disappears with selection: a chip that
    // changes width on toggle shifts every chip beside it.
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      spacing: TRSpacing.extraSmall,
      children: <Widget>[
        // Sized from the token the toolbar measures with, so a chip is exactly
        // as wide as the arithmetic that decided it fits.
        Icon(icon, size: TRControlMetrics.iconSizeOf(uiSize)),
        if (!compact) ...<Widget>[
          Flexible(
            // The chip caps and ellipsizes its own label.
            child: TRText.inherit(label, truncate: true),
          ),
          if (menuChildren != null)
            Icon(CoderIcons.expand, size: TRControlMetrics.iconSizeOf(uiSize)),
        ],
      ],
    );
    // Every chip sits inside the composer card, so the toolbar reads as one
    // surface: flat until a chip is active, and never a second nested border.
    final control = menuChildren == null
        ? TRButton(
            key: valueKey,
            appearance: selected ? TRAppearance.solid : TRAppearance.ghost,
            intent: selected ? TRIntent.primary : TRIntent.neutral,
            uiSize: uiSize,
            onPressed: onPressed == null ? null : () => onPressed!(context),
            child: content,
          )
        : TRMenu(
            key: valueKey,
            enabled: menuChildren!.isNotEmpty,
            uiSize: uiSize,
            trigger: content,
            menuChildren: menuChildren!,
          );
    return TRTooltip(
      message: tooltip,
      child: maxWidth == null
          ? control
          : ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth!),
              child: control,
            ),
    );
  }
}

/// Composer shown when no session is selected; the first prompt creates one.
class DraftSessionPane extends ConsumerWidget {
  /// Creates a [DraftSessionPane].
  const DraftSessionPane({
    required this.selection,
    required this.draftId,
    required this.onCreated,
    super.key,
  });

  /// Worktree the new session belongs to.
  final WorkspaceSelection selection;

  /// Stable identity that isolates this draft from drafts in other panes.
  final String draftId;

  /// Called after the session exists and its first turn has started.
  final ValueChanged<SessionDto> onCreated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agentsAsync = ref.watch(
      agentDefinitionsControllerProvider(selection.hostId),
    );
    final agents = agentsAsync.value;
    final agentsLoading = agentsAsync.isLoading && !agentsAsync.hasValue;
    final providersAsync = ref.watch(
      providerSettingsControllerProvider(selection.hostId),
    );
    final providers = providersAsync.value;
    final providersLoading =
        providersAsync.isLoading && !providersAsync.hasValue;
    final draft = ref.watch(
      sessionComposerDraftControllerProvider(
        selection.hostId,
        selection.worktreeId,
        draftId,
      ),
    );
    final definitions = selectableAgentDefinitions(
      agents?.definitions ?? const <AgentDefinitionDto>[],
    );
    final agent =
        definitions
            .where((definition) => definition.id == draft.agentDefinitionId)
            .firstOrNull ??
        definitions.firstOrNull;
    final l10n = AppLocalizations.of(context);
    final connections =
        providers?.connections ?? const <ProviderConnectionDto>[];
    final effective =
        draft.model ??
        effectiveModelFor(
          definition: agent,
          connections: connections,
          models: providers?.models ?? const <String, List<ProviderModelDto>>{},
          defaultModel: providers?.defaultModel,
        );
    final notifier = ref.read(
      sessionComposerDraftControllerProvider(
        selection.hostId,
        selection.worktreeId,
        draftId,
      ).notifier,
    );
    return Column(
      children: <Widget>[
        Expanded(child: Center(child: TRText.inherit(l10n.composerStartHint))),
        ComposerCompletionScope(
          hostId: selection.hostId,
          workspaceId: selection.workspaceId,
          worktreeId: selection.worktreeId,
          excludedClientActions: sessionlessClientActions,
          builder: (context, completion) => SessionComposer(
            commands: completion.commands,
            suggestions: completion.suggestions,
            onCompletionQueryChanged: completion.onQueryChanged,
            onClientCommand: (invocation) => runSessionlessClientCommand(
              context,
              invocation,
              hostId: selection.hostId,
              onToggleMode: () => notifier.selectMode(
                draft.mode == SessionMode.plan
                    ? SessionMode.normal
                    : SessionMode.plan,
              ),
            ),
            enabled: agent != null && effective != null,
            hint: (agentsLoading || providersLoading)
                ? null
                : (agent == null
                      ? l10n.composerNoPrimaryAgent
                      : (effective == null
                            ? l10n.composerConnectProviderFirst
                            : null)),
            bar: SessionComposerBar(
              hostId: selection.hostId,
              definitions: definitions,
              agentDefinitionId: agent?.id,
              selection: effective,
              onAgentChanged: notifier.selectAgent,
              onModelChanged: (selection, controls) {
                notifier
                  ..selectModel(selection)
                  ..selectModelControls(controls);
              },
              mode: draft.mode,
              onModeChanged: notifier.selectMode,
              modelControls: draft.modelControls,
              onModelControlsChanged: notifier.selectModelControls,
              permissionMode: draft.permissionMode,
              onPermissionModeChanged: notifier.selectPermissionMode,
            ),
            onModeToggled: () => notifier.selectMode(
              draft.mode == SessionMode.plan
                  ? SessionMode.normal
                  : SessionMode.plan,
            ),
            attachmentInput: ref.read(attachmentInputProvider),
            onSubmit: (submission) => _start(ref, submission, agent!, draft),
          ),
        ),
      ],
    );
  }

  Future<void> _start(
    WidgetRef ref,
    ComposerSubmission submission,
    AgentDefinitionDto agent,
    SessionComposerDraft draft,
  ) async {
    onCreated(
      await startSessionWithPrompt(
        ref,
        selection: selection,
        agentDefinitionId: agent.id,
        title: deriveSessionTitle(
          submission.text.isEmpty
              ? submission.attachments.first.fileName
              : submission.text,
        ),
        prompt: submission.text,
        attachments: submission.attachments,
        mode: draft.mode,
        model: draft.model,
        modelControls: draft.modelControls,
        permissionMode: draft.permissionMode,
      ),
    );
  }
}

/// Chat input with the agent and model selectors above it.
class SessionComposer extends StatefulWidget {
  /// Creates a [SessionComposer].
  const SessionComposer({
    required this.bar,
    required this.onSubmit,
    required this.enabled,
    this.busy = false,
    this.queued = const <QueuedTurn>[],
    this.onQueue,
    this.onQueuedEdit,
    this.onQueuedSendNow,
    this.onSubmitAndInterrupt,
    this.onModeToggled,
    this.header,
    this.hint,
    this.attachmentInput,
    this.contextTokens = 0,
    this.contextWindow,
    this.commands = const <ComposerCommand>[],
    this.suggestions = ComposerSuggestionsState.closed,
    this.onCompletionQueryChanged,
    this.onClientCommand,
    super.key,
  });

  /// Selector row rendered above the input.
  final SessionComposerBar bar;

  /// Tokens the last response reported for the live context window.
  final int contextTokens;

  /// Context window of the session's model; null hides the meter entirely
  /// rather than showing a percentage of a denominator nobody advertised.
  final int? contextWindow;

  /// Receives the trimmed prompt text.
  final FutureOr<void> Function(ComposerSubmission submission) onSubmit;

  /// Native input boundary; null disables picker, paste, and drop.
  final AttachmentInputPort? attachmentInput;

  /// Whether a turn is running, so a new prompt has to wait its turn.
  final bool busy;

  /// Prompts already waiting for the running turn, oldest first.
  final List<QueuedTurn> queued;

  /// Holds a prompt until the running turn settles.
  ///
  /// When null the composer sends even while [busy], which is what the draft
  /// and new-workspace composers do because they own no session yet.
  final void Function(ComposerSubmission submission)? onQueue;

  /// Takes a waiting prompt back out of the queue for editing.
  final QueuedTurn? Function(String id)? onQueuedEdit;

  /// Stops the running turn and starts a waiting prompt at once.
  final FutureOr<void> Function(String id)? onQueuedSendNow;

  /// Stops the running turn and sends the composed prompt at once.
  final FutureOr<void> Function(ComposerSubmission submission)?
  onSubmitAndInterrupt;

  /// Cycles the collaboration mode, mirroring the Shift+Tab shortcut.
  final VoidCallback? onModeToggled;

  /// Extra selectors rendered above [bar].
  final Widget? header;

  /// Whether the prompt can be typed and sent.
  ///
  /// This is about the session being usable at all, not about a turn being
  /// in flight: a running turn never stops the user from typing ahead.
  final bool enabled;

  /// Reason shown below the input when sending is unavailable.
  final String? hint;

  /// Rows offered for the token being completed; closed by default.
  final ComposerSuggestionsState suggestions;

  /// Reports the token under the caret so a host can search for it.
  final ValueChanged<ComposerTrigger?>? onCompletionQueryChanged;

  /// Runs an app-owned command, reporting whether it consumed the submission.
  ///
  /// A null handler leaves the message to submit as ordinary text, which is
  /// what a composer with no completion catalog wants.
  final Future<bool> Function(ComposerCommandInvocation invocation)?
  onClientCommand;

  /// Commands a whole-message `/name` submission is matched against.
  final List<ComposerCommand> commands;

  @override
  State<SessionComposer> createState() => _SessionComposerState();
}

class _SessionComposerState extends State<SessionComposer> {
  final _controller = TextEditingController();
  final _inputFocus = FocusNode();
  final TRInlineSuggestionsController<String> _suggestions =
      TRInlineSuggestionsController<String>();
  final List<PendingAttachment> _attachments = <PendingAttachment>[];
  bool _submitting = false;
  bool _dragging = false;

  /// Mention the user dismissed, so Enter sends it as prose again.
  Object? _dismissedMention;
  bool _focused = false;
  String? _attachmentError;
  ComposerTrigger? _trigger;

  @override
  void initState() {
    super.initState();
    // A listener rather than onChanged: a completion splices the value
    // programmatically, and that has to re-evaluate the token too.
    _controller.addListener(_handleTextChanged);
  }

  void _handleTextChanged() {
    final trigger = parseComposerTrigger(_controller.value);
    if (trigger == _trigger) return;
    setState(() => _trigger = trigger);
    widget.onCompletionQueryChanged?.call(trigger);
  }

  @override
  void dispose() {
    _inputFocus.dispose();
    _controller
      ..removeListener(_handleTextChanged)
      ..dispose();
    _suggestions.dispose();
    super.dispose();
  }

  /// Splices the chosen row over the token that asked for it.
  void _completeWith(ComposerSuggestion suggestion) {
    final trigger = _trigger;
    if (trigger == null) return;
    _controller.value = applyComposerCompletion(
      value: _controller.value,
      trigger: trigger,
      replacement: suggestion.replacement,
    );
    _inputFocus.requestFocus();
  }

  /// Runs an app-owned command instead of sending, if the text names one.
  Future<bool> _dispatchClientCommand() async {
    final handler = widget.onClientCommand;
    if (handler == null) return false;
    final invocation = parseComposerCommand(
      _controller.text.trim(),
      widget.commands,
    );
    if (invocation == null ||
        invocation.command.kind != ComposerCommandKind.client) {
      return false;
    }
    // A command replaces the whole submission, so an attachment has nowhere
    // to go and silently dropping it would lose the user's work.
    if (_attachments.isNotEmpty) {
      final l10n = AppLocalizations.of(context);
      setState(() => _attachmentError = l10n.composerCommandNoAttachments);
      return true;
    }
    _clear();
    return handler(invocation);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Attaching is about composing the next prompt, so it stays available
    // while a turn runs; only the upload of this prompt takes it away.
    final editable = widget.enabled && !_submitting;
    final queueing = widget.busy && widget.onQueue != null;
    final content = SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          TRSpacing.medium,
          TRSpacing.small,
          TRSpacing.medium,
          TRSpacing.medium,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          spacing: TRSpacing.small,
          children: <Widget>[
            if (widget.header != null) widget.header!,
            TRCard(
              // The card is the control: the prompt, its settings, and send are
              // one thing to the reader, so focus anywhere inside rings all of
              // it. A drop target reads the same way, since this card is where
              // the content lands. The input is plain, so the ring is painted
              // here once rather than around the text as well.
              focused: _focused || _dragging,
              padding: TRCardPadding.sm,
              child: Focus(
                canRequestFocus: false,
                skipTraversal: true,
                onFocusChange: (focused) => setState(() => _focused = focused),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  spacing: TRSpacing.small,
                  children: <Widget>[
                    for (
                      var index = 0;
                      index < widget.queued.length;
                      index += 1
                    )
                      _QueuedTurnRow(
                        slotKey: ValueKey<String>('queued-turn-$index'),
                        turn: widget.queued[index],
                        onEdit: widget.onQueuedEdit == null
                            ? null
                            : () => _editQueued(widget.queued[index].id),
                        onSendNow: widget.onQueuedSendNow == null
                            ? null
                            : () => _sendQueuedNow(widget.queued[index].id),
                      ),
                    ComposerSuggestionsOverlay(
                      state: widget.suggestions,
                      controller: _suggestions,
                      onSelected: _completeWith,
                      onDismissed: () {
                        // Remembered so Enter sends this token as prose. The
                        // key is the sigil position, so typing on into the
                        // same token stays dismissed while a new mention
                        // starts offering completion again.
                        _dismissedMention = parseComposerTrigger(
                          _controller.value,
                        )?.sessionKey;
                        widget.onCompletionQueryChanged?.call(null);
                      },
                      // Shift+Tab cycles the mode instead of moving focus, and
                      // Enter sends rather than opening a line.
                      child: Focus(
                        onKeyEvent: _handleKey,
                        child: TRTextField(
                          key: const ValueKey('session-composer-input'),
                          controller: _controller,
                          focusNode: _inputFocus,
                          appearance: TRFieldAppearance.plain,
                          minLines: 1,
                          maxLines: 8,
                          enabled: widget.enabled,
                          placeholder: l10n.composerInputHint,
                        ),
                      ),
                    ),
                    if (_attachments.isNotEmpty)
                      Wrap(
                        spacing: TRSpacing.extraSmall,
                        runSpacing: TRSpacing.extraSmall,
                        children: <Widget>[
                          for (
                            var index = 0;
                            index < _attachments.length;
                            index += 1
                          )
                            _PendingAttachmentPill(
                              key: ValueKey('pending-attachment-$index'),
                              attachment: _attachments[index],
                              uploading: _submitting,
                              onRemove: _submitting
                                  ? null
                                  : () => setState(
                                      () => _attachments.removeAt(index),
                                    ),
                            ),
                        ],
                      ),
                    if (widget.contextWindow case final window? when window > 0)
                      _ContextMeter(used: widget.contextTokens, window: window),
                    Row(
                      spacing: TRSpacing.small,
                      children: <Widget>[
                        // Attach leads and send stays pinned at the trailing
                        // edge; only the settings between them give up room.
                        Expanded(
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: widget.bar.withLeading(
                              TRIconButton(
                                key: const ValueKey('session-composer-attach'),
                                appearance: TRAppearance.ghost,
                                uiSize: TRUiSize.sm,
                                onPressed:
                                    editable && widget.attachmentInput != null
                                    ? _pickFiles
                                    : null,
                                icon: const Icon(CoderIcons.paperclip),
                                label: l10n.composerAttachLabel,
                              ),
                            ),
                          ),
                        ),
                        TRTooltip(
                          message: queueing
                              ? l10n.composerQueueTooltip
                              : l10n.composerSendLabel,
                          child: TRIconButton(
                            key: const ValueKey('session-composer-send'),
                            intent: TRIntent.primary,
                            uiSize: TRUiSize.sm,
                            loading: _submitting,
                            onPressed: widget.enabled
                                ? () => unawaited(_runDefaultAction())
                                : null,
                            icon: Icon(
                              queueing ? CoderIcons.queue : CoderIcons.send,
                            ),
                            label: queueing
                                ? l10n.composerQueueLabel
                                : l10n.composerSendLabel,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (widget.hint != null)
              TRText(
                widget.hint!,
                variant: TRTextVariant.bodySm,
                color: TRTextColor.danger,
              ),
            if (_attachmentError != null)
              TRText(
                _attachmentError!,
                key: const ValueKey('session-composer-attachment-error'),
                variant: TRTextVariant.bodySm,
                color: TRTextColor.danger,
              ),
          ],
        ),
      ),
    );
    final input = widget.attachmentInput;
    if (input == null || !input.supportsDrop) return content;
    return DropwellRegion(
      enabled: editable,
      onHoverChanged: (hovering) => setState(() => _dragging = hovering),
      onDrop: (files) async {
        setState(() => _dragging = false);
        await _addFiles(input.droppedFiles(files));
      },
      child: content,
    );
  }

  /// Whether Enter sends rather than opening a new line.
  ///
  /// A touch keyboard has no comfortable Shift+Enter, and its Enter key is
  /// where people reach for a line break, so those platforms send by button.
  bool get _submitsOnEnter => switch (Theme.of(context).platform) {
    TargetPlatform.android || TargetPlatform.iOS => false,
    _ => true,
  };

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    // First, so an open list owns Enter, Escape, Tab, and the arrows before
    // sending, dismissing, or the mode toggle can see them.
    if (_suggestions.handleKeyEvent(event) == KeyEventResult.handled) {
      return KeyEventResult.handled;
    }
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final pressed = HardwareKeyboard.instance.logicalKeysPressed;
    final control =
        pressed.contains(LogicalKeyboardKey.controlLeft) ||
        pressed.contains(LogicalKeyboardKey.controlRight) ||
        pressed.contains(LogicalKeyboardKey.metaLeft) ||
        pressed.contains(LogicalKeyboardKey.metaRight);
    final shift =
        pressed.contains(LogicalKeyboardKey.shiftLeft) ||
        pressed.contains(LogicalKeyboardKey.shiftRight);

    if (event.logicalKey == LogicalKeyboardKey.keyV && control) {
      final input = widget.attachmentInput;
      if (input != null) unawaited(_addFiles(input.pasteFiles()));
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.enter) {
      // A Korean or Japanese composition ends on the same Enter that would
      // otherwise send a half-written word.
      if (!_submitsOnEnter ||
          shift ||
          !widget.enabled ||
          _controller.value.composing.isValid) {
        return KeyEventResult.ignored;
      }
      // An unfinished `@` mention keeps Enter even when its list is not up
      // yet: the search is debounced and asynchronous, so the list can be
      // frames behind the keystroke that asked for it. Sending here would
      // fire the half-typed mention as prose and clear the field, losing the
      // prompt the user was still writing. The text is the signal rather than
      // the list, because the list is what flickers. Escape still hands the
      // token back to prose, and `/` is left alone; it dispatches on its own.
      final mention = parseComposerTrigger(_controller.value);
      if (mention != null &&
          mention.kind == ComposerTriggerKind.file &&
          mention.sessionKey != _dismissedMention) {
        return KeyEventResult.handled;
      }
      unawaited(control ? _runAlternateAction() : _runDefaultAction());
      return KeyEventResult.handled;
    }

    final toggle = widget.onModeToggled;
    if (toggle == null ||
        event.logicalKey != LogicalKeyboardKey.tab ||
        !shift) {
      return KeyEventResult.ignored;
    }
    toggle();
    return KeyEventResult.handled;
  }

  Future<void> _pickFiles() async {
    final input = widget.attachmentInput;
    if (input != null) await _addFiles(input.pickFiles());
  }

  Future<void> _addFiles(Future<List<PendingAttachment>> pending) async {
    try {
      final files = await pending;
      if (_attachments.length + files.length > maxPendingAttachmentCount) {
        throw const FormatException('A turn accepts at most 10 attachments.');
      }
      if (!mounted) return;
      setState(() {
        _attachmentError = null;
        _attachments.addAll(files);
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() => _attachmentError = '$error');
    }
  }

  ComposerSubmission? _take() {
    final text = _controller.text.trim();
    if (text.isEmpty && _attachments.isEmpty) return null;
    return ComposerSubmission(
      // The single place a skill or agent command becomes its prompt, so
      // every call site gets the expansion without repeating it.
      text: renderComposerPrompt(text, widget.commands),
      attachments: List<PendingAttachment>.unmodifiable(_attachments),
    );
  }

  /// Puts an unsent prompt back so a failure never loses what was typed.
  void _restore(ComposerSubmission submission) {
    _controller.text = submission.text;
    setState(() {
      _attachments
        ..clear()
        ..addAll(submission.attachments);
    });
  }

  void _clear() {
    _controller.clear();
    setState(() {
      _attachments.clear();
      _attachmentError = null;
    });
  }

  /// Sends, or holds the prompt for the running turn.
  Future<void> _runDefaultAction() async {
    // Ahead of the queue branch: an app-owned command acts on the app, so it
    // works while a turn runs and must never be held for one.
    if (await _dispatchClientCommand()) return;
    final queue = widget.onQueue;
    if (widget.busy && queue != null) {
      final submission = _take();
      if (submission == null) return;
      _clear();
      queue(submission);
      return;
    }
    await _submit(widget.onSubmit);
  }

  /// Sends past a running turn, stopping it first.
  Future<void> _runAlternateAction() async {
    final interrupt = widget.onSubmitAndInterrupt;
    if (widget.busy && interrupt != null) {
      await _submit(interrupt);
      return;
    }
    await _runDefaultAction();
  }

  Future<void> _submit(
    FutureOr<void> Function(ComposerSubmission submission) send,
  ) async {
    final submission = _take();
    if (submission == null) return;
    // Cleared before the upload starts: the prompt reads as sent, and a
    // failure puts it back rather than freezing it in the field.
    _clear();
    setState(() => _submitting = true);
    try {
      await send(submission);
    } on Exception catch (error) {
      if (!mounted) return;
      _restore(submission);
      setState(() => _attachmentError = '$error');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _sendQueuedNow(String id) async {
    try {
      await widget.onQueuedSendNow!(id);
    } on Exception catch (error) {
      if (mounted) setState(() => _attachmentError = '$error');
    }
  }

  void _editQueued(String id) {
    final taken = widget.onQueuedEdit?.call(id);
    if (taken == null) return;
    _controller.text = taken.text;
    setState(() {
      _attachments
        ..clear()
        ..addAll(taken.attachments);
    });
    _inputFocus.requestFocus();
  }
}

/// One prompt waiting for the running turn, shown above the input.
/// How much of the model's context window the session has spent.
///
/// The number is the last response's own total, not a running sum, so it drops
/// back to zero whenever the agent starts a new window.
class _ContextMeter extends StatelessWidget {
  const _ContextMeter({required this.used, required this.window});

  /// Tokens reported for the live window.
  final int used;

  /// Size of the window; always greater than zero at this point.
  final int window;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final percent = ((used / window) * 100).round().clamp(0, 100);
    return TRMeter(
      key: const ValueKey<String>('session-composer-context-meter'),
      value: used.toDouble().clamp(0, window.toDouble()),
      max: window.toDouble(),
      label: l10n.sessionContextMeter,
      valueText: l10n.sessionContextMeterValue(percent),
      // Warn while there is still room to react, and only call it dangerous
      // once a long tool result could no longer fit.
      variant: switch (percent) {
        >= 95 => TRStatusVariant.danger,
        >= 80 => TRStatusVariant.warning,
        _ => TRStatusVariant.neutral,
      },
    );
  }
}

class _QueuedTurnRow extends StatelessWidget {
  const _QueuedTurnRow({
    required this.slotKey,
    required this.turn,
    required this.onEdit,
    required this.onSendNow,
  }) : super(key: slotKey);

  /// Position-stable key the actions extend for their own keys.
  final ValueKey<String> slotKey;
  final QueuedTurn turn;
  final VoidCallback? onEdit;
  final VoidCallback? onSendNow;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TRCard(
      padding: TRCardPadding.sm,
      variant: TRCardVariant.elevated,
      child: Row(
        spacing: TRSpacing.extraSmall,
        children: <Widget>[
          const Icon(CoderIcons.queue),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              spacing: TRSpacing.extraSmall,
              children: <Widget>[
                Text(
                  turn.text.isEmpty
                      ? l10n.composerQueuedAttachments(turn.attachments.length)
                      : turn.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                // A prompt that has stopped retrying looks exactly like one
                // waiting its turn, so the reason is what tells the reader
                // there is something to act on.
                if (turn.error case final error?)
                  TRText(
                    l10n.composerQueuedFailed(error),
                    key: ValueKey<String>('${slotKey.value}-error'),
                    variant: TRTextVariant.bodySm,
                    color: TRTextColor.danger,
                  ),
              ],
            ),
          ),
          TRTooltip(
            message: l10n.composerQueuedEdit,
            child: TRIconButton(
              key: ValueKey('${slotKey.value}-edit'),
              appearance: TRAppearance.ghost,
              onPressed: onEdit,
              icon: const Icon(CoderIcons.edit),
              label: l10n.composerQueuedEdit,
            ),
          ),
          TRTooltip(
            message: l10n.composerQueuedSendNow,
            child: TRIconButton(
              key: ValueKey('${slotKey.value}-send'),
              appearance: TRAppearance.ghost,
              onPressed: onSendNow,
              icon: const Icon(CoderIcons.send),
              label: l10n.composerQueuedSendNow,
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingAttachmentPill extends StatelessWidget {
  const _PendingAttachmentPill({
    required this.attachment,
    required this.uploading,
    required this.onRemove,
    super.key,
  });

  final PendingAttachment attachment;
  final bool uploading;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: TRMeasurements.measureMd),
    child: TRCard(
      padding: TRCardPadding.sm,
      variant: TRCardVariant.elevated,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: TRSpacing.extraSmall,
        children: <Widget>[
          if (uploading)
            const TRSpinner()
          else
            _PendingAttachmentPreview(attachment: attachment),
          Flexible(
            child: TRText.inherit(
              '${attachment.fileName} · ${_formatBytes(attachment.byteSize)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TRIconButton(
            key: ValueKey('remove-${attachment.fileName}'),
            appearance: TRAppearance.ghost,
            onPressed: onRemove,
            icon: const Icon(CoderIcons.close),
            label: 'Remove ${attachment.fileName}',
          ),
        ],
      ),
    ),
  );
}

class _PendingAttachmentPreview extends StatefulWidget {
  const _PendingAttachmentPreview({required this.attachment});

  final PendingAttachment attachment;

  @override
  State<_PendingAttachmentPreview> createState() =>
      _PendingAttachmentPreviewState();
}

class _PendingAttachmentPreviewState extends State<_PendingAttachmentPreview> {
  Future<Uint8List>? _bytes;

  @override
  void initState() {
    super.initState();
    if (widget.attachment.isImage) _bytes = _read();
  }

  Future<Uint8List> _read() async {
    final builder = BytesBuilder(copy: false);
    await widget.attachment.openRead().forEach(builder.add);
    return builder.takeBytes();
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    if (bytes == null) return const Icon(CoderIcons.file);
    return FutureBuilder<Uint8List>(
      future: bytes,
      builder: (context, snapshot) => snapshot.hasData
          ? ClipRRect(
              borderRadius: const BorderRadius.all(TRRadii.extraSmall),
              child: Image.memory(
                snapshot.data!,
                // The thumbnail matches the icon it replaces, so a loaded
                // preview never reflows the pill.
                width: IconTheme.of(context).size,
                height: IconTheme.of(context).size,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(CoderIcons.image),
              ),
            )
          : const TRSpinner(),
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
