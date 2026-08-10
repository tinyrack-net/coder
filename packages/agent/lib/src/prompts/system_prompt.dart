import 'package:agent/src/prompts/prompt_assets.g.dart';

/// Base instructions used when neither the caller nor the model supplies any.
const String defaultBaseInstructions = PromptAssets.baseInstructionsDefault;

/// Everything one turn contributes to the model's instructions.
///
/// The runner owns the order these layers appear in; each layer is a plain
/// string so this package never learns where a layer came from.
class SystemPromptInputs {
  /// Creates a [SystemPromptInputs].
  const SystemPromptInputs({
    required this.workspaceRoot,
    this.permissionsInstructions,
    this.environmentContext,
    this.projectDoc,
    this.toolPrompts = const <String>[],
    this.modeInstructions,
    this.customInstructions,
    this.internalInstructions,
  });

  /// Absolute path the turn treats as the workspace root.
  final String workspaceRoot;

  /// Describes what the turn may do without asking, and what it must ask for.
  final String? permissionsInstructions;

  /// Machine-readable description of where and how the turn runs.
  final String? environmentContext;

  /// Project documentation collected from the workspace, as user data.
  final String? projectDoc;

  /// System-prompt paragraphs contributed by the turn's own capabilities.
  final List<String> toolPrompts;

  /// Instructions for the collaboration mode the session is in.
  final String? modeInstructions;

  /// Operator- or agent-definition-supplied instructions.
  final String? customInstructions;

  /// Ephemeral daemon-owned instructions for this request only.
  final String? internalInstructions;
}

/// Assembles the instructions a single model request is issued under.
///
/// The order is fixed: base instructions, then the rules the turn runs under,
/// then the workspace's own documentation, then the turn's capabilities, and
/// finally the instructions the host layered on top. Later layers may refine
/// earlier ones, so the most specific instruction is the last one the model
/// reads.
String buildSystemPrompt(SystemPromptInputs inputs) {
  final layers = <String?>[
    defaultBaseInstructions,
    inputs.permissionsInstructions,
    inputs.environmentContext,
    inputs.projectDoc,
    ...inputs.toolPrompts,
    inputs.modeInstructions,
    inputs.customInstructions,
    inputs.internalInstructions,
  ];
  return layers
      .map((layer) => layer?.trim() ?? '')
      .where((layer) => layer.isNotEmpty)
      .join('\n\n');
}

/// Renders the environment block describing where this turn runs.
///
/// The shape mirrors the upstream `<environment_context>` block so a model
/// trained on it reads the same tags here.
String environmentContext({
  required String workspaceRoot,
  String? shell,
  String? operatingSystem,
}) {
  final buffer = StringBuffer()
    ..writeln('<environment_context>')
    ..writeln('  <cwd>${_escapeXml(workspaceRoot)}</cwd>');
  if (shell != null && shell.isNotEmpty) {
    buffer.writeln('  <shell>${_escapeXml(shell)}</shell>');
  }
  if (operatingSystem != null && operatingSystem.isNotEmpty) {
    buffer.writeln('  <os>${_escapeXml(operatingSystem)}</os>');
  }
  buffer.write('</environment_context>');
  return buffer.toString();
}

String _escapeXml(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');
