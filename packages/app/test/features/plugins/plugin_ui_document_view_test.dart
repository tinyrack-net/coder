import 'package:app/src/features/plugins/presentation/plugin_ui_document_view.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:protocol/protocol.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

import '../../support/localization.dart';

void main() {
  testWidgets(
    'renders every allowlisted node and dispatches host-owned actions',
    (tester) async {
      final actions = <PluginUiActionDto>[];
      const document = PluginUiDocumentDto(
        id: 'document',
        pluginId: 'example.controls',
        revisionHash: 'revision',
        slot: PluginUiSlot.agentSettings,
        root: <String, dynamic>{
          'type': 'section',
          'title': 'Controls',
          'description': 'Native host controls',
          'children': <Map<String, dynamic>>[
            <String, dynamic>{'type': 'text', 'text': 'Plain text'},
            <String, dynamic>{
              'type': 'markdown',
              'text': '**Markdown text**',
            },
            <String, dynamic>{
              'type': 'code',
              'code': 'print("hello")',
              'language': 'lua',
            },
            <String, dynamic>{
              'type': 'diff',
              'code': '- old\n+ new',
            },
            <String, dynamic>{
              'type': 'alert',
              'title': 'Attention',
              'description': 'Review this value.',
              'variant': 'warning',
            },
            <String, dynamic>{
              'type': 'row',
              'children': <Map<String, dynamic>>[
                <String, dynamic>{
                  'type': 'badge',
                  'text': 'Ready',
                  'variant': 'success',
                },
                <String, dynamic>{
                  'type': 'progress',
                  'label': 'Progress',
                  'value': 50,
                },
              ],
            },
            <String, dynamic>{
              'type': 'disclosure',
              'title': 'Details',
              'open': true,
              'children': <Map<String, dynamic>>[
                <String, dynamic>{'type': 'text', 'text': 'Hidden detail'},
              ],
            },
            <String, dynamic>{
              'type': 'field',
              'id': 'query',
              'label': 'Query',
              'value': 'initial',
            },
            <String, dynamic>{
              'type': 'switch',
              'id': 'enabled',
              'label': 'Enabled',
              'value': true,
              'actionId': 'toggle',
            },
            <String, dynamic>{
              'type': 'select',
              'id': 'mode',
              'label': 'Mode',
              'value': 'safe',
              'options': <Map<String, dynamic>>[
                <String, dynamic>{'value': 'safe', 'label': 'Safe'},
                <String, dynamic>{'value': 'fast', 'label': 'Fast'},
              ],
            },
            <String, dynamic>{
              'type': 'button',
              'label': 'Apply',
              'actionId': 'apply',
              'intent': 'primary',
            },
          ],
        },
      );

      await tester.pumpWidget(
        _TestApp(
          child: SingleChildScrollView(
            child: PluginUiDocumentView(
              document: document,
              invalidDocumentLabel: 'Unsupported plugin interface',
              invalidDocumentDescription: 'Open the raw document',
              onAction: (action) async {
                actions.add(action);
                return document;
              },
            ),
          ),
        ),
      );

      expect(find.byType(TRCard), findsOneWidget);
      expect(find.byType(TRCodeBlock), findsNWidgets(2));
      expect(find.byType(TRAlert), findsOneWidget);
      expect(find.byType(TRBadge), findsOneWidget);
      expect(find.byType(TRProgress), findsOneWidget);
      expect(find.byType(TRCollapsible), findsOneWidget);
      expect(find.byType(TRTextField), findsOneWidget);
      expect(find.byType(TRSwitch), findsOneWidget);
      expect(find.byType(TRSelect<String>), findsOneWidget);
      expect(
        tester
            .widget<TRSelect<String>>(find.byType(TRSelect<String>))
            .presentation,
        isA<TRSelectLayerPresentation>(),
      );

      await tester.ensureVisible(find.widgetWithText(TRButton, 'Apply'));
      await tester.tap(find.widgetWithText(TRButton, 'Apply'));
      await tester.pumpAndSettle();

      expect(actions, hasLength(1));
      expect(actions.single.actionId, 'apply');
      expect(
        actions.single.data,
        containsPair(
          'values',
          <String, dynamic>{
            'query': 'initial',
            'enabled': true,
            'mode': 'safe',
          },
        ),
      );
    },
    tags: const <String>['feature_test__plugin_ui__widget'],
  );

  testWidgets(
    'falls back to a generic disclosure for an invalid document',
    (tester) async {
      const document = PluginUiDocumentDto(
        id: 'invalid',
        pluginId: 'example.invalid',
        revisionHash: 'revision',
        slot: PluginUiSlot.timeline,
        root: <String, dynamic>{
          'type': 'iframe',
          'src': 'https://untrusted.example',
        },
      );

      await tester.pumpWidget(
        const _TestApp(
          child: PluginUiDocumentView(
            document: document,
            invalidDocumentLabel: 'Unsupported plugin interface',
            invalidDocumentDescription: 'Open the raw document',
          ),
        ),
      );

      expect(find.byType(TRCollapsible), findsOneWidget);
      expect(find.text('Unsupported plugin interface'), findsOneWidget);
      expect(find.byType(TRButton), findsNothing);
      expect(find.byType(TRSwitch), findsNothing);
      expect(find.bySemanticsLabel('Unsupported plugin interface'), findsOne);
    },
    tags: const <String>['feature_test__plugin_ui__widget'],
  );

  testWidgets(
    'renders the pinned context-compaction timeline snapshot',
    (tester) async {
      const document = PluginUiDocumentDto(
        id: 'context-status',
        pluginId: 'tinest.context',
        revisionHash: 'context-revision',
        slot: PluginUiSlot.timeline,
        root: <String, dynamic>{
          'type': 'alert',
          'id': 'context-status',
          'title': 'Compacting context',
          'description':
              'The Agent driver is summarizing and replacing its model '
              'history.',
        },
      );

      await tester.pumpWidget(
        const _TestApp(
          child: PluginUiDocumentView(
            document: document,
            invalidDocumentLabel: 'Unsupported plugin interface',
            invalidDocumentDescription: 'Open the raw document',
          ),
        ),
      );

      expect(find.byType(TRAlert), findsOneWidget);
      expect(find.text('Compacting context'), findsOneWidget);
      expect(
        find.text(
          'The Agent driver is summarizing and replacing its model history.',
        ),
        findsOneWidget,
      );
    },
    tags: const <String>[
      'feature_test__context_compaction__widget',
      'feature_test__plugin_ui__widget',
    ],
  );

  testWidgets(
    'keeps native semantics and layout across themes locales and large text',
    (tester) async {
      const document = PluginUiDocumentDto(
        id: 'accessible',
        pluginId: 'example.accessible',
        revisionHash: 'revision',
        slot: PluginUiSlot.dialog,
        root: <String, dynamic>{
          'type': 'section',
          'title': 'Controls',
          'children': <Map<String, dynamic>>[
            <String, dynamic>{
              'type': 'field',
              'id': 'name',
              'label': 'Name',
              'value': 'Tinest',
            },
            <String, dynamic>{
              'type': 'button',
              'label': 'Save',
              'actionId': 'save',
            },
          ],
        },
      );

      for (final locale in const <Locale>[
        Locale('en'),
        Locale('ko'),
        Locale('ja'),
      ]) {
        for (final mode in ThemeMode.values) {
          await tester.pumpWidget(
            _TestApp(
              locale: locale,
              themeMode: mode,
              textScaler: const TextScaler.linear(2),
              child: const PluginUiDocumentView(
                document: document,
                semanticLabel: 'Plugin controls',
                invalidDocumentLabel: 'Unsupported plugin interface',
                invalidDocumentDescription: 'Open the raw document',
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.bySemanticsLabel('Plugin controls'), findsOneWidget);
          expect(find.byType(TRTextField), findsOneWidget);
          expect(find.widgetWithText(TRButton, 'Save'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      }
    },
    tags: const <String>['feature_test__plugin_ui__widget'],
  );

  testWidgets(
    'uses the native keyboard action path',
    (tester) async {
      const document = PluginUiDocumentDto(
        id: 'keyboard',
        pluginId: 'example.keyboard',
        revisionHash: 'revision',
        slot: PluginUiSlot.dialog,
        root: <String, dynamic>{
          'type': 'button',
          'label': 'Run',
          'actionId': 'run',
        },
      );
      final actions = <PluginUiActionDto>[];
      await tester.pumpWidget(
        _TestApp(
          child: PluginUiDocumentView(
            document: document,
            invalidDocumentLabel: 'Unsupported plugin interface',
            invalidDocumentDescription: 'Open the raw document',
            onAction: (action) async {
              actions.add(action);
              return document;
            },
          ),
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(actions.map((action) => action.actionId), <String>['run']);
    },
    tags: const <String>['feature_test__plugin_ui__widget'],
  );
}

class _TestApp extends StatelessWidget {
  const _TestApp({
    required this.child,
    this.locale = testLocale,
    this.themeMode,
    this.textScaler = TextScaler.noScaling,
  });

  final Widget child;
  final Locale locale;
  final ThemeMode? themeMode;
  final TextScaler textScaler;

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: testLightTheme,
    darkTheme: testDarkTheme,
    locale: locale,
    themeMode: themeMode,
    localizationsDelegates: testLocalizationsDelegates,
    supportedLocales: testSupportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: textScaler),
      child: child!,
    ),
    home: Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(TRSpacing.medium),
          child: child,
        ),
      ),
    ),
  );
}
