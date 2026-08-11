import 'package:cli/src/agent_cli.dart';
import 'package:cli/src/cli/context.dart';
import 'package:cli/src/cli/shared_flags.dart';
import 'package:cliweave/cliweave.dart';

final Command<TinestCliContext> _listCommand = buildCommand(
  docs: const CommandDocs(brief: 'List Markdown agent definitions'),
  parameters: CommandParameters(
    flags: daemonConnectionFlagSet(),
    positional: PositionalSet.none(),
  ),
  func: (context, flags, args) => withDaemon(
    context,
    flags,
    (client) => agentList(
      backend: TinestApiAgentCliBackend(client),
      output: context.output,
    ),
  ),
);

final Command<TinestCliContext> _validateCommand = buildCommand(
  docs: const CommandDocs(
    brief: 'Validate a Markdown definition without saving it',
    fullDescription:
        'The agent ID is taken from the file name, which is how a definition '
        'is named on disk.',
  ),
  parameters: CommandParameters(
    flags: daemonConnectionFlagSet(),
    positional: PositionalSet.one(
      Positional.required<String, TinestCliContext>(
        brief: 'Markdown file',
        parse: stringParser,
        placeholder: 'file',
      ),
    ).map((path) => (path: path)),
  ),
  func: (context, flags, args) => withDaemon(
    context,
    flags,
    (client) => agentValidate(
      backend: TinestApiAgentCliBackend(client),
      output: context.output,
      path: args.path,
      readFile: context.readFile,
    ),
  ),
);

final Command<TinestCliContext> _applyCommand = buildCommand(
  docs: const CommandDocs(brief: 'Create or update an agent definition'),
  parameters: CommandParameters(
    flags: daemonConnectionFlagSet()
        .and(
          ParsedFlag.required<String, TinestCliContext>(
            name: 'file',
            brief: 'Markdown file to apply',
            parse: stringParser,
            placeholder: 'path',
          ),
        )
        .map((values) => (daemon: values.$1, file: values.$2)),
    positional: PositionalSet.one(
      Positional.required<String, TinestCliContext>(
        brief: 'Agent ID',
        parse: stringParser,
        placeholder: 'id',
      ),
    ).map((id) => (id: id)),
  ),
  func: (context, flags, args) => withDaemon(
    context,
    flags.daemon,
    (client) => agentApply(
      backend: TinestApiAgentCliBackend(client),
      output: context.output,
      id: args.id,
      path: flags.file,
      readFile: context.readFile,
    ),
  ),
);

final Command<TinestCliContext> _archiveCommand = buildCommand(
  docs: const CommandDocs(brief: 'Archive a custom agent definition'),
  parameters: CommandParameters(
    flags: daemonConnectionFlagSet(),
    positional: PositionalSet.one(
      Positional.required<String, TinestCliContext>(
        brief: 'Agent ID',
        parse: stringParser,
        placeholder: 'id',
      ),
    ).map((id) => (id: id)),
  ),
  func: (context, flags, args) => withDaemon(
    context,
    flags,
    (client) => agentArchive(
      backend: TinestApiAgentCliBackend(client),
      output: context.output,
      id: args.id,
    ),
  ),
);

final Command<TinestCliContext> _resetCommand = buildCommand(
  docs: const CommandDocs(
    brief: 'Restore a built-in definition to its shipped content',
  ),
  parameters: CommandParameters(
    flags: daemonConnectionFlagSet(),
    positional: PositionalSet.one(
      Positional.required<String, TinestCliContext>(
        brief: 'Built-in agent ID',
        parse: stringParser,
        placeholder: 'tinest',
      ),
    ).map((id) => (id: id)),
  ),
  func: (context, flags, args) => withDaemon(
    context,
    flags,
    (client) => agentReset(
      backend: TinestApiAgentCliBackend(client),
      output: context.output,
      id: args.id,
    ),
  ),
);

/// The `tinest-cli agent` route map.
RouteMap<TinestCliContext> buildAgentRoutes() => buildRouteMap(
  docs: const RouteMapDocs(brief: 'Manage Markdown agent definitions'),
  routes: <String, RoutingTarget<TinestCliContext>>{
    'list': _listCommand,
    'validate': _validateCommand,
    'apply': _applyCommand,
    'archive': _archiveCommand,
    'reset': _resetCommand,
  },
);
