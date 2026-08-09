import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Operating-system folder selection boundary for the project picker.
///
/// Only a host that shares this machine's filesystem may use it, which today
/// means the app-owned embedded daemon. A remote daemon is browsed over RPC
/// instead, because its paths do not exist here.
abstract interface class DirectoryPickerPort {
  /// Opens the native folder chooser and returns the absolute path.
  ///
  /// Returns null when the user cancels.
  Future<String?> pickDirectory({String? initialDirectory});
}

/// Native folder chooser, or null on a platform that owns no local daemon.
///
/// The composition root supplies the adapter; tests override this port.
final directoryPickerProvider = Provider<DirectoryPickerPort?>((ref) => null);
