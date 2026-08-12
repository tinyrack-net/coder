part of '../app/app_flows_test.dart';

void _registerSharedAppFlows() {
  testWidgets(
    'model selection is owned by the design-system Select',
    (tester) async {
      const hostKey = ValueKey('model-picker-host');
      await tester.pumpWidget(
        MaterialApp(
          locale: testLocale,
          localizationsDelegates: testLocalizationsDelegates,
          supportedLocales: testSupportedLocales,
          theme: testLightTheme,
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                key: hostKey,
                width: 560,
                height: 600,
                child: AsyncModelSelect(
                  loadOptions: () async => const <ModelPickerOption>[],
                  currentSelection: null,
                  inheritLabel: 'Automatic',
                  onValueChange: (_) {},
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      final select = tester.widget<TRSelect<ModelPickerOption?>>(
        find.byType(TRSelect<ModelPickerOption?>),
      );
      expect(select.searchable, isTrue);
      expect(select.surface, TRSelectSurface.auto);
      expect(find.byType(TRDialog), findsNothing);
    },
    tags: const <String>['feature_test__session_lifecycle__widget'],
  );
}
