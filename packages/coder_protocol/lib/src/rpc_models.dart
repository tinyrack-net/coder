import 'package:coder_protocol/src/models.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'rpc_models.freezed.dart';
part 'rpc_models.g.dart';

@freezed
/// HelloParamsDto defines a public contract.
abstract class HelloParamsDto with _$HelloParamsDto {
  /// The HelloParamsDto public API member.
  const factory HelloParamsDto({
    required String clientId,
    required String clientKind,
    required int protocolVersion,
    required Map<String, bool> capabilities,
  }) = _HelloParamsDto;

  /// Creates a [HelloParamsDto].
  factory HelloParamsDto.fromJson(Map<String, dynamic> json) =>
      _$HelloParamsDtoFromJson(json);
}

@freezed
/// WorkspaceRegisterParamsDto defines a public contract.
abstract class WorkspaceRegisterParamsDto with _$WorkspaceRegisterParamsDto {
  /// The WorkspaceRegisterParamsDto public API member.
  const factory WorkspaceRegisterParamsDto({
    required String id,
    required String rootPath,
    required String name,
  }) = _WorkspaceRegisterParamsDto;

  /// Creates a [WorkspaceRegisterParamsDto].
  factory WorkspaceRegisterParamsDto.fromJson(Map<String, dynamic> json) =>
      _$WorkspaceRegisterParamsDtoFromJson(json);
}

@freezed
/// AgentListParamsDto defines a public contract.
abstract class AgentListParamsDto with _$AgentListParamsDto {
  /// The AgentListParamsDto public API member.
  const factory AgentListParamsDto({String? workspaceId}) = _AgentListParamsDto;

  /// Creates a [AgentListParamsDto].
  factory AgentListParamsDto.fromJson(Map<String, dynamic> json) =>
      _$AgentListParamsDtoFromJson(json);
}

@freezed
/// AgentCreateParamsDto defines a public contract.
abstract class AgentCreateParamsDto with _$AgentCreateParamsDto {
  /// The AgentCreateParamsDto public API member.
  const factory AgentCreateParamsDto({
    required String id,
    required String workspaceId,
    required String title,
    required String providerId,
    required String model,
    required String reasoningEffort,
    required PermissionMode permissionMode,
  }) = _AgentCreateParamsDto;

  /// Creates a [AgentCreateParamsDto].
  factory AgentCreateParamsDto.fromJson(Map<String, dynamic> json) =>
      _$AgentCreateParamsDtoFromJson(json);
}

@freezed
/// AgentConfigurationUpdateParamsDto defines a public contract.
abstract class AgentConfigurationUpdateParamsDto
    with _$AgentConfigurationUpdateParamsDto {
  /// The AgentConfigurationUpdateParamsDto public API member.
  const factory AgentConfigurationUpdateParamsDto({
    required String agentId,
    required String providerId,
    required String model,
    required String reasoningEffort,
  }) = _AgentConfigurationUpdateParamsDto;

  /// Creates a [AgentConfigurationUpdateParamsDto].
  factory AgentConfigurationUpdateParamsDto.fromJson(
    Map<String, dynamic> json,
  ) => _$AgentConfigurationUpdateParamsDtoFromJson(json);
}

@freezed
/// ProviderUpsertParamsDto defines a public contract.
abstract class ProviderUpsertParamsDto with _$ProviderUpsertParamsDto {
  /// The ProviderUpsertParamsDto public API member.
  const factory ProviderUpsertParamsDto({
    required ApiProviderDto provider,
    required bool makeDefault,
  }) = _ProviderUpsertParamsDto;

  /// Creates a [ProviderUpsertParamsDto].
  factory ProviderUpsertParamsDto.fromJson(Map<String, dynamic> json) =>
      _$ProviderUpsertParamsDtoFromJson(json);
}

@freezed
/// ProviderIdParamsDto defines a public contract.
abstract class ProviderIdParamsDto with _$ProviderIdParamsDto {
  /// The ProviderIdParamsDto public API member.
  const factory ProviderIdParamsDto({required String providerId}) =
      _ProviderIdParamsDto;

  /// Creates a [ProviderIdParamsDto].
  factory ProviderIdParamsDto.fromJson(Map<String, dynamic> json) =>
      _$ProviderIdParamsDtoFromJson(json);
}

@freezed
/// ProviderModelParamsDto defines a public contract.
abstract class ProviderModelParamsDto with _$ProviderModelParamsDto {
  /// The ProviderModelParamsDto public API member.
  const factory ProviderModelParamsDto({
    required String providerId,
    required String modelId,
  }) = _ProviderModelParamsDto;

  /// Creates a [ProviderModelParamsDto].
  factory ProviderModelParamsDto.fromJson(Map<String, dynamic> json) =>
      _$ProviderModelParamsDtoFromJson(json);
}

@freezed
/// ProviderModelUpsertParamsDto defines a public contract.
abstract class ProviderModelUpsertParamsDto
    with _$ProviderModelUpsertParamsDto {
  /// The ProviderModelUpsertParamsDto public API member.
  const factory ProviderModelUpsertParamsDto({
    required ProviderModelDto model,
  }) = _ProviderModelUpsertParamsDto;

  /// Creates a [ProviderModelUpsertParamsDto].
  factory ProviderModelUpsertParamsDto.fromJson(Map<String, dynamic> json) =>
      _$ProviderModelUpsertParamsDtoFromJson(json);
}

@freezed
/// ProviderCredentialSetParamsDto defines a public contract.
abstract class ProviderCredentialSetParamsDto
    with _$ProviderCredentialSetParamsDto {
  /// The ProviderCredentialSetParamsDto public API member.
  const factory ProviderCredentialSetParamsDto({
    required String providerId,
    required String apiKey,
  }) = _ProviderCredentialSetParamsDto;

  /// Creates a [ProviderCredentialSetParamsDto].
  factory ProviderCredentialSetParamsDto.fromJson(Map<String, dynamic> json) =>
      _$ProviderCredentialSetParamsDtoFromJson(json);
}

@freezed
/// TurnStartParamsDto defines a public contract.
abstract class TurnStartParamsDto with _$TurnStartParamsDto {
  /// The TurnStartParamsDto public API member.
  const factory TurnStartParamsDto({
    required String agentId,
    required String turnId,
    required String prompt,
  }) = _TurnStartParamsDto;

  /// Creates a [TurnStartParamsDto].
  factory TurnStartParamsDto.fromJson(Map<String, dynamic> json) =>
      _$TurnStartParamsDtoFromJson(json);
}

@freezed
/// AgentIdParamsDto defines a public contract.
abstract class AgentIdParamsDto with _$AgentIdParamsDto {
  /// The AgentIdParamsDto public API member.
  const factory AgentIdParamsDto({required String agentId}) = _AgentIdParamsDto;

  /// Creates a [AgentIdParamsDto].
  factory AgentIdParamsDto.fromJson(Map<String, dynamic> json) =>
      _$AgentIdParamsDtoFromJson(json);
}

@freezed
/// ApprovalResolveParamsDto defines a public contract.
abstract class ApprovalResolveParamsDto with _$ApprovalResolveParamsDto {
  /// The ApprovalResolveParamsDto public API member.
  const factory ApprovalResolveParamsDto({
    required String approvalId,
    required bool approved,
  }) = _ApprovalResolveParamsDto;

  /// Creates a [ApprovalResolveParamsDto].
  factory ApprovalResolveParamsDto.fromJson(Map<String, dynamic> json) =>
      _$ApprovalResolveParamsDtoFromJson(json);
}

@freezed
/// TimelineSubscribeParamsDto defines a public contract.
abstract class TimelineSubscribeParamsDto with _$TimelineSubscribeParamsDto {
  /// The TimelineSubscribeParamsDto public API member.
  const factory TimelineSubscribeParamsDto({
    required String agentId,
    required int afterSequence,
  }) = _TimelineSubscribeParamsDto;

  /// Creates a [TimelineSubscribeParamsDto].
  factory TimelineSubscribeParamsDto.fromJson(Map<String, dynamic> json) =>
      _$TimelineSubscribeParamsDtoFromJson(json);
}

@freezed
/// WorkspaceListResultDto defines a public contract.
abstract class WorkspaceListResultDto with _$WorkspaceListResultDto {
  /// The WorkspaceListResultDto public API member.
  const factory WorkspaceListResultDto({
    required List<WorkspaceDto> workspaces,
  }) = _WorkspaceListResultDto;

  /// Creates a [WorkspaceListResultDto].
  factory WorkspaceListResultDto.fromJson(Map<String, dynamic> json) =>
      _$WorkspaceListResultDtoFromJson(json);
}

@freezed
/// WorkspaceResultDto defines a public contract.
abstract class WorkspaceResultDto with _$WorkspaceResultDto {
  /// The WorkspaceResultDto public API member.
  const factory WorkspaceResultDto({required WorkspaceDto workspace}) =
      _WorkspaceResultDto;

  /// Creates a [WorkspaceResultDto].
  factory WorkspaceResultDto.fromJson(Map<String, dynamic> json) =>
      _$WorkspaceResultDtoFromJson(json);
}

@freezed
/// AgentListResultDto defines a public contract.
abstract class AgentListResultDto with _$AgentListResultDto {
  /// The AgentListResultDto public API member.
  const factory AgentListResultDto({required List<AgentDto> agents}) =
      _AgentListResultDto;

  /// Creates a [AgentListResultDto].
  factory AgentListResultDto.fromJson(Map<String, dynamic> json) =>
      _$AgentListResultDtoFromJson(json);
}

@freezed
/// AgentResultDto defines a public contract.
abstract class AgentResultDto with _$AgentResultDto {
  /// The AgentResultDto public API member.
  const factory AgentResultDto({required AgentDto agent}) = _AgentResultDto;

  /// Creates a [AgentResultDto].
  factory AgentResultDto.fromJson(Map<String, dynamic> json) =>
      _$AgentResultDtoFromJson(json);
}

@freezed
/// ProviderCatalogResultDto defines a public contract.
abstract class ProviderCatalogResultDto with _$ProviderCatalogResultDto {
  /// The ProviderCatalogResultDto public API member.
  const factory ProviderCatalogResultDto({
    required ProviderCatalogDto catalog,
  }) = _ProviderCatalogResultDto;

  /// Creates a [ProviderCatalogResultDto].
  factory ProviderCatalogResultDto.fromJson(Map<String, dynamic> json) =>
      _$ProviderCatalogResultDtoFromJson(json);
}

@freezed
/// ProviderResultDto defines a public contract.
abstract class ProviderResultDto with _$ProviderResultDto {
  /// The ProviderResultDto public API member.
  const factory ProviderResultDto({required ApiProviderDto provider}) =
      _ProviderResultDto;

  /// Creates a [ProviderResultDto].
  factory ProviderResultDto.fromJson(Map<String, dynamic> json) =>
      _$ProviderResultDtoFromJson(json);
}

@freezed
/// ProviderModelsResultDto defines a public contract.
abstract class ProviderModelsResultDto with _$ProviderModelsResultDto {
  /// The ProviderModelsResultDto public API member.
  const factory ProviderModelsResultDto({
    required List<ProviderModelDto> models,
  }) = _ProviderModelsResultDto;

  /// Creates a [ProviderModelsResultDto].
  factory ProviderModelsResultDto.fromJson(Map<String, dynamic> json) =>
      _$ProviderModelsResultDtoFromJson(json);
}

@freezed
/// ProviderModelResultDto defines a public contract.
abstract class ProviderModelResultDto with _$ProviderModelResultDto {
  /// The ProviderModelResultDto public API member.
  const factory ProviderModelResultDto({required ProviderModelDto model}) =
      _ProviderModelResultDto;

  /// Creates a [ProviderModelResultDto].
  factory ProviderModelResultDto.fromJson(Map<String, dynamic> json) =>
      _$ProviderModelResultDtoFromJson(json);
}

@freezed
/// ProviderDiagnosticResultDto defines a public contract.
abstract class ProviderDiagnosticResultDto with _$ProviderDiagnosticResultDto {
  /// The ProviderDiagnosticResultDto public API member.
  const factory ProviderDiagnosticResultDto({
    required ProviderDiagnosticDto diagnostic,
  }) = _ProviderDiagnosticResultDto;

  /// Creates a [ProviderDiagnosticResultDto].
  factory ProviderDiagnosticResultDto.fromJson(Map<String, dynamic> json) =>
      _$ProviderDiagnosticResultDtoFromJson(json);
}

@freezed
/// TurnStartResultDto defines a public contract.
abstract class TurnStartResultDto with _$TurnStartResultDto {
  /// The TurnStartResultDto public API member.
  const factory TurnStartResultDto({required bool created}) =
      _TurnStartResultDto;

  /// Creates a [TurnStartResultDto].
  factory TurnStartResultDto.fromJson(Map<String, dynamic> json) =>
      _$TurnStartResultDtoFromJson(json);
}

@freezed
/// ApprovalResultDto defines a public contract.
abstract class ApprovalResultDto with _$ApprovalResultDto {
  /// The ApprovalResultDto public API member.
  const factory ApprovalResultDto({required ApprovalRequestDto approval}) =
      _ApprovalResultDto;

  /// Creates a [ApprovalResultDto].
  factory ApprovalResultDto.fromJson(Map<String, dynamic> json) =>
      _$ApprovalResultDtoFromJson(json);
}

@freezed
/// TimelineResultDto defines a public contract.
abstract class TimelineResultDto with _$TimelineResultDto {
  /// The TimelineResultDto public API member.
  const factory TimelineResultDto({required List<TimelineEventDto> events}) =
      _TimelineResultDto;

  /// Creates a [TimelineResultDto].
  factory TimelineResultDto.fromJson(Map<String, dynamic> json) =>
      _$TimelineResultDtoFromJson(json);
}
