import 'package:coder_app/src/app/coder_app.dart';
import 'package:coder_app/src/app/composition/app_services.dart';
import 'package:coder_app/src/features/boot/presentation/bootstrap_gate.dart';
import 'package:coder_app/src/features/conversation/infrastructure/attachment_io.dart';
import 'package:coder_app/src/features/hosts/infrastructure/remote_bootstrap.dart';
import 'package:cryptography/cryptography.dart';
import 'package:cryptography_flutter/cryptography_flutter.dart';
import 'package:flutter/material.dart';

/// Starts the mobile widget tree with an injectable remote-only bootstrap.
Future<void> runMobileApp({AppServices? services}) async {
  WidgetsFlutterBinding.ensureInitialized();
  Cryptography.instance = FlutterCryptography.defaultInstance;
  runApp(
    BootstrapGate<AppServices>(
      bootstrap: () async => services ?? await createRemoteServices(),
      builder: (context, resolved) => CoderApp(
        services: resolved,
        attachmentInput: const NativeAttachmentInput(),
      ),
    ),
  );
}

/// Starts the production mobile application.
Future<void> main() => runMobileApp();
