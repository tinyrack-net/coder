import 'dart:convert';

const int coderProtocolVersion = 1;

abstract final class MessageType {
  static const String hello = 'hello';
  static const String serverInfo = 'server.info';
  static const String rpcError = 'rpc.error';
  static const String workspaceListRequest = 'workspace.list.request';
  static const String workspaceListResponse = 'workspace.list.response';
  static const String workspaceRegisterRequest = 'workspace.register.request';
  static const String workspaceRegisterResponse = 'workspace.register.response';
  static const String agentListRequest = 'agent.list.request';
  static const String agentListResponse = 'agent.list.response';
  static const String agentCreateRequest = 'agent.create.request';
  static const String agentCreateResponse = 'agent.create.response';
  static const String agentConfigurationUpdateRequest =
      'agent.configuration.update.request';
  static const String agentConfigurationUpdateResponse =
      'agent.configuration.update.response';
  static const String providerListRequest = 'provider.list.request';
  static const String providerListResponse = 'provider.list.response';
  static const String providerUpsertRequest = 'provider.upsert.request';
  static const String providerUpsertResponse = 'provider.upsert.response';
  static const String providerDeleteRequest = 'provider.delete.request';
  static const String providerDeleteResponse = 'provider.delete.response';
  static const String providerModelsListRequest =
      'provider.models.list.request';
  static const String providerModelsListResponse =
      'provider.models.list.response';
  static const String providerModelsRefreshRequest =
      'provider.models.refresh.request';
  static const String providerModelsRefreshResponse =
      'provider.models.refresh.response';
  static const String providerModelUpsertRequest =
      'provider.model.upsert.request';
  static const String providerModelUpsertResponse =
      'provider.model.upsert.response';
  static const String providerModelDeleteRequest =
      'provider.model.delete.request';
  static const String providerModelDeleteResponse =
      'provider.model.delete.response';
  static const String providerModelDiagnoseRequest =
      'provider.model.diagnose.request';
  static const String providerModelDiagnoseResponse =
      'provider.model.diagnose.response';
  static const String providerCredentialSetRequest =
      'provider.credential.set.request';
  static const String providerCredentialSetResponse =
      'provider.credential.set.response';
  static const String providerCredentialClearRequest =
      'provider.credential.clear.request';
  static const String providerCredentialClearResponse =
      'provider.credential.clear.response';
  static const String turnStartRequest = 'turn.start.request';
  static const String turnStartResponse = 'turn.start.response';
  static const String turnCancelRequest = 'turn.cancel.request';
  static const String turnCancelResponse = 'turn.cancel.response';
  static const String approvalResolveRequest = 'approval.resolve.request';
  static const String approvalResolveResponse = 'approval.resolve.response';
  static const String timelineSubscribeRequest = 'timeline.subscribe.request';
  static const String timelineSubscribeResponse = 'timeline.subscribe.response';
  static const String timelineEvent = 'timeline.event';
  static const String agentUpdate = 'agent.update';
  static const String approvalRequest = 'approval.request';
}

class ProtocolException implements Exception {
  const ProtocolException(this.message);

  final String message;

  @override
  String toString() => 'ProtocolException: $message';
}

class WireEnvelope {
  const WireEnvelope({
    required this.type,
    required this.payload,
    this.version = coderProtocolVersion,
    this.requestId,
  });

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

  factory WireEnvelope.decode(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const ProtocolException('Wire message must be a JSON object.');
    }
    return WireEnvelope.fromJson(Map<String, dynamic>.from(decoded));
  }

  final int version;
  final String type;
  final String? requestId;
  final Map<String, dynamic> payload;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'version': version,
    'type': type,
    if (requestId case final requestId?) 'requestId': requestId,
    'payload': payload,
  };

  String encode() => jsonEncode(toJson());
}
