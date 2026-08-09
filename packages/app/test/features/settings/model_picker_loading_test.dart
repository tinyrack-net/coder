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

Widget _host(ModelPickerOptionsLoader loader, {required Size size}) =>
    MaterialApp(
      locale: testLocale,
      localizationsDelegates: testLocalizationsDelegates,
      supportedLocales: testSupportedLocales,
      theme: testLightTheme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(size: size, disableAnimations: true),
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
