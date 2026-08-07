import 'package:coder_app/src/features/hosts/application/host_controller.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'permission_settings_controller.g.dart';

@riverpod
/// Owns the daemon-global permission default for one connected host.
class PermissionSettingsController extends _$PermissionSettingsController {
  @override
  Future<PermissionSettingsDto> build(String hostId) async {
    final api = await requireHostApi(ref, hostId);
    return api.getDefaultPermissionMode();
  }

  /// Persists and exposes a new daemon-global permission default.
  Future<void> setDefaultMode(PermissionMode mode) async {
    final previous = state;
    state = AsyncData<PermissionSettingsDto>(
      PermissionSettingsDto(defaultMode: mode),
    );
    try {
      final api = await requireHostApi(ref, hostId);
      state = AsyncData<PermissionSettingsDto>(
        await api.setDefaultPermissionMode(mode),
      );
    } on Object catch (error, stackTrace) {
      state = previous.hasValue
          ? AsyncData<PermissionSettingsDto>(previous.requireValue)
          : AsyncError<PermissionSettingsDto>(error, stackTrace);
      rethrow;
    }
  }
}
