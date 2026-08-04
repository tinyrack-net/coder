import 'dart:async';

import 'package:coder_daemon/src/agent_definitions.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:test/test.dart';

void main() {
  test('a stale scan cannot remove a definition created behind it', () async {
    final files = _ControllableAgentDefinitionFiles();
    final store = FileAgentDefinitionStore.withFiles(files);
    addTearDown(store.close);
    await store.initialize();
    final coder = (await store.get('coder'))!;

    files.pauseNextActiveScan();
    final staleReload = store.reload();
    await files.scanStarted;
    final create = store.create(
      'reviewer',
      coder.copyWith(
        id: 'reviewer',
        name: 'Reviewer',
        description: '',
        mode: AgentMode.subagent,
        callableAgentIds: const <String>[],
        sourcePath: '',
        contentHash: '',
        isBuiltIn: false,
      ),
    );

    files.releaseScan();
    await staleReload;
    await create;

    expect(files.activeDocuments, contains('reviewer'));
    expect(
      (await store.list()).map((definition) => definition.id),
      contains('reviewer'),
    );
  });

  test('watch reloads are debounced and drained before close', () async {
    final files = _ControllableAgentDefinitionFiles();
    final store = FileAgentDefinitionStore.withFiles(
      files,
      watchDebounce: const Duration(milliseconds: 1),
    );
    await store.initialize();
    final initialScans = files.activeScanCount;

    // Waiting for the reload the debounce timer schedules keeps the assertion
    // deterministic; a fixed delay races the timer whenever the machine is
    // busy. The three emits share one microtask, so no timer can fire between
    // them and they must coalesce into exactly one scan.
    final reloaded = store.changes.first;
    files
      ..emitChange()
      ..emitChange()
      ..emitChange();
    await reloaded;
    await store.close();

    expect(files.activeScanCount, initialScans + 1);
    expect(files.closed, isTrue);
  });
}

final class _ControllableAgentDefinitionFiles implements AgentDefinitionFiles {
  final StreamController<void> _changes = StreamController<void>.broadcast();
  final Map<String, String> _active = <String, String>{};
  final Map<String, String> _archived = <String, String>{};
  Completer<void>? _scanStarted;
  Completer<void>? _scanRelease;

  int activeScanCount = 0;
  bool closed = false;

  Iterable<String> get activeDocuments => _active.keys;

  Future<void> get scanStarted => _scanStarted!.future;

  void pauseNextActiveScan() {
    _scanStarted = Completer<void>();
    _scanRelease = Completer<void>();
  }

  void releaseScan() {
    _scanRelease!.complete();
    _scanRelease = null;
  }

  void emitChange() => _changes.add(null);

  @override
  Stream<void> get changes => _changes.stream;

  @override
  String activePath(String id) => '/agents/$id.md';

  @override
  Future<void> archive(String id) async {
    _archived[id] = _active.remove(id)!;
    emitChange();
  }

  @override
  String archivePath(String id) => '/agents/.archive/$id.md';

  @override
  Future<void> close() async {
    closed = true;
    await _changes.close();
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<List<AgentDefinitionDocument>> readActive() async {
    activeScanCount += 1;
    final snapshot = Map<String, String>.of(_active);
    final started = _scanStarted;
    final release = _scanRelease;
    if (started != null && release != null) {
      _scanStarted = null;
      started.complete();
      await release.future;
    }
    return <AgentDefinitionDocument>[
      for (final entry in snapshot.entries)
        AgentDefinitionDocument(
          id: entry.key,
          sourcePath: activePath(entry.key),
          source: entry.value,
        ),
    ];
  }

  @override
  Future<List<AgentDefinitionDocument>> readArchived() async =>
      <AgentDefinitionDocument>[
        for (final entry in _archived.entries)
          AgentDefinitionDocument(
            id: entry.key,
            sourcePath: archivePath(entry.key),
            source: entry.value,
          ),
      ];

  @override
  Future<void> writeActive(String id, String source) async {
    _active[id] = source;
    emitChange();
  }
}
