import 'package:args/args.dart';
import 'package:coder_client/coder_client.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:path/path.dart' as p;

/// Narrow Markdown agent administration port used by the standalone CLI.
abstract interface class AgentCliBackend {
  /// Lists active agent definitions.
  Future<List<AgentDefinitionDto>> list();

  /// Validates an unsaved Markdown source.
  Future<AgentDefinitionDto> validate(String id, String markdown);

  /// Creates or updates one definition.
  Future<AgentDefinitionDto> apply(
    String id,
    AgentDefinitionDto definition,
  );

  /// Archives one custom definition.
  Future<void> archive(String id);

  /// Resets the protected built-in definition.
  Future<AgentDefinitionDto> reset(String id);
}

/// Adapts [CoderApi] to the standalone agent administration commands.
final class CoderApiAgentCliBackend implements AgentCliBackend {
  /// Creates the client adapter.
  const CoderApiAgentCliBackend(this._api);

  final CoderApi _api;

  @override
  Future<List<AgentDefinitionDto>> list() => _api.listAgentDefinitions();

  @override
  Future<AgentDefinitionDto> validate(String id, String markdown) =>
      _api.validateAgentDefinition(id, markdown);

  @override
  Future<AgentDefinitionDto> apply(
    String id,
    AgentDefinitionDto definition,
  ) async {
    final existing = (await _api.listAgentDefinitions())
        .where((item) => item.id == id)
        .firstOrNull;
    if (existing == null) return _api.createAgentDefinition(id, definition);
    return _api.updateAgentDefinition(
      definition.copyWith(
        contentHash: existing.contentHash,
        sourcePath: existing.sourcePath,
        isBuiltIn: existing.isBuiltIn,
      ),
      expectedContentHash: existing.contentHash,
    );
  }

  @override
  Future<void> archive(String id) => _api.archiveAgentDefinition(id);

  @override
  Future<AgentDefinitionDto> reset(String id) => _api.resetAgentDefinition(id);
}

/// Executes one `coder_daemon agent` subcommand.
Future<int> runAgentCommand(
  List<String> arguments, {
  required AgentCliBackend backend,
  required StringSink output,
  Future<String> Function(String path)? readFile,
}) async {
  if (arguments.isEmpty || arguments.first == 'help') {
    output.writeln(_agentUsage);
    return 0;
  }
  switch (arguments.first) {
    case 'list':
      for (final definition in await backend.list()) {
        final state = definition.isStale ? 'stale' : 'ready';
        output.writeln(
          '${definition.id}\t${definition.mode.name}\t$state\t'
          '${definition.sourcePath}',
        );
      }
      return 0;
    case 'validate':
      if (arguments.length != 2) {
        throw const FormatException('agent validate requires a Markdown file.');
      }
      final path = arguments[1];
      final id = p.basenameWithoutExtension(path);
      final markdown = await _read(path, readFile);
      final validated = await backend.validate(id, markdown);
      output.writeln('Valid ${validated.id}: ${validated.name}');
      return 0;
    case 'apply':
      final parser = ArgParser()..addOption('file', mandatory: true);
      final options = parser.parse(arguments.skip(1).toList(growable: false));
      if (options.rest.length != 1) {
        throw const FormatException('agent apply requires an agent ID.');
      }
      final id = options.rest.single;
      final path = options.option('file')!;
      final markdown = await _read(path, readFile);
      final definition = await backend.validate(id, markdown);
      await backend.apply(id, definition);
      output.writeln('Applied $id.');
      return 0;
    case 'archive':
      if (arguments.length != 2) {
        throw const FormatException('agent archive requires an agent ID.');
      }
      await backend.archive(arguments[1]);
      output.writeln('Archived ${arguments[1]}.');
      return 0;
    case 'reset':
      if (arguments.length != 2 || arguments[1] != 'coder') {
        throw const FormatException('agent reset only supports coder.');
      }
      await backend.reset('coder');
      output.writeln('Reset coder.');
      return 0;
    default:
      throw FormatException('Unknown agent command: ${arguments.first}');
  }
}

Future<String> _read(
  String path,
  Future<String> Function(String path)? readFile,
) {
  final reader = readFile;
  if (reader == null) {
    throw StateError('A file reader is required.');
  }
  return reader(path);
}

const String _agentUsage = '''
agent list
agent validate <file>
agent apply <id> --file <path>
agent archive <id>
agent reset coder''';
