import 'package:coder_app/src/coder_list_row.dart';
import 'package:coder_app/src/settings/settings_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// Hosts one composite at a fixed width, so a geometry expectation reads the
/// composite rather than whatever the surrounding page happened to impose.
Widget _host(Widget child, {double width = 1200}) => MaterialApp(
  theme: TinyrackTheme.light(),
  home: Scaffold(
    body: SizedBox(width: width, child: child),
  ),
);

void main() {
  group('SettingsScaffold', () {
    testWidgets('caps its content and keeps it against the leading edge', (
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
        ),
      );

      // An unbounded column strands a label and its control at opposite edges
      // of a wide window, which is the defect this cap exists to prevent.
      final card = tester.getRect(find.byType(TRCard));
      expect(card.width, lessThanOrEqualTo(TRMeasurements.readingWidthMd));

      // Left aligned, not centred: the settings sidebar already weights the
      // window to one side.
      expect(card.left, TRSpacing.extraLarge);
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

    testWidgets('boxes rows and leaves form controls unboxed', (tester) async {
      await tester.pumpWidget(
        _host(
          const SettingsScaffold(
            children: <Widget>[
              SettingsSection(
                title: 'Boxed',
                children: <Widget>[
                  SettingsRow(title: TRText.inherit('Row')),
                ],
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
      expect(
        action.center.dy,
        moreOrLessEquals(heading.center.dy, epsilon: 2),
      );
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
                children: <Widget>[
                  SettingsRow(title: TRText.inherit('Erase')),
                ],
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
          .widgetList<CoderListRow>(find.byType(CoderListRow))
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

    testWidgets('activates from the row when it carries a tap', (
      tester,
    ) async {
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
        tester.widget<CoderListRow>(find.byType(CoderListRow)).contentPadding,
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
              SettingsRow(title: TRText.inherit('Coder')),
            ],
          ),
          width: TRMeasurements.paneMd,
        ),
      );

      expect(
        tester.getRect(find.text('Projects')).left,
        moreOrLessEquals(tester.getRect(find.text('Coder')).left, epsilon: 0.5),
      );
    });

    testWidgets('aligns a detail header with the pane body beneath it', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const Column(
            children: <Widget>[
              SettingsPaneHeader.detail(title: 'Coder'),
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
        tester.getRect(find.text('Coder')).left,
        moreOrLessEquals(tester.getRect(find.text('Hooks')).left, epsilon: 0.5),
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
