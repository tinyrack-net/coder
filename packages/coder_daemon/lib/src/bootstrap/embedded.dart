import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:coder_agent/coder_agent.dart';
import 'package:coder_daemon/src/bootstrap/application.dart';
import 'package:coder_daemon/src/bootstrap/config.dart';

/// Stable reason an embedded daemon could not finish starting.
enum EmbeddedDaemonStartupFailureReason {
  /// The configured listener port is already owned by another process.
  portInUse,

  /// Another daemon already holds the lock on this daemon home.
  alreadyRunning,

  /// Startup failed for another reason.
  unknown,
}

/// Typed failure reported when an embedded daemon cannot complete startup.
final class EmbeddedDaemonStartupException implements Exception {
  /// Creates an embedded startup failure with a safe diagnostic message.
  const EmbeddedDaemonStartupException(
    this.message, {
    this.reason = EmbeddedDaemonStartupFailureReason.unknown,
  });

  /// Startup diagnostic without credential values.
  final String message;

  /// Machine-readable failure category transported across the isolate.
  final EmbeddedDaemonStartupFailureReason reason;

  @override
  String toString() => message;
}

/// EmbeddedDaemonHandle defines a public contract.
class EmbeddedDaemonHandle implements DaemonHandle {
  EmbeddedDaemonHandle._({
    required this.boundEndpoint,
    required this.serverId,
    required this.bearerToken,
    required this._isolate,
    required this._commands,
  });

  /// The start public API member.
  static Future<EmbeddedDaemonHandle> start(
    DaemonConfig config, {
    ModelProvider? provider,
  }) async {
    final receive = ReceivePort();
    final isolate = await Isolate.spawn(_embeddedDaemonMain, <Object?>[
      receive.sendPort,
      config.toIsolateMessage(),
      provider,
    ], debugName: 'tinyrack-coder-daemon');
    final message = await receive.first.timeout(const Duration(seconds: 30));
    receive.close();
    if (message is! Map) {
      isolate.kill(priority: Isolate.immediate);
      throw const EmbeddedDaemonStartupException(
        'Embedded daemon returned an invalid ready message.',
      );
    }
    final values = Map<Object?, Object?>.from(message);
    if (values['error'] case final String error) {
      isolate.kill(priority: Isolate.immediate);
      final reasonName = values['errorReason'];
      final reason = EmbeddedDaemonStartupFailureReason.values
          .where((value) => value.name == reasonName)
          .firstOrNull;
      throw EmbeddedDaemonStartupException(
        error,
        reason: reason ?? EmbeddedDaemonStartupFailureReason.unknown,
      );
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
    _isolate.kill();
  }
}

Future<void> _embeddedDaemonMain(List<Object?> message) async {
  final ready = message[0]! as SendPort;
  final config = DaemonConfig.fromIsolateMessage(
    Map<Object?, Object?>.from(message[1]! as Map),
  );
  final provider = message[2] as ModelProvider?;
  try {
    final handle = await DaemonApplication.start(config, provider: provider);
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
  } on Exception catch (error) {
    _sendStartupError(ready, error);
  }
}

void _sendStartupError(SendPort ready, Object error) {
  ready.send(<Object?, Object?>{
    'error': '$error',
    'errorReason': _startupFailureReason(error).name,
  });
}

EmbeddedDaemonStartupFailureReason _startupFailureReason(Object error) {
  if (error is DaemonAlreadyRunningException) {
    return EmbeddedDaemonStartupFailureReason.alreadyRunning;
  }
  if (error case SocketException(:final osError)) {
    // EADDRINUSE is 48 on Darwin, 98 on Linux, and 10048 on Windows.
    if (const <int>{48, 98, 10048}.contains(osError?.errorCode)) {
      return EmbeddedDaemonStartupFailureReason.portInUse;
    }
    final message = '$error'.toLowerCase();
    if (message.contains('address already in use') ||
        message.contains('shared flag to bind')) {
      return EmbeddedDaemonStartupFailureReason.portInUse;
    }
  }
  return EmbeddedDaemonStartupFailureReason.unknown;
}
