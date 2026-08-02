import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:coder_agent/coder_agent.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:uuid/uuid.dart';

import 'agent_service.dart';
import 'config.dart';
import 'credential_store.dart';
import 'database.dart';
import 'provider_service.dart';
import 'server.dart';

abstract interface class DaemonHandle {
  Future<void> get ready;
  Uri get boundEndpoint;
  String get serverId;
  String get bearerToken;
  Future<void> stop();
}

abstract final class DaemonApplication {
  static Future<DaemonHandle> start(
    DaemonConfig config, {
    ModelProvider? provider,
  }) async {
    final home = Directory(config.homeDirectory);
    await home.create(recursive: true);
    final lockFile = File(p.join(home.path, 'daemon.lock'));
    final lock = await lockFile.open(mode: FileMode.append);
    try {
      await lock.lock(FileLock.exclusive);
    } catch (_) {
      await lock.close();
      rethrow;
    }

    final database = CoderDatabase(p.join(home.path, 'coder.sqlite'));
    try {
      await database.recoverInterruptedRuns();
      var serverId = await database.getSetting('server.id');
      if (serverId == null) {
        serverId = const Uuid().v4();
        await database.setSetting('server.id', serverId);
      }
      final credentials = CredentialStore(config.configDirectory);
      await credentials.load();
      final token =
          config.bearerToken ??
          credentials.bearerToken ??
          generateBearerToken();
      if (utf8.encode(token).length < 32) {
        throw ArgumentError(
          'Bearer token must contain at least 256 bits (32 bytes).',
        );
      }
      await database.setSetting(
        'auth.tokenHash',
        sha256.convert(utf8.encode(token)).toString(),
      );
      if (credentials.bearerToken != token) {
        await credentials.setBearerToken(token);
      }
      final events = StreamController<WireEnvelope>.broadcast(sync: true);
      final providers = ProviderService(
        database: database,
        credentials: credentials,
        fixedProvider: provider,
      );
      await providers.initialize(legacyOpenAIKey: config.apiKey);
      final service = AgentService(
        database: database,
        providers: providers,
        events: events.add,
        safetyIdentifier: sha256.convert(utf8.encode(serverId)).toString(),
      );
      final info = ServerInfoDto(
        serverId: serverId,
        version: config.version,
        protocolVersion: coderProtocolVersion,
        features: <String, bool>{
          'timelineCatchup': true,
          'approvals': true,
          'embeddedDaemon': true,
          'providerCatalog': true,
        },
      );
      final rpc = DaemonRpcServer(
        database: database,
        agents: service,
        providers: providers,
        serverInfo: info,
        token: token,
        events: events.stream,
      );
      final http = await shelf_io.serve(
        rpc.call,
        config.host,
        config.port,
        shared: false,
      );
      final presentationHost = config.host == '0.0.0.0'
          ? '127.0.0.1'
          : config.host;
      return _LocalDaemonHandle(
        endpoint: Uri(
          scheme: 'ws',
          host: presentationHost,
          port: http.port,
          path: '/ws',
        ),
        serverIdValue: serverId,
        token: token,
        http: http,
        rpc: rpc,
        database: database,
        events: events,
        lock: lock,
      );
    } catch (_) {
      await database.close();
      await lock.unlock();
      await lock.close();
      rethrow;
    }
  }
}

class _LocalDaemonHandle implements DaemonHandle {
  _LocalDaemonHandle({
    required Uri endpoint,
    required String serverIdValue,
    required String token,
    required HttpServer http,
    required DaemonRpcServer rpc,
    required CoderDatabase database,
    required StreamController<WireEnvelope> events,
    required RandomAccessFile lock,
  }) : _endpoint = endpoint,
       _serverId = serverIdValue,
       _token = token,
       _http = http,
       _rpc = rpc,
       _database = database,
       _events = events,
       _lock = lock;

  final Uri _endpoint;
  final String _serverId;
  final String _token;
  final HttpServer _http;
  final DaemonRpcServer _rpc;
  final CoderDatabase _database;
  final StreamController<WireEnvelope> _events;
  final RandomAccessFile _lock;
  bool _stopped = false;

  @override
  Uri get boundEndpoint => _endpoint;
  @override
  String get serverId => _serverId;
  @override
  String get bearerToken => _token;
  @override
  Future<void> get ready => Future<void>.value();

  @override
  Future<void> stop() async {
    if (_stopped) return;
    _stopped = true;
    await _http.close(force: true);
    await _rpc.close();
    await _events.close();
    await _database.close();
    await _lock.unlock();
    await _lock.close();
  }
}
