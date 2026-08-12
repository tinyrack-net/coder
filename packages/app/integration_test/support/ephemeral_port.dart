import 'dart:io';

/// Reserves a loopback TCP port that no process currently owns.
///
/// The app-owned daemon binds whatever `AppSettings.embeddedDaemonPort` says,
/// so a test that leaves the default in place binds the machine-global product
/// port. A second checkout verifying in parallel, or a developer running
/// `melos run:daemon`, then fails with `embeddedPortInUse`. Ask the operating
/// system for a port instead: it draws from the ephemeral range and does not
/// immediately reissue one it just released.
///
/// The app-owned embedded-port contract keeps every real-daemon E2E here.
Future<int> reserveEphemeralPort() async {
  final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = socket.port;
  await socket.close();
  return port;
}
