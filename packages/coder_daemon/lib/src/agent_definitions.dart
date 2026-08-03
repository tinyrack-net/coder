import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:coder_protocol/coder_protocol.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// Raised when a GUI update races an external editor update.
final class AgentFileConflict implements Exception {
  /// Creates a conflict containing the current content hash.
  const AgentFileConflict(this.currentContentHash);

  /// Hash the client must reload before trying another guarded update.
  final String currentContentHash;

  @override
  String toString() => 'agent_file_conflict: $currentContentHash';
}

/// Typed source-of-truth boundary for Markdown agent definitions.
abstract interface class AgentDefinitionStore {
  /// Emits after a valid catalog change or a stale diagnostic is detected.
  Stream<void> get changes;

  /// Loads files and creates the protected built-in Coder file when absent.
  Future<void> initialize();

  /// Returns visible definitions.
  Future<List<AgentDefinitionDto>> list();

  /// Returns archived definitions retained for historical sessions.
  Future<List<AgentDefinitionDto>> listArchived();

  /// Returns one visible definition.
  Future<AgentDefinitionDto?> get(String id);

  /// Resolves visible and archived definitions for historical sessions.
  Future<AgentDefinitionDto?> resolve(String id);

  /// Creates one custom definition.
  Future<AgentDefinitionDto> create(
    String id,
    AgentDefinitionDto definition,
  );

  /// Updates one definition using optimistic concurrency.
  Future<AgentDefinitionDto> update(
    AgentDefinitionDto definition, {
    required String expectedContentHash,
    bool force = false,
  });

  /// Moves one custom definition to the archive directory.
  Future<void> archive(String id);

  /// Restores the canonical built-in Coder definition.
  Future<AgentDefinitionDto> resetCoder();

  /// Reloads external file changes immediately.
  Future<void> reload();

  /// Stops filesystem observation.
  Future<void> close();
}

/// Production atomic filesystem adapter for `<configDirectory>/agents/*.md`.
final class FileAgentDefinitionStore implements AgentDefinitionStore {
  /// Creates a store rooted at the daemon config directory.
  FileAgentDefinitionStore(
    String configDirectory, {
    this.codec = const AgentMarkdownCodec(),
  }) : _directory = Directory(p.join(configDirectory, 'agents')),
       _archiveDirectory = Directory(
         p.join(configDirectory, 'agents', '.archive'),
       );

  /// Codec used for preserving frontmatter formatting and unknown fields.
  final AgentMarkdownCodec codec;
  final Directory _directory;
  final Directory _archiveDirectory;
  final Map<String, AgentDefinitionDto> _active =
      <String, AgentDefinitionDto>{};
  final Map<String, AgentDefinitionDto> _archived =
      <String, AgentDefinitionDto>{};
  final Map<String, String> _sources = <String, String>{};
  final StreamController<void> _changes = StreamController<void>.broadcast(
    sync: true,
  );
  StreamSubscription<FileSystemEvent>? _watchSubscription;
  Timer? _reloadTimer;
  Future<void>? _reloadInFlight;
  bool _initialized = false;
  bool _writing = false;
  bool _closed = false;

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    await _ensureDirectories();
    await _ensureCoder();
    _initialized = true;
    await reload();
    _watchSubscription = _directory.watch(recursive: true).listen((_) {
      if (_writing || _closed) return;
      _reloadTimer?.cancel();
      _reloadTimer = Timer(const Duration(milliseconds: 200), () {
        if (_closed) return;
        final reloadFuture = reload();
        _reloadInFlight = reloadFuture;
        unawaited(
          reloadFuture.whenComplete(() {
            if (identical(_reloadInFlight, reloadFuture)) {
              _reloadInFlight = null;
            }
          }),
        );
      });
    });
  }

  @override
  Future<List<AgentDefinitionDto>> list() async {
    await initialize();
    final definitions = _active.values.toList(growable: false)
      ..sort((left, right) {
        if (left.id == 'coder') return -1;
        if (right.id == 'coder') return 1;
        return left.name.compareTo(right.name);
      });
    return definitions;
  }

  @override
  Future<List<AgentDefinitionDto>> listArchived() async {
    await initialize();
    return List<AgentDefinitionDto>.unmodifiable(_archived.values);
  }

  @override
  Future<AgentDefinitionDto?> get(String id) async {
    await initialize();
    return _active[id];
  }

  @override
  Future<AgentDefinitionDto?> resolve(String id) async {
    await initialize();
    return _active[id] ?? _archived[id];
  }

  @override
  Future<AgentDefinitionDto> create(
    String id,
    AgentDefinitionDto definition,
  ) async {
    await initialize();
    _validateId(id);
    if (id == 'coder' || _active.containsKey(id) || _archived.containsKey(id)) {
      throw StateError('Agent definition already exists: $id');
    }
    if (definition.id != id) {
      throw const FormatException('Filename ID and definition ID must match.');
    }
    final path = _pathFor(id);
    final source = codec.encodeNew(definition);
    await _writeAtomic(path, source);
    final parsed = codec.decode(id: id, sourcePath: path, source: source);
    _active[id] = parsed;
    _sources[id] = source;
    _changes.add(null);
    return parsed;
  }

  @override
  Future<AgentDefinitionDto> update(
    AgentDefinitionDto definition, {
    required String expectedContentHash,
    bool force = false,
  }) async {
    await initialize();
    final current = _active[definition.id];
    if (current == null) {
      throw StateError('Agent definition not found: ${definition.id}');
    }
    if (!force && current.contentHash != expectedContentHash) {
      throw AgentFileConflict(current.contentHash);
    }
    if (current.mode != definition.mode) {
      throw const FormatException('Agent mode cannot be changed after create.');
    }
    final original = _sources[definition.id];
    if (original == null) {
      throw StateError('Agent source is unavailable: ${definition.id}');
    }
    final source = codec.encodeUpdate(
      originalSource: original,
      definition: definition,
    );
    await _writeAtomic(current.sourcePath, source);
    final parsed = codec.decode(
      id: definition.id,
      sourcePath: current.sourcePath,
      source: source,
    );
    _active[definition.id] = parsed;
    _sources[definition.id] = source;
    _changes.add(null);
    return parsed;
  }

  @override
  Future<void> archive(String id) async {
    await initialize();
    if (id == 'coder') {
      throw StateError('The built-in Coder agent cannot be archived.');
    }
    final current = _active[id];
    if (current == null) throw StateError('Agent definition not found: $id');
    final destination = p.join(_archiveDirectory.path, '$id.md');
    _writing = true;
    try {
      final destinationFile = File(destination);
      if (destinationFile.existsSync()) destinationFile.deleteSync();
      await File(current.sourcePath).rename(destination);
      await _restrictFile(destinationFile);
    } finally {
      _writing = false;
    }
    _active.remove(id);
    final archived = current.copyWith(
      sourcePath: destination,
      isArchived: true,
    );
    _archived[id] = archived;
    _sources[id] = await File(destination).readAsString();
    _changes.add(null);
  }

  @override
  Future<AgentDefinitionDto> resetCoder() async {
    await initialize();
    final source = codec.encodeNew(_defaultCoder(_pathFor('coder')));
    await _writeAtomic(_pathFor('coder'), source);
    final parsed = codec.decode(
      id: 'coder',
      sourcePath: _pathFor('coder'),
      source: source,
    );
    _active['coder'] = parsed;
    _sources['coder'] = source;
    _changes.add(null);
    return parsed;
  }

  @override
  Future<void> reload() async {
    await _ensureDirectories();
    await _ensureCoder();
    final seenActive = <String>{};
    await _loadDirectory(_directory, isArchived: false, seen: seenActive);
    for (final id in _active.keys.toList(growable: false)) {
      if (!seenActive.contains(id)) _active.remove(id);
    }
    if (!_active.containsKey('coder')) await resetCoder();
    final seenArchived = <String>{};
    await _loadDirectory(
      _archiveDirectory,
      isArchived: true,
      seen: seenArchived,
    );
    for (final id in _archived.keys.toList(growable: false)) {
      if (!seenArchived.contains(id)) _archived.remove(id);
    }
    _changes.add(null);
  }

  Future<void> _loadDirectory(
    Directory directory, {
    required bool isArchived,
    required Set<String> seen,
  }) async {
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File || p.extension(entity.path) != '.md') continue;
      if (FileSystemEntity.typeSync(entity.path, followLinks: false) ==
          FileSystemEntityType.link) {
        continue;
      }
      final id = p.basenameWithoutExtension(entity.path);
      try {
        _validateId(id);
        final source = await entity.readAsString();
        final parsed = codec.decode(
          id: id,
          sourcePath: entity.path,
          source: source,
          isArchived: isArchived,
        );
        (isArchived ? _archived : _active)[id] = parsed;
        _sources[id] = source;
        seen.add(id);
      } on FormatException catch (error) {
        final target = isArchived ? _archived : _active;
        final previous = target[id];
        if (previous != null) {
          target[id] = previous.copyWith(
            isStale: true,
            diagnostics: <AgentDefinitionDiagnosticDto>[
              AgentDefinitionDiagnosticDto(
                code: 'invalid_agent_markdown',
                message: error.message,
                line: switch (error) {
                  YamlException(:final span?) => span.start.line + 1,
                  _ => null,
                },
                column: switch (error) {
                  YamlException(:final span?) => span.start.column + 1,
                  _ => null,
                },
              ),
            ],
          );
          seen.add(id);
        }
      } on FileSystemException {
        // Editors commonly implement atomic save by replacing the enumerated
        // path. A vanished entry belongs to the next debounced snapshot; an
        // error for a path that still exists remains a real storage failure.
        if (entity.existsSync()) rethrow;
      }
    }
  }

  Future<void> _ensureCoder() async {
    final file = File(_pathFor('coder'));
    if (file.existsSync()) return;
    final source = codec.encodeNew(_defaultCoder(file.path));
    await _writeAtomic(file.path, source);
  }

  Future<void> _ensureDirectories() async {
    await _directory.create(recursive: true);
    await _archiveDirectory.create(recursive: true);
    await _restrictDirectory(_directory);
    await _restrictDirectory(_archiveDirectory);
  }

  Future<void> _writeAtomic(String path, String source) async {
    final file = File(path);
    final temporary = File('$path.$pid.tmp');
    _writing = true;
    try {
      await temporary.writeAsString(source, flush: true);
      await _restrictFile(temporary);
      if (Platform.isWindows && file.existsSync()) file.deleteSync();
      await temporary.rename(path);
      await _restrictFile(file);
    } finally {
      _writing = false;
      if (temporary.existsSync()) temporary.deleteSync();
    }
  }

  Future<void> _restrictDirectory(Directory directory) async {
    if (!Platform.isWindows) {
      await Process.run('chmod', <String>['700', directory.path]);
    }
  }

  Future<void> _restrictFile(File file) async {
    if (!Platform.isWindows) {
      await Process.run('chmod', <String>['600', file.path]);
    }
  }

  String _pathFor(String id) => p.join(_directory.path, '$id.md');

  @override
  Future<void> close() async {
    _closed = true;
    _reloadTimer?.cancel();
    await _watchSubscription?.cancel();
    await _reloadInFlight;
    await _changes.close();
  }
}

AgentDefinitionDto _defaultCoder(String sourcePath) => AgentDefinitionDto(
  id: 'coder',
  name: 'Coder',
  description: 'General-purpose coding agent',
  mode: AgentMode.primary,
  promptEnabled: true,
  systemPrompt:
      'You are a coding agent. Read relevant code before editing and validate '
      'your work.',
  model: const AgentModelSelectionDto(source: AgentModelSource.daemonDefault),
  reasoningEffort: 'medium',
  permissionMode: PermissionMode.ask,
  toolIds: const <String>[
    'list_directory',
    'read_file',
    'search_text',
    'apply_patch',
    'run_command',
  ],
  callableAgentIds: const <String>[],
  contentHash: '',
  sourcePath: sourcePath,
  isBuiltIn: true,
);

/// Validates domain relationships independently of filesystem mechanics.
final class AgentDefinitionService {
  /// Creates an agent definition application service.
  AgentDefinitionService({
    required this._store,
    required Iterable<AgentToolDefinitionDto> tools,
    this.codec = const AgentMarkdownCodec(),
  }) : _tools = <String, AgentToolDefinitionDto>{
         for (final tool in tools) tool.id: tool,
       };

  final AgentDefinitionStore _store;
  final Map<String, AgentToolDefinitionDto> _tools;

  /// Codec used for validation-only RPC requests.
  final AgentMarkdownCodec codec;

  /// Emits after source files or diagnostics change.
  Stream<void> get changes => _store.changes;

  /// Initializes the source store.
  Future<void> initialize() => _store.initialize();

  /// Returns definitions decorated with unavailable-tool diagnostics.
  Future<List<AgentDefinitionDto>> list() async => Future.wait(
    (await _store.list()).map(_decorate),
  );

  /// Returns one visible definition.
  Future<AgentDefinitionDto> get(String id) async {
    final definition = await _store.get(id);
    if (definition == null) throw StateError('Agent definition not found: $id');
    return _decorate(definition);
  }

  /// Resolves active or archived configuration for a turn snapshot.
  Future<AgentDefinitionDto> resolve(String id) async {
    final definition = await _store.resolve(id);
    if (definition == null) throw StateError('Agent definition not found: $id');
    if (definition.isStale && definition.contentHash.isEmpty) {
      throw StateError('Agent definition is invalid: $id');
    }
    return _decorate(definition);
  }

  /// Returns the runtime tool catalog.
  List<AgentToolDefinitionDto> toolCatalog() {
    final tools = _tools.values.toList(growable: false)
      ..sort((left, right) => left.name.compareTo(right.name));
    return tools;
  }

  /// Whether an active or archived definition fixes itself to a connection.
  Future<bool> referencesProvider(String connectionId) async {
    final definitions = <AgentDefinitionDto>[
      ...await _store.list(),
      ...await _store.listArchived(),
    ];
    return definitions.any(
      (definition) =>
          definition.model.source == AgentModelSource.fixed &&
          definition.model.providerConnectionId == connectionId,
    );
  }

  /// Creates a custom definition after validating references.
  Future<AgentDefinitionDto> create(
    String id,
    AgentDefinitionDto definition,
  ) async {
    await _validateReferences(definition);
    return _decorate(await _store.create(id, definition));
  }

  /// Updates a definition after validating immutable and cross-file rules.
  Future<AgentDefinitionDto> update(
    AgentDefinitionDto definition, {
    required String expectedContentHash,
    bool force = false,
  }) async {
    await _validateReferences(definition);
    return _decorate(
      await _store.update(
        definition,
        expectedContentHash: expectedContentHash,
        force: force,
      ),
    );
  }

  /// Archives a custom definition and removes it from primary allowlists.
  Future<void> archive(String id) async {
    await _store.archive(id);
    for (final definition in await _store.list()) {
      if (!definition.callableAgentIds.contains(id)) continue;
      await _store.update(
        definition.copyWith(
          callableAgentIds: definition.callableAgentIds
              .where((candidate) => candidate != id)
              .toList(growable: false),
        ),
        expectedContentHash: definition.contentHash,
      );
    }
  }

  /// Restores the protected built-in Coder definition.
  Future<AgentDefinitionDto> reset(String id) async {
    if (id != 'coder') {
      throw StateError('Only the built-in Coder agent can be reset.');
    }
    return _decorate(await _store.resetCoder());
  }

  /// Parses and validates one unsaved Markdown document.
  Future<AgentDefinitionDto> validate(String id, String markdown) async {
    final parsed = codec.decode(
      id: id,
      sourcePath: '<validation>/$id.md',
      source: markdown,
    );
    await _validateReferences(parsed);
    return _decorate(parsed);
  }

  Future<void> _validateReferences(AgentDefinitionDto definition) async {
    if (definition.mode == AgentMode.subagent &&
        definition.callableAgentIds.isNotEmpty) {
      throw const FormatException('Subagents cannot call other agents.');
    }
    final definitions = <String, AgentDefinitionDto>{
      for (final item in await _store.list()) item.id: item,
    };
    for (final id in definition.callableAgentIds) {
      final target = definitions[id];
      if (target == null ||
          target.isArchived ||
          target.isStale ||
          target.mode != AgentMode.subagent) {
        throw FormatException(
          'Callable agent must be an active subagent: $id',
        );
      }
    }
  }

  Future<AgentDefinitionDto> _decorate(AgentDefinitionDto definition) async {
    final unavailable = definition.toolIds
        .where((id) => !_tools.containsKey(id))
        .map(
          (id) => AgentDefinitionDiagnosticDto(
            code: 'unavailable_tool',
            message: 'Tool is not available in this daemon: $id',
          ),
        );
    return definition.copyWith(
      diagnostics: <AgentDefinitionDiagnosticDto>[
        ...definition.diagnostics.where(
          (diagnostic) => diagnostic.code != 'unavailable_tool',
        ),
        ...unavailable,
      ],
    );
  }

  /// Stops file observation.
  Future<void> close() => _store.close();
}

/// Parses and updates the Coder agent Markdown format.
final class AgentMarkdownCodec {
  /// Creates the stateless Markdown codec.
  const AgentMarkdownCodec();

  /// Parses one Markdown document into a typed definition.
  AgentDefinitionDto decode({
    required String id,
    required String sourcePath,
    required String source,
    bool isArchived = false,
  }) {
    _validateId(id);
    final document = _AgentMarkdownDocument.parse(source);
    final decoded = loadYaml(
      document.frontmatter,
      sourceUrl: Uri.file(sourcePath),
    );
    if (decoded is! YamlMap) {
      throw const FormatException('Agent frontmatter must be a YAML map.');
    }
    final frontmatter = _stringMap(decoded);
    if (_requiredInt(frontmatter, 'version') != 1) {
      throw const FormatException('Unsupported agent Markdown version.');
    }
    final mode = _enumValue(
      AgentMode.values,
      _requiredString(frontmatter, 'mode'),
      'mode',
    );
    final modelMap = _requiredMap(frontmatter, 'model');
    final modelSource = _enumValue(
      AgentModelSource.values,
      _requiredString(modelMap, 'source'),
      'model.source',
    );
    final providerConnectionId = _optionalString(
      modelMap,
      'providerConnectionId',
    );
    final modelId = _optionalString(modelMap, 'modelId');
    if (modelSource == AgentModelSource.fixed &&
        (providerConnectionId == null || modelId == null)) {
      throw const FormatException(
        'Fixed agent models require providerConnectionId and modelId.',
      );
    }
    final callableAgentIds = _stringList(frontmatter, 'callableAgents');
    if (mode == AgentMode.subagent && callableAgentIds.isNotEmpty) {
      throw const FormatException('Subagents cannot call other agents.');
    }
    return AgentDefinitionDto(
      id: id,
      name: _requiredString(frontmatter, 'name'),
      description: _requiredString(frontmatter, 'description'),
      mode: mode,
      promptEnabled: _requiredBool(frontmatter, 'promptEnabled'),
      systemPrompt: document.body.trim(),
      model: AgentModelSelectionDto(
        source: modelSource,
        providerConnectionId: providerConnectionId,
        modelId: modelId,
      ),
      reasoningEffort: _requiredString(frontmatter, 'reasoningEffort'),
      permissionMode: _enumValue(
        PermissionMode.values,
        _requiredString(frontmatter, 'permissionMode'),
        'permissionMode',
      ),
      toolIds: _stringList(frontmatter, 'tools'),
      callableAgentIds: callableAgentIds,
      contentHash: sha256.convert(utf8.encode(source)).toString(),
      sourcePath: sourcePath,
      isBuiltIn: id == 'coder',
      isArchived: isArchived,
    );
  }

  /// Rewrites known fields while retaining unknown YAML and comments.
  String encodeUpdate({
    required String originalSource,
    required AgentDefinitionDto definition,
  }) {
    final document = _AgentMarkdownDocument.parse(originalSource);
    final editor = YamlEditor(document.frontmatter)
      ..update(<Object>['version'], 1)
      ..update(<Object>['name'], definition.name)
      ..update(<Object>['description'], definition.description)
      ..update(<Object>['mode'], definition.mode.name)
      ..update(<Object>['promptEnabled'], definition.promptEnabled)
      ..update(<Object>['model'], _modelMap(definition.model))
      ..update(<Object>['reasoningEffort'], definition.reasoningEffort)
      ..update(<Object>['permissionMode'], definition.permissionMode.name)
      ..update(<Object>['tools'], definition.toolIds)
      ..update(<Object>['callableAgents'], definition.callableAgentIds);
    return '---\n$editor\n---\n\n${definition.systemPrompt.trim()}\n';
  }

  /// Creates a canonical new Markdown document.
  String encodeNew(AgentDefinitionDto definition) {
    final editor = YamlEditor('')
      ..update(<Object>[], <String, Object?>{
        'version': 1,
        'name': definition.name,
        'description': definition.description,
        'mode': definition.mode.name,
        'promptEnabled': definition.promptEnabled,
        'model': _modelMap(definition.model),
        'reasoningEffort': definition.reasoningEffort,
        'permissionMode': definition.permissionMode.name,
        'tools': definition.toolIds,
        'callableAgents': definition.callableAgentIds,
      });
    return '---\n$editor\n---\n\n${definition.systemPrompt.trim()}\n';
  }

  static Map<String, Object?> _modelMap(AgentModelSelectionDto model) =>
      <String, Object?>{
        'source': model.source.name,
        'providerConnectionId': ?model.providerConnectionId,
        'modelId': ?model.modelId,
      };
}

final class _AgentMarkdownDocument {
  const _AgentMarkdownDocument({
    required this.frontmatter,
    required this.body,
  });

  factory _AgentMarkdownDocument.parse(String source) {
    final normalized = source.replaceAll('\r\n', '\n');
    final lines = normalized.split('\n');
    var start = 0;
    while (start < lines.length && lines[start].trim().isEmpty) {
      start += 1;
    }
    if (start == lines.length || lines[start].trim() != '---') {
      throw const FormatException(
        'Agent Markdown must start with frontmatter.',
      );
    }
    var end = start + 1;
    while (end < lines.length && lines[end].trim() != '---') {
      end += 1;
    }
    if (end == lines.length) {
      throw const FormatException('Agent Markdown frontmatter is not closed.');
    }
    return _AgentMarkdownDocument(
      frontmatter: lines.sublist(start + 1, end).join('\n'),
      body: lines.sublist(end + 1).join('\n'),
    );
  }

  final String frontmatter;
  final String body;
}

void _validateId(String id) {
  if (!RegExp(r'^[a-z0-9][a-z0-9_-]{0,63}$').hasMatch(id)) {
    throw const FormatException('Invalid agent definition ID.');
  }
}

Map<String, Object?> _stringMap(YamlMap value) {
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw const FormatException('Agent frontmatter keys must be strings.');
    }
    result[entry.key as String] = _plainValue(entry.value);
  }
  return result;
}

Object? _plainValue(Object? value) => switch (value) {
  YamlMap() => _stringMap(value),
  YamlList() => value.nodes.map((node) => _plainValue(node.value)).toList(),
  _ => value,
};

Map<String, Object?> _requiredMap(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! Map<String, Object?>) {
    throw FormatException('$key must be a map.');
  }
  return value;
}

String _requiredString(Map<String, Object?> map, String key) {
  final value = _optionalString(map, key);
  if (value == null) throw FormatException('$key must be a non-empty string.');
  return value;
}

String? _optionalString(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value == null) return null;
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$key must be a non-empty string.');
  }
  return value.trim();
}

int _requiredInt(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! int) throw FormatException('$key must be an integer.');
  return value;
}

bool _requiredBool(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! bool) throw FormatException('$key must be a boolean.');
  return value;
}

List<String> _stringList(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! List<Object?> || value.any((item) => item is! String)) {
    throw FormatException('$key must be a string list.');
  }
  return List<String>.unmodifiable(value.cast<String>());
}

T _enumValue<T extends Enum>(List<T> values, String name, String field) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  throw FormatException('Unsupported $field: $name.');
}
