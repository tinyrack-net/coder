import 'dart:io';

import 'package:cli/cli.dart';

Future<void> main(List<String> arguments) async {
  exitCode = await runCli(arguments);
}
