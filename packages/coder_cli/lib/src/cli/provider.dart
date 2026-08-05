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
          EnumFlag.optional<ProviderConnectMethod, CoderCliContext>(
            name: 'method',
            brief: 'Authentication method',
            values: <String, ProviderConnectMethod>{
              for (final method in ProviderConnectMethod.values)
                method.id: method,
            },
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
        .map(
          (values) => (
            daemon: values.$1.$1,
            method: values.$1.$2,
            apiKey: values.$2,
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
      method: flags.method,
      apiKey: flags.apiKey,
      readSecret: context.readSecret,
      progress: context.progress,
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
    'catalog-refresh': _catalogRefreshCommand,
  },
);
