import 'package:cliweave/cliweave.dart';
import 'package:coder_cli/src/cli/context.dart';

/// Shell scripts that call back into the hidden completion command.
final CompletionScripts completionScripts = CompletionScripts(
  executableName: 'coder-cli',
);

Command<CoderCliContext> _scriptCommand(String shell, String script) {
  return buildCommand(
    docs: CommandDocs(
      brief: 'Print the $shell completion script',
      fullDescription:
          'Load it with `source <(coder-cli completion $shell)`, or write it '
          'to the completion directory of $shell to install it permanently.',
    ),
    parameters: CommandParameters(
      flags: FlagSet<NoFlags, CoderCliContext>.none(),
      positional: PositionalSet.none(),
    ),
    func: (context, flags, args) => context.process.stdout.write(script),
  );
}

/// The hidden route the generated shell scripts invoke.
///
/// It answers one `completion<TAB>description` line per candidate. The
/// application is read from the context because it is built from this very
/// command.
final Command<CoderCliContext> completeCommand = buildCommand(
  docs: const CommandDocs(brief: 'Propose completions for a partial command'),
  parameters: CommandParameters(
    flags: FlagSet<NoFlags, CoderCliContext>.none(),
    positional: PositionalSet.array(
      Positional.required<String, CoderCliContext>(
        brief: 'Partial command line',
        parse: stringParser,
        placeholder: 'input',
      ),
    ),
  ),
  func: (context, flags, args) async {
    final application = context.application;
    if (application == null) return;
    final completions = await proposeCompletions(
      application,
      completionScripts.resolveCompletionInputs(args),
      RunContext.direct(context),
    );
    if (completions.isEmpty) return;
    final lines = completions
        .map(
          (candidate) => candidate.brief.isEmpty
              ? candidate.completion
              : '${candidate.completion}\t${candidate.brief}',
        )
        .join('\n');
    context.process.stdout.write('$lines\n');
  },
);

/// The `coder-cli completion` route map.
RouteMap<CoderCliContext> buildCompletionRoutes() => buildRouteMap(
  docs: const RouteMapDocs(brief: 'Print a shell completion script'),
  routes: <String, RoutingTarget<CoderCliContext>>{
    'bash': _scriptCommand('bash', completionScripts.bash),
    'zsh': _scriptCommand('zsh', completionScripts.zsh),
    'fish': _scriptCommand('fish', completionScripts.fish),
    'powershell': _scriptCommand('powershell', completionScripts.powershell),
  },
);
