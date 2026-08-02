import 'dart:convert';

/// The coderProtocolVersion public API member.
const int coderProtocolVersion = 2;

/// Public API exposed by this library.
abstract final class RpcMethod {
  /// The hello public API member.
  static const String hello = 'hello';

  /// The workspaceList public API member.
  static const String workspaceList = 'workspace.list';

  /// The workspaceRegister public API member.
  static const String workspaceRegister = 'workspace.register';

  /// The agentList public API member.
  static const String agentList = 'agent.list';

  /// The agentCreate public API member.
  static const String agentCreate = 'agent.create';

  /// The agentConfigurationUpdate public API member.
  static const String agentConfigurationUpdate = 'agent.configuration.update';

  /// The providerList public API member.
  static const String providerList = 'provider.list';

  /// The providerUpsert public API member.
  static const String providerUpsert = 'provider.upsert';

  /// The providerDelete public API member.
  static const String providerDelete = 'provider.delete';

  /// The providerModelsList public API member.
  static const String providerModelsList = 'provider.models.list';

  /// The providerModelsRefresh public API member.
  static const String providerModelsRefresh = 'provider.models.refresh';

  /// The providerModelUpsert public API member.
  static const String providerModelUpsert = 'provider.model.upsert';

  /// The providerModelDelete public API member.
  static const String providerModelDelete = 'provider.model.delete';

  /// The providerModelDiagnose public API member.
  static const String providerModelDiagnose = 'provider.model.diagnose';

  /// The providerCredentialSet public API member.
  static const String providerCredentialSet = 'provider.credential.set';

  /// The providerCredentialClear public API member.
  static const String providerCredentialClear = 'provider.credential.clear';

  /// The turnStart public API member.
  static const String turnStart = 'turn.start';

  /// The turnCancel public API member.
  static const String turnCancel = 'turn.cancel';

  /// The approvalResolve public API member.
  static const String approvalResolve = 'approval.resolve';

  /// The timelineSubscribe public API member.
  static const String timelineSubscribe = 'timeline.subscribe';
}

/// Public API exposed by this library.
abstract final class RpcNotification {
  /// The timelineEvent public API member.
  static const String timelineEvent = 'timeline.event';

  /// The agentUpdated public API member.
  static const String agentUpdated = 'agent.updated';

  /// The approvalRequested public API member.
  static const String approvalRequested = 'approval.requested';
}

/// ProtocolException defines a public contract.
class ProtocolException implements Exception {
  /// Creates a [ProtocolException].
  const ProtocolException(this.message);

  /// The message public API member.
  final String message;

  @override
  String toString() => 'ProtocolException: $message';
}

/// WireEnvelope defines a public contract.
class WireEnvelope {
  /// Creates a [WireEnvelope].
  const WireEnvelope({
    required this.type,
    required this.payload,
    this.version = coderProtocolVersion,
    this.requestId,
  });

  /// Creates a [WireEnvelope].
  factory WireEnvelope.fromJson(Map<String, dynamic> json) {
    final version = json['version'];
    final type = json['type'];
    final payload = json['payload'];
    final requestId = json['requestId'];
    if (version is! int || type is! String || payload is! Map) {
      throw const ProtocolException('Invalid wire envelope.');
    }
    if (requestId != null && requestId is! String) {
      throw const ProtocolException('requestId must be a string.');
    }
    return WireEnvelope(
      version: version,
      type: type,
      requestId: requestId as String?,
      payload: Map<String, dynamic>.from(payload),
    );
  }

  /// Creates a [WireEnvelope].
  factory WireEnvelope.decode(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const ProtocolException('Wire message must be a JSON object.');
    }
    return WireEnvelope.fromJson(Map<String, dynamic>.from(decoded));
  }

  /// The version public API member.
  final int version;

  /// The type public API member.
  final String type;

  /// The requestId public API member.
  final String? requestId;

  /// The payload public API member.
  final Map<String, dynamic> payload;

  /// The toJson public API member.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'version': version,
    'type': type,
    'requestId': ?requestId,
    'payload': payload,
  };

  /// The encode public API member.
  String encode() => jsonEncode(toJson());
}
