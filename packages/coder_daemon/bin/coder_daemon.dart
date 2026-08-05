import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:coder_daemon/coder_daemon.dart';

Future<void> main(List<String> arguments) async {
  // The provider and agent subcommands moved to their own binary so that the
  // CLI no longer carries the daemon's database and provider stack.
  if (arguments.firstOrNull case final command?
      when const <String>{'provider', 'agent'}.contains(command)) {
    stderr.writeln(
      'The $command commands moved to the coder-cli binary. '
              'Run `coder-cli $command ${arguments.skip(1).join(' ')}`.'
          .trimRight(),
    );
    exitCode = 64;
    return;
  }
  final defaults = DaemonConfig.fromEnvironment();
  final parser = ArgParser()
    ..addOption('home', defaultsTo: defaults.homeDirectory)
    ..addOption('listen', defaultsTo: '${defaults.host}:${defaults.port}')
    ..addOption('token', defaultsTo: defaults.bearerToken)
    ..addFlag('help', abbr: 'h', negatable: false);
  final options = parser.parse(arguments);
  if (options.flag('help')) {
    stdout.writeln('Tinyrack Coder daemon\n${parser.usage}');
    return;
  }
  final listen = options.option('listen')!;
  final separator = listen.lastIndexOf(':');
  if (separator < 1) throw const FormatException('--listen must be host:port.');
  final handle = await DaemonApplication.start(
    defaults.copyWith(
      homeDirectory: options.option('home'),
      configDirectory: options.option('home'),
      host: listen.substring(0, separator),
      port: int.parse(listen.substring(separator + 1)),
      bearerToken: options.option('token'),
    ),
  );
  stdout.writeln('Tinyrack Coder daemon listening on ${handle.boundEndpoint}');
  if (options.option('token') == null) {
    stdout.writeln('Connection token: ${handle.bearerToken}');
  }
  final stopping = Completer<void>();
  late final StreamSubscription<ProcessSignal> interrupt;
  StreamSubscription<ProcessSignal>? terminate;
  interrupt = ProcessSignal.sigint.watch().listen((_) => stopping.complete());
  if (!Platform.isWindows) {
    terminate = ProcessSignal.sigterm.watch().listen((_) {
      if (!stopping.isCompleted) stopping.complete();
    });
  }
  await stopping.future;
  await interrupt.cancel();
  await terminate?.cancel();
  await handle.stop();
}
