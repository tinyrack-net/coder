import 'dart:io';

import 'package:coder_cli/coder_cli.dart';

Future<void> main(List<String> arguments) async {
  exitCode = await runCli(arguments);
}
