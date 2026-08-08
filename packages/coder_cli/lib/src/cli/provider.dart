import 'package:cliweave/cliweave.dart';
import 'package:coder_cli/src/cli/context.dart';
import 'package:coder_cli/src/cli/shared_flags.dart';
import 'package:coder_cli/src/provider_cli.dart';

final Command<CoderCliContext> _listCommand = buildCommand(
  docs: const CommandDocs(brief: 'List provider connections'),
  parameters: CommandParameters(
    flags: daemonConnectionFlagSet(),
    positional: PositionalSet.none(),
  ),
  func: (context, flags, args) => withDaemon(
    context,
    flags,
    (client) => providerList(
      backend: CoderApiProviderCliBackend(client),
      output: context.output,
    ),
  ),
);

final Command<CoderCliContext> _connectCommand = buildCommand(
  docs: const CommandDocs(
    brief: 'Connect a provider',
    fullDescription:
        'Connects the named provider. Without --method a local provider is '
        'connected without a credential and a hosted one asks for an API key.',
  ),
  parameters: CommandParameters(
    flags: daemonConnectionFlagSet()
        .and(
          // An open string rather than a closed enum: the valid ids are
          // whatever the daemon's catalog advertises for the provider, so a
          // new vendor's flows need no CLI release. providerConnect validates
          // against the catalog and names the valid ids on a mistake.
          ParsedFlag.optional<String, CoderCliContext>(
            name: 'method',
            brief: 'Authentication method id from the provider catalog',
            parse: stringParser,
            placeholder: 'method',
          ),
        )
        .and(
          // Hidden because passing a secret on the command line leaks it
          // into the shell history; the interactive prompt is the
          // documented path.
          ParsedFlag.optional<String, CoderCliContext>(
            name: 'api-key',
            brief: 'API key to use instead of prompting',
            parse: stringParser,
            hidden: true,
            placeholder: 'key',
          ),
        )
        .and(
          ParsedFlag.optional<String, CoderCliContext>(
            name: 'prefix',
            brief: 'Qualified model prefix (generated when omitted)',
            parse: stringParser,
            placeholder: 'prefix',
          ),
        )
        .map(
          (values) => (
            daemon: values.$1.$1.$1,
            method: values.$1.$1.$2,
            apiKey: values.$1.$2,
            prefix: values.$2,
          ),
        ),
    positional: PositionalSet.one(
      Positional.required<String, CoderCliContext>(
        brief: 'Provider definition ID',
        parse: stringParser,
        placeholder: 'id',
      ),
    ).map((id) => (id: id)),
  ),
  func: (context, flags, args) => withDaemon(
    context,
    flags.daemon,
    (client) => providerConnect(
      backend: CoderApiProviderCliBackend(client),
      output: context.output,
      definitionId: args.id,
      methodId: flags.method,
      apiKey: flags.apiKey,
      modelPrefix: flags.prefix,
      readSecret: context.readSecret,
      progress: context.progress,
    ),
  ),
);

final Command<CoderCliContext> _prefixSetCommand = buildCommand(
  docs: const CommandDocs(brief: 'Change a provider model prefix'),
  parameters: CommandParameters(
    flags: daemonConnectionFlagSet(),
    positional:
        PositionalSet.one(
              Positional.required<String, CoderCliContext>(
                brief: 'Connection ID',
                parse: stringParser,
                placeholder: 'connection-id',
              ),
            )
            .and(
              Positional.required<String, CoderCliContext>(
                brief: 'New model prefix',
                parse: stringParser,
                placeholder: 'prefix',
              ),
            )
            .map((values) => (values.$1, values.$2)),
  ),
  func: (context, flags, args) => withDaemon(
    context,
    flags,
    (client) => providerPrefixSet(
      backend: CoderApiProviderCliBackend(client),
      output: context.output,
      connectionId: args.$1,
      modelPrefix: args.$2,
    ),
  ),
);

final Command<CoderCliContext> _disconnectCommand = buildCommand(
  docs: const CommandDocs(brief: 'Remove a provider connection'),
  parameters: CommandParameters(
    flags: daemonConnectionFlagSet(),
    positional: PositionalSet.one(
      Positional.required<String, CoderCliContext>(
        brief: 'Connection ID',
        parse: stringParser,
        placeholder: 'connection-id',
      ),
    ).map((id) => (id: id)),
  ),
  func: (context, flags, args) => withDaemon(
    context,
    flags,
    (client) => providerDisconnect(
      backend: CoderApiProviderCliBackend(client),
      output: context.output,
      connectionId: args.id,
    ),
  ),
);

final Command<CoderCliContext> _catalogRefreshCommand = buildCommand(
  docs: const CommandDocs(brief: 'Refresh public model metadata'),
  parameters: CommandParameters(
    flags: daemonConnectionFlagSet(),
    positional: PositionalSet.none(),
  ),
  func: (context, flags, args) => withDaemon(
    context,
    flags,
    (client) => providerCatalogRefresh(
      backend: CoderApiProviderCliBackend(client),
      output: context.output,
      progress: context.progress,
    ),
  ),
);

/// The `coder-cli provider` route map.
RouteMap<CoderCliContext> buildProviderRoutes() => buildRouteMap(
  docs: const RouteMapDocs(brief: 'Manage provider connections'),
  routes: <String, RoutingTarget<CoderCliContext>>{
    'list': _listCommand,
    'connect': _connectCommand,
    'disconnect': _disconnectCommand,
    'prefix-set': _prefixSetCommand,
    'catalog-refresh': _catalogRefreshCommand,
  },
);
