import 'dart:ui' as ui;

import 'package:app/src/app/router/app_router.dart';
import 'package:app/src/features/hosts/application/host_controller.dart';
import 'package:app/src/features/hosts/domain/host_models.dart';
import 'package:app/src/shared/presentation/tinest_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

import '../../support/fake_tinest_api.dart';
import '../../support/localization.dart';
import '../../support/router_harness.dart';

void main() {
  testWidgets(
    'compact Settings home shows a non-interactive row when no daemon exists',
    (tester) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final router = await pumpRoutedApp(
        tester,
        FakeTinestApi(),
        initialLocation: const SettingsHomeRoute().location,
        overrides: [
          hostRegistryControllerProvider.overrideWith(
            _EmptyHostRegistryController.new,
          ),
        ],
      );
      addTearDown(router.dispose);

      final emptyRow = find.byKey(
        const ValueKey<String>('settings-daemon-empty-row'),
      );
      expect(emptyRow, findsOneWidget);
      expect(find.text(testL10n.settingsDaemonSelectEmpty), findsOneWidget);

      final row = tester.widget<TRNavigationRow>(emptyRow);
      expect(row.enabled, isFalse);
      expect(row.onPressed, isNull);
      expect(row.trailing, isNull);
      expect(
        find.descendant(
          of: emptyRow,
          matching: find.byIcon(
            TinestIcons.forwardFor(tester.element(emptyRow)),
          ),
        ),
        findsNothing,
      );
      expect(
        tester
            .getSemantics(find.text(testL10n.settingsDaemonSelectEmpty))
            .getSemanticsData()
            .hasAction(ui.SemanticsAction.tap),
        isFalse,
      );

      await tester.tap(emptyRow);
      await tester.pumpAndSettle();
      expect(currentLocation(router), const SettingsHomeRoute().location);
    },
    tags: const <String>[
      'feature_test__app_navigation__widget',
      'feature_test__daemon_management__widget',
    ],
  );
}

final class _EmptyHostRegistryController extends HostRegistryController {
  @override
  Future<HostRegistryState> build() async => const HostRegistryState(
    settings: AppSettings(embeddedDaemonEnabled: false),
    profiles: <RemoteDaemonProfile>[],
    runtimes: <String, HostRuntimeSnapshot>{},
  );
}
