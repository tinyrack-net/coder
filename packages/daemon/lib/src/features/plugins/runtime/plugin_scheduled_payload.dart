import 'package:daemon/src/features/plugins/runtime/plugin_json_schema.dart';
import 'package:daemon/src/features/plugins/runtime/plugin_registration.dart';

/// Resolves one exact revision-local scheduled handler binding.
PluginHookRegistration resolvePluginScheduledHandler({
  required PluginRegistration registration,
  required String pluginId,
  required String executionRevisionHash,
  required String bindingId,
}) {
  if (registration.descriptor.id != pluginId ||
      registration.revisionHash != executionRevisionHash) {
    throw StateError(
      'Scheduled handler revision is not pinned: '
      '$pluginId@$executionRevisionHash.',
    );
  }
  final matches = registration.hooks.where(
    (hook) =>
        hook.lifecycle == PluginLifecycle.scheduled &&
        hook.binding.localId == bindingId &&
        hook.binding.pluginId == pluginId &&
        hook.binding.executionRevisionHash == executionRevisionHash,
  );
  if (matches.length != 1) {
    throw StateError(
      'Binding is not the registered scheduled hook for '
      '$pluginId@$executionRevisionHash: $bindingId.',
    );
  }
  return matches.single;
}

/// Normalizes and validates a durable payload against its exact handler.
Map<String, dynamic> validatePluginScheduledPayload(
  PluginHookRegistration handler,
  Object? value, {
  required String path,
}) {
  final object = value is List<Object?> && value.isEmpty
      ? const <String, Object?>{}
      : value;
  final normalized = normalizePluginJson(object, path: path);
  if (normalized is! Map<String, Object?>) {
    throw PluginJsonValidationException(
      'Scheduled handler payload must be an object.',
      path: path,
    );
  }
  final schema = handler.payloadSchema;
  if (schema != null) {
    validatePluginJsonSchema(schema, normalized, path: path);
  }
  return Map<String, dynamic>.unmodifiable(normalized);
}
