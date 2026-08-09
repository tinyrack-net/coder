import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:app/src/shared/presentation/settings_layout.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

import '../support/localization.dart';

void main() {
  for (final mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
    unawaited(
      goldenTest(
        'settings rows keep the card surface stable while a switch is hovered '
        'in ${mode.name}',
        fileName: 'settings_row_hover_${mode.name}',
        constraints: const BoxConstraints.tightFor(width: 620, height: 520),
        whilePerforming: (tester) async {
          final mouse = await tester.createGesture(
            kind: PointerDeviceKind.mouse,
          );
          await mouse.addPointer(location: Offset.zero);
          addTearDown(mouse.removePointer);
          await mouse.moveTo(
            tester.getCenter(
              find.byKey(
                const ValueKey<String>('settings-hover-golden-switch'),
              ),
            ),
          );
          await tester.pumpAndSettle();
          return null;
        },
        builder: () => _scenario(mode),
      ),
    );
  }
}

Widget _scenario(ThemeMode mode) => SizedBox(
  width: 560,
  height: 460,
  child: MaterialApp(
    theme: testLightTheme,
    darkTheme: testDarkTheme,
    themeMode: mode,
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(TRSpacing.extraLarge),
        child: SettingsSection(
          title: 'Local execution',
          children: <Widget>[
            SettingsRow(
              title: const TRText.inherit('Embedded daemon'),
              description: const TRText.inherit(
                'Starts with the app and stops when it exits.',
              ),
              control: TRSwitch(
                key: const ValueKey<String>('settings-hover-golden-switch'),
                checked: true,
                onCheckedChange: (_) {},
              ),
              onTap: () {},
            ),
            SettingsRow(
              title: const TRText.inherit('Allow network access'),
              description: const TRText.inherit(
                'Accept connections on every IPv4 interface.',
              ),
              control: TRSwitch(checked: false, onCheckedChange: (_) {}),
              onTap: () {},
            ),
          ],
        ),
      ),
    ),
  ),
);
