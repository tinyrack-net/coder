part of '../app/app_flows_test.dart';

void _registerSharedAppFlows() {
  testWidgets(
    'model picker relies on the dialog for content margins',
    (tester) async {
      const hostKey = ValueKey('model-picker-host');
      await tester.pumpWidget(
        MaterialApp(
          locale: testLocale,
          localizationsDelegates: testLocalizationsDelegates,
          supportedLocales: testSupportedLocales,
          theme: testLightTheme,
          home: const Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                key: hostKey,
                width: 560,
                height: 600,
                child: ModelPicker(
                  options: <ModelPickerOption>[],
                  currentSelection: null,
                  title: 'Model picker',
                ),
              ),
            ),
          ),
        ),
      );

      final host = find.byKey(hostKey);
      final title = find.text('Model picker');
      final search = find.byKey(const ValueKey('model-search-field'));
      expect(tester.getTopLeft(title).dx, tester.getTopLeft(host).dx);
      expect(tester.getSize(search).width, tester.getSize(host).width);
    },
    tags: const <String>['feature_test__session_lifecycle__widget'],
  );
}
