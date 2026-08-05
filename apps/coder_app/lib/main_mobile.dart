import 'package:coder_app/src/app.dart';
import 'package:coder_app/src/app_services.dart';
import 'package:coder_app/src/attachment_io.dart';
import 'package:coder_app/src/boot/bootstrap_gate.dart';
import 'package:coder_app/src/remote_bootstrap.dart';
import 'package:flutter/material.dart';

/// Starts the mobile widget tree with an injectable remote-only bootstrap.
Future<void> runMobileApp({AppServices? services}) async {
  WidgetsFlutterBinding.ensureInitialized();
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
