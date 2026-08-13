import 'dart:async';

import 'package:app/src/shared/presentation/settings_layout.dart';
import 'package:app/src/shared/presentation/tinest_layout_metrics.dart';
import 'package:app/src/shared/presentation/tinest_list_row.dart';
import 'package:app/src/shared/presentation/tinest_page_shell.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

import '../../support/localization.dart';

/// Hosts one composite at a fixed width, so a geometry expectation reads the
/// composite rather than whatever the surrounding page happened to impose.
Widget _host(Widget child, {double width = 1200}) => MaterialApp(
  theme: TinyrackTheme.light(),
  home: Scaffold(
    body: SizedBox(width: width, child: child),
  ),
);

Finder _rowSurface(Finder owner, EdgeInsetsGeometry padding) => find.descendant(
  of: owner,
  matching: find.byWidgetPredicate(
    (widget) => widget is AnimatedContainer && widget.padding == padding,
  ),
);

Finder _switchSurface(Finder owner) => find.descendant(
  of: owner,
  matching: find.byWidgetPredicate(
    (widget) => widget is AnimatedContainer && widget.padding != null,
  ),
);

Color _containerColor(WidgetTester tester, Finder finder) {
  final decoration = tester.widget<AnimatedContainer>(finder).decoration;
  return (decoration! as BoxDecoration).color!;
}

void main() {
  testWidgets(
    'SettingsAsyncContent preserves stale data across refresh',
    (tester) async {
      final loads = <Completer<String>>[];
      final provider = FutureProvider<String>((ref) {
        final load = Completer<String>();
        loads.add(load);
        return load.future;
      });
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: testLocale,
            localizationsDelegates: testLocalizationsDelegates,
            supportedLocales: testSupportedLocales,
            theme: testLightTheme,
            home: Consumer(
              builder: (context, ref, _) => SettingsAsyncContent<String>(
                state: ref.watch(provider),
                loading: const SettingsSkeletonLayout.form(
                  semanticLabel: '설정 불러오는 중',
                ),
                error: (error, _) => TRText.inherit('$error'),
                data: (value) => Center(
                  child: TRButton(
                    onPressed: () => ref.invalidate(provider),
                    child: TRText.inherit(value),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(TRSkeleton), findsWidgets);

      loads.single.complete('Ready');
      await tester.pump();
      await tester.pump();
      expect(find.text('Ready'), findsOneWidget);

      await tester.tap(find.text('Ready'));
      await tester.pump();
      expect(find.text('Ready'), findsOneWidget);
      expect(find.byType(SettingsSkeletonLayout), findsNothing);

      loads.last.completeError(Exception('refresh failed'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Ready'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('settings-refresh-error')),
        findsOneWidget,
      );
    },
    tags: const <String>['feature_test__settings_async_loading__widget'],
  );

  group('SettingsSkeletonLayout', () {
    testWidgets(
      'renders an inert labelled form skeleton',
      (tester) async {
        await tester.pumpWidget(
          _host(
            const SettingsSkeletonLayout.form(
              semanticLabel: 'Loading settings',
            ),
          ),
        );

        expect(
          find.byKey(const ValueKey<String>('settings-skeleton-form')),
          findsOneWidget,
        );
        expect(find.byType(TRSkeleton), findsWidgets);
        expect(find.bySemanticsLabel('Loading settings'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(SettingsSkeletonLayout),
            matching: find.byType(Focus),
          ),
          findsNothing,
        );
      },
      tags: const <String>['feature_test__settings_async_loading__widget'],
    );

    testWidgets(
      'adapts list-detail loading to the available width',
      (tester) async {
        await tester.pumpWidget(
          _host(
            const SettingsSkeletonLayout.listDetail(
              semanticLabel: 'Loading settings',
            ),
          ),
        );
        expect(
          find.byKey(const ValueKey<String>('settings-skeleton-list-pane')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey<String>('settings-skeleton-detail-pane')),
          findsOneWidget,
        );

        await tester.pumpWidget(
          _host(
            const SettingsSkeletonLayout.listDetail(
              semanticLabel: 'Loading settings',
            ),
            width: 390,
          ),
        );
        expect(
          find.byKey(const ValueKey<String>('settings-skeleton-list-pane')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey<String>('settings-skeleton-detail-pane')),
          findsNothing,
        );
      },
      tags: const <String>['feature_test__settings_async_loading__widget'],
    );
  });

  group('SettingsCompactPaneTransition', () {
    testWidgets('uses the Tinyrack fade and scale motion for a new pane', (
      tester,
    ) async {
      var pane = 'collection';
      late StateSetter update;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return SettingsCompactPaneTransition(
                paneKey: ValueKey<String>(pane),
                child: Text(pane),
              );
            },
          ),
          width: 390,
        ),
      );

      update(() => pane = 'detail');
      await tester.pump();

      final switcher = tester.widget<AnimatedSwitcher>(
        find.byType(AnimatedSwitcher),
      );
      expect(switcher.duration, TRMotion.slow);
      expect(switcher.reverseDuration, TRMotion.slow);
      expect(switcher.switchInCurve, TRMotion.easeOut);
      expect(switcher.switchOutCurve, TRMotion.standard);
      final enteringFade = tester.widget<FadeTransition>(
        find.ancestor(
          of: find.text('detail'),
          matching: find.byType(FadeTransition),
        ),
      );
      final enteringScale = tester.widget<ScaleTransition>(
        find.ancestor(
          of: find.text('detail'),
          matching: find.byType(ScaleTransition),
        ),
      );
      expect(enteringFade.opacity.value, 0);
      expect(enteringScale.scale.value, TRMeasurements.overlayClosedScale);

      await tester.pump(TRMotion.slow ~/ 2);
      expect(enteringFade.opacity.value, inExclusiveRange(0, 1));
      expect(
        enteringScale.scale.value,
        inExclusiveRange(TRMeasurements.overlayClosedScale, 1),
      );

      await tester.pumpAndSettle();
      expect(find.text('collection'), findsNothing);
      expect(find.text('detail'), findsOneWidget);
      expect(
        find.ancestor(
          of: find.text('detail'),
          matching: find.byType(FadeTransition),
        ),
        findsNothing,
      );
      expect(
        find.ancestor(
          of: find.text('detail'),
          matching: find.byType(ScaleTransition),
        ),
        findsNothing,
      );
    });

    testWidgets('only the entering pane owns input and semantics', (
      tester,
    ) async {
      var pane = 'collection';
      var collectionTaps = 0;
      var detailTaps = 0;
      late StateSetter update;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              final collection = pane == 'collection';
              return SettingsCompactPaneTransition(
                paneKey: ValueKey<String>(pane),
                child: Semantics(
                  label: '$pane semantics',
                  button: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (collection) {
                        collectionTaps += 1;
                      } else {
                        detailTaps += 1;
                      }
                    },
                    child: Center(child: Text(pane)),
                  ),
                ),
              );
            },
          ),
          width: 390,
        ),
      );

      update(() => pane = 'detail');
      await tester.pump();

      final departingSemantics = tester.widget<ExcludeSemantics>(
        find.ancestor(
          of: find.text('collection'),
          matching: find.byType(ExcludeSemantics),
        ),
      );
      final enteringSemantics = tester.widget<ExcludeSemantics>(
        find.ancestor(
          of: find.text('detail'),
          matching: find.byType(ExcludeSemantics),
        ),
      );
      final departingPointers = tester.widgetList<IgnorePointer>(
        find.ancestor(
          of: find.text('collection'),
          matching: find.byType(IgnorePointer),
        ),
      );
      final enteringPointers = tester.widgetList<IgnorePointer>(
        find.ancestor(
          of: find.text('detail'),
          matching: find.byType(IgnorePointer),
        ),
      );
      expect(departingSemantics.excluding, isTrue);
      expect(enteringSemantics.excluding, isFalse);
      expect(departingPointers.any((widget) => widget.ignoring), isTrue);
      expect(enteringPointers.any((widget) => !widget.ignoring), isTrue);
      await tester.tapAt(tester.getCenter(find.text('detail')));
      expect(collectionTaps, 0);
      expect(detailTaps, 1);
    });

    testWidgets('replaces the pane immediately when animations are disabled', (
      tester,
    ) async {
      var pane = 'collection';
      late StateSetter update;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: _host(
            StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return SettingsCompactPaneTransition(
                  paneKey: ValueKey<String>(pane),
                  child: Text(pane),
                );
              },
            ),
            width: 390,
          ),
        ),
      );

      update(() => pane = 'detail');
      await tester.pump();

      expect(find.text('collection'), findsNothing);
      expect(find.text('detail'), findsOneWidget);
      expect(find.byType(AnimatedSwitcher), findsNothing);
    });
  });

  testWidgets('SettingsListDetailLayout shares desktop and compact Back', (
    tester,
  ) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(1200, 800);
    addTearDown(tester.view.reset);
    final navigation = SettingsPaneNavigationController();
    addTearDown(navigation.dispose);
    var detailVisible = true;
    late StateSetter update;
    Widget surface(double width) => _host(
      StatefulBuilder(
        builder: (context, setState) {
          update = setState;
          return SettingsPaneNavigationScope(
            controller: navigation,
            child: SettingsListDetailLayout(
              collection: const Text('Collection'),
              detail: const Text('Detail'),
              detailVisible: detailVisible,
              onBack: () => update(() => detailVisible = false),
            ),
          );
        },
      ),
      width: width,
    );

    await tester.pumpWidget(surface(1200));
    await tester.pump();
    expect(find.text('Collection'), findsOneWidget);
    expect(find.text('Detail'), findsOneWidget);
    expect(navigation.canGoBack, isFalse);
    expect(find.byType(SettingsCompactPaneTransition), findsNothing);

    tester.view.physicalSize = const Size(600, 800);
    await tester.pumpWidget(surface(600));
    await tester.pump();
    expect(find.text('Collection'), findsNothing);
    expect(find.text('Detail'), findsOneWidget);
    expect(navigation.canGoBack, isTrue);

    tester.view.physicalSize = const Size(390, 800);
    await tester.pumpWidget(surface(390));
    await tester.pump();
    expect(find.text('Collection'), findsNothing);
    expect(find.text('Detail'), findsOneWidget);
    expect(navigation.canGoBack, isTrue);
    expect(find.byType(SettingsCompactPaneTransition), findsOneWidget);

    navigation.goBack();
    await tester.pumpAndSettle();
    expect(find.text('Collection'), findsOneWidget);
    expect(find.text('Detail'), findsNothing);
  });

  testWidgets(
    'collection rows share the sidebar inset, navigation surface, and rhythm',
    (tester) async {
      await tester.pumpWidget(
        _host(
          const Column(
            children: <Widget>[
              SettingsPaneHeader.collection(title: 'Projects'),
              Expanded(
                child: SettingsCollectionList(
                  children: <Widget>[
                    SettingsRow.collection(
                      title: TRText.inherit('First'),
                      selected: true,
                    ),
                    SettingsRow.collection(
                      title: TRText.inherit('Second'),
                      selected: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
          width: TinestLayoutMetrics.settingsCollectionWidth,
        ),
      );

      final list = tester.widget<ListView>(
        find.descendant(
          of: find.byType(SettingsCollectionList),
          matching: find.byType(ListView),
        ),
      );
      expect(
        list.padding,
        const EdgeInsets.symmetric(
          horizontal: TRSpacing.medium,
          vertical: TRSpacing.medium,
        ),
      );

      final first = tester.getRect(find.widgetWithText(TinestListRow, 'First'));
      final second = tester.getRect(
        find.widgetWithText(TinestListRow, 'Second'),
      );
      expect(first.left, TRSpacing.medium);
      expect(
        first.right,
        TinestLayoutMetrics.settingsCollectionWidth - TRSpacing.medium,
      );
      expect(
        tester
            .widget<TinestListRow>(find.widgetWithText(TinestListRow, 'First'))
            .contentPadding,
        const EdgeInsets.symmetric(
          horizontal: TRSpacing.medium,
          vertical: TRSpacing.medium,
        ),
      );
      expect(second.top - first.bottom, TRSpacing.extraSmall);
      final separator = tester.getRect(find.byType(TRSeparator));
      expect(first.top - separator.bottom, TRSpacing.medium);
      final firstSurface = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.widgetWithText(TinestListRow, 'First'),
          matching: find.byType(AnimatedContainer),
        ),
      );
      expect(
        (firstSurface.decoration! as BoxDecoration).color,
        tester.element(find.text('First')).tinyrackTheme.surfaceHover,
      );
      expect(
        tester.getRect(find.text('First')).left,
        moreOrLessEquals(
          tester.getRect(find.text('Projects')).left,
          epsilon: 0.5,
        ),
      );
    },
  );

  testWidgets('compact collections keep the same row inset and alignment', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        SettingsListDetailLayout(
          collection: const Column(
            children: <Widget>[
              SettingsPaneHeader.collection(title: 'Projects'),
              Expanded(
                child: SettingsCollectionList(
                  children: <Widget>[
                    SettingsRow.collection(
                      title: TRText.inherit('Tinest'),
                      selected: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
          detail: const Text('Detail'),
          detailVisible: false,
          onBack: () {},
        ),
        width: 390,
      ),
    );

    final row = tester.getRect(find.widgetWithText(TinestListRow, 'Tinest'));
    expect(row.left, TRSpacing.medium);
    expect(row.right, 390 - TRSpacing.medium);
    expect(
      tester.getRect(find.text('Tinest')).left,
      moreOrLessEquals(
        tester.getRect(find.text('Projects')).left,
        epsilon: 0.5,
      ),
    );
    expect(
      tester.widget<TinestListRow>(find.byType(TinestListRow)).contentPadding,
      const EdgeInsets.symmetric(
        horizontal: TRSpacing.medium,
        vertical: TRSpacing.medium,
      ),
    );
  });

  testWidgets('standard rows retain the content selected surface', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const SettingsRow(title: TRText.inherit('Standard'), selected: true),
      ),
    );

    final surface = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byType(TinestListRow),
        matching: find.byType(AnimatedContainer),
      ),
    );
    expect(
      (surface.decoration! as BoxDecoration).color,
      tester.element(find.text('Standard')).tinyrackTheme.surfaceSelected,
    );
  });

  testWidgets('collection header matches the tree navigation leading inset', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const Column(
          children: <Widget>[
            SettingsPaneHeader.collection(title: 'Projects'),
            Expanded(
              child: SettingsCollectionList(
                children: <Widget>[
                  SettingsRow.collection(
                    leading: Icon(Icons.folder),
                    title: TRText.inherit('Tinest'),
                    selected: true,
                  ),
                ],
              ),
            ),
          ],
        ),
        width: TinestLayoutMetrics.settingsCollectionWidth,
      ),
    );

    final header = tester.getRect(find.text('Projects'));
    final row = tester.getRect(find.byType(TinestListRow));
    expect(
      header.left,
      moreOrLessEquals(row.left + TRSpacing.medium, epsilon: 0.5),
    );
  });

  testWidgets('list-detail skeleton uses the collection spacing contract', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const SettingsSkeletonLayout.listDetail(
          semanticLabel: 'Loading settings',
        ),
      ),
    );

    final list = tester.widget<ListView>(
      find.descendant(
        of: find.byType(SettingsCollectionList),
        matching: find.byType(ListView),
      ),
    );
    expect(
      list.padding,
      const EdgeInsets.symmetric(
        horizontal: TRSpacing.medium,
        vertical: TRSpacing.medium,
      ),
    );
    expect(
      find.descendant(
        of: find.byType(SettingsCollectionList),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Padding &&
              widget.padding == SettingsRow.collectionContentPadding,
        ),
      ),
      findsNWidgets(4),
    );
  });

  group('SettingsScaffold', () {
    testWidgets(
      'scrolls the focused final field above the keyboard and restores',
      (tester) async {
        const viewport = Size(390, 760);
        const keyboardHeight = 300.0;
        const fieldKey = ValueKey<String>('last-settings-input');
        final viewInsets = ValueNotifier<EdgeInsets>(EdgeInsets.zero);
        addTearDown(viewInsets.dispose);
        await tester.binding.setSurfaceSize(viewport);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          MaterialApp(
            theme: TinyrackTheme.light(),
            builder: (context, child) => ValueListenableBuilder<EdgeInsets>(
              valueListenable: viewInsets,
              builder: (context, insets, _) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  size: viewport,
                  viewInsets: insets,
                ),
                child: child!,
              ),
            ),
            home: TinestPageShell(
              body: SettingsScaffold(
                children: <Widget>[
                  for (var index = 0; index < 2; index += 1)
                    SettingsSection(
                      title: 'Section $index',
                      children: const <Widget>[SizedBox(height: 120)],
                    ),
                  const SettingsSection.form(
                    title: 'Final section',
                    children: <Widget>[
                      TRTextField(key: fieldKey, label: 'Endpoint'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.byKey(fieldKey), findsOneWidget);
        await tester.ensureVisible(find.byKey(fieldKey));
        await tester.showKeyboard(find.byKey(fieldKey));
        viewInsets.value = const EdgeInsets.only(bottom: keyboardHeight);
        await tester.pumpAndSettle();

        final keyboardTop = viewport.height - keyboardHeight;
        expect(
          tester.getRect(find.byKey(fieldKey)).bottom,
          lessThanOrEqualTo(keyboardTop),
        );
        expect(tester.takeException(), isNull);

        viewInsets.value = EdgeInsets.zero;
        await tester.pumpAndSettle();
        expect(tester.getRect(find.byType(TRAppShell)), Offset.zero & viewport);
        expect(tester.takeException(), isNull);
      },
      tags: const <String>['feature_test__soft_keyboard_visibility__widget'],
    );

    testWidgets('caps its content and centres it in a wide pane', (
      tester,
    ) async {
      // A real surface, not just a SizedBox: the default test window is
      // narrower than the cap, so the column would fill it and centring would
      // never be exercised.
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _host(
          SettingsScaffold(
            children: <Widget>[
              SettingsSection(
                title: 'Section',
                children: <Widget>[
                  SettingsRow(
                    title: const TRText.inherit('Row'),
                    control: TRButton(
                      onPressed: () {},
                      child: const TRText.inherit('Do'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          width: 1400,
        ),
      );

      // An unbounded column strands a label and its control at opposite edges
      // of a wide window, which is the defect this cap exists to prevent.
      final card = tester.getRect(find.byType(TRCard));
      expect(
        card.width,
        lessThanOrEqualTo(TinestLayoutMetrics.settingsContentMaxWidth),
      );

      // Centred, so a wide window does not strand the column against one
      // edge with a growing void beside it.
      expect(card.width, TinestLayoutMetrics.settingsContentMaxWidth);
      expect(card.left, moreOrLessEquals(1400 - card.right, epsilon: 0.5));
    });

    testWidgets('fills a pane narrower than the cap', (tester) async {
      await tester.pumpWidget(
        _host(
          const SettingsScaffold(
            children: <Widget>[
              SettingsSection(
                title: 'Section',
                children: <Widget>[SettingsRow(title: TRText.inherit('Row'))],
              ),
            ],
          ),
          // A list-detail detail pane is narrower than the cap, so centring
          // has to leave the column filling it rather than shrinking it.
          width: 600,
        ),
      );

      final card = tester.getRect(find.byType(TRCard));
      expect(card.left, TRSpacing.large);
      expect(card.width, 600 - 2 * TRSpacing.large);
    });

    testWidgets('separates its sections by one step', (tester) async {
      await tester.pumpWidget(
        _host(
          const SettingsScaffold(
            children: <Widget>[
              SettingsSection(title: 'First', children: <Widget>[]),
              SettingsSection(title: 'Second', children: <Widget>[]),
            ],
          ),
        ),
      );

      final first = tester.getRect(find.text('First'));
      final second = tester.getRect(find.text('Second'));
      expect(second.top - first.top, greaterThan(TRSpacing.twoExtraLarge));
    });
  });

  group('SettingsSection', () {
    testWidgets('heads every section at the same scale', (tester) async {
      await tester.pumpWidget(
        _host(
          const SettingsScaffold(
            children: <Widget>[
              SettingsSection(title: 'Boxed', children: <Widget>[]),
              SettingsSection.form(title: 'Form', children: <Widget>[]),
            ],
          ),
        ),
      );

      // Both section shapes carry one heading scale. Two sizes for one level
      // is what split the app-scoped pages from the daemon-scoped ones.
      for (final title in <String>['Boxed', 'Form']) {
        expect(
          tester.widget<TRText>(find.widgetWithText(TRText, title)).variant,
          TRTextVariant.headingMd,
        );
      }
    });

    testWidgets('uses the medium gap between a heading and its description', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const SettingsScaffold(
            children: <Widget>[
              SettingsSection(
                title: 'Section',
                description: 'Description',
                children: <Widget>[],
              ),
            ],
          ),
        ),
      );

      final heading = tester.getRect(find.widgetWithText(TRText, 'Section'));
      final description = tester.getRect(
        find.widgetWithText(TRText, 'Description'),
      );
      expect(
        description.top - heading.bottom,
        moreOrLessEquals(TRSpacing.medium, epsilon: 0.5),
      );
    });

    testWidgets('boxes rows and leaves form controls unboxed', (tester) async {
      await tester.pumpWidget(
        _host(
          const SettingsScaffold(
            children: <Widget>[
              SettingsSection(
                title: 'Boxed',
                children: <Widget>[SettingsRow(title: TRText.inherit('Row'))],
              ),
            ],
          ),
        ),
      );
      expect(find.byType(TRCard), findsOneWidget);

      await tester.pumpWidget(
        _host(
          const SettingsScaffold(
            children: <Widget>[
              SettingsSection.form(
                title: 'Form',
                children: <Widget>[TRTextField(label: 'Prompt')],
              ),
            ],
          ),
        ),
      );
      expect(find.byType(TRCard), findsNothing);
    });

    testWidgets('places a section action opposite its heading', (tester) async {
      await tester.pumpWidget(
        _host(
          SettingsScaffold(
            children: <Widget>[
              SettingsSection(
                title: 'Remotes',
                action: TRButton(
                  onPressed: () {},
                  child: const TRText.inherit('Add'),
                ),
                children: const <Widget>[],
              ),
            ],
          ),
        ),
      );

      // The action belongs on the heading line. Left to a Wrap inside a
      // centring Column it drifted to the middle of the pane instead.
      final heading = tester.getRect(find.text('Remotes'));
      final action = tester.getRect(find.byType(TRButton));
      expect(action.left, greaterThan(heading.right));
      expect(action.center.dy, moreOrLessEquals(heading.center.dy, epsilon: 2));
    });
  });

  group('SettingsSection header', () {
    testWidgets('wraps its action rather than overflowing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: TinyrackTheme.light(),
          home: MediaQuery(
            // A heading and its action do not fit on one line on a narrow
            // window at a large text scale, and a Row cannot give.
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: SizedBox(
                width: 390,
                child: SettingsScaffold(
                  children: <Widget>[
                    SettingsSection(
                      title: '원격 daemons',
                      action: TRButton(
                        onPressed: () {},
                        child: const TRText.inherit('원격 daemon 추가'),
                      ),
                      children: const <Widget>[],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('SettingsSection banner', () {
    testWidgets('sits between the heading and the content', (tester) async {
      await tester.pumpWidget(
        _host(
          const SettingsScaffold(
            children: <Widget>[
              SettingsSection(
                title: 'Reset',
                banner: TRAlert(title: TRText.inherit('Failed')),
                children: <Widget>[SettingsRow(title: TRText.inherit('Erase'))],
              ),
            ],
          ),
        ),
      );

      // A save result or a connection failure belongs to its section, so it
      // is placed inside the section rather than stacked above it as another
      // top-level block with a full section gap around it.
      final heading = tester.getRect(find.text('Reset'));
      final banner = tester.getRect(find.text('Failed'));
      final row = tester.getRect(find.text('Erase'));
      expect(banner.top, greaterThan(heading.bottom));
      expect(row.top, greaterThan(banner.bottom));
    });
  });

  group('SettingsRow', () {
    testWidgets('puts the description leading and the control trailing', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          SettingsScaffold(
            children: <Widget>[
              SettingsSection(
                title: 'Section',
                children: <Widget>[
                  SettingsRow(
                    title: const TRText.inherit('Theme'),
                    description: const TRText.inherit('Applies everywhere'),
                    control: TRButton(
                      onPressed: () {},
                      child: const TRText.inherit('Change'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

      final title = tester.getRect(find.text('Theme'));
      final description = tester.getRect(find.text('Applies everywhere'));
      final control = tester.getRect(find.byType(TRButton));
      expect(title.left, description.left);
      expect(control.left, greaterThan(title.right));
    });

    testWidgets('stacks a responsive control below readable copy when narrow', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          SettingsRow(
            title: const TRText.inherit('Display language'),
            description: const TRText.inherit(
              'Applies to the whole app and remains readable at narrow widths.',
            ),
            wrapsDescription: true,
            controlLayout: SettingsControlLayout.responsive,
            control: TRButton(
              onPressed: () {},
              child: const TRText.inherit('System default'),
            ),
          ),
          width:
              TRBreakpoints.small + SettingsRow.contentPadding.horizontal - 1,
        ),
      );

      final description = tester.getRect(
        find.text(
          'Applies to the whole app and remains readable at narrow widths.',
        ),
      );
      final control = tester.getRect(find.byType(TRButton));
      final row = tester.widget<TinestListRow>(find.byType(TinestListRow));
      expect(control.top, greaterThan(description.bottom));
      expect(row.trailingLayout, TinestListRowTrailingLayout.below);
      expect(row.unboundedSubtitle, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps a responsive control trailing when copy has room', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          SettingsRow(
            title: const TRText.inherit('Theme'),
            description: const TRText.inherit('Applies everywhere'),
            wrapsDescription: true,
            controlLayout: SettingsControlLayout.responsive,
            control: TRButton(
              onPressed: () {},
              child: const TRText.inherit('Follow system'),
            ),
          ),
          width: TRBreakpoints.small + SettingsRow.contentPadding.horizontal,
        ),
      );

      final title = tester.getRect(find.text('Theme'));
      final control = tester.getRect(find.byType(TRButton));
      final row = tester.widget<TinestListRow>(find.byType(TinestListRow));
      expect(control.left, greaterThan(title.right));
      expect(row.trailingLayout, TinestListRowTrailingLayout.inline);
      expect(row.unboundedSubtitle, isFalse);
    });

    testWidgets('keeps compact switch controls trailing on a narrow row', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          SettingsRow(
            title: const TRText.inherit('Enabled'),
            description: const TRText.inherit(
              'This explanatory sentence should remain fully readable.',
            ),
            wrapsDescription: true,
            control: TRSwitch(checked: true, onCheckedChange: (_) {}),
          ),
          width: 390,
        ),
      );

      final title = tester.getRect(find.text('Enabled'));
      final control = tester.getRect(find.byType(TRSwitch));
      final row = tester.widget<TinestListRow>(find.byType(TinestListRow));
      expect(control.left, greaterThan(title.right));
      expect(row.trailingLayout, TinestListRowTrailingLayout.inline);
      expect(row.unboundedSubtitle, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('wraps Japanese copy without overflow at large text scale', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: TinyrackTheme.light(),
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: SizedBox(
                width: 390,
                child: SettingsRow(
                  title: const TRText.inherit('表示言語'),
                  description: const TRText.inherit(
                    'アプリ全体に適用され、狭い画面でも省略されずに表示されます。',
                  ),
                  wrapsDescription: true,
                  controlLayout: SettingsControlLayout.responsive,
                  control: TRButton(
                    onPressed: () {},
                    child: const TRText.inherit('システム設定に従う'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final description = tester.getRect(
        find.text('アプリ全体に適用され、狭い画面でも省略されずに表示されます。'),
      );
      final control = tester.getRect(find.byType(TRButton));
      final row = tester.widget<TinestListRow>(find.byType(TinestListRow));
      expect(control.top, greaterThan(description.bottom));
      expect(row.trailingLayout, TinestListRowTrailingLayout.below);
      expect(row.unboundedSubtitle, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('insets every row in a card identically', (tester) async {
      await tester.pumpWidget(
        _host(
          SettingsScaffold(
            children: <Widget>[
              SettingsSection(
                title: 'Section',
                children: <Widget>[
                  SettingsRow(
                    leading: const Icon(Icons.circle),
                    title: const TRText.inherit('With leading'),
                    control: TRSwitch(checked: true, onCheckedChange: (_) {}),
                  ),
                  SettingsRow(
                    title: const TRText.inherit('Without leading'),
                    control: TRSwitch(checked: false, onCheckedChange: (_) {}),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

      // Two rows in one card drew their content at different insets, so the
      // card had no single alignment line down its leading edge.
      final rows = tester
          .widgetList<TinestListRow>(find.byType(TinestListRow))
          .toList();
      expect(rows, hasLength(2));
      expect(rows.first.contentPadding, rows.last.contentPadding);
      expect(
        rows.first.contentPadding,
        const EdgeInsets.symmetric(
          horizontal: TRSpacing.large,
          vertical: TRSpacing.medium,
        ),
      );

      // The trailing controls line up with each other too.
      final switches = find.byType(TRSwitch);
      expect(
        tester.getRect(switches.first).right,
        moreOrLessEquals(tester.getRect(switches.last).right, epsilon: 0.5),
      );
    });

    testWidgets('activates from the row when it carries a tap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          SettingsScaffold(
            children: <Widget>[
              SettingsSection(
                title: 'Section',
                children: <Widget>[
                  SettingsRow(
                    title: const TRText.inherit('Toggle me'),
                    onTap: () => taps++,
                    control: TRSwitch(checked: false, onCheckedChange: (_) {}),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.text('Toggle me'));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets(
      'keeps the settings surface stable while the row and switch are hovered',
      (tester) async {
        await tester.pumpWidget(
          _host(
            SettingsRow(
              key: const ValueKey<String>('settings-hover-row'),
              title: const TRText.inherit('Enabled'),
              onTap: () {},
              control: TRSwitch(checked: false, onCheckedChange: (_) {}),
            ),
          ),
        );

        final row = find.byKey(const ValueKey<String>('settings-hover-row'));
        final rowSurface = _rowSurface(row, SettingsRow.contentPadding);
        final switchFinder = find.byType(TRSwitch);
        final theme = tester.element(row).tinyrackTheme;
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        addTearDown(mouse.removePointer);
        await mouse.addPointer(location: Offset.zero);

        await mouse.moveTo(tester.getCenter(find.text('Enabled')));
        await tester.pumpAndSettle();
        expect(_containerColor(tester, rowSurface), theme.surface);

        await mouse.moveTo(tester.getCenter(switchFinder));
        await tester.pumpAndSettle();
        expect(_containerColor(tester, rowSurface), theme.surface);
        expect(
          _containerColor(tester, _switchSurface(switchFinder)),
          theme.surfaceHover,
        );
      },
    );

    testWidgets('keeps collection rows free of row hover', (tester) async {
      await tester.pumpWidget(
        _host(
          SettingsRow.collection(
            key: const ValueKey<String>('settings-collection-hover-row'),
            title: const TRText.inherit('Project'),
            onTap: () {},
          ),
        ),
      );

      final row = find.byKey(
        const ValueKey<String>('settings-collection-hover-row'),
      );
      final theme = tester.element(row).tinyrackTheme;
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.text('Project')));
      await tester.pumpAndSettle();

      expect(
        _containerColor(
          tester,
          _rowSurface(row, SettingsRow.collectionContentPadding),
        ),
        theme.surface,
      );
    });

    testWidgets('keeps hover for non-settings list rows', (tester) async {
      await tester.pumpWidget(
        _host(
          TinestListRow(
            contentPadding: SettingsRow.contentPadding,
            title: const TRText.inherit('Open'),
            onTap: () {},
          ),
        ),
      );

      final row = find.byType(TinestListRow);
      final theme = tester.element(row).tinyrackTheme;
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.text('Open')));
      await tester.pumpAndSettle();

      expect(
        _containerColor(tester, _rowSurface(row, SettingsRow.contentPadding)),
        theme.surfaceHover,
      );
    });
  });

  group('SettingsRow flush', () {
    testWidgets('drops only the inline inset', (tester) async {
      await tester.pumpWidget(
        _host(
          Column(
            children: <Widget>[
              const TRTextField(label: 'Base URL'),
              SettingsRow(
                flush: true,
                title: const TRText.inherit('Requires an API key'),
                control: TRSwitch(checked: true, onCheckedChange: (_) {}),
              ),
            ],
          ),
          width: 400,
        ),
      );

      // A dialog pads its own content, so a row inside one has to line up
      // with the fields above it rather than sitting a step further in.
      expect(
        tester.getRect(find.text('Requires an API key')).left,
        moreOrLessEquals(0, epsilon: 0.5),
      );
      // The vertical rhythm is unchanged, so a flush row is not a third inset.
      expect(
        tester.widget<TinestListRow>(find.byType(TinestListRow)).contentPadding,
        SettingsRow.flushPadding,
      );
    });
  });

  group('SettingsPaneHeader', () {
    testWidgets('aligns a list header with the rows beneath it', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const Column(
            children: <Widget>[
              SettingsPaneHeader.list(title: 'Projects'),
              SettingsRow(title: TRText.inherit('Tinest')),
            ],
          ),
          width: TinestLayoutMetrics.settingsCollectionWidth,
        ),
      );

      expect(
        tester.getRect(find.text('Projects')).left,
        moreOrLessEquals(
          tester.getRect(find.text('Tinest')).left,
          epsilon: 0.5,
        ),
      );
    });

    testWidgets('aligns a detail header with the pane body beneath it', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const Column(
            children: <Widget>[
              SettingsPaneHeader.detail(title: 'Tinest'),
              Expanded(
                child: SettingsScaffold(
                  children: <Widget>[
                    SettingsSection.form(
                      title: 'Hooks',
                      children: <Widget>[TRTextField(label: 'Setup')],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

      // A detail header inset less than its own body left the pane with two
      // competing leading edges.
      expect(
        tester.getRect(find.text('Tinest')).left,
        moreOrLessEquals(tester.getRect(find.text('Hooks')).left, epsilon: 0.5),
      );
    });

    testWidgets('spaces actions and wraps them below long titles', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: TinyrackTheme.light(),
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: SizedBox(
                width: 390,
                child: SettingsPaneHeader.detail(
                  title: 'A deliberately long settings detail heading',
                  subtitle: '/a/long/path/that/must/not/crowd/the/actions',
                  actions: <Widget>[
                    TRIconButton(
                      label: 'Copy',
                      onPressed: () {},
                      icon: const Icon(Icons.copy),
                    ),
                    TRButton(
                      key: const ValueKey<String>('save-action'),
                      onPressed: () {},
                      child: const TRText.inherit('Save'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final copy = tester.getRect(find.byType(TRIconButton));
      final save = tester.getRect(
        find.byKey(const ValueKey<String>('save-action')),
      );
      expect(save.left - copy.right, greaterThanOrEqualTo(TRSpacing.small));
    });
  });

  group('SettingsEmptyState', () {
    testWidgets('centres a readable title, description, and action', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          SettingsEmptyState(
            title: 'Nothing selected',
            description: 'Choose an item from the list to edit it.',
            icon: const Icon(Icons.tune),
            action: TRButton(
              onPressed: () {},
              child: const TRText.inherit('Create'),
            ),
          ),
          width: 900,
        ),
      );

      final title = tester.getRect(find.text('Nothing selected'));
      final description = tester.getRect(
        find.text('Choose an item from the list to edit it.'),
      );
      final action = tester.getRect(find.byType(TRButton));
      expect(
        title.center.dx,
        moreOrLessEquals(
          tester.getRect(find.byType(Scaffold)).center.dx,
          epsilon: 1,
        ),
      );
      expect(description.top - title.bottom, TRSpacing.extraSmall);
      expect(action.top - description.bottom, TRSpacing.large);
    });
  });

  group('SettingsDialogForm', () {
    testWidgets(
      'keeps the final field and action in the keyboard-visible viewport',
      (tester) async {
        const viewport = Size(390, 760);
        const keyboardHeight = 300.0;
        const fieldKey = ValueKey<String>('dialog-final-input');
        const actionKey = ValueKey<String>('dialog-primary-action');
        await tester.binding.setSurfaceSize(viewport);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          MaterialApp(
            theme: TinyrackTheme.light(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                size: viewport,
                viewInsets: const EdgeInsets.only(bottom: keyboardHeight),
              ),
              child: child!,
            ),
            home: Builder(
              builder: (context) => TRButton(
                onPressed: () => showTRAlertDialog<void>(
                  context: context,
                  builder: (context) => TRAlertDialog(
                    title: const TRText.inherit('Edit connection'),
                    content: SettingsDialogForm(
                      children: <Widget>[
                        for (var index = 0; index < 7; index += 1)
                          TRTextField(label: 'Field $index'),
                        const TRTextField(
                          key: fieldKey,
                          label: 'Final field',
                        ),
                      ],
                    ),
                    actions: <TRButton>[
                      TRButton(
                        key: actionKey,
                        onPressed: () {},
                        child: const TRText.inherit('Save'),
                      ),
                    ],
                  ),
                ),
                child: const TRText.inherit('Open'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(fieldKey));
        await tester.showKeyboard(find.byKey(fieldKey));
        await tester.pumpAndSettle();

        final keyboardTop = viewport.height - keyboardHeight;
        expect(
          tester.getRect(find.byKey(fieldKey)).bottom,
          lessThanOrEqualTo(keyboardTop),
        );
        expect(
          tester.getRect(find.byKey(actionKey)).bottom,
          lessThanOrEqualTo(keyboardTop),
        );
        expect(tester.takeException(), isNull);
      },
      tags: const <String>['feature_test__soft_keyboard_visibility__widget'],
    );

    testWidgets('uses the overlay token and one gap between fields', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const Center(
            child: SettingsDialogForm(
              children: <Widget>[
                TRTextField(label: 'Name'),
                TRTextField(label: 'Description'),
              ],
            ),
          ),
        ),
      );

      final form = tester.getRect(find.byType(SettingsDialogForm));
      final fields = find.byType(TRTextField);
      expect(form.width, TRMeasurements.overlayWidthMd);
      expect(
        tester.getRect(fields.at(1)).top - tester.getRect(fields.at(0)).bottom,
        TRSpacing.large,
      );
    });
  });

  group('SettingsCompactToolbar', () {
    testWidgets('gives every select the full width', (tester) async {
      await tester.pumpWidget(
        _host(
          SettingsCompactToolbar(
            builder: (width) => <Widget>[
              for (final label in <String>['Category', 'Daemon', 'Project'])
                TRSelect<String>.controlled(
                  value: null,
                  label: label,
                  width: width,
                  items: const <TRSelectItem<String>>[
                    TRSelectItem<String>(value: 'a', label: 'A'),
                  ],
                  onValueChange: (_) {},
                ),
            ],
          ),
          width: 390,
        ),
      );

      // Three stacked selects rendered at three different widths and
      // alignments, because only one of them was told to fill the pane. The
      // trigger has to fill it, not just the field around it: a tap lands on
      // the centre of the control, which otherwise falls in empty space.
      const expected = 390 - 2 * TRSpacing.large;
      final triggers = find.descendant(
        of: find.byType(SettingsCompactToolbar),
        matching: find.byType(TextButton),
      );
      expect(triggers, findsNWidgets(3));
      for (var index = 0; index < 3; index++) {
        expect(tester.getRect(triggers.at(index)).width, expected);
      }
    });
  });
}
