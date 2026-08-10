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

/// The related set of capabilities a client presents and toggles together.
///
/// A capability declares its own group, so the one list in
/// `builtInAgentToolRegistry` stays the whole registration surface. Declaration
/// order here is the order groups are presented in, which is why it is separate
/// from registry order: the registry order is what the model is advertised, and
/// reordering it to suit a settings screen would change what the model sees.
enum AgentToolGroup {
  /// Finds and reads workspace files.
  filesystem,

  /// Changes workspace files.
  editing,

  /// Starts processes.
  execution,

  /// Moves files in and out of the conversation as attachments.
  attachments,

  /// Reaches MCP servers and the resources they publish.
  mcp,

  /// Drives collaborating subagents.
  collaboration,

  /// Steers the turn itself: plans, questions, and time.
  session,
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

/// Model-facing tool surface selected for one turn.
enum AgentToolSurfaceMode {
  /// Tools are exposed directly.
  direct,

  /// Only Lua orchestration entrypoints are exposed directly.
  luaCode,
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

/// Value shape accepted by a provider-owned model control.
enum AgentModelControlKind {
  /// A closed set of strings.
  choice,

  /// An on/off value.
  toggle,

  /// A bounded whole number.
  integer,
}

/// Presentation hint for a provider-owned model control.
enum AgentModelControlPresentation {
  /// A compact menu chip.
  menuChip,

  /// A selectable chip.
  selectableChip,

  /// A validated numeric dialog.
  numberDialog,
}

/// Stable control IDs understood by built-in provider plugins.
abstract final class AgentModelControlIds {
  /// Provider-specific reasoning effort or level.
  static const String reasoningEffort = 'reasoning_effort';

  /// Provider-specific reasoning strategy.
  static const String reasoningMode = 'reasoning_mode';

  /// Explicit reasoning-token budget.
  static const String thinkingBudget = 'thinking_budget';

  /// Provider fast or priority processing mode.
  static const String fastMode = 'fast_mode';
}

/// One permitted value for a choice control.
final class AgentModelControlChoice {
  /// Creates a choice.
  const AgentModelControlChoice({
    required this.id,
    required this.label,
    this.description,
  });

  /// Stable provider value.
  final String id;

  /// User-facing label.
  final String label;

  /// Optional user-facing explanation.
  final String? description;
}

/// Describes a model-specific request control.
final class AgentModelControlDescriptor {
  /// Creates a descriptor.
  const AgentModelControlDescriptor({
    required this.id,
    required this.label,
    required this.kind,
    required this.presentation,
    this.description,
    this.choices = const <AgentModelControlChoice>[],
    this.minimum,
    this.maximum,
    this.step,
    this.conflictsWith = const <String>[],
  });

  /// Stable ID.
  final String id;

  /// User-facing label.
  final String label;

  /// Accepted value shape.
  final AgentModelControlKind kind;

  /// Suggested client presentation.
  final AgentModelControlPresentation presentation;

  /// Optional explanation.
  final String? description;

  /// Permitted values for [AgentModelControlKind.choice].
  final List<AgentModelControlChoice> choices;

  /// Inclusive lower bound for integer values.
  final int? minimum;

  /// Inclusive upper bound for integer values.
  final int? maximum;

  /// Permitted integer increment.
  final int? step;

  /// IDs that cannot be submitted with this control.
  final List<String> conflictsWith;
}

/// A typed provider-control value.
sealed class AgentModelControlValue {
  const AgentModelControlValue();
}

/// A closed-set string value.
final class AgentModelControlStringValue extends AgentModelControlValue {
  /// Creates a string value.
  const AgentModelControlStringValue({required this.value});

  /// Provider value.
  final String value;
}

/// A boolean value.
final class AgentModelControlBoolValue extends AgentModelControlValue {
  /// Creates a boolean value.
  const AgentModelControlBoolValue({required this.value});

  /// Provider value.
  final bool value;
}

/// An integer value.
final class AgentModelControlIntValue extends AgentModelControlValue {
  /// Creates an integer value.
  const AgentModelControlIntValue({required this.value});

  /// Provider value.
  final int value;
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
    this.imageInput = AgentCapabilitySupport.unknown,
    this.fileInput = AgentCapabilitySupport.unknown,
    this.toolSurface = AgentToolSurfaceMode.direct,
    this.controls = const <AgentModelControlDescriptor>[],
    this.source = AgentCapabilitySource.unknown,
  });

  /// Streaming support.
  final AgentCapabilitySupport streaming;

  /// Tool-calling support.
  final AgentCapabilitySupport toolCalling;

  /// Image-input support.
  final AgentCapabilitySupport imageInput;

  /// File-input support.
  final AgentCapabilitySupport fileInput;

  /// Model-selected orchestration surface.
  final AgentToolSurfaceMode toolSurface;

  /// Provider-owned controls accepted by this model and endpoint.
  final List<AgentModelControlDescriptor> controls;

  /// Metadata provenance.
  final AgentCapabilitySource source;

  /// Returns a copy with selected fields replaced.
  AgentModelCapabilities copyWith({
    AgentCapabilitySupport? streaming,
    AgentCapabilitySupport? toolCalling,
    AgentCapabilitySupport? imageInput,
    AgentCapabilitySupport? fileInput,
    AgentToolSurfaceMode? toolSurface,
    List<AgentModelControlDescriptor>? controls,
    AgentCapabilitySource? source,
  }) => AgentModelCapabilities(
    streaming: streaming ?? this.streaming,
    toolCalling: toolCalling ?? this.toolCalling,
    imageInput: imageInput ?? this.imageInput,
    fileInput: fileInput ?? this.fileInput,
    toolSurface: toolSurface ?? this.toolSurface,
    controls: controls ?? this.controls,
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
    required this.group,
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

  /// The related capabilities this one is presented and toggled with.
  final AgentToolGroup group;

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
