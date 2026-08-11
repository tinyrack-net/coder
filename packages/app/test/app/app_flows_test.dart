import 'dart:async';

import 'package:app/src/app/coder_app.dart';
import 'package:app/src/app/composition/app_providers.dart';
import 'package:app/src/app/composition/app_services.dart';
import 'package:app/src/app/presentation/workspace_page.dart';
import 'package:app/src/app/router/app_router.dart';
import 'package:app/src/features/conversation/application/chat_timeline_model.dart';
import 'package:app/src/features/conversation/presentation/chat_approval_card.dart';
import 'package:app/src/features/conversation/presentation/chat_question_card.dart';
import 'package:app/src/features/conversation/presentation/chat_timeline_view.dart';
import 'package:app/src/features/hosts/application/host_controller.dart';
import 'package:app/src/features/hosts/domain/host_models.dart';
import 'package:app/src/features/hosts/domain/host_ports.dart';
import 'package:app/src/features/workspace/presentation/widgets/workspace_sidebar.dart';
import 'package:app/src/shared/presentation/coder_control_density.dart';
import 'package:app/src/shared/presentation/coder_icons.dart';
import 'package:app/src/shared/presentation/coder_selection_row.dart';
import 'package:app/src/shared/presentation/model_picker.dart';
import 'package:app/src/shared/presentation/toast_messenger.dart';
import 'package:client/client.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:protocol/protocol.dart';
import 'package:termworld/termworld.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

import '../support/fake_coder_api.dart';
import '../support/localization.dart';

part '../features/agents/app_flow_cases.dart';
part '../features/conversation/app_flow_cases.dart';
part '../features/sessions/app_flow_cases.dart';
part '../features/settings/app_flow_cases.dart';
part '../features/workspace/app_flow_cases.dart';
part '../shared/app_flow_cases.dart';

const liveTerminal = TerminalDto(
  id: 'terminal-deep-link',
  worktreeId: 'checkout',
  title: 'Remote terminal',
  shell: ShellSpecDto(executable: '/bin/sh'),
  status: TerminalStatus.running,
  columns: 80,
  rows: 24,
  lastSequence: 0,
);

/// Arguments of an `update_plan` call, as the model sends them.
const Map<String, dynamic> _planArguments = <String, dynamic>{
  'plan': <Map<String, dynamic>>[
    <String, dynamic>{'step': 'Move the parser', 'status': 'pending'},
    <String, dynamic>{'step': 'Add tests', 'status': 'pending'},
  ],
  'explanation': 'Parser first.',
};

void main() {
  _registerSharedAppFlows();
  _registerWorkspaceAppFlows();
  _registerSettingsAppFlows();
  _registerAgentsAppFlows();
  _registerSessionsAppFlows();
  _registerConversationAppFlows();
}

Future<GoRouter> _pumpRoute(
  WidgetTester tester,
  FakeCoderApi api,
  String location, {
  MemoryAppStore? store,
  bool disableAnimations = false,
  bool settle = true,
}) async {
  final router = GoRouter(initialLocation: location, routes: $appRoutes);
  final app = MaterialApp.router(
    theme: testLightTheme,
    darkTheme: testDarkTheme,
    locale: testLocale,
    localizationsDelegates: testLocalizationsDelegates,
    supportedLocales: testSupportedLocales,
    routerConfig: router,
    // Mirrors what CoderApp wraps every route in, so a screen under test can
    // report a result the same way it does when the app runs.
    builder: (context, child) => CoderControlDensity(
      child: CoderToastScope(child: child ?? const SizedBox.shrink()),
    ),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appServicesProvider.overrideWithValue(
          fakeAppServices(api, store: store),
        ),
      ],
      child: disableAnimations
          ? MediaQuery(
              data: MediaQueryData(
                disableAnimations: true,
                size: tester.view.physicalSize / tester.view.devicePixelRatio,
              ),
              child: app,
            )
          : app,
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  return router;
}

Finder _textField(String label) => find.byWidgetPredicate(
  (widget) => widget is TRTextField && widget.label == label,
  description: 'TRTextField labelled "$label"',
);

Finder _textInput(String label) => find.descendant(
  of: _textField(label),
  matching: find.byType(EditableText),
);

Future<void> _openComposerSetting(
  WidgetTester tester,
  String setting,
) async {
  final direct = find.byKey(ValueKey<String>('session-composer-$setting'));
  if (direct.evaluate().isNotEmpty) {
    await tester.tap(direct);
    await tester.pumpAndSettle();
    return;
  }
  await tester.tap(
    find.byKey(const ValueKey<String>('session-composer-settings')),
  );
  await tester.pumpAndSettle();
  final row = find.byKey(
    ValueKey<String>('session-composer-settings-$setting'),
  );
  await tester.ensureVisible(row);
  await tester.pumpAndSettle();
  await tester.tap(row);
  await tester.pumpAndSettle();
}

Future<void> _dismissComposerSettings(WidgetTester tester) async {
  if (find
      .byKey(const ValueKey<String>('session-composer-settings-sheet'))
      .evaluate()
      .isEmpty) {
    return;
  }
  await tester.sendKeyEvent(LogicalKeyboardKey.escape);
  await tester.pumpAndSettle();
}

Future<void> _selectComposerMode(
  WidgetTester tester,
  SessionMode mode,
) async {
  final direct = find.byKey(
    const ValueKey<String>('session-composer-mode'),
  );
  if (direct.evaluate().isNotEmpty) {
    await tester.tap(direct);
    await tester.pumpAndSettle();
    return;
  }
  await _openComposerSetting(tester, 'mode');
  await tester.tap(
    find.byKey(
      ValueKey<String>('session-composer-mode-${mode.name}-sheet'),
    ),
  );
  await tester.pumpAndSettle();
  await _dismissComposerSettings(tester);
}

final class _MappedClients implements HostClientFactory {
  const _MappedClients(this.apis);

  final Map<String, CoderApi> apis;

  @override
  Future<CoderApi> connect({
    required HostConnection connection,
    required HostConnectionCredential credential,
    required String clientId,
    required String clientKind,
  }) async =>
      apis[(connection as DirectHostConnection).endpoint.websocketUri.host]!;
}
