import 'package:coder_agent/coder_agent.dart';
import 'package:coder_protocol/coder_protocol.dart';

/// Converts protocol risk to the agent domain.
AgentToolRisk agentRisk(ToolRisk value) =>
    AgentToolRisk.values.byName(value.name);

/// Converts agent risk to the protocol contract.
ToolRisk protocolRisk(AgentToolRisk value) =>
    ToolRisk.values.byName(value.name);

/// Converts protocol permissions to the agent domain.
AgentPermissionMode agentPermission(PermissionMode value) =>
    AgentPermissionMode.values.byName(value.name);

/// Converts protocol session mode to the agent domain.
AgentSessionMode agentSessionMode(SessionMode value) =>
    AgentSessionMode.values.byName(value.name);

/// Converts agent runtime status to the protocol contract.
SessionStatus protocolSessionStatus(AgentSessionStatus value) =>
    SessionStatus.values.byName(value.name);

/// Converts attachment category to the agent domain.
AgentAttachmentKind agentAttachmentKind(AttachmentKind value) =>
    AgentAttachmentKind.values.byName(value.name);

/// Converts provider authentication kind to the agent domain.
AgentProviderAuthKind agentAuthKind(ProviderAuthKind value) =>
    AgentProviderAuthKind.values.byName(value.name);

/// Converts provider authorization flow to the agent domain.
AgentProviderAuthFlow agentAuthFlow(ProviderAuthFlow value) =>
    AgentProviderAuthFlow.values.byName(value.name);

/// Converts provider authorization flow to the protocol contract.
ProviderAuthFlow protocolAuthFlow(AgentProviderAuthFlow value) =>
    ProviderAuthFlow.values.byName(value.name);

/// Converts model capabilities to the agent domain.
AgentModelCapabilities agentCapabilities(ModelCapabilitiesDto value) =>
    AgentModelCapabilities(
      streaming: AgentCapabilitySupport.values.byName(value.streaming.name),
      toolCalling: AgentCapabilitySupport.values.byName(value.toolCalling.name),
      reasoningEffort: AgentCapabilitySupport.values.byName(
        value.reasoningEffort.name,
      ),
      imageInput: AgentCapabilitySupport.values.byName(value.imageInput.name),
      fileInput: AgentCapabilitySupport.values.byName(value.fileInput.name),
      serviceTier: AgentCapabilitySupport.values.byName(value.serviceTier.name),
      supportedReasoningEfforts: value.supportedReasoningEfforts,
      supportedServiceTiers: value.supportedServiceTiers,
      source: AgentCapabilitySource.values.byName(value.source.name),
    );

/// Converts model capabilities to the protocol contract.
ModelCapabilitiesDto protocolCapabilities(AgentModelCapabilities value) =>
    ModelCapabilitiesDto(
      streaming: CapabilitySupport.values.byName(value.streaming.name),
      toolCalling: CapabilitySupport.values.byName(value.toolCalling.name),
      reasoningEffort: CapabilitySupport.values.byName(
        value.reasoningEffort.name,
      ),
      imageInput: CapabilitySupport.values.byName(value.imageInput.name),
      fileInput: CapabilitySupport.values.byName(value.fileInput.name),
      serviceTier: CapabilitySupport.values.byName(value.serviceTier.name),
      supportedReasoningEfforts: value.supportedReasoningEfforts,
      supportedServiceTiers: value.supportedServiceTiers,
      source: CapabilitySource.values.byName(value.source.name),
    );

/// Converts optional pricing to the protocol contract.
ModelPricingDto? protocolPricing(AgentModelPricing? value) => value == null
    ? null
    : ModelPricingDto(
        input: value.input,
        output: value.output,
        cacheRead: value.cacheRead,
        cacheWrite: value.cacheWrite,
      );

/// Converts optional token limits to the protocol contract.
ModelLimitsDto? protocolLimits(AgentModelLimits? value) => value == null
    ? null
    : ModelLimitsDto(
        context: value.context,
        input: value.input,
        output: value.output,
      );

/// Converts provider metadata to the protocol contract.
ProviderDefinitionDto protocolProviderDefinition(
  AgentProviderDefinition value,
) => ProviderDefinitionDto(
  id: value.id,
  name: value.name,
  description: value.description,
  authMethods: <ProviderAuthMethodDto>[
    for (final method in value.authMethods)
      ProviderAuthMethodDto(
        id: method.id,
        label: method.label,
        kind: ProviderAuthKind.values.byName(method.kind.name),
        flow: ProviderAuthFlow.values.byName(method.flow.name),
        experimental: method.experimental,
      ),
  ],
  recommendedModelIds: value.recommendedModelIds,
  local: value.local,
  experimental: value.experimental,
  documentationUrl: value.documentationUrl,
);

/// Converts tool metadata to the protocol contract.
AgentToolDefinitionDto protocolToolDefinition(AgentToolDefinition value) =>
    AgentToolDefinitionDto(
      id: value.id,
      name: value.name,
      description: value.description,
      risk: protocolRisk(value.risk),
      available: value.available,
      alwaysOn: value.alwaysOn,
    );
