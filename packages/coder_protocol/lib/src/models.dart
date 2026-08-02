import 'package:freezed_annotation/freezed_annotation.dart';

part 'models.freezed.dart';
part 'models.g.dart';

/// Values supported by AgentStatus.
enum AgentStatus {
  /// The initializing public API member.
  initializing,

  /// The idle public API member.
  idle,

  /// The running public API member.
  running,

  /// The waitingForApproval public API member.
  waitingForApproval,

  /// The failed public API member.
  failed,

  /// The closed public API member.
  closed,
}

/// Values supported by TurnStatus.
enum TurnStatus {
  /// The running public API member.
  running,

  /// The waitingForApproval public API member.
  waitingForApproval,

  /// The completed public API member.
  completed,

  /// The failed public API member.
  failed,

  /// The interrupted public API member.
  interrupted,

  /// The cancelled public API member.
  cancelled,
}

/// Values supported by PermissionMode.
enum PermissionMode {
  /// Allows read-only tools and rejects mutations.
  readOnly,

  /// Automatically reads and asks before every mutation.
  ask,

  /// Allows workspace file writes but asks before commands.
  workspaceWrite,
}

/// Values supported by ApprovalStatus.
enum ApprovalStatus {
  /// The approval has not been resolved.
  pending,

  /// The user approved the invocation.
  approved,

  /// The user denied the invocation.
  denied,

  /// The daemon cancelled the approval.
  cancelled,
}

/// Values supported by ToolRisk.
enum ToolRisk {
  /// Reads workspace state without mutating it.
  read,

  /// Writes workspace files.
  write,

  /// Starts a child process.
  command,
}

/// Values supported by ApiTransport.
enum ApiTransport {
  /// Uses the OpenAI Responses API.
  responses,

  /// Uses the OpenAI-compatible Chat Completions API.
  chatCompletions,
}

/// Values supported by CredentialSource.
enum CredentialSource {
  /// Does not send a credential.
  none,

  /// Reads a credential from the daemon credential store.
  stored,

  /// Reads a credential from a daemon environment variable.
  environment,
}

/// Values supported by ProviderModelSource.
enum ProviderModelSource {
  /// The model came from a built-in provider preset.
  preset,

  /// The model came from the provider models endpoint.
  discovered,

  /// The user configured the model explicitly.
  manual,
}

/// Values supported by CapabilitySupport.
enum CapabilitySupport {
  /// Support has not been established.
  unknown,

  /// The capability is supported.
  supported,

  /// The capability is not supported.
  unsupported,
}

/// Values supported by CapabilitySource.
enum CapabilitySource {
  /// No capability source is available.
  unknown,

  /// A built-in preset supplied the capability.
  preset,

  /// A diagnostic request supplied the capability.
  diagnostic,

  /// The user supplied the capability.
  manual,
}

/// Values supported by DiagnosticStatus.
enum DiagnosticStatus {
  /// The model has not been diagnosed.
  unknown,

  /// The diagnostic completed successfully.
  verified,

  /// The diagnostic failed.
  failed,
}

@freezed
/// WorkspaceDto defines a public contract.
abstract class WorkspaceDto with _$WorkspaceDto {
  /// The WorkspaceDto public API member.
  const factory WorkspaceDto({
    required String id,
    required String name,
    required String rootPath,
    required DateTime createdAt,
  }) = _WorkspaceDto;

  /// Creates a [WorkspaceDto].
  factory WorkspaceDto.fromJson(Map<String, dynamic> json) =>
      _$WorkspaceDtoFromJson(json);
}

@freezed
/// AgentDto defines a public contract.
abstract class AgentDto with _$AgentDto {
  /// The AgentDto public API member.
  const factory AgentDto({
    required String id,
    required String workspaceId,
    required String title,
    required String providerId,
    required String model,
    required AgentStatus status,
    required PermissionMode permissionMode,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default('medium') String reasoningEffort,
    String? activeTurnId,
    String? lastError,
  }) = _AgentDto;

  /// Creates a [AgentDto].
  factory AgentDto.fromJson(Map<String, dynamic> json) =>
      _$AgentDtoFromJson(json);
}

@freezed
/// ModelCapabilitiesDto defines a public contract.
abstract class ModelCapabilitiesDto with _$ModelCapabilitiesDto {
  /// The ModelCapabilitiesDto public API member.
  const factory ModelCapabilitiesDto({
    @Default(CapabilitySupport.unknown) CapabilitySupport streaming,
    @Default(CapabilitySupport.unknown) CapabilitySupport toolCalling,
    @Default(CapabilitySupport.unknown) CapabilitySupport reasoningEffort,
    @Default(<String>[]) List<String> supportedReasoningEfforts,
    @Default(CapabilitySource.unknown) CapabilitySource source,
  }) = _ModelCapabilitiesDto;

  /// Creates a [ModelCapabilitiesDto].
  factory ModelCapabilitiesDto.fromJson(Map<String, dynamic> json) =>
      _$ModelCapabilitiesDtoFromJson(json);
}

@freezed
/// ApiProviderDto defines a public contract.
abstract class ApiProviderDto with _$ApiProviderDto {
  /// The ApiProviderDto public API member.
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

  /// Creates a [ApiProviderDto].
  factory ApiProviderDto.fromJson(Map<String, dynamic> json) =>
      _$ApiProviderDtoFromJson(json);
}

@freezed
/// ProviderPresetDto defines a public contract.
abstract class ProviderPresetDto with _$ProviderPresetDto {
  /// The ProviderPresetDto public API member.
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

  /// Creates a [ProviderPresetDto].
  factory ProviderPresetDto.fromJson(Map<String, dynamic> json) =>
      _$ProviderPresetDtoFromJson(json);
}

@freezed
/// ProviderModelDto defines a public contract.
abstract class ProviderModelDto with _$ProviderModelDto {
  /// The ProviderModelDto public API member.
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

  /// Creates a [ProviderModelDto].
  factory ProviderModelDto.fromJson(Map<String, dynamic> json) =>
      _$ProviderModelDtoFromJson(json);
}

@freezed
/// ProviderCatalogDto defines a public contract.
abstract class ProviderCatalogDto with _$ProviderCatalogDto {
  /// The ProviderCatalogDto public API member.
  const factory ProviderCatalogDto({
    required List<ApiProviderDto> providers,
    required List<ProviderPresetDto> presets,
    String? defaultProviderId,
  }) = _ProviderCatalogDto;

  /// Creates a [ProviderCatalogDto].
  factory ProviderCatalogDto.fromJson(Map<String, dynamic> json) =>
      _$ProviderCatalogDtoFromJson(json);
}

@freezed
/// ProviderDiagnosticDto defines a public contract.
abstract class ProviderDiagnosticDto with _$ProviderDiagnosticDto {
  /// The ProviderDiagnosticDto public API member.
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

  /// Creates a [ProviderDiagnosticDto].
  factory ProviderDiagnosticDto.fromJson(Map<String, dynamic> json) =>
      _$ProviderDiagnosticDtoFromJson(json);
}

@freezed
/// TimelineEventDto defines a public contract.
abstract class TimelineEventDto with _$TimelineEventDto {
  /// The TimelineEventDto public API member.
  const factory TimelineEventDto({
    required String agentId,
    required int sequence,
    required String type,
    required Map<String, dynamic> data,
    required DateTime createdAt,
    String? turnId,
  }) = _TimelineEventDto;

  /// Creates a [TimelineEventDto].
  factory TimelineEventDto.fromJson(Map<String, dynamic> json) =>
      _$TimelineEventDtoFromJson(json);
}

@freezed
/// ApprovalRequestDto defines a public contract.
abstract class ApprovalRequestDto with _$ApprovalRequestDto {
  /// The ApprovalRequestDto public API member.
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

  /// Creates a [ApprovalRequestDto].
  factory ApprovalRequestDto.fromJson(Map<String, dynamic> json) =>
      _$ApprovalRequestDtoFromJson(json);
}

@freezed
/// ServerInfoDto defines a public contract.
abstract class ServerInfoDto with _$ServerInfoDto {
  /// The ServerInfoDto public API member.
  const factory ServerInfoDto({
    required String serverId,
    required String version,
    required int protocolVersion,
    required Map<String, bool> features,
  }) = _ServerInfoDto;

  /// Creates a [ServerInfoDto].
  factory ServerInfoDto.fromJson(Map<String, dynamic> json) =>
      _$ServerInfoDtoFromJson(json);
}

@freezed
/// RpcErrorDto defines a public contract.
abstract class RpcErrorDto with _$RpcErrorDto {
  /// The RpcErrorDto public API member.
  const factory RpcErrorDto({
    required String code,
    required String message,
    required bool retryable,
    Map<String, dynamic>? details,
  }) = _RpcErrorDto;

  /// Creates a [RpcErrorDto].
  factory RpcErrorDto.fromJson(Map<String, dynamic> json) =>
      _$RpcErrorDtoFromJson(json);
}
