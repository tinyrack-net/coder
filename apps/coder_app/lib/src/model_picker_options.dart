import 'package:coder_app/src/controller.dart';
import 'package:coder_app/src/model_picker.dart';
import 'package:coder_app/src/session_model_options.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Loads every provider-qualified model the user may currently pick.
///
/// Model catalogs load per connection, so this fills in the connections whose
/// lists are still missing before flattening them. Both the composer chip and
/// the provider settings default-model card offer the same options.
Future<List<ModelPickerOption>> loadModelPickerOptions(
  WidgetRef ref,
  String hostId,
) async {
  final controller = providerSettingsControllerProvider(hostId);
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
  return <ModelPickerOption>[
    for (final connection in connections)
      for (final model
          in loaded?.models[connection.id] ?? const <ProviderModelDto>[])
        ModelPickerOption(
          providerName: connection.displayName,
          model: model,
        ),
  ];
}
