import 'package:agent/src/prompts/prompt_assets.g.dart';

/// Developer instructions appended while a session is in plan mode.
///
/// Ported from the Codex CLI collaboration-mode template so the behavior
/// matches: planning is enforced by instructions, not by the approval policy.
String planModeInstructions() => PromptAssets.collabPlanMode;
