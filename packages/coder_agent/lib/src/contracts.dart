/// Provider-neutral risk classification used by approval policies.
enum AgentToolRisk {
  /// Reads state only.
  read,

  /// Writes workspace state.
  write,

  /// Starts a process.
  command,

  /// Has effects the runtime cannot classify.
  dangerous,
}

/// Permission policy selected for one agent turn.
enum AgentPermissionMode {
  /// Refuses mutation.
  readOnly,

  /// Requests approval for mutation.
  ask,

  /// Allows workspace writes.
  workspaceWrite,

  /// Allows every tool.
  fullAccess,
}

/// Collaboration mode of one agent run.
enum AgentSessionMode {
  /// Executes normal turns.
  normal,

  /// Restricts a turn to planning.
  plan,
}

/// Runtime lifecycle states emitted by the agent engine.
enum AgentSessionStatus {
  /// Runtime is initializing.
  initializing,

  /// Runtime is idle.
  idle,

  /// A turn is running.
  running,

  /// A tool awaits approval.
  waitingForApproval,

  /// A question awaits user input.
  waitingForInput,

  /// A turn failed.
  failed,

  /// Session is closed.
  closed,
}

/// Broad attachment category understood by provider adapters.
enum AgentAttachmentKind {
  /// Previewable image bytes.
  image,

  /// Any other file.
  file,
}

/// Support level reported for a model capability.
enum AgentCapabilitySupport {
  /// Support is unknown.
  unknown,

  /// Capability is supported.
  supported,

  /// Capability is unsupported.
  unsupported,
}

/// Provenance of model capability metadata.
enum AgentCapabilitySource {
  /// No source is known.
  unknown,

  /// Bundled metadata supplied the value.
  bundled,

  /// Refreshed metadata supplied the value.
  refreshed,

  /// A diagnostic supplied the value.
  diagnostic,

  /// The user supplied the value.
  manual,
}

/// Provider authentication mechanism.
enum AgentProviderAuthKind {
  /// Provider API key.
  apiKey,

  /// OAuth credentials.
  oauth,

  /// No credentials.
  none,
}

/// Interactive authorization flow.
enum AgentProviderAuthFlow {
  /// No interaction.
  none,

  /// Direct API-key input.
  apiKey,

  /// Browser callback OAuth.
  oauthBrowser,

  /// Device-code OAuth.
  oauthDevice,
}

/// Provider-neutral model capabilities consumed by the runtime.
final class AgentModelCapabilities {
  /// Creates provider-neutral capability metadata.
  const AgentModelCapabilities({
    this.streaming = AgentCapabilitySupport.unknown,
    this.toolCalling = AgentCapabilitySupport.unknown,
    this.reasoningEffort = AgentCapabilitySupport.unknown,
    this.imageInput = AgentCapabilitySupport.unknown,
    this.fileInput = AgentCapabilitySupport.unknown,
    this.serviceTier = AgentCapabilitySupport.unknown,
    this.supportedReasoningEfforts = const <String>[],
    this.supportedServiceTiers = const <String>[],
    this.source = AgentCapabilitySource.unknown,
  });

  /// Streaming support.
  final AgentCapabilitySupport streaming;

  /// Tool-calling support.
  final AgentCapabilitySupport toolCalling;

  /// Reasoning-effort support.
  final AgentCapabilitySupport reasoningEffort;

  /// Image-input support.
  final AgentCapabilitySupport imageInput;

  /// File-input support.
  final AgentCapabilitySupport fileInput;

  /// Service-tier support.
  final AgentCapabilitySupport serviceTier;

  /// Accepted reasoning efforts.
  final List<String> supportedReasoningEfforts;

  /// Accepted service tiers.
  final List<String> supportedServiceTiers;

  /// Metadata provenance.
  final AgentCapabilitySource source;

  /// Returns a copy with selected fields replaced.
  AgentModelCapabilities copyWith({
    AgentCapabilitySupport? streaming,
    AgentCapabilitySupport? toolCalling,
    AgentCapabilitySupport? reasoningEffort,
    AgentCapabilitySupport? imageInput,
    AgentCapabilitySupport? fileInput,
    AgentCapabilitySupport? serviceTier,
    List<String>? supportedReasoningEfforts,
    List<String>? supportedServiceTiers,
    AgentCapabilitySource? source,
  }) => AgentModelCapabilities(
    streaming: streaming ?? this.streaming,
    toolCalling: toolCalling ?? this.toolCalling,
    reasoningEffort: reasoningEffort ?? this.reasoningEffort,
    imageInput: imageInput ?? this.imageInput,
    fileInput: fileInput ?? this.fileInput,
    serviceTier: serviceTier ?? this.serviceTier,
    supportedReasoningEfforts:
        supportedReasoningEfforts ?? this.supportedReasoningEfforts,
    supportedServiceTiers: supportedServiceTiers ?? this.supportedServiceTiers,
    source: source ?? this.source,
  );
}

/// Optional model pricing metadata.
final class AgentModelPricing {
  /// Creates optional pricing metadata.
  const AgentModelPricing({
    this.input,
    this.output,
    this.cacheRead,
    this.cacheWrite,
  });

  /// Input-token price.
  final double? input;

  /// Output-token price.
  final double? output;

  /// Cache-read price.
  final double? cacheRead;

  /// Cache-write price.
  final double? cacheWrite;
}

/// Optional model token limits.
final class AgentModelLimits {
  /// Creates optional token limits.
  const AgentModelLimits({this.context, this.input, this.output});

  /// Context-window limit.
  final int? context;

  /// Input-token limit.
  final int? input;

  /// Output-token limit.
  final int? output;
}

/// One public authentication choice of a provider plugin.
final class AgentProviderAuthMethod {
  /// Creates an authentication method.
  const AgentProviderAuthMethod({
    required this.id,
    required this.label,
    required this.kind,
    required this.flow,
    this.experimental = false,
  });

  /// Stable method identifier.
  final String id;

  /// Display label.
  final String label;

  /// Credential kind.
  final AgentProviderAuthKind kind;

  /// User interaction flow.
  final AgentProviderAuthFlow flow;

  /// Whether the method is experimental.
  final bool experimental;
}

/// Provider metadata owned by the provider-neutral agent boundary.
final class AgentProviderDefinition {
  /// Creates provider metadata.
  const AgentProviderDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.authMethods,
    this.recommendedModelIds = const <String>[],
    this.local = false,
    this.experimental = false,
    this.documentationUrl,
  });

  /// Stable provider identifier.
  final String id;

  /// Display name.
  final String name;

  /// User-facing description.
  final String description;

  /// Supported authentication methods.
  final List<AgentProviderAuthMethod> authMethods;

  /// Bundled recommended models.
  final List<String> recommendedModelIds;

  /// Whether the provider is local.
  final bool local;

  /// Whether the provider is experimental.
  final bool experimental;

  /// Optional documentation URL.
  final String? documentationUrl;
}

/// Tool metadata exposed by the pure agent runtime.
final class AgentToolDefinition {
  /// Creates tool metadata.
  const AgentToolDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.risk,
    this.available = true,
    this.alwaysOn = false,
  });

  /// Stable tool identifier.
  final String id;

  /// Display name.
  final String name;

  /// User-facing description.
  final String description;

  /// Approval risk.
  final AgentToolRisk risk;

  /// Whether the tool is available.
  final bool available;

  /// Whether every turn receives it.
  final bool alwaysOn;
}

/// Minimal session context required to build one turn's tools.
final class AgentSessionContext {
  /// Creates a session context.
  const AgentSessionContext({required this.id, this.value});

  /// Stable session identifier.
  final String id;

  /// Adapter-owned metadata opaque to the agent runtime.
  final Object? value;
}

/// Agent definition marker kept independent from wire DTOs.
final class AgentDefinitionContext {
  /// Creates a definition context.
  const AgentDefinitionContext({required this.id, this.value});

  /// Stable definition identifier.
  final String id;

  /// Adapter-owned metadata opaque to the agent runtime.
  final Object? value;
}
