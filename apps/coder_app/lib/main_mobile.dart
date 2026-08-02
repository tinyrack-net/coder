import 'package:coder_app/src/app.dart';
import 'package:coder_app/src/bootstrap.dart';
import 'package:coder_app/src/remote_bootstrap.dart';
import 'package:flutter/material.dart';

/// Starts the mobile widget tree with an injectable remote-only bootstrap.
Future<void> runMobileApp({AppBootstrap? bootstrap}) async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(CoderApp(bootstrap: bootstrap ?? RemoteBootstrap()));
}

/// Starts the production mobile application.
Future<void> main() => runMobileApp();
