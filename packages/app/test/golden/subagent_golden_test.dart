import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:app/src/features/conversation/application/subagent_track_model.dart';
import 'package:app/src/features/conversation/presentation/subagents/subagent_track.dart';
import 'package:flutter/material.dart';
import 'package:protocol/protocol.dart';

import '../support/localization.dart';

void main() {
  final now = DateTime.utc(2026);

  SessionDto subagent(
    String id, {
    required String taskName,
    required String agentPath,
    required AgentLifecycle lifecycle,
    String parentId = 'root',
    int second = 0,
  }) => SessionDto(
    id: id,
    worktreeId: 'checkout',
    title: taskName,
    agentDefinitionId: 'coder',
    origin: SessionOrigin.delegated,
    status: SessionStatus.idle,
    parentSessionId: parentId,
    taskName: taskName,
    agentPath: agentPath,
    rootSessionId: 'root',
    lifecycle: lifecycle,
    createdAt: now.add(Duration(seconds: second)),
    updatedAt: now.add(Duration(seconds: second)),
  );

  // Settled lifecycles only: a running row animates its spinner forever,
  // which a golden frame cannot settle on.
  final rows = buildSubagentTrackRows(<SessionDto>[
    subagent(
      'explore',
      taskName: 'explore_auth',
      agentPath: '/root/explore_auth',
      lifecycle: AgentLifecycle.completed,
    ),
    subagent(
      'docs',
      taskName: 'read_docs',
      agentPath: '/root/explore_auth/read_docs',
      lifecycle: AgentLifecycle.errored,
      parentId: 'explore',
      second: 1,
    ),
    subagent(
      'tests',
      taskName: 'run_tests',
      agentPath: '/root/run_tests',
      lifecycle: AgentLifecycle.interrupted,
      second: 2,
    ),
  ], 'root');

  Widget track(ThemeMode mode, {required bool expanded}) => MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: testLocale,
    localizationsDelegates: testLocalizationsDelegates,
    supportedLocales: testSupportedLocales,
    theme: testLightTheme,
    darkTheme: testDarkTheme,
    themeMode: mode,
    home: Scaffold(
      body: Align(
        alignment: Alignment.topCenter,
        child: _TrackHarness(rows: rows, expanded: expanded),
      ),
    ),
  );

  unawaited(
    goldenTest(
      'the subagent track renders collapsed and expanded in both themes',
      fileName: 'subagent_track',
      constraints: const BoxConstraints.tightFor(width: 1100, height: 900),
      builder: () => GoldenTestGroup(
        columns: 2,
        children: <Widget>[
          GoldenTestScenario(
            name: 'collapsed light',
            child: SizedBox(
              width: 480,
              height: 160,
              child: track(ThemeMode.light, expanded: false),
            ),
          ),
          GoldenTestScenario(
            name: 'collapsed dark',
            child: SizedBox(
              width: 480,
              height: 160,
              child: track(ThemeMode.dark, expanded: false),
            ),
          ),
          GoldenTestScenario(
            name: 'expanded light',
            child: SizedBox(
              width: 480,
              height: 320,
              child: track(ThemeMode.light, expanded: true),
            ),
          ),
          GoldenTestScenario(
            name: 'expanded dark',
            child: SizedBox(
              width: 480,
              height: 320,
              child: track(ThemeMode.dark, expanded: true),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Hosts the track at a fixed expansion state for a stable golden frame.
class _TrackHarness extends StatelessWidget {
  const _TrackHarness({required this.rows, required this.expanded});

  final List<SubagentTrackRow> rows;
  final bool expanded;

  @override
  Widget build(BuildContext context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: true),
    child: _ExpandedTrack(rows: rows, expanded: expanded),
  );
}

class _ExpandedTrack extends StatefulWidget {
  const _ExpandedTrack({required this.rows, required this.expanded});

  final List<SubagentTrackRow> rows;
  final bool expanded;

  @override
  State<_ExpandedTrack> createState() => _ExpandedTrackState();
}

class _ExpandedTrackState extends State<_ExpandedTrack> {
  final GlobalKey _trackKey = GlobalKey();

  @override
  Widget build(BuildContext context) => SubagentTrack(
    key: _trackKey,
    rows: widget.rows,
    maxListHeight: 240,
    onOpenSubagent: (_) {},
    initiallyOpen: widget.expanded,
  );
}
