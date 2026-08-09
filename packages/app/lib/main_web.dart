import 'package:app/src/app/coder_app.dart';
import 'package:app/src/app/composition/app_services.dart';
import 'package:app/src/features/boot/presentation/bootstrap_gate.dart';
import 'package:app/src/features/conversation/infrastructure/attachment_web.dart';
import 'package:app/src/features/hosts/infrastructure/remote_bootstrap.dart';
import 'package:cryptography/cryptography.dart';
import 'package:cryptography_flutter/cryptography_flutter.dart';
import 'package:flutter/material.dart';

/// Starts the web widget tree with an injectable remote-only bootstrap.
///
/// A browser cannot host a daemon, so this reuses the mobile bootstrap and
/// simply never supplies an embedded launcher.
Future<void> runWebApp({AppServices? services}) async {
  WidgetsFlutterBinding.ensureInitialized();
  Cryptography.instance = FlutterCryptography.defaultInstance;
  runApp(
    BootstrapGate<AppServices>(
      bootstrap: () async =>
          services ?? await createRemoteServices(clientKind: 'web'),
      builder: (context, resolved) => CoderApp(
        services: resolved,
        attachmentInput: const WebAttachmentInput(),
      ),
    ),
  );
}

/// Starts the production web application.
Future<void> main() => runWebApp();
