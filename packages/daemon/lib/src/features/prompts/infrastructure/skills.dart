import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:agent/agent.dart';
import 'package:crypto/crypto.dart';
import 'package:daemon/src/features/prompts/infrastructure/built_in_skills.dart';
import 'package:daemon/src/shared/infrastructure/persistence/repositories.dart';
import 'package:path/path.dart' as p;
import 'package:protocol/protocol.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// Raised when a GUI update races an external editor update.
final class SkillFileConflict implements Exception {
  /// Creates a conflict carrying the hash the client must reload.
  const SkillFileConflict(this.currentContentHash);

  /// Hash currently on disk.
  final String currentContentHash;

  @override
  String toString() => 'skill_file_conflict: $currentContentHash';
}

/// Selects which project, if any, participates in a skill request.
final class SkillScope {
  /// Creates a scope; both fields are null for the global sources alone.
  const SkillScope({this.workspaceId, this.projectRoot});

  /// The global sources with no project overlay.
  static const SkillScope global = SkillScope();

  /// Workspace owning the project skills, used to key enablement.
  final String? workspaceId;

  /// Absolute workspace root containing `.agents/skills`.
  final String? projectRoot;
}

/// One skill document read from a filesystem boundary.
final class SkillDocument {
  /// Creates an immutable document snapshot.
  const SkillDocument({
    required this.id,
    required this.sourcePath,
    required this.source,
    required this.directory,
  });

  /// Directory-derived stable skill ID.
  final String id;

  /// Absolute path of `SKILL.md`.
  final String sourcePath;

  /// Complete Markdown source.
  final String source;

  /// Absolute directory holding the document and its bundled files.
  final String directory;
}

/// Typed filesystem and watcher boundary for one skills root.
abstract interface class SkillFiles {
  /// Which source the root represents.
  SkillSource get source;

  /// Emits when source files may have changed.
  Stream<void> get changes;

  /// Creates protected directories when owned, and starts observation.
  Future<void> initialize();

  /// Returns a point-in-time snapshot of readable skill documents.
  Future<List<SkillDocument>> read();

  /// Returns the canonical directory for [id].
  String skillDirectory(String id);

  /// Returns the canonical document path for [id].
  String documentPath(String id);

  /// Lists files bundled next to [id], excluding the document itself.
  Future<List<SkillResourceDto>> resources(String id);

  /// Atomically writes one skill document.
  Future<void> write(String id, String source);

  /// Moves one skill directory into the archive.
  Future<void> archive(String id);

  /// Stops observation.
  Future<void> close();
}

/// Native filesystem adapter for one `<root>/<id>/SKILL.md` tree.
final class NativeSkillFiles implements SkillFiles {
  /// Creates an adapter rooted at one skills directory.
  ///
  /// [createIfMissing] and permission restriction are reserved for the
  /// daemon-owned configuration root. Shared trees such as `~/.agents/skills`
  /// and a project checkout keep whatever permissions their owner chose.
  NativeSkillFiles(
    String root, {
    required this.source,
    this.createIfMissing = false,
    this.maxResources = 200,
  }) : _directory = Directory(root),
       _archiveDirectory = Directory(p.join(root, _archiveName));

  static const String _archiveName = '.archive';
  static const String _documentName = 'SKILL.md';

  @override
  final SkillSource source;

  /// Whether the daemon owns and may create this root.
  final bool createIfMissing;

  /// Upper bound on bundled files reported for one skill.
  final int maxResources;

  final Directory _directory;
  final Directory _archiveDirectory;
  final StreamController<void> _changes = StreamController<void>.broadcast(
    sync: true,
  );
  StreamSubscription<FileSystemEvent>? _watchSubscription;
  bool _initialized = false;

  @override
  Stream<void> get changes => _changes.stream;

  @override
  String skillDirectory(String id) => p.join(_directory.path, id);

  @override
  String documentPath(String id) => p.join(_directory.path, id, _documentName);

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    if (createIfMissing) {
      await _directory.create(recursive: true);
      await _restrict(_directory.path, '700');
    }
    if (_directory.existsSync()) _watch();
    _initialized = true;
  }

  void _watch() {
    _watchSubscription = _directory
        .watch(recursive: true)
        .listen((_) => _changes.add(null), onError: (Object _) {});
  }

  @override
  Future<List<SkillDocument>> read() async {
    if (!_directory.existsSync()) return const <SkillDocument>[];
    // A shared root may appear after the daemon started, so pick up the
    // watcher on the first read that finds the directory.
    if (_initialized && _watchSubscription == null) _watch();
    final documents = <SkillDocument>[];
    await for (final entity in _directory.list(followLinks: false)) {
      if (entity is! Directory) continue;
      final id = p.basename(entity.path);
      if (id.startsWith('.')) continue;
      if (FileSystemEntity.typeSync(entity.path, followLinks: false) ==
          FileSystemEntityType.link) {
        continue;
      }
      final document = File(p.join(entity.path, _documentName));
      if (!document.existsSync()) continue;
      try {
        documents.add(
          SkillDocument(
            id: id,
            sourcePath: document.path,
            source: await document.readAsString(),
            directory: entity.path,
          ),
        );
      } on FileSystemException {
        // Atomic editors may replace an entry after directory enumeration.
        if (document.existsSync()) rethrow;
      }
    }
    return documents;
  }

  @override
  Future<List<SkillResourceDto>> resources(String id) async {
    final directory = Directory(skillDirectory(id));
    if (!directory.existsSync()) return const <SkillResourceDto>[];
    final resources = <SkillResourceDto>[];
    await for (final entity in directory.list(recursive: true)) {
      if (entity is! File) continue;
      final relative = p.relative(entity.path, from: directory.path);
      if (relative == _documentName) continue;
      if (p.split(relative).first == _archiveName) continue;
      if (FileSystemEntity.typeSync(entity.path, followLinks: false) ==
          FileSystemEntityType.link) {
        continue;
      }
      resources.add(
        SkillResourceDto(
          path: p.split(relative).join('/'),
          sizeBytes: entity.lengthSync(),
        ),
      );
      if (resources.length >= maxResources) break;
    }
    resources.sort((left, right) => left.path.compareTo(right.path));
    return resources;
  }

  @override
  Future<void> write(String id, String source) async {
    final directory = Directory(skillDirectory(id));
    await directory.create(recursive: true);
    if (createIfMissing) await _restrict(directory.path, '700');
    final file = File(documentPath(id));
    final temporary = File('${file.path}.$pid.tmp');
    try {
      await temporary.writeAsString(source, flush: true);
      if (Platform.isWindows && file.existsSync()) file.deleteSync();
      await temporary.rename(file.path);
      if (createIfMissing) await _restrict(file.path, '600');
    } finally {
      if (temporary.existsSync()) temporary.deleteSync();
    }
  }

  @override
  Future<void> archive(String id) async {
    final source = Directory(skillDirectory(id));
    final destination = Directory(p.join(_archiveDirectory.path, id));
    await _archiveDirectory.create(recursive: true);
    if (destination.existsSync()) destination.deleteSync(recursive: true);
    await source.rename(destination.path);
  }

  Future<void> _restrict(String path, String mode) async {
    if (Platform.isWindows) return;
    await Process.run('chmod', <String>[mode, path]);
  }

  @override
  Future<void> close() async {
    await _watchSubscription?.cancel();
    await _changes.close();
  }
}

/// Source-of-truth catalog merging built-in, user, config, and project skills.
final class FileSkillStore {
  /// Creates a store over the global roots, ordered lowest precedence first.
  FileSkillStore({
    required this.roots,
    required this.settings,
    this.builtIns = builtInSkills,
    this.watchDebounce = const Duration(milliseconds: 200),
    this.maxProjectRoots = 8,
  });

  static const String _enablementKey = 'skills.enablement';

  /// Global roots, ordered lowest precedence first.
  final List<SkillFiles> roots;

  /// Key-value store holding the enablement overrides.
  final SettingsRepository settings;

  /// Skills shipped inside the daemon.
  final List<BuiltInSkill> builtIns;

  /// Delay used to coalesce native editor event bursts.
  final Duration watchDebounce;

  /// Upper bound on simultaneously watched project roots.
  final int maxProjectRoots;

  final Map<SkillSource, Map<String, _ParsedSkill>> _global =
      <SkillSource, Map<String, _ParsedSkill>>{};
  final Map<String, _ProjectRoot> _projects = <String, _ProjectRoot>{};
  final StreamController<void> _changes = StreamController<void>.broadcast(
    sync: true,
  );
  final List<StreamSubscription<void>> _watchSubscriptions =
      <StreamSubscription<void>>[];
  Future<void> _operationTail = Future<void>.value();
  Future<void>? _initializeFuture;
  Timer? _reloadTimer;
  Future<void>? _watchReload;
  bool _closed = false;

  /// Emits after a catalog change or a stale diagnostic is detected.
  Stream<void> get changes => _changes.stream;

  /// Number of project roots currently cached and watched.
  int get trackedProjectRoots => _projects.length;

  /// Creates owned directories and starts observation.
  Future<void> initialize() {
    _ensureOpen();
    return _initializeFuture ??= _serialize(() async {
      for (final root in roots) {
        await root.initialize();
        _watchSubscriptions.add(
          root.changes.listen((_) => _scheduleReload()),
        );
      }
      await _reloadGlobalLocked();
    });
  }

  /// Returns every skill visible in [scope], shadowed entries included.
  Future<List<SkillDto>> list({SkillScope scope = SkillScope.global}) async {
    await initialize();
    return _serialize(() async => _resolveLocked(scope));
  }

  /// Returns one skill visible in [scope].
  Future<SkillDto?> get(
    String id, {
    SkillScope scope = SkillScope.global,
  }) async {
    final skills = await list(scope: scope);
    for (final skill in skills) {
      if (skill.id == id && !skill.isShadowed) return skill;
    }
    return null;
  }

  /// Creates one skill in a writable source.
  Future<SkillDto> create({
    required String id,
    required SkillSource source,
    required String name,
    required String description,
    required String body,
    SkillScope scope = SkillScope.global,
  }) async {
    await initialize();
    return _serialize(() async {
      _validateId(id);
      final files = await _writableFilesLocked(source, scope);
      final existing = await _resolveLocked(scope);
      if (existing.any((skill) => skill.id == id)) {
        throw StateError('Skill already exists: $id');
      }
      final document = _codec.encodeNew(
        name: name,
        description: description,
        body: body,
      );
      await files.write(id, document);
      await _reloadForLocked(source, scope);
      return _requireLocked(id, scope);
    });
  }

  /// Updates one skill using optimistic concurrency.
  Future<SkillDto> update(
    SkillDto skill, {
    required String expectedContentHash,
    bool force = false,
    SkillScope scope = SkillScope.global,
  }) async {
    await initialize();
    return _serialize(() async {
      final current = await _requireLocked(skill.id, scope);
      if (!current.isEditable) {
        throw StateError('Skill is read-only: ${skill.id}');
      }
      if (!force && current.contentHash != expectedContentHash) {
        throw SkillFileConflict(current.contentHash);
      }
      final files = await _writableFilesLocked(current.source, scope);
      final parsed = _parsedLocked(skill.id, current.source, scope);
      await files.write(
        skill.id,
        _codec.encodeUpdate(
          originalSource: parsed?.rawSource ?? '',
          name: skill.name,
          description: skill.description,
          body: skill.body,
        ),
      );
      await _reloadForLocked(current.source, scope);
      return _requireLocked(skill.id, scope);
    });
  }

  /// Archives one skill inside its own source root.
  Future<void> delete(
    String id, {
    SkillScope scope = SkillScope.global,
  }) async {
    await initialize();
    await _serialize(() async {
      final current = await _requireLocked(id, scope);
      if (!current.isEditable) throw StateError('Skill is read-only: $id');
      final files = await _writableFilesLocked(current.source, scope);
      await files.archive(id);
      await _reloadForLocked(current.source, scope);
    });
  }

  /// Turns one skill on or off within its scope.
  Future<SkillDto> setEnabled(
    String id, {
    required bool enabled,
    SkillScope scope = SkillScope.global,
  }) async {
    await initialize();
    return _serialize(() async {
      final current = await _requireLocked(id, scope);
      if (current.isMandatory) {
        throw StateError('Skill is always enabled: $id');
      }
      final key = _enablementKeyFor(current.source, scope);
      final overrides = await _readEnablement(key);
      final builtIn = _builtInById(id);
      final defaultEnabled = builtIn?.defaultEnabled ?? true;
      if (enabled == defaultEnabled) {
        overrides.remove(id);
      } else {
        overrides[id] = enabled;
      }
      await settings.setValue(key, jsonEncode(overrides));
      _changes.add(null);
      return _requireLocked(id, scope);
    });
  }

  /// Reloads external changes immediately.
  Future<void> reload() async {
    await initialize();
    await _serialize(() async {
      await _reloadGlobalLocked();
      for (final project in _projects.values) {
        await _reloadProjectLocked(project);
      }
    });
  }

  Future<List<SkillDto>> _resolveLocked(SkillScope scope) async {
    final projectRoot = scope.projectRoot;
    final project = projectRoot == null
        ? null
        : await _projectRootLocked(projectRoot);
    final globalOverrides = await _readEnablement(_enablementKey);
    final projectOverrides = scope.workspaceId == null
        ? <String, bool>{}
        : await _readEnablement(_projectEnablementKey(scope.workspaceId!));

    final winners = <String, SkillDto>{};
    final shadowed = <SkillDto>[];

    void offer(SkillDto candidate) {
      final incumbent = winners[candidate.id];
      if (incumbent == null) {
        winners[candidate.id] = candidate;
        return;
      }
      if (incumbent.isMandatory) {
        shadowed.add(
          candidate.copyWith(
            isShadowed: true,
            diagnostics: <SkillDiagnosticDto>[
              ...candidate.diagnostics,
              const SkillDiagnosticDto(
                code: 'shadowed_builtin',
                message:
                    'A mandatory built-in skill owns this ID and cannot be '
                    'replaced.',
              ),
            ],
          ),
        );
        return;
      }
      shadowed.add(incumbent.copyWith(isShadowed: true));
      winners[candidate.id] = candidate;
    }

    for (final builtIn in builtIns) {
      offer(
        SkillDto(
          id: builtIn.id,
          name: builtIn.name,
          description: builtIn.description,
          source: SkillSource.builtIn,
          sourcePath: '',
          contentHash: _hash(builtIn.body),
          body: builtIn.body.trim(),
          isMandatory: builtIn.isMandatory,
          isEnabled:
              builtIn.isMandatory ||
              (globalOverrides[builtIn.id] ?? builtIn.defaultEnabled),
        ),
      );
    }
    for (final root in roots) {
      for (final parsed in _sortedParsed(_global[root.source])) {
        offer(
          await _toDto(
            parsed,
            root,
            isEnabled: globalOverrides[parsed.id] ?? true,
          ),
        );
      }
    }
    if (project != null) {
      for (final parsed in _sortedParsed(project.parsed)) {
        offer(
          await _toDto(
            parsed,
            project.files,
            isEnabled: projectOverrides[parsed.id] ?? true,
          ),
        );
      }
    }

    final resolved = <SkillDto>[...winners.values, ...shadowed]
      ..sort((left, right) => left.id.compareTo(right.id));
    return List<SkillDto>.unmodifiable(resolved);
  }

  Iterable<_ParsedSkill> _sortedParsed(Map<String, _ParsedSkill>? parsed) {
    final values = (parsed ?? const <String, _ParsedSkill>{}).values.toList()
      ..sort((left, right) => left.id.compareTo(right.id));
    return values;
  }

  Future<SkillDto> _toDto(
    _ParsedSkill parsed,
    SkillFiles files, {
    required bool isEnabled,
  }) async => SkillDto(
    id: parsed.id,
    name: parsed.name,
    description: parsed.description,
    source: files.source,
    sourcePath: parsed.sourcePath,
    contentHash: parsed.contentHash,
    body: parsed.body,
    resources: await files.resources(parsed.id),
    isEnabled: isEnabled,
    isEditable: true,
    isStale: parsed.isStale,
    diagnostics: parsed.diagnostics,
  );

  Future<SkillDto> _requireLocked(String id, SkillScope scope) async {
    for (final skill in await _resolveLocked(scope)) {
      if (skill.id == id && !skill.isShadowed) return skill;
    }
    throw StateError('Skill not found: $id');
  }

  _ParsedSkill? _parsedLocked(String id, SkillSource source, SkillScope scope) {
    if (source == SkillSource.project) {
      final root = scope.projectRoot;
      return root == null ? null : _projects[root]?.parsed[id];
    }
    return _global[source]?[id];
  }

  Future<SkillFiles> _writableFilesLocked(
    SkillSource source,
    SkillScope scope,
  ) async {
    if (source == SkillSource.builtIn) {
      throw StateError('Built-in skills cannot be modified.');
    }
    if (source == SkillSource.project) {
      final root = scope.projectRoot;
      if (root == null) throw StateError('No project is selected.');
      return (await _projectRootLocked(root)).files;
    }
    for (final root in roots) {
      if (root.source == source) return root;
    }
    throw StateError('Unknown skill source: ${source.name}');
  }

  Future<_ProjectRoot> _projectRootLocked(String projectRoot) async {
    final cached = _projects.remove(projectRoot);
    if (cached != null) {
      _projects[projectRoot] = cached;
      return cached;
    }
    while (_projects.length >= maxProjectRoots) {
      final oldest = _projects.keys.first;
      final evicted = _projects.remove(oldest)!;
      await evicted.close();
    }
    final files = NativeSkillFiles(
      p.join(projectRoot, '.agents', 'skills'),
      source: SkillSource.project,
    );
    await files.initialize();
    final entry = _ProjectRoot(files: files)
      ..watch = files.changes.listen((_) => _scheduleReload());
    _projects[projectRoot] = entry;
    await _reloadProjectLocked(entry);
    return entry;
  }

  Future<void> _reloadGlobalLocked() async {
    for (final root in roots) {
      _global[root.source] = _parse(
        await root.read(),
        previous: _global[root.source],
      );
    }
    _changes.add(null);
  }

  Future<void> _reloadProjectLocked(_ProjectRoot project) async {
    project.parsed = _parse(
      await project.files.read(),
      previous: project.parsed,
    );
    _changes.add(null);
  }

  Future<void> _reloadForLocked(SkillSource source, SkillScope scope) async {
    if (source == SkillSource.project) {
      final root = scope.projectRoot;
      final project = root == null ? null : _projects[root];
      if (project != null) await _reloadProjectLocked(project);
      return;
    }
    await _reloadGlobalLocked();
  }

  Map<String, _ParsedSkill> _parse(
    List<SkillDocument> documents, {
    Map<String, _ParsedSkill>? previous,
  }) {
    final parsed = <String, _ParsedSkill>{};
    for (final document in documents) {
      try {
        _validateId(document.id);
        parsed[document.id] = _codec.decode(document);
      } on FormatException catch (error) {
        final last = previous?[document.id];
        final fallback = last ?? _ParsedSkill.unparsed(document);
        parsed[document.id] = fallback.copyWith(
          isStale: true,
          diagnostics: <SkillDiagnosticDto>[
            SkillDiagnosticDto(
              code: 'invalid_skill_markdown',
              message: error.message,
            ),
          ],
        );
      }
    }
    return parsed;
  }

  Future<Map<String, bool>> _readEnablement(String key) async {
    final stored = await settings.getValue(key);
    if (stored == null) return <String, bool>{};
    final decoded = jsonDecode(stored);
    if (decoded is! Map) return <String, bool>{};
    return <String, bool>{
      for (final entry in decoded.entries)
        if (entry.key is String && entry.value is bool)
          entry.key! as String: entry.value! as bool,
    };
  }

  String _enablementKeyFor(SkillSource source, SkillScope scope) =>
      source == SkillSource.project && scope.workspaceId != null
      ? _projectEnablementKey(scope.workspaceId!)
      : _enablementKey;

  String _projectEnablementKey(String workspaceId) =>
      '$_enablementKey.$workspaceId';

  BuiltInSkill? _builtInById(String id) {
    for (final builtIn in builtIns) {
      if (builtIn.id == id) return builtIn;
    }
    return null;
  }

  void _scheduleReload() {
    if (_closed) return;
    _reloadTimer?.cancel();
    _reloadTimer = Timer(watchDebounce, () {
      if (_closed) return;
      final reloadFuture = _serialize(() async {
        await _reloadGlobalLocked();
        for (final project in _projects.values) {
          await _reloadProjectLocked(project);
        }
      });
      _watchReload = reloadFuture;
      unawaited(
        reloadFuture.then<void>(
          (_) {},
          onError: (Object error, StackTrace stackTrace) {
            if (!_closed) Zone.current.handleUncaughtError(error, stackTrace);
          },
        ),
      );
    });
  }

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final previous = _operationTail;
    final release = Completer<void>();
    _operationTail = release.future;
    Future<T> run() async {
      await previous;
      try {
        return await operation();
      } finally {
        release.complete();
      }
    }

    return run();
  }

  void _ensureOpen() {
    if (_closed) throw StateError('Skill store is closed.');
  }

  /// Stops observation of every root.
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _reloadTimer?.cancel();
    for (final subscription in _watchSubscriptions) {
      await subscription.cancel();
    }
    await _watchReload;
    await _operationTail;
    for (final project in _projects.values) {
      await project.close();
    }
    _projects.clear();
    for (final root in roots) {
      await root.close();
    }
    await _changes.close();
  }
}

final class _ProjectRoot {
  _ProjectRoot({required this.files});

  final NativeSkillFiles files;
  Map<String, _ParsedSkill> parsed = <String, _ParsedSkill>{};
  StreamSubscription<void>? watch;

  Future<void> close() async {
    await watch?.cancel();
    await files.close();
  }
}

final class _ParsedSkill {
  const _ParsedSkill({
    required this.id,
    required this.name,
    required this.description,
    required this.sourcePath,
    required this.rawSource,
    required this.contentHash,
    required this.body,
    this.isStale = false,
    this.diagnostics = const <SkillDiagnosticDto>[],
  });

  factory _ParsedSkill.unparsed(SkillDocument document) => _ParsedSkill(
    id: document.id,
    name: document.id,
    description: '',
    sourcePath: document.sourcePath,
    rawSource: document.source,
    contentHash: '',
    body: '',
  );

  final String id;
  final String name;
  final String description;
  final String sourcePath;
  final String rawSource;
  final String contentHash;
  final String body;
  final bool isStale;
  final List<SkillDiagnosticDto> diagnostics;

  _ParsedSkill copyWith({
    bool? isStale,
    List<SkillDiagnosticDto>? diagnostics,
  }) => _ParsedSkill(
    id: id,
    name: name,
    description: description,
    sourcePath: sourcePath,
    rawSource: rawSource,
    contentHash: contentHash,
    body: body,
    isStale: isStale ?? this.isStale,
    diagnostics: diagnostics ?? this.diagnostics,
  );
}

const _SkillMarkdownCodec _codec = _SkillMarkdownCodec();

/// Parses and updates the skill Markdown format.
final class _SkillMarkdownCodec {
  const _SkillMarkdownCodec();

  /// Parses one document, preserving its source for later updates.
  _ParsedSkill decode(SkillDocument document) {
    final parsed = _SkillMarkdownDocument.parse(document.source);
    final decoded = loadYaml(
      parsed.frontmatter,
      sourceUrl: p.isAbsolute(document.sourcePath)
          ? Uri.file(document.sourcePath)
          : null,
    );
    if (decoded is! YamlMap) {
      throw const FormatException('Skill frontmatter must be a YAML map.');
    }
    final name = decoded['name'];
    final description = decoded['description'];
    if (name is! String || name.trim().isEmpty) {
      throw const FormatException('name must be a non-empty string.');
    }
    if (description is! String || description.trim().isEmpty) {
      throw const FormatException('description must be a non-empty string.');
    }
    return _ParsedSkill(
      id: document.id,
      name: name.trim(),
      description: description.trim(),
      sourcePath: document.sourcePath,
      rawSource: document.source,
      contentHash: _hash(document.source),
      body: parsed.body.trim(),
    );
  }

  /// Rewrites known fields while retaining unknown YAML and comments.
  String encodeUpdate({
    required String originalSource,
    required String name,
    required String description,
    required String body,
  }) {
    if (originalSource.isEmpty) {
      return encodeNew(name: name, description: description, body: body);
    }
    final document = _SkillMarkdownDocument.parse(originalSource);
    final editor = YamlEditor(document.frontmatter)
      ..update(<Object>['name'], name)
      ..update(<Object>['description'], description);
    return '---\n$editor\n---\n\n${body.trim()}\n';
  }

  /// Creates a canonical new document.
  String encodeNew({
    required String name,
    required String description,
    required String body,
  }) {
    final editor = YamlEditor('')
      ..update(<Object>[], <String, Object?>{
        'name': name,
        'description': description,
      });
    return '---\n$editor\n---\n\n${body.trim()}\n';
  }
}

final class _SkillMarkdownDocument {
  const _SkillMarkdownDocument({required this.frontmatter, required this.body});

  factory _SkillMarkdownDocument.parse(String source) {
    final lines = source.replaceAll('\r\n', '\n').split('\n');
    var start = 0;
    while (start < lines.length && lines[start].trim().isEmpty) {
      start += 1;
    }
    if (start == lines.length || lines[start].trim() != '---') {
      throw const FormatException('SKILL.md must start with frontmatter.');
    }
    var end = start + 1;
    while (end < lines.length && lines[end].trim() != '---') {
      end += 1;
    }
    if (end == lines.length) {
      throw const FormatException('SKILL.md frontmatter is not closed.');
    }
    return _SkillMarkdownDocument(
      frontmatter: lines.sublist(start + 1, end).join('\n'),
      body: lines.sublist(end + 1).join('\n'),
    );
  }

  final String frontmatter;
  final String body;
}

/// Application service exposing skills to RPC callers and to turns.
final class SkillCatalogService {
  /// Creates a skill application service.
  SkillCatalogService({required this.store});

  /// Source-of-truth catalog backing this service.
  final FileSkillStore store;

  /// Emits after a catalog change.
  Stream<void> get changes => store.changes;

  /// Number of project roots currently cached and watched.
  int get trackedProjectRoots => store.trackedProjectRoots;

  /// Creates owned directories and starts observation.
  Future<void> initialize() => store.initialize();

  /// Returns every skill visible in [scope].
  Future<List<SkillDto>> list({SkillScope scope = SkillScope.global}) =>
      store.list(scope: scope);

  /// Returns one skill visible in [scope].
  Future<SkillDto> get(
    String id, {
    SkillScope scope = SkillScope.global,
  }) async {
    final skill = await store.get(id, scope: scope);
    if (skill == null) throw StateError('Skill not found: $id');
    return skill;
  }

  /// Creates one skill in a writable source.
  Future<SkillDto> create({
    required String id,
    required SkillSource source,
    required String name,
    required String description,
    required String body,
    SkillScope scope = SkillScope.global,
  }) => store.create(
    id: id,
    source: source,
    name: name,
    description: description,
    body: body,
    scope: scope,
  );

  /// Updates one skill using optimistic concurrency.
  Future<SkillDto> update(
    SkillDto skill, {
    required String expectedContentHash,
    bool force = false,
    SkillScope scope = SkillScope.global,
  }) => store.update(
    skill,
    expectedContentHash: expectedContentHash,
    force: force,
    scope: scope,
  );

  /// Archives one skill.
  Future<void> delete(String id, {SkillScope scope = SkillScope.global}) =>
      store.delete(id, scope: scope);

  /// Turns one skill on or off.
  Future<SkillDto> setEnabled(
    String id, {
    required bool enabled,
    SkillScope scope = SkillScope.global,
  }) => store.setEnabled(id, enabled: enabled, scope: scope);

  /// Reloads external changes immediately.
  Future<void> reload() => store.reload();

  /// Builds the immutable catalog one turn sees.
  Future<SkillCatalog> viewFor(String projectRoot) async =>
      SkillSnapshotCatalog(
        await store.list(scope: SkillScope(projectRoot: projectRoot)),
      );

  /// Stops observation.
  Future<void> close() => store.close();
}

/// Immutable, turn-scoped catalog built from one resolved skill list.
final class SkillSnapshotCatalog implements SkillCatalog {
  /// Creates a catalog over the enabled, non-shadowed entries of [skills].
  SkillSnapshotCatalog(List<SkillDto> skills)
    : _byName = <String, SkillDto>{
        for (final skill in skills)
          if (skill.isEnabled && !skill.isShadowed && !skill.isStale)
            skill.name: skill,
      };

  final Map<String, SkillDto> _byName;

  @override
  List<SkillSummary> summaries() {
    final names = _byName.keys.toList()..sort();
    return <SkillSummary>[
      for (final name in names)
        SkillSummary(
          name: name,
          description: _byName[name]!.description,
        ),
    ];
  }

  @override
  Future<SkillContent> read(String name) async {
    final skill = _require(name);
    return SkillContent(
      name: skill.name,
      description: skill.description,
      instructions: skill.body,
      directory: skill.sourcePath.isEmpty ? null : p.dirname(skill.sourcePath),
      resources: skill.resources
          .map(
            (resource) => SkillResourceRef(
              path: resource.path,
              sizeBytes: resource.sizeBytes,
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<String> readResource(String name, String relativePath) async {
    final skill = _require(name);
    if (skill.sourcePath.isEmpty) {
      throw SkillLookupException('Skill has no bundled files: $name');
    }
    final guard = SkillPathGuard(p.dirname(skill.sourcePath));
    return File(guard.resolveExisting(relativePath)).readAsString();
  }

  SkillDto _require(String name) {
    final skill = _byName[name];
    if (skill == null) {
      throw SkillLookupException('Unknown or disabled skill: $name');
    }
    return skill;
  }
}

String _hash(String source) => sha256.convert(utf8.encode(source)).toString();

void _validateId(String id) {
  if (!RegExp(r'^[a-z0-9][a-z0-9_-]{0,63}$').hasMatch(id)) {
    throw const FormatException('Invalid skill ID.');
  }
}
