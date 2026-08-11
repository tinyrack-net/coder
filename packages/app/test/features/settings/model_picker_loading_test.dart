import 'dart:async';

import 'package:app/src/shared/presentation/model_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

import '../../support/localization.dart';

void main() {
  testWidgets(
    'model picker opens immediately and replaces its skeleton with models',
    (tester) async {
      final gate = Completer<List<ModelPickerOption>>();
      await tester.binding.setSurfaceSize(const Size(1000, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _host(() => gate.future, size: const Size(1000, 800)),
      );

      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(TRMotion.normal);

      expect(
        find.byKey(const ValueKey<String>('settings-skeleton-overlay')),
        findsOneWidget,
      );
      expect(find.byType(TRDialog), findsOneWidget);

      gate.complete(const <ModelPickerOption>[_option]);
      await tester.pump();
      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('settings-skeleton-overlay')),
        findsNothing,
      );
      expect(find.text('provider/gpt-test'), findsOneWidget);
    },
    tags: const <String>['feature_test__settings_async_loading__widget'],
  );

  testWidgets(
    'model picker keeps its overlay open while retrying a load',
    (
      tester,
    ) async {
      final first = Completer<List<ModelPickerOption>>();
      final second = Completer<List<ModelPickerOption>>();
      var calls = 0;
      await tester.binding.setSurfaceSize(const Size(390, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _host(
          () => calls++ == 0 ? first.future : second.future,
          size: const Size(390, 760),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(TRMotion.normal);
      expect(find.byType(TRDrawer), findsOneWidget);

      first.completeError(Exception('catalog failed'));
      await tester.pump();
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('model-picker-load-error')),
        findsOneWidget,
      );

      await tester.tap(find.text('다시 시도'));
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('settings-skeleton-overlay')),
        findsOneWidget,
      );

      second.complete(const <ModelPickerOption>[_option]);
      await tester.pump();
      await tester.pump();
      expect(find.text('provider/gpt-test'), findsOneWidget);
    },
    tags: const <String>['feature_test__settings_async_loading__widget'],
  );

  testWidgets(
    'mobile model sheet keeps its surface edge to edge and content safe',
    (tester) async {
      const size = Size(390, 760);
      const insets = EdgeInsets.fromLTRB(12, 24, 8, 34);
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _host(
          () async => const <ModelPickerOption>[_option],
          size: size,
          padding: insets,
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final drawer = find.byType(TRDrawer);
      final safeArea = find.descendant(
        of: drawer,
        matching: find.byType(SafeArea),
      );
      final safeContent = find.descendant(
        of: safeArea,
        matching: find.byType(Padding),
      );
      expect(tester.getRect(drawer).bottom, size.height);
      expect(
        tester.getSize(drawer).height,
        lessThanOrEqualTo(size.height * 0.7),
      );
      expect(tester.getRect(safeContent.at(1)).left, insets.left);
      expect(
        tester.getRect(safeContent.at(1)).right,
        size.width - insets.right,
      );
      expect(
        tester.getRect(safeContent.at(1)).bottom,
        size.height - insets.bottom,
      );
    },
    tags: const <String>['feature_test__settings_async_loading__widget'],
  );

  testWidgets(
    'long mobile model sheet stays capped and scrolls to the last option',
    (tester) async {
      const size = Size(390, 760);
      final options = <ModelPickerOption>[
        for (var index = 0; index < 40; index += 1)
          ModelPickerOption(
            providerName: 'Provider',
            model: ProviderModelDto(
              connectionId: 'provider',
              id: 'provider/model-$index',
              providerModelId: 'model-$index',
              label: 'Model $index',
              source: ProviderModelSource.bundled,
              capabilities: const ModelCapabilitiesDto(),
            ),
          ),
      ];
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_host(() async => options, size: size));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final drawer = find.byType(TRDrawer);
      final lastOption = find.byKey(
        const ValueKey<String>('model-option-provider-model-39'),
      );
      expect(tester.getSize(drawer).height, size.height * 0.7);
      expect(tester.getRect(lastOption).top, greaterThan(size.height));

      await tester.ensureVisible(lastOption);
      await tester.pumpAndSettle();
      expect(
        tester.getRect(lastOption).bottom,
        lessThanOrEqualTo(tester.getRect(drawer).bottom),
      );
      await tester.tap(lastOption);
      await tester.pumpAndSettle();
      expect(find.byType(TRDrawer), findsNothing);
    },
    tags: const <String>['feature_test__settings_async_loading__widget'],
  );

  testWidgets(
    'long desktop model dialog delegates overflow scrolling to the dialog',
    (tester) async {
      const size = Size(1000, 800);
      final options = <ModelPickerOption>[
        for (var index = 0; index < 40; index += 1)
          ModelPickerOption(
            providerName: 'Provider',
            model: ProviderModelDto(
              connectionId: 'provider',
              id: 'provider/desktop-$index',
              providerModelId: 'desktop-$index',
              label: 'Desktop $index',
              source: ProviderModelSource.bundled,
              capabilities: const ModelCapabilitiesDto(),
            ),
          ),
      ];
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_host(() async => options, size: size));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(TRDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.enterText(
        find.byKey(const ValueKey<String>('model-search-field')),
        'desktop-39',
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey<String>('model-option-provider-desktop-39'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TRDialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
    tags: const <String>['feature_test__settings_async_loading__widget'],
  );
}

const _option = ModelPickerOption(
  providerName: 'Test provider',
  model: ProviderModelDto(
    connectionId: 'provider',
    id: 'provider/gpt-test',
    providerModelId: 'gpt-test',
    label: 'GPT Test',
    source: ProviderModelSource.bundled,
    capabilities: ModelCapabilitiesDto(),
  ),
);

Widget _host(
  ModelPickerOptionsLoader loader, {
  required Size size,
  EdgeInsets padding = EdgeInsets.zero,
}) => MaterialApp(
  locale: testLocale,
  localizationsDelegates: testLocalizationsDelegates,
  supportedLocales: testSupportedLocales,
  theme: testLightTheme,
  builder: (context, child) => MediaQuery(
    data:
        MediaQuery.of(
          context,
        ).copyWith(
          size: size,
          padding: padding,
          viewPadding: padding,
          disableAnimations: true,
        ),
    child: child!,
  ),
  home: Builder(
    builder: (context) => Center(
      child: TRButton(
        onPressed: () => unawaited(
          showModelPicker(
            context,
            loadOptions: loader,
            currentSelection: null,
          ),
        ),
        child: const TRText.inherit('Open'),
      ),
    ),
  ),
);
