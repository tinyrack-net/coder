import 'dart:async';
import 'dart:convert';

import 'package:app/src/features/conversation/presentation/chat_markdown.dart';
import 'package:app/src/shared/presentation/tinest_select_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:protocol/protocol.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// Dispatches one action through the host and returns the next UI snapshot.
typedef PluginUiActionDispatcher = Future<PluginUiDocumentDto> Function(
  PluginUiActionDto action,
);

/// Renders a pinned declarative plugin document using only public host widgets.
///
/// The document is parsed completely before any control is built. One invalid
/// node therefore sends the entire document to a non-interactive disclosure
/// instead of leaving a partially trusted interface on screen.
class PluginUiDocumentView extends StatefulWidget {
  /// Creates a host-rendered plugin document.
  const PluginUiDocumentView({
    required this.document,
    required this.invalidDocumentLabel,
    required this.invalidDocumentDescription,
    this.semanticLabel,
    this.onAction,
    super.key,
  });

  /// Immutable document snapshot emitted by a pinned plugin revision.
  final PluginUiDocumentDto document;

  /// Host-localized label for the invalid-document fallback.
  final String invalidDocumentLabel;

  /// Host-localized supporting text for the invalid-document fallback.
  final String invalidDocumentDescription;

  /// Host-owned accessible name for this surface.
  final String? semanticLabel;

  /// Host action dispatcher. Interactive nodes are disabled when absent.
  final PluginUiActionDispatcher? onAction;

  @override
  State<PluginUiDocumentView> createState() => _PluginUiDocumentViewState();
}

class _PluginUiDocumentViewState extends State<PluginUiDocumentView> {
  _UiNode? _root;
  Object? _parseError;
  Map<String, dynamic> _values = <String, dynamic>{};
  String? _busyActionId;

  @override
  void initState() {
    super.initState();
    _load(widget.document);
  }

  @override
  void didUpdateWidget(PluginUiDocumentView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.document != widget.document) _load(widget.document);
  }

  void _load(PluginUiDocumentDto document) {
    try {
      final parser = _PluginUiParser();
      _root = parser.parse(document.root);
      _values = parser.initialValues;
      _parseError = null;
    } on Object catch (error) {
      _root = null;
      _values = <String, dynamic>{};
      _parseError = error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final root = _root;
    final child = root == null
        ? _InvalidPluginUiDocument(
            document: widget.document,
            label: widget.invalidDocumentLabel,
            description: widget.invalidDocumentDescription,
            error: _parseError,
          )
        : _buildNode(context, root);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: widget.semanticLabel,
      child: child,
    );
  }

  Widget _buildNode(BuildContext context, _UiNode node) => switch (node.type) {
    _UiNodeType.section => _PluginUiSection(
      title: node.string('title'),
      description: node.string('description'),
      children: node.children
          .map((child) => _buildNode(context, child))
          .toList(growable: false),
    ),
    _UiNodeType.row => Wrap(
      spacing: TRSpacing.small,
      runSpacing: TRSpacing.small,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: node.children
          .map((child) => _buildNode(context, child))
          .toList(growable: false),
    ),
    _UiNodeType.text => TRText(
      node.requiredString('text'),
      variant: _textVariant(node.string('variant')),
      color: _textColor(node.string('color')),
    ),
    _UiNodeType.markdown => MarkdownBody(
      data: node.requiredString('text'),
      selectable: true,
      builders: chatMarkdownBuilders(),
      styleSheet: chatMarkdownStyleSheet(context),
    ),
    _UiNodeType.code || _UiNodeType.diff => TRCodeBlock(
      code: node.requiredString('code'),
      language: node.type == _UiNodeType.diff
          ? 'diff'
          : node.string('language'),
      wrap: node.boolean('wrap') ?? false,
    ),
    _UiNodeType.alert => TRAlert(
      title: TRText.inherit(node.requiredString('title')),
      description: node.string('description') == null
          ? null
          : TRText.inherit(node.requiredString('description')),
      variant: _statusVariant(node.string('variant')),
    ),
    _UiNodeType.badge => TRBadge(
      variant: _statusVariant(node.string('variant')),
      child: TRText.inherit(node.requiredString('text')),
    ),
    _UiNodeType.progress => ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: TRMeasurements.measureSm),
      child: TRProgress(
        value: node.number('value')?.toDouble(),
        min: node.number('min')?.toDouble() ?? 0,
        max: node.number('max')?.toDouble() ?? 100,
        label: node.string('label'),
        variant: _statusVariant(node.string('variant')),
      ),
    ),
    _UiNodeType.disclosure => TRCollapsible(
      defaultOpen: node.boolean('open') ?? false,
      trigger: TRText.inherit(node.requiredString('title')),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: TRSpacing.medium,
        children: node.children
            .map((child) => _buildNode(context, child))
            .toList(growable: false),
      ),
    ),
    _UiNodeType.field => _field(node),
    _UiNodeType.button => TRButton(
      intent: _intent(node.string('intent')),
      appearance: _appearance(node.string('appearance')),
      loading: _busyActionId == node.requiredString('actionId'),
      loadingLabel: node.string('loadingLabel'),
      onPressed: widget.onAction == null || _busyActionId != null
          ? null
          : () => unawaited(_dispatch(node)),
      child: TRText.inherit(node.requiredString('label')),
    ),
    _UiNodeType.switchControl => _switch(node),
    _UiNodeType.select => _select(node),
  };

  Widget _field(_UiNode node) {
    final id = node.requiredString('id');
    return TRField(
      label: node.string('label'),
      description: node.string('description'),
      disabled: node.boolean('disabled') ?? false,
      control: TRTextField(
        key: ValueKey<String>('plugin-ui-${widget.document.id}-$id'),
        initialValue: _values[id] as String?,
        placeholder: node.string('placeholder'),
        enabled: !(node.boolean('disabled') ?? false),
        readOnly: node.boolean('readOnly') ?? false,
        onChanged: (value) => _values[id] = value,
      ),
    );
  }

  Widget _switch(_UiNode node) {
    final id = node.requiredString('id');
    final disabled =
        widget.onAction == null ||
        _busyActionId != null ||
        (node.boolean('disabled') ?? false);
    return TRField(
      label: node.string('label'),
      description: node.string('description'),
      disabled: disabled,
      control: TRSwitch(
        checked: _values[id]! as bool,
        semanticLabel: node.string('label'),
        disabled: disabled,
        readOnly: node.boolean('readOnly') ?? false,
        onCheckedChange: (value) {
          setState(() => _values[id] = value);
          if (node.string('actionId') != null) {
            unawaited(_dispatch(node, value: value));
          }
        },
      ),
    );
  }

  Widget _select(_UiNode node) {
    final id = node.requiredString('id');
    final value = _values[id] as String?;
    final options = node.options;
    final disabled =
        widget.onAction == null ||
        _busyActionId != null ||
        (node.boolean('disabled') ?? false);
    return TRField(
      label: node.string('label'),
      description: node.string('description'),
      disabled: disabled,
      control: TRSelect<String>.controlled(
        searchable: true,
        presentation: TinestSelectPresentation.resolve(context),
        value: value,
        placeholder: node.string('placeholder'),
        enabled: !disabled,
        readOnly: node.boolean('readOnly') ?? false,
        items: options
            .map(
              (option) => TRSelectItem<String>(
                value: option.value,
                label: option.label,
                enabled: option.enabled,
              ),
            )
            .toList(growable: false),
        onValueChange: (next) {
          if (next == null) return;
          setState(() => _values[id] = next);
          if (node.string('actionId') != null) {
            unawaited(_dispatch(node, value: next));
          }
        },
      ),
    );
  }

  Future<void> _dispatch(_UiNode node, {Object? value}) async {
    final dispatcher = widget.onAction;
    final actionId = node.string('actionId');
    if (dispatcher == null || actionId == null || _busyActionId != null) return;
    setState(() => _busyActionId = actionId);
    try {
      final data = <String, dynamic>{
        ...node.actionData,
        'value': ?value,
        'values': Map<String, dynamic>.unmodifiable(_values),
      };
      final next = await dispatcher(
        PluginUiActionDto(
          documentId: widget.document.id,
          actionId: actionId,
          data: data,
        ),
      );
      if (!mounted) return;
      setState(() {
        _load(next);
        _busyActionId = null;
      });
    } on Object {
      if (mounted) setState(() => _busyActionId = null);
      rethrow;
    }
  }
}

class _PluginUiSection extends StatelessWidget {
  const _PluginUiSection({
    required this.title,
    required this.description,
    required this.children,
  });

  final String? title;
  final String? description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => TRCard(
    padding: TRCardPadding.lg,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: TRSpacing.medium,
      children: <Widget>[
        if (title != null || description != null)
          TRCardHeader(
            children: <Widget>[
              if (title case final title?)
                TRCardTitle(child: TRText.inherit(title)),
              if (description case final description?)
                TRCardDescription(child: TRText.inherit(description)),
            ],
          ),
        ...children,
      ],
    ),
  );
}

class _InvalidPluginUiDocument extends StatelessWidget {
  const _InvalidPluginUiDocument({
    required this.document,
    required this.label,
    required this.description,
    required this.error,
  });

  final PluginUiDocumentDto document;
  final String label;
  final String description;
  final Object? error;

  @override
  Widget build(BuildContext context) => TRCollapsible(
    trigger: TRText.inherit(label),
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: TRSpacing.medium,
      children: <Widget>[
        TRText(description, color: TRTextColor.muted),
        TRCodeBlock(
          code: const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
            'document': document.toJson(),
            if (error != null) 'validationError': '$error',
          }),
          language: 'json',
          wrap: true,
        ),
      ],
    ),
  );
}

enum _UiNodeType {
  section,
  row,
  text,
  markdown,
  code,
  diff,
  alert,
  badge,
  progress,
  disclosure,
  field,
  button,
  switchControl,
  select,
}

final class _UiOption {
  const _UiOption({
    required this.value,
    required this.label,
    required this.enabled,
  });

  final String value;
  final String label;
  final bool enabled;
}

final class _UiNode {
  const _UiNode({
    required this.type,
    required this.values,
    this.children = const <_UiNode>[],
    this.options = const <_UiOption>[],
    this.actionData = const <String, dynamic>{},
  });

  final _UiNodeType type;
  final Map<String, Object?> values;
  final List<_UiNode> children;
  final List<_UiOption> options;
  final Map<String, dynamic> actionData;

  String requiredString(String key) => values[key]! as String;
  String? string(String key) => values[key] as String?;
  bool? boolean(String key) => values[key] as bool?;
  num? number(String key) => values[key] as num?;
}

final class _PluginUiParser {
  static const int _maxDepth = 24;
  static const int _maxNodes = 256;

  final Set<String> _controlIds = <String>{};
  final Map<String, dynamic> _initialValues = <String, dynamic>{};
  int _nodeCount = 0;

  Map<String, dynamic> get initialValues =>
      Map<String, dynamic>.unmodifiable(_initialValues);

  _UiNode parse(Map<String, dynamic> root) => _parseNode(root, depth: 0);

  _UiNode _parseNode(Object? raw, {required int depth}) {
    if (depth > _maxDepth) {
      throw const FormatException('Plugin UI exceeds the nesting limit.');
    }
    _nodeCount += 1;
    if (_nodeCount > _maxNodes) {
      throw const FormatException('Plugin UI exceeds the node limit.');
    }
    final map = _map(raw, 'node');
    final typeName = _requiredString(map, 'type');
    final type = switch (typeName) {
      'section' => _UiNodeType.section,
      'row' => _UiNodeType.row,
      'text' => _UiNodeType.text,
      'markdown' => _UiNodeType.markdown,
      'code' => _UiNodeType.code,
      'diff' => _UiNodeType.diff,
      'alert' => _UiNodeType.alert,
      'badge' => _UiNodeType.badge,
      'progress' => _UiNodeType.progress,
      'disclosure' => _UiNodeType.disclosure,
      'field' || 'form_field' => _UiNodeType.field,
      'button' => _UiNodeType.button,
      'switch' => _UiNodeType.switchControl,
      'select' => _UiNodeType.select,
      _ => throw FormatException('Unsupported plugin UI node: $typeName'),
    };
    final values = <String, Object?>{'type': typeName};
    var children = const <_UiNode>[];
    var options = const <_UiOption>[];
    var actionData = const <String, dynamic>{};

    switch (type) {
      case _UiNodeType.section:
        _copyOptionalString(map, values, 'title');
        _copyOptionalString(map, values, 'description');
        children = _children(map, depth);
      case _UiNodeType.row:
        children = _children(map, depth);
      case _UiNodeType.text:
        values['text'] = _requiredString(map, 'text');
        _copyEnum(
          map,
          values,
          'variant',
          const <String>{
            'body',
            'bodySm',
            'caption',
            'code',
            'headingSm',
            'headingMd',
            'headingLg',
            'label',
          },
        );
        _copyEnum(
          map,
          values,
          'color',
          const <String>{
            'default',
            'muted',
            'primary',
            'info',
            'success',
            'warning',
            'danger',
          },
        );
      case _UiNodeType.markdown:
        values['text'] = _requiredString(map, 'text');
      case _UiNodeType.code || _UiNodeType.diff:
        values['code'] = _requiredString(map, 'code');
        _copyOptionalString(map, values, 'language');
        _copyOptionalBool(map, values, 'wrap');
      case _UiNodeType.alert:
        values['title'] = _requiredString(map, 'title');
        _copyOptionalString(map, values, 'description');
        _copyStatusVariant(map, values);
      case _UiNodeType.badge:
        values['text'] = _requiredString(map, 'text');
        _copyStatusVariant(map, values);
      case _UiNodeType.progress:
        _copyOptionalString(map, values, 'label');
        _copyOptionalNum(map, values, 'value');
        _copyOptionalNum(map, values, 'min');
        _copyOptionalNum(map, values, 'max');
        _copyStatusVariant(map, values);
        final min = values['min'] as num? ?? 0;
        final max = values['max'] as num? ?? 100;
        if (max <= min) {
          throw const FormatException('Progress max must be greater than min.');
        }
      case _UiNodeType.disclosure:
        values['title'] = _requiredString(map, 'title');
        _copyOptionalBool(map, values, 'open');
        children = _children(map, depth);
      case _UiNodeType.field:
        final id = _controlId(map, values);
        _copyOptionalString(map, values, 'label');
        _copyOptionalString(map, values, 'description');
        _copyOptionalString(map, values, 'placeholder');
        _copyOptionalBool(map, values, 'disabled');
        _copyOptionalBool(map, values, 'readOnly');
        final value = map['value'];
        if (value != null && value is! String) {
          throw const FormatException('Field value must be a string.');
        }
        _initialValues[id] = value as String? ?? '';
      case _UiNodeType.button:
        values['label'] = _requiredString(map, 'label');
        values['actionId'] = _requiredString(map, 'actionId');
        _copyOptionalString(map, values, 'loadingLabel');
        _copyEnum(
          map,
          values,
          'intent',
          const <String>{
            'neutral',
            'primary',
            'info',
            'success',
            'warning',
            'danger',
          },
        );
        _copyEnum(
          map,
          values,
          'appearance',
          const <String>{'solid', 'outline', 'ghost'},
        );
        actionData = _optionalMap(map['data'], 'button data');
      case _UiNodeType.switchControl:
        final id = _controlId(map, values);
        _copyOptionalString(map, values, 'label');
        _copyOptionalString(map, values, 'description');
        _copyOptionalString(map, values, 'actionId');
        _copyOptionalBool(map, values, 'disabled');
        _copyOptionalBool(map, values, 'readOnly');
        final value = map['value'];
        if (value is! bool) {
          throw const FormatException('Switch value must be a boolean.');
        }
        _initialValues[id] = value;
        actionData = _optionalMap(map['data'], 'switch data');
      case _UiNodeType.select:
        final id = _controlId(map, values);
        _copyOptionalString(map, values, 'label');
        _copyOptionalString(map, values, 'description');
        _copyOptionalString(map, values, 'placeholder');
        _copyOptionalString(map, values, 'actionId');
        _copyOptionalBool(map, values, 'disabled');
        _copyOptionalBool(map, values, 'readOnly');
        final rawOptions = map['options'];
        if (rawOptions is! List<Object?> || rawOptions.isEmpty) {
          throw const FormatException(
            'Select options must be a non-empty list.',
          );
        }
        final optionIds = <String>{};
        options = rawOptions
            .map((rawOption) {
              final option = _map(rawOption, 'select option');
              final value = _requiredString(option, 'value');
              if (!optionIds.add(value)) {
                throw FormatException('Duplicate select option: $value');
              }
              return _UiOption(
                value: value,
                label: _requiredString(option, 'label'),
                enabled: _optionalBool(option, 'enabled') ?? true,
              );
            })
            .toList(growable: false);
        final selected = map['value'];
        if (selected != null && selected is! String) {
          throw const FormatException('Select value must be a string.');
        }
        if (selected != null && !optionIds.contains(selected)) {
          throw const FormatException('Select value must name an option.');
        }
        _initialValues[id] = selected;
        actionData = _optionalMap(map['data'], 'select data');
    }
    return _UiNode(
      type: type,
      values: Map<String, Object?>.unmodifiable(values),
      children: List<_UiNode>.unmodifiable(children),
      options: List<_UiOption>.unmodifiable(options),
      actionData: Map<String, dynamic>.unmodifiable(actionData),
    );
  }

  List<_UiNode> _children(Map<String, dynamic> map, int depth) {
    final raw = map['children'];
    if (raw is! List<Object?>) {
      throw const FormatException('Container children must be a list.');
    }
    return raw
        .map((child) => _parseNode(child, depth: depth + 1))
        .toList(growable: false);
  }

  String _controlId(
    Map<String, dynamic> map,
    Map<String, Object?> values,
  ) {
    final id = _requiredString(map, 'id');
    if (!_controlIds.add(id)) {
      throw FormatException('Duplicate plugin UI control ID: $id');
    }
    values['id'] = id;
    return id;
  }

  void _copyStatusVariant(
    Map<String, dynamic> map,
    Map<String, Object?> values,
  ) => _copyEnum(
    map,
    values,
    'variant',
    const <String>{'neutral', 'info', 'success', 'warning', 'danger'},
  );
}

Map<String, dynamic> _map(Object? value, String label) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map<Object?, Object?> &&
      value.keys.every((key) => key is String)) {
    return value.map((key, value) => MapEntry(key! as String, value));
  }
  throw FormatException('$label must be an object.');
}

Map<String, dynamic> _optionalMap(Object? value, String label) =>
    value == null ? const <String, dynamic>{} : _map(value, label);

String _requiredString(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$key must be a non-empty string.');
  }
  return value;
}

void _copyOptionalString(
  Map<String, dynamic> source,
  Map<String, Object?> target,
  String key,
) {
  final value = source[key];
  if (value == null) return;
  if (value is! String) throw FormatException('$key must be a string.');
  target[key] = value;
}

void _copyOptionalBool(
  Map<String, dynamic> source,
  Map<String, Object?> target,
  String key,
) {
  final value = source[key];
  if (value == null) return;
  if (value is! bool) throw FormatException('$key must be a boolean.');
  target[key] = value;
}

bool? _optionalBool(Map<String, dynamic> source, String key) {
  final value = source[key];
  if (value == null) return null;
  if (value is! bool) throw FormatException('$key must be a boolean.');
  return value;
}

void _copyOptionalNum(
  Map<String, dynamic> source,
  Map<String, Object?> target,
  String key,
) {
  final value = source[key];
  if (value == null) return;
  if (value is! num || !value.isFinite) {
    throw FormatException('$key must be a finite number.');
  }
  target[key] = value;
}

void _copyEnum(
  Map<String, dynamic> source,
  Map<String, Object?> target,
  String key,
  Set<String> allowed,
) {
  final value = source[key];
  if (value == null) return;
  if (value is! String || !allowed.contains(value)) {
    throw FormatException('Unsupported $key: $value');
  }
  target[key] = value;
}

TRStatusVariant _statusVariant(String? value) => switch (value) {
  'info' => TRStatusVariant.info,
  'success' => TRStatusVariant.success,
  'warning' => TRStatusVariant.warning,
  'danger' => TRStatusVariant.danger,
  _ => TRStatusVariant.neutral,
};

TRIntent _intent(String? value) => switch (value) {
  'primary' => TRIntent.primary,
  'info' => TRIntent.info,
  'success' => TRIntent.success,
  'warning' => TRIntent.warning,
  'danger' => TRIntent.danger,
  _ => TRIntent.neutral,
};

TRAppearance _appearance(String? value) => switch (value) {
  'outline' => TRAppearance.outline,
  'ghost' => TRAppearance.ghost,
  _ => TRAppearance.solid,
};

TRTextVariant _textVariant(String? value) => switch (value) {
  'bodySm' => TRTextVariant.bodySm,
  'caption' => TRTextVariant.caption,
  'code' => TRTextVariant.code,
  'headingSm' => TRTextVariant.headingSm,
  'headingMd' => TRTextVariant.headingMd,
  'headingLg' => TRTextVariant.headingLg,
  'label' => TRTextVariant.label,
  _ => TRTextVariant.body,
};

TRTextColor? _textColor(String? value) => switch (value) {
  'default' => TRTextColor.defaultColor,
  'muted' => TRTextColor.muted,
  'primary' => TRTextColor.primary,
  'info' => TRTextColor.info,
  'success' => TRTextColor.success,
  'warning' => TRTextColor.warning,
  'danger' => TRTextColor.danger,
  _ => null,
};
