import 'package:protocol/protocol.dart';

/// Decodes one durable `plugin.ui` event without requiring plugin source.
PluginUiDocumentDto? pluginUiDocumentFromEvent(TimelineEventDto event) {
  if (event.type != 'plugin.ui') return null;
  return pluginUiDocumentFromJson(event.data['document']);
}

/// Decodes a revision-pinned declarative UI document from JSON-compatible data.
PluginUiDocumentDto? pluginUiDocumentFromJson(Object? value) {
  if (value is PluginUiDocumentDto) return value;
  if (value is! Map<dynamic, dynamic>) return null;
  final id = value['id'];
  final pluginId = value['pluginId'];
  final revisionHash = value['revisionHash'];
  final slotName = value['slot'];
  final root = value['root'];
  final slots = PluginUiSlot.values.where((slot) => slot.name == slotName);
  if (id is! String ||
      id.isEmpty ||
      pluginId is! String ||
      pluginId.isEmpty ||
      revisionHash is! String ||
      revisionHash.isEmpty ||
      slots.length != 1 ||
      root is! Map<dynamic, dynamic> ||
      !root.keys.every((key) => key is String)) {
    return null;
  }
  return PluginUiDocumentDto(
    id: id,
    pluginId: pluginId,
    revisionHash: revisionHash,
    slot: slots.single,
    root: Map<String, dynamic>.unmodifiable(
      root.map((key, item) => MapEntry(key! as String, item)),
    ),
  );
}
