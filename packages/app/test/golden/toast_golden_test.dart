import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:app/src/shared/presentation/toast_messenger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

import '../support/localization.dart';

/// Reports the application shows over whatever the user was looking at.
///
/// The stack is the interesting shape rather than any one card: a one-line
/// success next to a failure carrying a daemon message is where a card taller
/// than its content, or text the region failed to style, shows up.
const _reports = <({String title, String? description, bool failed})>[
  (title: 'Saved', description: null, failed: false),
  (
    title: 'Could not save the project',
    description:
        'Connection to 127.0.0.1:52413 was reset while writing the frame for '
        'updateWorkspace (attempt 3 of 3).',
    failed: true,
  ),
  (title: 'Path copied', description: null, failed: false),
];

void main() {
  for (final mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
    unawaited(
      goldenTest(
        'a stack of reports fits its content in ${mode.name}',
        fileName: 'toast_stack_${mode.name}',
        constraints: const BoxConstraints.tightFor(width: 760, height: 560),
        // The cards arrive with an entry animation, so a settled frame is the
        // only one worth comparing.
        whilePerforming: (tester) async {
          await tester.pumpAndSettle();
          return null;
        },
        builder: () => _scenario(mode),
      ),
    );
  }
}

Widget _scenario(ThemeMode mode) => SizedBox(
  width: 700,
  height: 500,
  child: ProviderScope(
    child: MaterialApp(
      theme: testLightTheme,
      darkTheme: testDarkTheme,
      themeMode: mode,
      locale: testLocale,
      localizationsDelegates: testLocalizationsDelegates,
      supportedLocales: testSupportedLocales,
      home: Consumer(
        builder: (context, ref, _) {
          final messenger = ref.read(toastMessengerProvider);
          for (final report in _reports) {
            if (report.failed) {
              messenger.failure(
                report.title,
                error: StateError(report.description!),
                id: report.title,
              );
            } else {
              messenger.success(
                report.title,
                description: report.description,
                id: report.title,
              );
            }
          }
          // Deliberately not wrapped in a Scaffold. The running application
          // mounts the scope as a sibling of its routes so a report outlives
          // the route that asked for it, and only that placement shows whether
          // the region styles its own text.
          // The page itself is left blank so the comparison is about the cards
          // and the space they take, not about whatever they happen to cover.
          return ColoredBox(
            color: context.tinyrackTheme.surfaceMuted,
            child: const TinestToastScope(child: SizedBox.expand()),
          );
        },
      ),
    ),
  ),
);
