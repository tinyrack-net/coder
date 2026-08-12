import 'package:app/src/features/hosts/domain/host_models.dart';
import 'package:app/src/features/hosts/domain/host_ports.dart';

/// Stable settings value that is never bound by an ephemeral test launcher.
const int testEmbeddedDaemonPort = 49152;

/// Starts a real embedded daemon on an OS-assigned port.
///
/// The app-owned daemon binds whatever `AppSettings.embeddedDaemonPort` says,
/// but reserving and releasing a port before startup leaves a race. This typed
/// test adapter ignores the display setting and passes zero to the production
/// launcher, which keeps the socket allocation and readiness message inside
/// the daemon lifecycle.
///
/// The app-owned embedded-port contract keeps every real-daemon E2E here.
final class EphemeralEmbeddedDaemonLauncher implements EmbeddedDaemonLauncher {
  const EphemeralEmbeddedDaemonLauncher(this.delegate);

  final EmbeddedDaemonLauncher delegate;

  @override
  Future<EmbeddedDaemonSession> start({
    required EmbeddedDaemonExposure exposure,
    required int port,
  }) => delegate.start(exposure: exposure, port: 0);
}
