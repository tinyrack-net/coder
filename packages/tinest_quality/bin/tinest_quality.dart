import 'dart:io';

import 'src/application.dart';

Future<void> main(List<String> arguments) async {
  exitCode = await runTinestQuality(arguments);
}
