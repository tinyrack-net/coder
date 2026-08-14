import 'package:app/src/features/providers/application/provider_settings_controller.dart';
import 'package:app/src/features/providers/application/session_model_options.dart';
import 'package:app/src/shared/presentation/model_picker.dart';
import 'package:protocol/protocol.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'model_picker_options.g.dart';

/// Loads every provider-qualified model the user may currently pick.
///
/// Exposed as a loader rather than as the option list itself because opening
/// the picker must fetch what is missing right then; a plain `FutureProvider`
/// would answer the second open from cache. The `Ref` handed to [_load] is this
/// provider's, so the fetch below is bound to the provider's lifetime rather
/// than to whichever widget happened to open the picker.
///
/// `keepAlive` for that same reason: callers read the loader and invoke it
/// later, so an auto-disposed provider would hand out a closure over a `Ref`
/// that is already gone. It holds no state and is keyed only by host.
@Riverpod(keepAlive: true)
ModelPickerOptionsLoader modelPickerOptionsLoader(Ref ref, String hostId) =>
    () => _load(ref, hostId);

/// Model catalogs load per connection, so this fills in the connections whose
/// lists are still missing before flattening them. The composer, agent editor,
/// and daemon model settings all offer the same runnable options.
Future<List<ModelPickerOption>> _load(Ref ref, String hostId) async {
  final controller = providerSettingsControllerProvider(hostId);
  await ref.read(controller.future);
  final connections = usableConnections(
    ref.read(controller).value?.connections ?? const <ProviderConnectionDto>[],
  );
  final notifier = ref.read(controller.notifier);
  final known = ref.read(controller).value?.models;
  await Future.wait<void>(
    connections
        .where((connection) => known?[connection.id] == null)
        .map((connection) => notifier.loadModels(connection.id)),
  );
  final loaded = ref.read(controller).value;
  final options = <ModelPickerOption>[];
  for (final connection in connections) {
    final models =
        <ProviderModelDto>[
          ...loaded?.models[connection.id] ?? const <ProviderModelDto>[],
        ]..sort((left, right) {
          final byLabel = left.label.compareTo(right.label);
          return byLabel != 0 ? byLabel : left.id.compareTo(right.id);
        });
    options.addAll(
      models
          .where(
            (model) =>
                model.capabilities.streaming == CapabilitySupport.supported &&
                model.capabilities.toolCalling == CapabilitySupport.supported,
          )
          .map(
            (model) => ModelPickerOption(
              providerName: connection.displayName,
              model: model,
            ),
          ),
    );
  }
  return options;
}
