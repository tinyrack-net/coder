import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/remote_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(CoderApp(bootstrap: RemoteBootstrap()));
}
