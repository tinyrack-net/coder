import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:coder_app/src/features/boot/presentation/boot_splash.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  unawaited(
    goldenTest(
      'the boot splash centers the brand mark on the dark surface',
      fileName: 'boot_splash',
      constraints: const BoxConstraints.tightFor(width: 600, height: 420),
      // An asset image resolves off the test's fake async, so without this the
      // golden captures the surface with the mark still missing — exactly the
      // regression this test exists to catch.
      pumpBeforeTest: (tester) async {
        await tester.runAsync(() async {
          for (final element in find.byType(Image).evaluate()) {
            await precacheImage((element.widget as Image).image, element);
          }
        });
        await tester.pumpAndSettle();
      },
      builder: () => GoldenTestGroup(
        children: <Widget>[
          GoldenTestScenario(
            name: 'boot splash',
            child: const SizedBox(
              width: 520,
              height: 320,
              child: BootSplash(),
            ),
          ),
        ],
      ),
    ),
  );
}
