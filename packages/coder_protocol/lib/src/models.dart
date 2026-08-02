import 'package:freezed_annotation/freezed_annotation.dart';

part 'models.freezed.dart';
part 'models.g.dart';

enum AgentStatus {
  initializing,
  idle,
  running,
  waitingForApproval,
  failed,
  closed,
}

enum TurnStatus {
  running,
  waitingForApproval,
  completed,
  failed,
  interrupted,
  cancelled,
}

enum PermissionMode { readOnly, ask, workspaceWrite }

enum ApprovalStatus { pending, approved, denied, cancelled }

enum ToolRisk { read, write, command }

enum ApiTransport { responses, chatCompletions }

enum CredentialSource { none, stored, environment }

enum ProviderModelSource { preset, discovered, manual }

enum CapabilitySupport { unknown, supported, unsupported }

enum CapabilitySource { unknown, preset, diagnostic, manual }

enum DiagnosticStatus { unknown, verified, failed }

@freezed
abstract class WorkspaceDto with _$WorkspaceDto {
  const factory WorkspaceDto({
    required String id,
    required String name,
    required String rootPath,
    required DateTime createdAt,
  }) = _WorkspaceDto;

  factory WorkspaceDto.fromJson(Map<String, dynamic> json) =>
      _$WorkspaceDtoFromJson(json);
}

@freezed
abstract class AgentDto with _$AgentDto {
  const factory AgentDto({
    required String id,
    required String workspaceId,
    required String title,
    required String providerId,
    required String model,
    @Default('medium') String reasoningEffort,
    required AgentStatus status,
    required PermissionMode permissionMode,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? activeTurnId,
    String? lastError,
  }) = _AgentDto;

  factory AgentDto.fromJson(Map<String, dynamic> json) =>
      _$AgentDtoFromJson(json);
}

@freezed
abstract class ModelCapabilitiesDto with _$ModelCapabilitiesDto {
  const factory ModelCapabilitiesDto({
    @Default(CapabilitySupport.unknown) CapabilitySupport streaming,
    @Default(CapabilitySupport.unknown) CapabilitySupport toolCalling,
    @Default(CapabilitySupport.unknown) CapabilitySupport reasoningEffort,
    @Default(<String>[]) List<String> supportedReasoningEfforts,
    @Default(CapabilitySource.unknown) CapabilitySource source,
  }) = _ModelCapabilitiesDto;

  factory ModelCapabilitiesDto.fromJson(Map<String, dynamic> json) =>
      _$ModelCapabilitiesDtoFromJson(json);
}

@freezed
abstract class ApiProviderDto with _$ApiProviderDto {
  const factory ApiProviderDto({
    required String id,
    required String name,
    required String presetId,
    required String baseUrl,
    required ApiTransport transport,
    required CredentialSource credentialSource,
    required bool credentialConfigured,
    required bool enabled,
    required bool strictToolSchema,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? environmentVariable,
    String? defaultModelId,
    @Default(<String>[]) List<String> visibleModelIds,
  }) = _ApiProviderDto;

  factory ApiProviderDto.fromJson(Map<String, dynamic> json) =>
      _$ApiProviderDtoFromJson(json);
}

@freezed
abstract class ProviderPresetDto with _$ProviderPresetDto {
  const factory ProviderPresetDto({
    required String id,
    required String name,
    required String defaultBaseUrl,
    required ApiTransport defaultTransport,
    required CredentialSource defaultCredentialSource,
    required bool strictToolSchema,
    String? defaultEnvironmentVariable,
    String? defaultModelId,
    @Default(<String>[]) List<String> modelIds,
  }) = _ProviderPresetDto;

  factory ProviderPresetDto.fromJson(Map<String, dynamic> json) =>
      _$ProviderPresetDtoFromJson(json);
}

@freezed
abstract class ProviderModelDto with _$ProviderModelDto {
  const factory ProviderModelDto({
    required String providerId,
    required String id,
    required String label,
    required ProviderModelSource source,
    required ModelCapabilitiesDto capabilities,
    @Default(DiagnosticStatus.unknown) DiagnosticStatus diagnosticStatus,
    DateTime? verifiedAt,
    String? diagnosticError,
  }) = _ProviderModelDto;

  factory ProviderModelDto.fromJson(Map<String, dynamic> json) =>
      _$ProviderModelDtoFromJson(json);
}

@freezed
abstract class ProviderCatalogDto with _$ProviderCatalogDto {
  const factory ProviderCatalogDto({
    required List<ApiProviderDto> providers,
    required List<ProviderPresetDto> presets,
    String? defaultProviderId,
  }) = _ProviderCatalogDto;

  factory ProviderCatalogDto.fromJson(Map<String, dynamic> json) =>
      _$ProviderCatalogDtoFromJson(json);
}

@freezed
abstract class ProviderDiagnosticDto with _$ProviderDiagnosticDto {
  const factory ProviderDiagnosticDto({
    required String providerId,
    required String model,
    required DiagnosticStatus status,
    required bool endpointReachable,
    required bool streaming,
    required bool toolCalling,
    required DateTime checkedAt,
    String? error,
  }) = _ProviderDiagnosticDto;

  factory ProviderDiagnosticDto.fromJson(Map<String, dynamic> json) =>
      _$ProviderDiagnosticDtoFromJson(json);
}

@freezed
abstract class TimelineEventDto with _$TimelineEventDto {
  const factory TimelineEventDto({
    required String agentId,
    required int sequence,
    required String type,
    required Map<String, dynamic> data,
    required DateTime createdAt,
    String? turnId,
  }) = _TimelineEventDto;

  factory TimelineEventDto.fromJson(Map<String, dynamic> json) =>
      _$TimelineEventDtoFromJson(json);
}

@freezed
abstract class ApprovalRequestDto with _$ApprovalRequestDto {
  const factory ApprovalRequestDto({
    required String id,
    required String agentId,
    required String turnId,
    required String toolCallId,
    required String toolName,
    required ToolRisk risk,
    required Map<String, dynamic> arguments,
    required ApprovalStatus status,
    required DateTime createdAt,
    String? preview,
  }) = _ApprovalRequestDto;

  factory ApprovalRequestDto.fromJson(Map<String, dynamic> json) =>
      _$ApprovalRequestDtoFromJson(json);
}

@freezed
abstract class ServerInfoDto with _$ServerInfoDto {
  const factory ServerInfoDto({
    required String serverId,
    required String version,
    required int protocolVersion,
    required Map<String, bool> features,
  }) = _ServerInfoDto;

  factory ServerInfoDto.fromJson(Map<String, dynamic> json) =>
      _$ServerInfoDtoFromJson(json);
}

@freezed
abstract class RpcErrorDto with _$RpcErrorDto {
  const factory RpcErrorDto({
    required String code,
    required String message,
    required bool retryable,
    Map<String, dynamic>? details,
  }) = _RpcErrorDto;

  factory RpcErrorDto.fromJson(Map<String, dynamic> json) =>
      _$RpcErrorDtoFromJson(json);
}
