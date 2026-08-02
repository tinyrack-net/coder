import 'dart:async';
import 'dart:isolate';

import 'application.dart';
import 'config.dart';

class EmbeddedDaemonHandle implements DaemonHandle {
  EmbeddedDaemonHandle._({
    required this.boundEndpoint,
    required this.serverId,
    required this.bearerToken,
    required Isolate isolate,
    required SendPort commands,
  }) : _isolate = isolate,
       _commands = commands;

  static Future<EmbeddedDaemonHandle> start(DaemonConfig config) async {
    final receive = ReceivePort();
    final isolate = await Isolate.spawn(_embeddedDaemonMain, <Object?>[
      receive.sendPort,
      config.toIsolateMessage(),
    ], debugName: 'tinyrack-coder-daemon');
    final message = await receive.first.timeout(const Duration(seconds: 30));
    receive.close();
    if (message is! Map) {
      isolate.kill(priority: Isolate.immediate);
      throw StateError('Embedded daemon returned an invalid ready message.');
    }
    final values = Map<Object?, Object?>.from(message);
    if (values['error'] case final String error) {
      isolate.kill(priority: Isolate.immediate);
      throw StateError(error);
    }
    return EmbeddedDaemonHandle._(
      boundEndpoint: Uri.parse(values['endpoint']! as String),
      serverId: values['serverId']! as String,
      bearerToken: values['token']! as String,
      isolate: isolate,
      commands: values['commands']! as SendPort,
    );
  }

  @override
  final Uri boundEndpoint;
  @override
  final String serverId;
  @override
  final String bearerToken;
  final Isolate _isolate;
  final SendPort _commands;
  bool _stopped = false;

  @override
  Future<void> get ready => Future<void>.value();

  @override
  Future<void> stop() async {
    if (_stopped) return;
    _stopped = true;
    final response = ReceivePort();
    _commands.send(<Object?>['stop', response.sendPort]);
    await response.first.timeout(const Duration(seconds: 10));
    response.close();
    _isolate.kill(priority: Isolate.beforeNextEvent);
  }
}

Future<void> _embeddedDaemonMain(List<Object?> message) async {
  final ready = message[0]! as SendPort;
  final config = DaemonConfig.fromIsolateMessage(
    Map<Object?, Object?>.from(message[1]! as Map),
  );
  try {
    final handle = await DaemonApplication.start(config);
    final commands = ReceivePort();
    ready.send(<Object?, Object?>{
      'endpoint': handle.boundEndpoint.toString(),
      'serverId': handle.serverId,
      'token': handle.bearerToken,
      'commands': commands.sendPort,
    });
    await for (final command in commands) {
      if (command is List && command.firstOrNull == 'stop') {
        await handle.stop();
        if (command.length > 1 && command[1] is SendPort) {
          (command[1] as SendPort).send(true);
        }
        commands.close();
      }
    }
  } catch (error) {
    ready.send(<Object?, Object?>{'error': '$error'});
  }
}
