import 'package:agent/src/prompts/prompt_assets.g.dart';

/// Instructions injected while a session goal is being pursued.
///
/// Renders `{{objective}}`, `{{tokensUsed}}`, `{{tokenBudget}}`, and
/// `{{remainingTokens}}`.
const String goalContinuationPrompt = PromptAssets.goalsContinuation;

/// Instructions injected once a session goal has spent its token budget.
///
/// Renders `{{objective}}`, `{{tokensUsed}}`, and `{{tokenBudget}}`.
const String goalBudgetLimitPrompt = PromptAssets.goalsBudgetLimit;

/// How an agent that owns subagents should coordinate them.
const String orchestratorPrompt = PromptAssets.agentsOrchestrator;

/// How a spawned subagent should carry out the task it was delegated.
const String subagentPrompt = PromptAssets.agentsSubagent;

/// How to write a patch the `apply_patch` tool will accept.
const String applyPatchToolInstructions =
    PromptAssets.applyPatchToolInstructions;
