import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:coder_app/src/features/conversation/presentation/goal_status_bar.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/material.dart';

import '../support/localization.dart';

void main() {
  unawaited(
    goldenTest(
      'goal bar adapts across desktop mobile light and dark',
      fileName: 'session_goal_states',
      constraints: const BoxConstraints.tightFor(width: 1040, height: 620),
      builder: () => GoldenTestGroup(
        columns: 2,
        children: <Widget>[
          GoldenTestScenario(
            name: 'desktop light',
            child: _scenario(ThemeMode.light, 480, SessionMode.normal),
          ),
          GoldenTestScenario(
            name: 'desktop dark',
            child: _scenario(ThemeMode.dark, 480, SessionMode.normal),
          ),
          GoldenTestScenario(
            name: 'mobile light plan hold',
            child: _scenario(ThemeMode.light, 360, SessionMode.plan),
          ),
          GoldenTestScenario(
            name: 'mobile dark plan hold',
            child: _scenario(ThemeMode.dark, 360, SessionMode.plan),
          ),
        ],
      ),
    ),
  );
}

Widget _scenario(ThemeMode mode, double width, SessionMode sessionMode) {
  final now = DateTime.utc(2026, 8, 8);
  return SizedBox(
    width: width,
    height: 180,
    child: MaterialApp(
      theme: testLightTheme,
      darkTheme: testDarkTheme,
      themeMode: mode,
      locale: testLocale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: GoalStatusBar(
            goal: GoalDto(
              sessionId: 'session',
              goalId: 'goal',
              objective: '세션 Goal을 여러 턴에 걸쳐 구현하고 검증하기',
              status: GoalStatus.active,
              tokenBudget: 12000,
              tokensUsed: 4200,
              timeUsedSeconds: 95,
              createdAt: now,
              updatedAt: now,
            ),
            sessionMode: sessionMode,
            onEdit: () {},
            onStatusChanged: (_) {},
            onClear: () {},
          ),
        ),
      ),
    ),
  );
}
